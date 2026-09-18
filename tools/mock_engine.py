#!/usr/bin/env python3
"""Small control-protocol simulator for Flutter development."""

from __future__ import annotations

import argparse
import json
import math
import os
import socketserver
import struct
import time
import wave
from pathlib import Path
from typing import Any


STATE: dict[str, Any] = {
    "engine": "ready",
    "bypassed": False,
    "pre_bypassed": False,
    "amp_bypassed": False,
    "preset": "Desktop Demo",
    "preset_id": None,
    "preset_dirty": False,
    "pre_model": "/mock/overdrive.nam",
    "model": "/mock/desktop-amp.nam",
    "pedal_drive_db": 0.0,
    "pedal_mix": 1.0,
    "pedal_level_db": 0.0,
    "amp_bass_db": 0.0,
    "amp_mid_db": 0.0,
    "amp_treble_db": 0.0,
    "amp_volume_db": 0.0,
    "sample_rate": 48_000,
    "buffer_frames": 64,
}
PRESETS: list[dict[str, Any]] = []
PRESET_COUNTER = {"next": 1}
RIG_FIELDS = (
    "pre_bypassed",
    "pre_model",
    "amp_bypassed",
    "model",
    "pedal_drive_db",
    "pedal_mix",
    "pedal_level_db",
    "amp_bass_db",
    "amp_mid_db",
    "amp_treble_db",
    "amp_volume_db",
)


class ControlHandler(socketserver.StreamRequestHandler):
    def handle(self) -> None:
        for raw_line in self.rfile:
            request_id = "unknown"
            try:
                request = json.loads(raw_line)
                request_id = str(request.get("id", request_id))
                response = process_request(request)
            except (json.JSONDecodeError, TypeError) as exception:
                response = error(request_id, "invalid_json", str(exception))
            self.wfile.write(json.dumps(response, separators=(",", ":")).encode() + b"\n")


def process_request(request: dict[str, Any]) -> dict[str, Any]:
    request_id = str(request.get("id", "unknown"))
    if request.get("api") != 1:
        return error(request_id, "unsupported_api", "Only API v1 is supported")

    request_type = request.get("type")
    payload = request.get("payload", {})
    if not isinstance(payload, dict):
        return error(request_id, "invalid_payload", "payload must be an object")
    if request_type == "get_state":
        return state_message(request_id)
    if request_type == "get_meters":
        phase = time.monotonic() * 2.5
        input_db = -30.0 + 18.0 * (0.5 + 0.5 * math.sin(phase))
        return message(
            request_id,
            "meters",
            {
                "input_db": input_db,
                "output_db": input_db - 2.5,
                "clipped": False,
                "cpu_percent": 4.0,
                "xruns": 0,
            },
        )
    if request_type == "render_preview":
        preview_path = Path(
            os.environ.get("PEDAL_PREVIEW_FILE", "/tmp/pedal-mock-preview.wav")
        )
        write_mock_preview(preview_path)
        return message(
            request_id,
            "preview",
            {"path": str(preview_path), "duration_seconds": 1.0},
        )
    if request_type == "list_presets":
        return message(
            request_id,
            "presets",
            {
                "presets": [
                    {
                        "id": preset["id"],
                        "name": preset["name"],
                        "pre_model": preset["rig"]["pre_model"],
                        "model": preset["rig"]["model"],
                    }
                    for preset in PRESETS
                ]
            },
        )
    if request_type == "save_preset":
        name = valid_preset_name(payload)
        if name is None:
            return error(request_id, "invalid_name", "invalid preset name")
        preset_id = f"preset-{PRESET_COUNTER['next']}"
        PRESET_COUNTER["next"] += 1
        PRESETS.append(
            {
                "id": preset_id,
                "name": name,
                "rig": {field: STATE[field] for field in RIG_FIELDS},
            }
        )
        STATE.update({"preset": name, "preset_id": preset_id, "preset_dirty": False})
        return state_message(request_id)
    if request_type == "load_preset":
        preset = find_preset(payload.get("id"))
        if preset is None:
            return error(request_id, "preset_not_found", "preset was not found")
        STATE.update(preset["rig"])
        STATE.update(
            {"preset": preset["name"], "preset_id": preset["id"], "preset_dirty": False}
        )
        return state_message(request_id)
    if request_type == "rename_preset":
        preset = find_preset(payload.get("id"))
        name = valid_preset_name(payload)
        if preset is None:
            return error(request_id, "preset_not_found", "preset was not found")
        if name is None:
            return error(request_id, "invalid_name", "invalid preset name")
        preset["name"] = name
        if STATE["preset_id"] == preset["id"]:
            STATE["preset"] = name
        return state_message(request_id)
    if request_type == "delete_preset":
        preset = find_preset(payload.get("id"))
        if preset is None:
            return error(request_id, "preset_not_found", "preset was not found")
        PRESETS.remove(preset)
        if STATE["preset_id"] == preset["id"]:
            STATE["preset_id"] = None
            STATE["preset_dirty"] = False
        return state_message(request_id)
    if request_type == "set_bypass":
        bypassed = payload.get("bypassed")
        if not isinstance(bypassed, bool):
            return error(request_id, "invalid_payload", "bypassed must be boolean")
        STATE["bypassed"] = bypassed
        return state_message(request_id)
    if request_type == "set_slot_bypass":
        slot = valid_slot(payload, request_id)
        if isinstance(slot, dict):
            return slot
        bypassed = payload.get("bypassed")
        if not isinstance(bypassed, bool):
            return error(request_id, "invalid_payload", "bypassed must be boolean")
        STATE["pre_bypassed" if slot == "pre" else "amp_bypassed"] = bypassed
        STATE["preset_dirty"] = STATE["preset_id"] is not None
        return state_message(request_id)
    if request_type == "clear_model":
        slot = valid_slot(payload, request_id)
        if isinstance(slot, dict):
            return slot
        STATE["pre_model" if slot == "pre" else "model"] = None
        STATE["pre_bypassed" if slot == "pre" else "amp_bypassed"] = False
        STATE["preset_dirty"] = STATE["preset_id"] is not None
        return state_message(request_id)
    if request_type == "select_model":
        slot = valid_slot(payload, request_id)
        if isinstance(slot, dict):
            return slot
        path = payload.get("path")
        if not isinstance(path, str) or not path:
            return error(request_id, "invalid_payload", "path must be a string")
        STATE["pre_model" if slot == "pre" else "model"] = path
        STATE["pre_bypassed" if slot == "pre" else "amp_bypassed"] = False
        preset = payload.get("preset")
        if isinstance(preset, str) and preset:
            STATE["preset"] = preset
        STATE["preset_id"] = None
        STATE["preset_dirty"] = False
        return state_message(request_id)
    if request_type == "set_control":
        control = payload.get("control")
        value = payload.get("value")
        ranges = {
            "pedal_drive_db": (0.0, 24.0),
            "pedal_mix": (0.0, 1.0),
            "pedal_level_db": (-24.0, 12.0),
            "amp_bass_db": (-12.0, 12.0),
            "amp_mid_db": (-12.0, 12.0),
            "amp_treble_db": (-12.0, 12.0),
            "amp_volume_db": (-24.0, 12.0),
        }
        if control not in ranges:
            return error(request_id, "invalid_control", "unknown control")
        if not isinstance(value, (int, float)) or isinstance(value, bool):
            return error(request_id, "invalid_payload", "value must be numeric")
        minimum, maximum = ranges[control]
        if not minimum <= value <= maximum:
            return error(request_id, "invalid_control", "value is outside its range")
        STATE[control] = float(value)
        STATE["preset_dirty"] = STATE["preset_id"] is not None
        return state_message(request_id)
    return error(request_id, "unknown_message", "Unknown message type")


