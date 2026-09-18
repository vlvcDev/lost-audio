import sys
import threading
import unittest
from pathlib import Path

CATALOG_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CATALOG_ROOT))

from pedal_catalog.oauth_callback import complete_callback  # noqa: E402
from pedal_catalog.tone3000 import Tone3000Error  # noqa: E402


class FakeService:
    def __init__(self) -> None:
        self.callback = None

    def complete_auth(self, code, state, tone_id):
        if state == "bad":
            raise Tone3000Error("state mismatch")
        self.callback = (code, state, tone_id)

    def cancel_auth(self, state):
        if state == "bad":
            raise Tone3000Error("state mismatch")
        self.callback = (None, state, None)


class OAuthCallbackTests(unittest.TestCase):
    def test_callback_completes_login_without_exposing_tokens(self) -> None:
        service = FakeService()
        status, title, detail = complete_callback(
            "/callback?code=hello&state=good&tone_id=42",
            "/callback",
            service,
            threading.Lock(),
        )

        self.assertEqual(status, 200)
        self.assertEqual(service.callback, ("hello", "good", "42"))
        self.assertEqual(title, "Tone selected")
        self.assertNotIn("hello", detail)

    def test_callback_rejects_wrong_path_and_bad_state(self) -> None:
        service = FakeService()
        missing, _, _ = complete_callback(
            "/other", "/callback", service, threading.Lock()
        )
        bad, title, detail = complete_callback(
            "/callback?code=x&state=bad",
            "/callback",
            service,
            threading.Lock(),
        )

        self.assertEqual(missing, 404)
        self.assertEqual(bad, 400)
        self.assertEqual(title, "Connection failed")
        self.assertIn("state mismatch", detail)

    def test_canceled_selection_is_a_successful_return(self) -> None:
        service = FakeService()
        status, title, _ = complete_callback(
            "/callback?state=good&canceled=true",
            "/callback",
            service,
            threading.Lock(),
        )

        self.assertEqual(status, 200)
        self.assertEqual(title, "No tone selected")
        self.assertEqual(service.callback, (None, "good", None))


if __name__ == "__main__":
    unittest.main()
