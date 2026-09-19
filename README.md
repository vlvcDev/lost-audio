# Pedal V0

Pedal V0 is a Raspberry Pi 5 guitar processor focused on two jobs: running Neural Amp Modeler (NAM) captures and arranging a small pedalboard around them. The repository starts with a thin vertical slice: a versioned control protocol, a Rust engine shell, a Flutter touchscreen client, and a Python catalog indexer.

## Current state

- Rust daemon owns the continuous ALSA stream, restores pedal and amp NAM slots, and provides a 30 Hz input high-pass filter, gate, compressor, post-NAM EQ, chorus, delay, reverb, 30-second RAM looper, −1 dBFS safety limiter, and real-time-safe controls.
- Flutter Linux UI controls the rig and displays input/output peaks, clipping, DSP CPU use, and cumulative XRuns. Its clean-input tuner supports Standard, Drop D, D Standard, Drop C, Open G, and Open D.
- A hardware-free **PREVIEW** control renders a deterministic guitar-like riff through the current pedal and amp chain, then plays it through the computer's normal output.
- Presets save both NAM slots, bypass choices, and all adjustable controls in an offline, power-safe library.
- Python catalog tool indexes local `.nam` files into SQLite using content hashes.
- Offline catalog daemon exposes the persistent library to Flutter over a local Unix socket.
- TONE3000 client implements the hosted PKCE Select flow, A2-only NAM model listing, token refresh, and authenticated atomic downloads behind a mockable transport.
- Engine state is atomically persisted under `/var/lib/pedal`; the last playable rig survives a power cycle with no network connection.
- Python mock daemon makes the UI testable before the Rust/Pi toolchain is installed.
- ALSA discovery, negotiation, and continuous block processing are implemented. NAM Core A2 inference is integrated into the daemon and passes both the desktop soak and restored-model startup checks; live model swapping and the built-in pedalboard effects are available. IR convolution remains deferred.

## Repository map

| Path | Responsibility |
|---|---|
| `crates/pedal-engine` | Real-time engine host and control socket (Rust) |
| `crates/nam-bridge` | Safe Rust wrapper around the narrow NAM Core C ABI |
| `apps/pedal_ui` | 3.5-inch touchscreen UI (Flutter/Dart) |
| `services/catalog` | Local NAM/IR catalog and import tooling (Python) |
| `tools/dev.sh` | One-command desktop demo, service lifecycle, logs, and checks |
| `tools/mock_engine.py` | Desktop protocol simulator |
| `docs` | Architecture, protocol, and Pi bring-up notes |
| `deploy/systemd` | Boot-time service definitions |

## Desktop control-plane demo

Run `tools/dev.sh demo` to build and start the real Rust engine without opening an audio device, start the catalog, and launch Flutter. Press Ctrl+C to close the UI and its background services. Use `tools/dev.sh help` for backend-only startup, status, logs, shutdown, and test commands.

The Python mock remains available with `make mock` for isolated control-protocol experiments. It uses `/tmp/pedal-control.sock` by default.

The `pedal-engine` package now has a default executable, so a hardware-free control test can run with:

```sh
PEDAL_AUDIO_ENABLED=0 PEDAL_CONTROL_SOCKET=/tmp/pedal-control.sock PEDAL_STATE_FILE=/tmp/pedal-engine-state.json cargo run -p pedal-engine
```

Omit `PEDAL_AUDIO_ENABLED=0` to let the daemon open the selected ALSA endpoint. At startup it negotiates the stream, restores the saved local model, transfers exclusive model ownership to the audio thread, and applies bypass through an atomic flag. A model-load failure forces clean bypass while leaving the control service available.

The v1 control protocol also accepts `select_model` with an absolute local `.nam` path, preset name, and a `pre` or `amp` slot. The requesting control thread fully validates and prepares the model first. Independent single-slot mailboxes let the audio thread adopt each model at a block boundary without waiting; old models are retained for disposal outside the real-time path. Only successfully prepared selections become persistent restart state.

The active V0 signal chain is now:

```text
guitar input -> 30 Hz high-pass -> gate -> compressor -> optional pedal/pre NAM
             -> optional amp NAM -> EQ -> chorus -> delay -> reverb -> looper
             -> -1 dBFS safety limiter -> stereo output
```

The header's **Tuner** control reads the clean guitar input before the gate, NAM, and effect chain, so it remains useful regardless of the current rig. It provides a cents needle plus common tuning targets; it does not mute or change the live sound and turns off when closed.

