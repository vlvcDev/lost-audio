import json
import sys
import tempfile
import time
import unittest
from pathlib import Path

CATALOG_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CATALOG_ROOT))

from pedal_catalog.backing_tracks import (  # noqa: E402
    BackingTrackService,
    DEFAULT_STRENGTH,
)


class FakeStableAudioTransport:
    def __init__(self, result=b"RIFFfake-wav"):
        self.requests = []
        self.result = result

    def generate(self, request):
        self.requests.append(request)
        return self.result


class BackingTrackTests(unittest.TestCase):
    def _create_riff(self, root: Path) -> None:
        clean = root / "riff-1-clean.wav"
        clean.write_bytes(b"RIFFclean-dry")
        (root / "riff-1.json").write_text(
            json.dumps(
                {
                    "id": "riff-1",
                    "name": "Bridge Idea",
                    "clean_path": str(clean),
                }
            )
        )

    def test_queue_generates_a_cached_wav_without_exposing_the_key(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self._create_riff(root)
            transport = FakeStableAudioTransport()
            service = BackingTrackService(
                "sk-stability-test",
                root,
                transport=transport,
            )

            queued = service.queue("riff-1", "Driving drums and bass", duration_seconds=20)
            track = self._wait_for_completion(service, queued.id)

            self.assertEqual(track.status, "ready")
            self.assertEqual(track.strength, DEFAULT_STRENGTH)
            self.assertTrue(Path(track.path).is_file())
            self.assertEqual(Path(track.path).read_bytes(), b"RIFFfake-wav")
            body = transport.requests[0].data
            self.assertIn(b'Content-Disposition: form-data; name="audio"', body)
            self.assertIn(b"Driving drums and bass", body)
            self.assertNotIn(b"sk-stability-test", body)
            self.assertEqual(service.list_tracks("riff-1")[0].id, track.id)

    def test_riff_paths_outside_the_vault_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "riff-1.json").write_text(
                json.dumps(
                    {"id": "riff-1", "name": "Bad", "clean_path": "/tmp/not-a-riff.wav"}
                )
            )
            service = BackingTrackService("sk-test", root, transport=FakeStableAudioTransport())

            with self.assertRaisesRegex(Exception, "outside the Riff Vault"):
                service.queue("riff-1", "Punchy drums")

    def _wait_for_completion(self, service: BackingTrackService, track_id: str):
        for _ in range(100):
            track = service.job(track_id)
            if track.status in {"ready", "failed"}:
                return track
            time.sleep(0.01)
        self.fail("backing track did not complete")


if __name__ == "__main__":
    unittest.main()
