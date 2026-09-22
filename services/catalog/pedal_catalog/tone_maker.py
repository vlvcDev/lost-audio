"""Device-side AI planning for intentional, user-approved tone changes."""

from __future__ import annotations

import json
import secrets
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Protocol

from .index import upsert_model
from .jev_ranker import JevError, JevRigRanker
from .tone3000_service import Tone3000Service
from .tone_memory import ToneMemoryError, ToneMemoryService


OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses"
PLAN_TTL_SECONDS = 10 * 60

CONTROL_RANGES = {
    "pedal_drive_db": (0.0, 24.0),
    "pedal_mix": (0.0, 1.0),
    "pedal_level_db": (-24.0, 12.0),
    "gate_threshold_db": (-80.0, -10.0),
    "compressor_ratio": (1.0, 20.0),
    "amp_bass_db": (-12.0, 12.0),
    "amp_mid_db": (-12.0, 12.0),
    "amp_treble_db": (-12.0, 12.0),
    "amp_volume_db": (-24.0, 12.0),
    "eq_low_db": (-12.0, 12.0),
    "eq_mid_db": (-12.0, 12.0),
    "eq_high_db": (-12.0, 12.0),
    "delay_mix": (0.0, 1.0),
    "reverb_mix": (0.0, 1.0),
}
EFFECT_KEYS = ("eq", "chorus", "delay", "reverb")


class ToneMakerError(RuntimeError):
    """Raised for safe, user-facing AI tone-maker failures."""


class OpenAITransport(Protocol):
    def send(self, request: urllib.request.Request) -> dict[str, Any]: ...


class UrllibOpenAITransport:
    """Minimal dependency-free transport so the catalog stays easy to deploy."""

    def send(self, request: urllib.request.Request) -> dict[str, Any]:
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                payload = json.loads(response.read())
        except urllib.error.HTTPError as error:
            detail = ""
            try:
                body = json.loads(error.read())
                detail = str(body.get("error", {}).get("message") or body.get("message") or "")
            except (json.JSONDecodeError, UnicodeDecodeError, AttributeError):
                pass
            suffix = f": {detail}" if detail else ""
            raise ToneMakerError(f"OpenAI request failed ({error.code}){suffix}") from error
        except (urllib.error.URLError, TimeoutError) as error:
            raise ToneMakerError("OpenAI could not be reached") from error
        if not isinstance(payload, dict):
            raise ToneMakerError("OpenAI returned an invalid response")
        return payload


@dataclass(frozen=True)
class TonePlan:
    summary: str
    pedal_query: str
    amp_query: str
    controls: dict[str, float]
    effects: dict[str, bool]

    @classmethod
    def from_payload(cls, payload: dict[str, Any]) -> "TonePlan":
        try:
            controls = {
                name: float(payload["controls"][name]) for name in CONTROL_RANGES
            }
            effects = {name: bool(payload["effects"][name]) for name in EFFECT_KEYS}
            summary = str(payload["summary"]).strip()[:240]
            pedal_query = str(payload["pedal_query"]).strip()[:160]
            amp_query = str(payload["amp_query"]).strip()[:160]
        except (KeyError, TypeError, ValueError) as error:
            raise ToneMakerError("OpenAI returned an incomplete tone plan") from error
        if not summary or not pedal_query or not amp_query:
            raise ToneMakerError("OpenAI returned an incomplete tone plan")
        for name, value in controls.items():
            low, high = CONTROL_RANGES[name]
            if not low <= value <= high:
                raise ToneMakerError("OpenAI returned a tone control outside its safe range")
        return cls(summary, pedal_query, amp_query, controls, effects)

    def as_payload(self) -> dict[str, Any]:
        return {
            "summary": self.summary,
            "pedal_query": self.pedal_query,
            "amp_query": self.amp_query,
            "controls": self.controls,
            "effects": self.effects,
        }


@dataclass(frozen=True)
class ToneRig:
    """One explicitly selectable pedal + amp pairing."""

    label: str
    rationale: str
    pedal: dict[str, Any] | None
    amp: dict[str, Any]
    ranking_confidence: float | None = None
    ranking_score: float | None = None

    def as_payload(self) -> dict[str, Any]:
        return {
            "label": self.label,
            "rationale": self.rationale,
            "pedal": self.pedal,
            "amp": self.amp,
            "ranking_confidence": self.ranking_confidence,
            "ranking_score": self.ranking_score,
        }