The Flutter tone picker asks whether a model should load as **PEDAL** or **AMP** and displays the resulting chain. The main rig screen is a scrollable, PSX-inspired pedalboard: tap a pedal face to edit its settings or its footswitch to engage/bypass it. Gate, compressor, EQ, chorus, delay, and reverb settings and on/off states are preset-safe. The looper captures up to 30 seconds after the reverb and supports record, play, overdub, and stop; loop audio is intentionally RAM-only and clears after a restart. Pedal controls provide drive, dry/wet mix, and level around the capture. Amp controls provide a post-capture three-band tone stack and volume. Models, bypass settings, and control values survive an offline restart. A hardware-free integration test also processes a block through two real A2 networks in series.

Tap the large rig name to open the preset library. It supports save, load, rename, and delete; an asterisk marks a loaded preset whose slot or control settings have been changed. Preset loading validates all referenced local models before replacing the current rig, and deleting a preset never interrupts the sound currently in memory.

## Development toolchain

Rust 1.98.1 and Flutter 3.47.4 are installed outside Snap in `/home/vlvcdev/Documents/Codex/.pedal-dev-tools`. Load them into a terminal with `source tools/dev-env.sh`.

The Rust workspace, including its ALSA feature, compiles on this host. Flutter analysis and widget tests also run. Building the native Flutter Linux bundle requires system development packages that must be installed from an administrator-owned terminal:

```sh
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libasound2-dev
```

Afterward, run `make check` and `make ui-build`.

## Catalog demo

Place `.nam` files in `data/models`, then run `make catalog`. The tool creates `data/catalog.db` and records a stable SHA-256 identity for each model. TONE3000 downloads are authenticated, hashed, atomically installed, and retain their source model ID when indexed. Tone downloads remain opt-in; V0 never makes network calls on the audio thread.

Run `make catalog-serve` to keep the desktop catalog available at `/tmp/pedal-catalog.sock`. The Flutter **TONES** button lists these models, can rescan the folder, and sends a selected path plus its pedal/amp placement to the Rust engine. The sheet stays open while NAM Core validates and prepares the model; failures are shown without replacing the active or persisted tone.

The cloud button starts TONE3000's hosted Select browser. TONE3000 handles authentication, searching, previews, and the final tone choice; Pedal receives the selected tone ID, offers its NAM A2 models, and installs the chosen model locally. To enable it, start the catalog with a publishable key and a callback address that resolves to this machine from the browser completing selection:

```sh
export PEDAL_TONE3000_PUBLISHABLE_KEY=t3k_pub_your_key
export PEDAL_TONE3000_REDIRECT_URI=http://pedal.local:8787/callback
make catalog-serve
```

The UI presents the short handoff address `http://pedal.local:8787/connect`; opening it redirects to the current PKCE-protected login. The callback listener binds on all interfaces at the explicit redirect port, so the firewall must allow TCP 8787 on trusted local networks. For a production Pi, put the two variables in `/etc/pedal/tone3000.env`; the systemd unit reads that file. Tokens default to `tone3000-tokens.json` beside the catalog database with owner-only permissions.

For the current desktop end-to-end demo, the development harness replaces the three-terminal setup:

```sh
tools/dev.sh demo
```

This starts the real Rust engine with audio disabled, starts the catalog, waits for both sockets, launches Flutter, and cleans up the background services when the UI closes. State, presets, downloaded credentials, the catalog database, and logs are kept under `.pedal-dev`; downloaded `.nam` models remain in `data/models` for later offline use.

Press **TEST AUDIO** in the main UI to audition the current rig without a guitar or Scarlett. The built-in test is a real CC0 guitar DI recording made through a Focusrite Scarlett; choose **DRY** or **YOUR RIG** for an A/B comparison. You can also choose a local WAV or retain the deterministic synthetic riff for repeatable engineering checks. The engine accepts mono or stereo PCM/float WAV input, mixes it to mono, resamples it to 48 kHz, and renders it through the current NAM and effects chain. Flutter plays the resulting stereo WAV through PipeWire (`pw-play`) or ALSA (`aplay`). The generated file lives at `.pedal-dev/preview.wav` and is replaced on each preview. Source and licensing for the bundled recording are documented in `data/test-audio/README.md`.

For backend-only work or troubleshooting:

```sh
tools/dev.sh up
tools/dev.sh status
tools/dev.sh logs
tools/dev.sh down
tools/dev.sh test
```

When the Scarlett is available, run the same harness with audio enabled:

```sh
PEDAL_AUDIO_ENABLED=1 tools/dev.sh demo
```

