"""Stable Audio-backed, user-initiated Riff Vault accompaniment renders.

The catalog owns the network request and the Stability credential.  A render is
intentionally never part of the real-time audio process: completed files are
ordinary cached audio that can be played while the device is offline.
"""

from __future__ import annotations

import json
import mimetypes
import os
import secrets
import threading
import time
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Protocol


STABLE_AUDIO_URL = "https://api.stability.ai/v2beta/audio/stable-audio-2/audio-to-audio"
DEFAULT_DURATION_SECONDS = 20
DEFAULT_STRENGTH = 0.65
MAX_STYLE_LENGTH = 500


class BackingTrackError(RuntimeError):
    """Raised for concise, player-facing backing-track failures."""


class StableAudioTransport(Protocol):
    def generate(self, request: urllib.request.Request) -> bytes: ...


class UrllibStableAudioTransport:
    def generate(self, request: urllib.request.Request) -> bytes:
        try:
            with urllib.request.urlopen(request, timeout=180) as response:
                payload = response.read()
                content_type = response.headers.get_content_type()
        except urllib.error.HTTPError as error:
            detail = ""
            try:
                body = json.loads(error.read())
                detail = str(
                    body.get("message")
                    or body.get("error", {}).get("message")
                    or body.get("error")
                    or ""
                )
            except (json.JSONDecodeError, UnicodeDecodeError, AttributeError):
                pass
            suffix = f": {detail}" if detail else ""
            raise BackingTrackError(
                f"Stable Audio request failed ({error.code}){suffix}"
            ) from error
        except (urllib.error.URLError, TimeoutError) as error:
            raise BackingTrackError("Stable Audio could not be reached") from error
        if not payload:
            raise BackingTrackError("Stable Audio returned an empty track")
        if content_type == "application/json":
            raise BackingTrackError("Stable Audio returned an unexpected JSON response")
        return payload


@dataclass
class BackingTrack:
    id: str
    riff_id: str
    riff_name: str
    style: str
    created_at_ms: int
    status: str
    duration_seconds: int
    strength: float
    path: str | None = None
    error: str | None = None

    def as_payload(self) -> dict[str, Any]:
        return asdict(self)


