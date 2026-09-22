import sys
import tempfile
import unittest
from pathlib import Path

CATALOG_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CATALOG_ROOT))

from pedal_catalog.tone_memory import ToneMemoryError, ToneMemoryService  # noqa: E402


def candidate():
    return {
        "query": "Tight metal rhythm",
        "summary": "Focused high gain with a dry finish.",
        "rig_label": "Focused thrash",
        "pre_model": {
            "name": "Boost.nam",
            "path": "/models/boost.nam",
            "source": "tone3000:ai:pedal-2",
        },
        "amp_model": {
            "name": "Amp.nam",
            "path": "/models/amp.nam",
            "source": "tone3000:ai:amp-3",
        },
        "controls": {"amp_mid_db": 2.0},
        "effects": {"eq": True, "reverb": False},
    }


class ToneMemoryTests(unittest.TestCase):
    def test_confirmed_tone_persists_a_portable_local_recipe(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "tone-memory.json"
            memory = ToneMemoryService(path, clock=lambda: 123.456)

            saved = memory.save(candidate(), "Great with bridge humbucker")

            self.assertEqual(saved["created_at_ms"], 123456)
            self.assertEqual(saved["query"], "Tight metal rhythm")
            self.assertEqual(memory.list_records()[0]["amp_model"]["path"], "/models/amp.nam")

    def test_invalid_candidate_does_not_create_a_library_file(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "tone-memory.json"
            memory = ToneMemoryService(path)

            with self.assertRaises(ToneMemoryError):
                memory.save({})

            self.assertFalse(path.exists())

    def test_related_query_finds_a_confirmed_recipe(self):
        with tempfile.TemporaryDirectory() as directory:
            memory = ToneMemoryService(Path(directory) / "tone-memory.json")
            memory.save(candidate())

            matches = memory.matches("Need a tight metal tone")

            self.assertEqual(len(matches), 1)
            self.assertEqual(matches[0]["rig_label"], "Focused thrash")


if __name__ == "__main__":
    unittest.main()