The engine normally selects one duplex interface for both capture and playback. For development-only split routing—such as Scarlett guitar input monitored through the desktop's current PipeWire output—set the endpoints independently:

```sh
PEDAL_AUDIO_ENABLED=1 \
PEDAL_AUDIO_CAPTURE_DEVICE=hw:CARD=USB \
PEDAL_AUDIO_PLAYBACK_DEVICE=pipewire \
tools/dev.sh demo
```

Bluetooth playback is useful for functional checks but adds substantial codec/buffering latency. Use the Scarlett's wired headphone or line output for latency evaluation and normal playing.

For desktop testing with runtime output switching, let PipeWire manage both endpoints while keeping Scarlett Input 1 selected as the system input:

```sh
PEDAL_AUDIO_ENABLED=1 PEDAL_AUDIO_DEVICE=pipewire tools/dev.sh demo
```

The **OUTPUT** button lists the currently available PipeWire sinks and changes the live route without restarting the engine. Disconnected devices are omitted. Bluetooth outputs are marked with a latency warning. This desktop routing aid depends on `wpctl`; the production appliance continues to use its dedicated class-compliant USB interface directly.

The hosted Select flow deliberately requests only NAM format, architecture 2 tones. The catalog does not expose TONE3000's unrestricted search endpoint. Manually imported local `.nam` files are not filtered by architecture at catalog time; the engine remains responsible for rejecting anything NAM Core cannot load. A publishable TONE3000 API key and registered OAuth callback are only needed for live integration testing—unit tests use mocked response shapes and make no network calls.

## Offline and portable operation

Internet access is an import-time feature, not a playback dependency. Production installs keep downloaded models in `/var/lib/pedal/models`, the SQLite catalog in `/var/lib/pedal/catalog.db`, and the last engine state in `/var/lib/pedal/engine-state.json`. These paths are outside the application bundle so software upgrades do not replace the user's library. The Rust engine restores its last state before accepting UI connections and does not wait for Wi-Fi, TONE3000, OAuth, or the Python catalog worker.

An interrupted state update cannot replace the last good state file: changes are written and synced to a temporary file, then renamed atomically. If the saved state is missing or corrupt, the engine boots with safe defaults. An appliance acceptance test will cold-boot with networking disabled and verify that a previously downloaded tone is playable.

## Hardware assumptions

- Raspberry Pi 5, 8 GB recommended
- Raspberry Pi OS Lite, 64-bit
- Focusrite Scarlett 2i2 reference interface, with generic class-compliant USB support
- 48 kHz sample rate, 64-sample target buffer
- Touch display using the Flutter Linux embedder under Wayland

See `docs/architecture.md` for boundaries and latency targets.

## Audio-interface probe

On the Raspberry Pi, connect the interface and run `cargo run -p pedal-engine --bin pedal-audio-probe`. Automatic selection prefers device descriptions containing `Scarlett`, then `USB Audio`, then another duplex ALSA device. Set `PEDAL_AUDIO_DEVICE` to an ALSA PCM name to override selection.

After the probe succeeds, `cargo run -p pedal-engine --bin pedal-audio-loopback --release` routes interface input 1 to both outputs without NAM or effects. This diagnostic deliberately allocates all buffers before streaming. Set `PEDAL_GUITAR_INPUT=1` to select physical input 2 (the value is zero-based).

Without hardware, run `make virtual-audio` to exercise PipeWire's virtual ALSA endpoint for at most two seconds. The command exits cleanly even when no virtual capture source is producing samples. This proves stream negotiation and, when a source is present, block transport; it does not substitute for USB latency or XRun measurements.

Run `make dsp-soak` for a deterministic, hardware-free test. It generates 60 seconds of two-channel input, selects the guitar channel, crosses the integer/float DSP boundary, runs the current processor, routes mono output to stereo, and checks conversion error plus per-block deadlines. It runs faster than real time and uses the same 48 kHz/64-frame block shape as the target device.

## NAM Core

NeuralAmpModelerCore is pinned as a Git submodule at `vendor/NeuralAmpModelerCore`. Clone this repository with submodules, or initialize an existing clone using `git submodule update --init --recursive`. `make nam-upstream-check` builds the upstream loader and benchmark and loads its A2-fast reference model. The `nam-bridge` Rust crate builds the C++ inference sources with float samples and exposes exclusive model ownership plus bounded block processing.

Run `make nam-soak` to load the bundled A2 reference model through the Rust/C ABI boundary and process ten seconds of synthetic 48 kHz audio in 64-frame blocks. Pass another model path after the binary name when testing a local capture.
