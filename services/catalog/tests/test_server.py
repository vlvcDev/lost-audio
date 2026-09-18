import sys
import tempfile
import unittest
from pathlib import Path

CATALOG_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CATALOG_ROOT))

from pedal_catalog.index import scan_models  # noqa: E402
from pedal_catalog.server import handle_request  # noqa: E402


class FakeTone3000Service:
    def status(self):
        return {
            "available": True,
            "connected": True,
            "auth_pending": False,
            "selected_tone_id": "7",
        }

    def selected(self):
        return {
            "tone": {"id": "7", "name": "Clean", "author": "Ada", "gear": "amp"},
            "models": [{"id": "9", "tone_id": "7", "name": "Bright"}],
        }

    def download(self, tone_id, model_id, models_dir):
        path = models_dir / "Downloaded.nam"
        path.write_bytes(b"model")
        return path, "hash"


class CatalogServerTests(unittest.TestCase):
    def test_tone3000_status_is_optional_and_selection_is_forwarded(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            unavailable = handle_request(
                {"api": 1, "id": "1", "type": "tone3000_status", "payload": {}},
                root,
                root / "catalog.db",
            )
            available = handle_request(
                {
                    "api": 1,
                    "id": "2",
                    "type": "tone3000_selected",
                    "payload": {},
                },
                root,
                root / "catalog.db",
                FakeTone3000Service(),
            )

            self.assertFalse(unavailable["payload"]["available"])
            self.assertEqual(available["payload"]["tone"]["name"], "Clean")

    def test_tone3000_download_is_immediately_indexed_for_offline_use(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            models = root / "models"
            models.mkdir()
            response = handle_request(
                {
                    "api": 1,
                    "id": "3",
                    "type": "tone3000_download",
                    "payload": {"tone_id": "7", "model_id": "9"},
                },
                models,
                root / "catalog.db",
                FakeTone3000Service(),
            )

            self.assertEqual(response["type"], "tone3000_downloaded")
            self.assertEqual(response["payload"]["model"]["source"], "tone3000:model:9")

    def test_lists_offline_models_in_protocol_response(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            models = root / "models"
            models.mkdir()
            (models / "Clean Combo.nam").write_bytes(b"model")
            database = root / "catalog.db"
            scan_models(models, database)

            response = handle_request(
                {"api": 1, "id": "ui-1", "type": "list_models", "payload": {}},
                models,
                database,
            )

            self.assertEqual(response["type"], "models")
            self.assertEqual(response["payload"]["models"][0]["name"], "Clean Combo")
            self.assertTrue(response["payload"]["models"][0]["path"].endswith(".nam"))

    def test_refresh_discovers_a_new_model(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            models = root / "models"
            models.mkdir()
            database = root / "catalog.db"
            (models / "New Tone.nam").write_bytes(b"model")

            response = handle_request(
                {"api": 1, "id": "ui-2", "type": "refresh_models", "payload": {}},
                models,
                database,
            )

            self.assertEqual(response["type"], "refreshed")
            self.assertEqual(response["payload"]["count"], 1)


if __name__ == "__main__":
    unittest.main()
