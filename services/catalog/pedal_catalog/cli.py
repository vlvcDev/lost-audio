from __future__ import annotations

import argparse
import os
from pathlib import Path

from .index import scan_models
from .server import serve
from .tone3000 import DEFAULT_BASE_URL
from .tone3000_service import Tone3000Service


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(prog="pedal-catalog")
    commands = root.add_subparsers(dest="command", required=True)
    scan = commands.add_parser("scan", help="index local .nam files")
    scan.add_argument("--models", type=Path, required=True)
    scan.add_argument("--database", type=Path, required=True)
    server = commands.add_parser("serve", help="run the local catalog socket service")
    server.add_argument("--models", type=Path, required=True)
    server.add_argument("--database", type=Path, required=True)
    server.add_argument("--socket", type=Path, required=True)
    server.add_argument(
        "--tone3000-key", default=os.environ.get("PEDAL_TONE3000_PUBLISHABLE_KEY")
    )
    server.add_argument(
        "--tone3000-redirect-uri",
        default=os.environ.get("PEDAL_TONE3000_REDIRECT_URI"),
    )
    server.add_argument(
        "--tone3000-token-file",
        type=Path,
        default=os.environ.get("PEDAL_TONE3000_TOKEN_FILE"),
    )
    server.add_argument(
        "--tone3000-base-url",
        default=os.environ.get("PEDAL_TONE3000_BASE_URL", DEFAULT_BASE_URL),
    )
    return root


def main() -> None:
    arguments = parser().parse_args()
    if arguments.command == "scan":
        records = scan_models(arguments.models, arguments.database)
        print(f"Indexed {len(records)} NAM model(s) into {arguments.database}")
    elif arguments.command == "serve":
        if bool(arguments.tone3000_key) != bool(arguments.tone3000_redirect_uri):
            raise SystemExit(
                "Both PEDAL_TONE3000_PUBLISHABLE_KEY and "
                "PEDAL_TONE3000_REDIRECT_URI are required"
            )
        tone3000 = None
        if arguments.tone3000_key:
            token_file = arguments.tone3000_token_file or (
                arguments.database.parent / "tone3000-tokens.json"
            )
            tone3000 = Tone3000Service(
                arguments.tone3000_key,
                arguments.tone3000_redirect_uri,
                token_file,
                base_url=arguments.tone3000_base_url,
            )
        serve(arguments.models, arguments.database, arguments.socket, tone3000)


if __name__ == "__main__":
    main()