@dataclass(frozen=True)
class ToneRecommendation:
    identifier: str
    expires_at: float
    prompt: str
    plan: TonePlan
    rigs: list[ToneRig]
    ranking_provider: str
    ranking_note: str | None = None

    def as_payload(self) -> dict[str, Any]:
        return {
            "recommendation_id": self.identifier,
            "expires_at": self.expires_at,
            "plan": self.plan.as_payload(),
            "rigs": [rig.as_payload() for rig in self.rigs],
            "ranking_provider": self.ranking_provider,
            "ranking_note": self.ranking_note,
        }


class ToneMakerService:
    """Plans with OpenAI, searches TONE3000, and optionally ranks with Jev."""

    def __init__(
        self,
        api_key: str,
        *,
        model: str = "gpt-5-mini",
        transport: OpenAITransport | None = None,
        jev_ranker: JevRigRanker | None = None,
        tone_memory: ToneMemoryService | None = None,
        clock: callable = time.time,
    ) -> None:
        self.api_key = api_key
        self.model = model
        self.transport = transport or UrllibOpenAITransport()
        self.jev_ranker = jev_ranker
        self.tone_memory = tone_memory
        self.clock = clock
        self._recommendations: dict[str, ToneRecommendation] = {}

    @property
    def available(self) -> bool:
        return bool(self.api_key.strip())

    def status(self, tone3000: Tone3000Service | None) -> dict[str, Any]:
        try:
            memory_available = bool(self.tone_memory and self.tone_memory.has_records())
        except ToneMemoryError:
            memory_available = False
        return {
            "available": self.available,
            "tone3000_connected": bool(tone3000 and tone3000.connected),
            "jev_available": bool(self.jev_ranker and self.jev_ranker.available),
            "tone_memory_available": memory_available,
        }

    def recommend(
        self, prompt: str, tone3000: Tone3000Service | None
    ) -> ToneRecommendation:
        prompt = prompt.strip()
        if not 3 <= len(prompt) <= 500:
            raise ToneMakerError("Describe the tone in 3 to 500 characters")
        if self.tone_memory is not None:
            # Each recipe carries its own controls/effects; recall one proven
            # match at a time rather than mixing a different rig with the
            # first match's settings.
            try:
                saved = self.tone_memory.matches(prompt, limit=1)
            except ToneMemoryError as error:
                raise ToneMakerError(str(error)) from error
            if saved:
                return self._recommend_from_memory(prompt, saved)
        if not self.available:
            raise ToneMakerError("OpenAI is not configured on this device")
        if tone3000 is None or not tone3000.connected:
            raise ToneMakerError("Connect your TONE3000 account before making a tone")
        plan = self._plan(prompt)
        pedal_candidates = tone3000.search(plan.pedal_query, role="pedal")
        amp_candidates = tone3000.search(plan.amp_query, role="amp")
        if not amp_candidates:
            raise ToneMakerError("TONE3000 did not return compatible NAM A2 candidates")
        ranking_provider, ranking_note, rigs = self._rank_rigs(
            plan, pedal_candidates, amp_candidates
        )
        self._prune_expired()
        recommendation = ToneRecommendation(
            identifier=secrets.token_urlsafe(18),
            expires_at=self.clock() + PLAN_TTL_SECONDS,
            prompt=prompt,
            plan=plan,
            rigs=rigs,
            ranking_provider=ranking_provider,
            ranking_note=ranking_note,
        )
        self._recommendations[recommendation.identifier] = recommendation
        return recommendation

    def apply(
        self,
        recommendation_id: str,
        rig_index: int,
        tone3000: Tone3000Service | None,
        models_dir: Path,
        database: Path,
    ) -> dict[str, Any]:
        self._prune_expired()
        recommendation = self._recommendations.get(recommendation_id)
        if recommendation is None:
            raise ToneMakerError("That AI recommendation expired; ask again to refresh it")
        if not 0 <= rig_index < len(recommendation.rigs):
            raise ToneMakerError("That rig choice is no longer available; ask again to refresh it")
        rig = recommendation.rigs[rig_index]
        needs_download = any(
            candidate is not None and "local_path" not in candidate
            for candidate in (rig.pedal, rig.amp)
        )
        if needs_download and (tone3000 is None or not tone3000.connected):
            raise ToneMakerError("Connect your TONE3000 account before applying a tone")
        installed: dict[str, Any] = {}
        for role, candidate in (
            ("pre_model", rig.pedal),
            ("amp_model", rig.amp),
        ):
            if candidate is None:
                continue
            local_path = candidate.get("local_path")
            if isinstance(local_path, str):
                path = Path(local_path)
                if not path.is_file() or path.suffix != ".nam":
                    raise ToneMakerError("A saved Tone Memory model is no longer available")
                source = str(candidate.get("source", "tone-memory"))
            else:
                tone_id = str(candidate["id"])
                assert tone3000 is not None
                path, _ = tone3000.download_best_model(tone_id, models_dir)
                source = f"tone3000:ai:{tone_id}"
            installed[role] = {
                **upsert_model(path, database, source=source).__dict__,
                "tone": candidate,
            }
        if "amp_model" not in installed:
            raise ToneMakerError("No compatible amp NAM was available to apply")
        self._recommendations.pop(recommendation_id, None)
        tone_memory = {
            "query": recommendation.prompt,
            "summary": recommendation.plan.summary,
            "rig_label": rig.label,
            "controls": recommendation.plan.controls,
            "effects": recommendation.plan.effects,
            "amp_model": _memory_model(installed["amp_model"]),
        }
        if "pre_model" in installed:
            tone_memory["pre_model"] = _memory_model(installed["pre_model"])
        return {
            "summary": recommendation.plan.summary,
            "rig_label": rig.label,
            "controls": recommendation.plan.controls,
            "effects": recommendation.plan.effects,
            "tone_memory": tone_memory,
            **installed,
        }

    def _plan(self, prompt: str) -> TonePlan:
        return TonePlan.from_payload(
            self._request_structured(
                name="aero_dsp_tone_plan",
                schema=_PLAN_SCHEMA,
                system_prompt=_SYSTEM_PROMPT,
                user_input=prompt,
            )
        )

    def _recommend_from_memory(
        self, prompt: str, records: list[dict[str, Any]]
    ) -> ToneRecommendation:
        first = records[0]
        plan = TonePlan.from_payload(
            {
                "summary": first["summary"],
                "pedal_query": "saved personal pedal",
                "amp_query": "saved personal amp",
                "controls": first["controls"],
                "effects": first["effects"],
            }
        )
        rigs = [
            ToneRig(
                label=f"Your saved tone: {record['rig_label']}",
                rationale=(
                    f"You confirmed this for “{record['query']}”. "
                    "It uses cached NAMs and works offline."
                ),
                pedal=_local_candidate(record.get("pre_model"), "pedal", record["id"]),
                amp=_local_candidate(record["amp_model"], "amp", record["id"]),
            )
            for record in records
        ]
        recommendation = ToneRecommendation(
            identifier=secrets.token_urlsafe(18),
            expires_at=self.clock() + PLAN_TTL_SECONDS,
            prompt=prompt,
            plan=plan,
            rigs=rigs,
            ranking_provider="tone_memory",
            ranking_note="Your locally confirmed tone matches this request.",
        )
        self._prune_expired()
        self._recommendations[recommendation.identifier] = recommendation
        return recommendation

    def _rank_rigs(
        self,
        plan: TonePlan,
        pedal_candidates: list[dict[str, Any]],
        amp_candidates: list[dict[str, Any]],
    ) -> tuple[str, str | None, list[ToneRig]]:
        """Prefer Jev for bounded metadata ranking; retain OpenAI as fallback."""

        if self.jev_ranker and self.jev_ranker.available:
            try:
                matches = self.jev_ranker.rank(
                    plan.as_payload(), pedal_candidates, amp_candidates
                )
            except JevError as error:
                return (
                    "openai",
                    str(error),
                    self._rank_rigs_with_openai(
                        plan, pedal_candidates, amp_candidates
                    ),
                )
            if matches:
                return (
                    "jev",
                    None,
                    [
                        ToneRig(
                            label=f"Jev pick {index + 1}",
                            rationale=_jev_rationale(match.score, match.confidence),
                            pedal=match.pedal,
                            amp=match.amp,
                            ranking_confidence=match.confidence,
                            ranking_score=match.score / 4.0,
                        )
                        for index, match in enumerate(matches)
                    ],
                )
            return (
                "openai",
                "Jev was not confident enough to rank these catalog matches.",
                self._rank_rigs_with_openai(
                    plan, pedal_candidates, amp_candidates
                ),
            )
        return (
            "openai",
            "Jev is not configured on this device.",
            self._rank_rigs_with_openai(
                plan, pedal_candidates, amp_candidates
            ),
        )

    def _rank_rigs_with_openai(
        self,
        plan: TonePlan,
        pedal_candidates: list[dict[str, Any]],
        amp_candidates: list[dict[str, Any]],
    ) -> list[ToneRig]:
        count = min(3, len(pedal_candidates), len(amp_candidates))
        if count == 0:
            return [
                ToneRig(
                    label=f"Amp pick {index + 1}",
                    rationale="No compatible drive NAM was found, so this rig uses the amp alone.",
                    pedal=None,
                    amp=amp,
                )
                for index, amp in enumerate(amp_candidates[:3])
            ]
        candidate_payload = {
            "plan": plan.as_payload(),
            "candidate_count": count,
            "pedal_candidates": [_candidate_brief(candidate) for candidate in pedal_candidates],
            "amp_candidates": [_candidate_brief(candidate) for candidate in amp_candidates],
        }
        ranked = self._request_structured(
                name="aero_dsp_rig_ranking",
            schema=_rig_schema(count),
            system_prompt=_RANKING_PROMPT,
            user_input=json.dumps(candidate_payload, separators=(",", ":")),
        )
        raw_rigs = ranked.get("rigs")
        if not isinstance(raw_rigs, list) or len(raw_rigs) != count:
            raise ToneMakerError("OpenAI returned an incomplete rig ranking")
        pedals_by_id = {str(candidate["id"]): candidate for candidate in pedal_candidates}
        amps_by_id = {str(candidate["id"]): candidate for candidate in amp_candidates}
        rigs: list[ToneRig] = []
        pairs: set[tuple[str, str]] = set()
        for raw_rig in raw_rigs:
            if not isinstance(raw_rig, dict):
                raise ToneMakerError("OpenAI returned an invalid rig ranking")
            pedal_id = str(raw_rig.get("pedal_tone_id", ""))
            amp_id = str(raw_rig.get("amp_tone_id", ""))
            pedal = pedals_by_id.get(pedal_id)
            amp = amps_by_id.get(amp_id)
            if pedal is None or amp is None or (pedal_id, amp_id) in pairs:
                raise ToneMakerError("OpenAI chose a rig outside the available catalog results")
            pairs.add((pedal_id, amp_id))
            label = str(raw_rig.get("label", "")).strip()[:48]
            rationale = str(raw_rig.get("rationale", "")).strip()[:180]
            if not label or not rationale:
                raise ToneMakerError("OpenAI returned an incomplete rig ranking")
            rigs.append(ToneRig(label, rationale, pedal, amp))
        return rigs

    def _request_structured(
        self,
        *,
        name: str,
        schema: dict[str, Any],
        system_prompt: str,
        user_input: str,
    ) -> dict[str, Any]:
        request = urllib.request.Request(
            OPENAI_RESPONSES_URL,
            data=json.dumps(
                {
                    "model": self.model,
                    "store": False,
                    "input": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_input},
                    ],
                    "text": {
                        "format": {
                            "type": "json_schema",
                            "name": name,
                            "strict": True,
                            "schema": schema,
                        }
                    },
                },
                separators=(",", ":"),
            ).encode(),
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        response = self.transport.send(request)
        return _structured_output(response)

    def _prune_expired(self) -> None:
        now = self.clock()
        self._recommendations = {
            identifier: recommendation
            for identifier, recommendation in self._recommendations.items()
            if recommendation.expires_at > now
        }


