import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

CATALOG_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CATALOG_ROOT))

from pedal_catalog.index import list_models, scan_models, upsert_model  # noqa: E402


class CatalogIndexTests(unittest.TestCase):
    def test_scan_indexes_only_nam_files_and_updates_changed_content(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            models = root / "models"
            models.mkdir()
            model = models / "Clean Combo.nam"
            model.write_text("first model", encoding="utf-8")
            (models / "Clean Combo Copy.nam").write_text("first model", encoding="utf-8")
            (models / "notes.txt").write_text("ignore me", encoding="utf-8")
            database = root / "catalog.db"

            first = scan_models(models, database)
            model.write_text("updated model", encoding="utf-8")
            second = scan_models(models, database)

            self.assertEqual(len(first), 2)
            self.assertEqual(len(second), 2)
            first_by_name = {record.name: record for record in first}
            second_by_name = {record.name: record for record in second}
            self.assertNotEqual(
                first_by_name["Clean Combo"].sha256,
                second_by_name["Clean Combo"].sha256,
            )
            self.assertEqual(
                first_by_name["Clean Combo Copy"].sha256,
                second_by_name["Clean Combo Copy"].sha256,
            )
            with sqlite3.connect(database) as connection:
                count = connection.execute("SELECT COUNT(*) FROM models").fetchone()[0]
            self.assertEqual(count, 2)

            (models / "Clean Combo Copy.nam").unlink()
            scan_models(models, database)
            self.assertEqual([item.name for item in list_models(database)], ["Clean Combo"])

    def test_downloaded_model_retains_tone3000_provenance(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            model = root / "download.nam"
            model.write_bytes(b"model")
            database = root / "catalog.db"

            record = upsert_model(model, database, source="tone3000:model:99")

            self.assertEqual(record.source, "tone3000:model:99")
            with sqlite3.connect(database) as connection:
                source = connection.execute(
                    "SELECT source FROM models WHERE path = ?", (str(model.resolve()),)
                ).fetchone()[0]
            self.assertEqual(source, "tone3000:model:99")


if __name__ == "__main__":
    unittest.main()
