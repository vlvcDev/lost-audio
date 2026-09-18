from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "mock_engine.py"
SPEC = importlib.util.spec_from_file_location("mock_engine", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
mock_engine = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(mock_engine)


class MockEngineTests(unittest.TestCase):
    def setUp(self) -> None:
        self.original_state = copy.deepcopy(mock_engine.STATE)
        self.original_presets = copy.deepcopy(mock_engine.PRESETS)
        self.original_counter = mock_engine.PRESET_COUNTER["next"]

    def tearDown(self) -> None:
        mock_engine.STATE.clear()
        mock_engine.STATE.update(self.original_state)
        mock_engine.PRESETS.clear()
        mock_engine.PRESETS.extend(self.original_presets)
        mock_engine.PRESET_COUNTER["next"] = self.original_counter

    def request(self, request_type: str, payload: dict[str, object]):
        return mock_engine.process_request(
            {"api": 1, "id": "test-1", "type": request_type, "payload": payload}
        )

    def test_slots_are_controlled_independently(self) -> None:
        response = self.request(
            "set_slot_bypass", {"slot": "pre", "bypassed": True}
        )

        state = response["payload"]
        self.assertTrue(state["pre_bypassed"])
        self.assertFalse(state["amp_bypassed"])

    def test_clear_removes_only_requested_model(self) -> None:
        amp_model = mock_engine.STATE["model"]

        response = self.request("clear_model", {"slot": "pre"})

        state = response["payload"]
        self.assertIsNone(state["pre_model"])
        self.assertEqual(state["model"], amp_model)

    def test_select_model_engages_the_slot(self) -> None:
        mock_engine.STATE["amp_bypassed"] = True

        response = self.request(
            "select_model",
            {"slot": "amp", "path": "/models/new-amp.nam", "preset": "New Amp"},
        )

        state = response["payload"]
        self.assertEqual(state["model"], "/models/new-amp.nam")
        self.assertEqual(state["preset"], "New Amp")
        self.assertFalse(state["amp_bypassed"])

    def test_adjustable_control_is_validated(self) -> None:
        response = self.request(
            "set_control", {"control": "amp_bass_db", "value": 4.5}
        )
        self.assertEqual(response["payload"]["amp_bass_db"], 4.5)

        response = self.request(
            "set_control", {"control": "amp_bass_db", "value": 20}
        )
        self.assertEqual(response["type"], "error")
        self.assertEqual(mock_engine.STATE["amp_bass_db"], 4.5)

    def test_meter_response_contains_health_and_levels(self) -> None:
        response = self.request("get_meters", {})

        self.assertEqual(response["type"], "meters")
        self.assertIn("input_db", response["payload"])
        self.assertIn("output_db", response["payload"])
        self.assertEqual(response["payload"]["xruns"], 0)

    def test_preview_response_points_to_playable_wav(self) -> None:
        response = self.request("render_preview", {})
        path = Path(response["payload"]["path"])
        try:
            self.assertEqual(response["type"], "preview")
            self.assertEqual(path.read_bytes()[:4], b"RIFF")
        finally:
            path.unlink(missing_ok=True)

    def test_preset_lifecycle_restores_the_saved_rig(self) -> None:
        mock_engine.STATE["pedal_mix"] = 0.4
        saved = self.request("save_preset", {"name": " Crunch "})
        preset_id = saved["payload"]["preset_id"]
        mock_engine.STATE["pedal_mix"] = 1.0

        loaded = self.request("load_preset", {"id": preset_id})
        self.assertEqual(loaded["payload"]["pedal_mix"], 0.4)

        listed = self.request("list_presets", {})
        self.assertEqual(listed["payload"]["presets"][0]["name"], "Crunch")

        self.request("rename_preset", {"id": preset_id, "name": "Lead"})
        self.assertEqual(mock_engine.STATE["preset"], "Lead")
        self.request("delete_preset", {"id": preset_id})
        self.assertEqual(mock_engine.PRESETS, [])


if __name__ == "__main__":
    unittest.main()