def _structured_output(response: dict[str, Any]) -> dict[str, Any]:
    text = response.get("output_text")
    if not isinstance(text, str):
        for item in response.get("output", []):
            if not isinstance(item, dict):
                continue
            for content in item.get("content", []):
                if isinstance(content, dict) and isinstance(content.get("text"), str):
                    text = content["text"]
                    break
            if isinstance(text, str):
                break
    if not isinstance(text, str):
        raise ToneMakerError("OpenAI did not return a tone plan")
    try:
        payload = json.loads(text)
    except json.JSONDecodeError as error:
        raise ToneMakerError("OpenAI returned an invalid tone plan") from error
    if not isinstance(payload, dict):
        raise ToneMakerError("OpenAI returned an invalid tone plan")
    return payload


_SYSTEM_PROMPT = """You are AERO>>DSP's guitar tone planner. Convert a player's
description into practical searches for a pedal NAM and an amp NAM, plus safe
settings for AERO>>DSP's existing pedalboard. Do not claim a perfect replica
of a recording. Favor tight, musical, playable settings. Search terms must be
short gear- or genre-oriented phrases likely to occur in a NAM catalog. Return
only the required JSON schema."""

_RANKING_PROMPT = """You are AERO>>DSP's guitar rig curator. Rank the requested
number of distinct pedal-NAM plus amp-NAM pairs from the supplied candidate lists
for the provided tone plan. Use only IDs that appear in those lists. Give each
pair a short, useful label and a plain-language reason it fits the plan. Do not
claim an exact replica of any artist or recording. Return only the required JSON
schema."""