class BackingTrackService:
    """Queues Stable Audio renders and persists only safe local metadata."""

    def __init__(
        self,
        api_key: str,
        riff_directory: Path,
        *,
        tracks_directory: Path | None = None,
        transport: StableAudioTransport | None = None,
        clock: callable = time.time,
    ) -> None:
        self.api_key = api_key.strip()
        self.riff_directory = riff_directory
        self.tracks_directory = tracks_directory or riff_directory / "backing-tracks"
        self.transport = transport or UrllibStableAudioTransport()
        self.clock = clock
        self._jobs: dict[str, BackingTrack] = {}
        self._lock = threading.Lock()

    @property
    def available(self) -> bool:
        return bool(self.api_key)

    def status(self) -> dict[str, Any]:
        return {"available": self.available}

    def queue(
        self,
        riff_id: str,
        style: str,
        *,
        duration_seconds: int = DEFAULT_DURATION_SECONDS,
        strength: float = DEFAULT_STRENGTH,
    ) -> BackingTrack:
        if not self.available:
            raise BackingTrackError("Stable Audio is not configured on this device")
        riff = self._load_riff(riff_id)
        style = style.strip()
        if not 3 <= len(style) <= MAX_STYLE_LENGTH:
            raise BackingTrackError("Describe the backing style in 3 to 500 characters")
        if not 5 <= duration_seconds <= 60:
            raise BackingTrackError("Backing tracks can be 5 to 60 seconds long")
        if not 0.01 <= strength <= 1:
            raise BackingTrackError("Reference strength must be between 0.01 and 1")
        clean_path = self._safe_riff_audio_path(riff.get("clean_path"))
        if not clean_path.is_file():
            raise BackingTrackError("The clean DI for that riff is no longer available")

        created_at_ms = int(self.clock() * 1000)
        track = BackingTrack(
            id=f"backing-{created_at_ms}-{secrets.token_hex(3)}",
            riff_id=riff_id,
            riff_name=str(riff.get("name") or "Untitled Riff")[:64],
            style=style,
            created_at_ms=created_at_ms,
            status="queued",
            duration_seconds=duration_seconds,
            strength=strength,
        )
        with self._lock:
            self._jobs[track.id] = track
        thread = threading.Thread(
            target=self._render,
            args=(track.id, clean_path),
            name=f"pedal-backing-{track.id[-6:]}",
            daemon=True,
        )
        thread.start()
        return track

    def job(self, track_id: str) -> BackingTrack:
        with self._lock:
            track = self._jobs.get(track_id)
            if track is not None:
                return track
        for track in self.list_tracks():
            if track.id == track_id:
                return track
        raise BackingTrackError("That backing-track job is no longer available")

    def list_tracks(self, riff_id: str | None = None) -> list[BackingTrack]:
        tracks = []
        if self.tracks_directory.exists():
            for file in self.tracks_directory.glob("*.json"):
                try:
                    data = json.loads(file.read_text())
                    track = BackingTrack(**data)
                except (OSError, TypeError, json.JSONDecodeError):
                    continue
                if riff_id is None or track.riff_id == riff_id:
                    tracks.append(track)
        with self._lock:
            for track in self._jobs.values():
                if track.status not in {"queued", "rendering"}:
                    continue
                if riff_id is None or track.riff_id == riff_id:
                    tracks = [item for item in tracks if item.id != track.id]
                    tracks.append(track)
        return sorted(tracks, key=lambda item: item.created_at_ms, reverse=True)

    def _render(self, track_id: str, clean_path: Path) -> None:
        track = self.job(track_id)
        self._replace(track_id, status="rendering", error=None)
        try:
            body, content_type = _multipart_body(
                fields={
                    "prompt": _prompt_for(track.style),
                    "output_format": "wav",
                    "duration": str(track.duration_seconds),
                    "steps": "8",
                    "strength": str(track.strength),
                },
                file_field="audio",
                path=clean_path,
            )
            request = urllib.request.Request(
                STABLE_AUDIO_URL,
                data=body,
                method="POST",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Accept": "audio/*",
                    "Content-Type": content_type,
                },
            )
            audio = self.transport.generate(request)
            self.tracks_directory.mkdir(parents=True, exist_ok=True)
            destination = self.tracks_directory / f"{track.id}.wav"
            temporary = destination.with_suffix(".wav.new")
            temporary.write_bytes(audio)
            os.replace(temporary, destination)
            self._replace(track_id, status="ready", path=str(destination), error=None)
            self._write_metadata(self.job(track_id))
        except BackingTrackError as error:
            self._replace(track_id, status="failed", error=str(error))
            self._write_metadata(self.job(track_id))
        except OSError as error:
            self._replace(track_id, status="failed", error=f"Could not save backing track: {error}")
            self._write_metadata(self.job(track_id))
        except Exception:
            # A worker must never leave an indefinitely spinning UI job if an
            # upstream response changes shape or a local decoder surprises us.
            self._replace(
                track_id,
                status="failed",
                error="Backing-track generation did not complete",
            )
            self._write_metadata(self.job(track_id))

    def _replace(self, track_id: str, **changes: Any) -> None:
        with self._lock:
            track = self._jobs[track_id]
            for name, value in changes.items():
                setattr(track, name, value)

    def _write_metadata(self, track: BackingTrack) -> None:
        self.tracks_directory.mkdir(parents=True, exist_ok=True)
        destination = self.tracks_directory / f"{track.id}.json"
        temporary = destination.with_suffix(".json.new")
        temporary.write_text(json.dumps(track.as_payload(), indent=2) + "\n")
        os.replace(temporary, destination)

    def _load_riff(self, riff_id: str) -> dict[str, Any]:
        if not riff_id or "/" in riff_id or "\\" in riff_id:
            raise BackingTrackError("Choose a saved riff before generating a backing track")
        metadata = self.riff_directory / f"{riff_id}.json"
        try:
            payload = json.loads(metadata.read_text())
        except FileNotFoundError as error:
            raise BackingTrackError("That saved riff no longer exists") from error
        except (OSError, json.JSONDecodeError) as error:
            raise BackingTrackError("That saved riff could not be read") from error
        if not isinstance(payload, dict) or payload.get("id") != riff_id:
            raise BackingTrackError("That saved riff is invalid")
        return payload

    def _safe_riff_audio_path(self, value: Any) -> Path:
        if not isinstance(value, str):
            raise BackingTrackError("That saved riff has no clean DI recording")
        path = Path(value).resolve()
        root = self.riff_directory.resolve()
        try:
            path.relative_to(root)
        except ValueError as error:
            raise BackingTrackError("That riff points outside the Riff Vault") from error
        return path


def _prompt_for(style: str) -> str:
    return (
        "Instrumental backing track following the pulse and harmonic center of the "
        "supplied clean electric-guitar riff. "
        f"{style}. "
        "Feature supporting drums and bass, leave room for the player's guitar, no vocals, "
        "no lead-guitar melody, and finish so the result can loop cleanly."
    )


def _multipart_body(
    *, fields: dict[str, str], file_field: str, path: Path
) -> tuple[bytes, str]:
    """Build the small multipart request without a deployment-only dependency."""
    boundary = f"----pedal-{secrets.token_hex(16)}"
    chunks: list[bytes] = []
    for name, value in fields.items():
        chunks.extend(
            [
                f"--{boundary}\r\n".encode(),
                f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode(),
                value.encode(),
                b"\r\n",
            ]
        )
    mime = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    chunks.extend(
        [
            f"--{boundary}\r\n".encode(),
            (
                f'Content-Disposition: form-data; name="{file_field}"; '
                f'filename="{path.name}"\r\n'
            ).encode(),
            f"Content-Type: {mime}\r\n\r\n".encode(),
            path.read_bytes(),
            b"\r\n",
            f"--{boundary}--\r\n".encode(),
        ]
    )
    return b"".join(chunks), f"multipart/form-data; boundary={boundary}"
