.PHONY: check test mock catalog catalog-serve dev dev-up dev-down dev-status dsp-soak nam-soak nam-upstream-check virtual-audio ui-check ui-build

dev:
	tools/dev.sh demo

dev-up:
	tools/dev.sh up

dev-down:
	tools/dev.sh down

dev-status:
	tools/dev.sh status

check:
	cargo fmt --check
	cargo clippy --workspace --all-targets -- -D warnings
	python3 -m unittest discover -s services/catalog/tests -v
	python3 -m unittest discover -s tools/tests -v
	$(MAKE) ui-check

test:
	cargo test --workspace
	python3 -m unittest discover -s services/catalog/tests -v
	python3 -m unittest discover -s tools/tests -v

mock:
	python3 tools/mock_engine.py

catalog:
	PYTHONPATH=services/catalog python3 -m pedal_catalog.cli scan --models data/models --database data/catalog.db

catalog-serve:
	PYTHONPATH=services/catalog python3 -m pedal_catalog.cli serve --models data/models --database data/catalog.db --socket /tmp/pedal-catalog.sock

virtual-audio:
	PEDAL_AUDIO_DEVICE=default PEDAL_LOOPBACK_BLOCKS=256 PEDAL_LOOPBACK_TIMEOUT_MS=2000 cargo run -p pedal-engine --bin pedal-audio-loopback --release

dsp-soak:
	cargo run -p pedal-engine --bin pedal-dsp-soak --release

nam-upstream-check:
	cmake -S vendor/NeuralAmpModelerCore -B target/nam-core -DCMAKE_BUILD_TYPE=Release -DNAM_ENABLE_A2_FAST=ON
	cmake --build target/nam-core --target loadmodel benchmodel -j2
	target/nam-core/tools/loadmodel vendor/NeuralAmpModelerCore/example_models/wavenet_a2_max.nam

nam-soak:
	cargo run -p pedal-engine --bin pedal-nam-soak --release

ui-check:
	cd apps/pedal_ui && dart format --output=none --set-exit-if-changed lib test
	cd apps/pedal_ui && flutter analyze
	cd apps/pedal_ui && flutter test

ui-build:
	cd apps/pedal_ui && flutter build linux --release