def _candidate_brief(candidate: dict[str, Any]) -> dict[str, str]:
    """Give the ranker only catalog metadata, never model content or credentials."""

    return {
        "id": str(candidate.get("id", "")),
        "name": str(candidate.get("name", ""))[:160],
        "author": str(candidate.get("author", ""))[:100],
        "gear": str(candidate.get("gear", ""))[:100],
    }


def _jev_rationale(score: float, confidence: float) -> str:
    match = (
        "excellent"
        if score >= 3.5
        else "strong"
        if score >= 2.5
        else "plausible"
        if score >= 1.5
        else "weak"
    )
    return (
        f"Jev rates this as a {match} catalog-metadata match "
        f"({round(confidence * 100)}% confidence). Compare it by ear before applying."
    )


def _memory_model(installed: dict[str, Any]) -> dict[str, str]:
    """Keep only the portable model identity needed to recall a local rig."""
    return {
        key: str(installed.get(key, ""))
        for key in ("name", "path", "source")
    }


def _local_candidate(
    model: Any, gear: str, record_id: str
) -> dict[str, Any] | None:
    if model is None:
        return None
    if not isinstance(model, dict):
        raise ToneMakerError("A saved Tone Memory recipe is invalid")
    path = model.get("path")
    name = model.get("name")
    source = model.get("source")
    if not all(isinstance(value, str) and value for value in (path, name, source)):
        raise ToneMakerError("A saved Tone Memory recipe is invalid")
    return {
        "id": f"memory:{record_id}:{gear}",
        "name": name,
        "author": "Your Tone Memory",
        "gear": gear,
        "local_path": path,
        "source": source,
    }