def write_mock_preview(path: Path) -> None:
    sample_rate = 48_000
    path.parent.mkdir(parents=True, exist_ok=True)
    frames = bytearray()
    for frame in range(sample_rate):
        envelope = max(0.0, 1.0 - frame / sample_rate)
        sample = int(
            math.sin(2.0 * math.pi * 110.0 * frame / sample_rate)
            * envelope
            * 0.15
            * 32767
        )
        frames.extend(struct.pack("<hh", sample, sample))
    with wave.open(str(path), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(sample_rate)
        output.writeframes(frames)


def valid_slot(payload: dict[str, Any], request_id: str) -> str | dict[str, Any]:
    slot = payload.get("slot")
    if slot not in ("pre", "amp"):
        return error(request_id, "invalid_payload", "slot must be 'pre' or 'amp'")
    return slot


def valid_preset_name(payload: dict[str, Any]) -> str | None:
    name = payload.get("name")
    if not isinstance(name, str):
        return None
    name = name.strip()
    return name if 0 < len(name) <= 64 else None


def find_preset(preset_id: Any) -> dict[str, Any] | None:
    return next((preset for preset in PRESETS if preset["id"] == preset_id), None)


def state_message(request_id: str) -> dict[str, Any]:
    return message(request_id, "state", dict(STATE))


def message(request_id: str, message_type: str, payload: dict[str, Any]) -> dict[str, Any]:
    return {"api": 1, "id": request_id, "type": message_type, "payload": payload}


def error(request_id: str, code: str, description: str) -> dict[str, Any]:
    return message(request_id, "error", {"code": code, "message": description})


class ControlServer(socketserver.ThreadingUnixStreamServer):
    daemon_threads = True


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--socket",
        type=Path,
        default=Path(os.environ.get("PEDAL_CONTROL_SOCKET", "/tmp/pedal-control.sock")),
    )
    arguments = parser.parse_args()
    arguments.socket.parent.mkdir(parents=True, exist_ok=True)
    arguments.socket.unlink(missing_ok=True)
    try:
        with ControlServer(str(arguments.socket), ControlHandler) as server:
            print(f"Mock engine listening on {arguments.socket}", flush=True)
            server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        arguments.socket.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