def _rig_schema(count: int) -> dict[str, Any]:
    return {
        "type": "object",
        "additionalProperties": False,
        "required": ["rigs"],
        "properties": {
            "rigs": {
                "type": "array",
                "minItems": count,
                "maxItems": count,
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "required": [
                        "pedal_tone_id",
                        "amp_tone_id",
                        "label",
                        "rationale",
                    ],
                    "properties": {
                        "pedal_tone_id": {"type": "string"},
                        "amp_tone_id": {"type": "string"},
                        "label": {"type": "string", "maxLength": 48},
                        "rationale": {"type": "string", "maxLength": 180},
                    },
                },
            },
        },
    }

_PLAN_SCHEMA: dict[str, Any] = {
    "type": "object",
    "additionalProperties": False,
    "required": ["summary", "pedal_query", "amp_query", "controls", "effects"],
    "properties": {
        "summary": {"type": "string", "maxLength": 240},
        "pedal_query": {"type": "string", "maxLength": 160},
        "amp_query": {"type": "string", "maxLength": 160},
        "controls": {
            "type": "object",
            "additionalProperties": False,
            "required": list(CONTROL_RANGES),
            "properties": {
                name: {"type": "number", "minimum": low, "maximum": high}
                for name, (low, high) in CONTROL_RANGES.items()
            },
        },
        "effects": {
            "type": "object",
            "additionalProperties": False,
            "required": list(EFFECT_KEYS),
            "properties": {name: {"type": "boolean"} for name in EFFECT_KEYS},
        },
    },
}
