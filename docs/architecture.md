# V0 architecture

## System boundary

```text
 Guitar
   |
   v
USB audio interface <-> Rust engine <---- Unix socket ----> Flutter UI
                          |   ^                                |
                          |   +---- prepared assets -----------+
                          v
                 NAM Core + pedal DSP
                          ^
                          |
                    local model files
                          ^
                          |
            Python catalog/import worker <----> TONE3000
                          |
                          v
                     SQLite catalog
```

The Rust process is the only owner of the audio device and DSP graph. Flutter is a control surface, never an audio processor. Python performs slow file, database, metadata, and future TONE3000 work outside the audio process.

## Technology choices

| Area | V0 choice | Reason |
|---|---|---|
| Real-time engine | Stable Rust | Memory safety and predictable native performance |
| Amp capture runtime | NAM Core C++ behind a narrow C ABI | Use the upstream inference implementation without coupling the whole engine to C++ |
| UI | Flutter + Dart, Linux GTK embedder | One touch-first codebase with a productive widget system |
| Catalog/import | Python 3.11+ | Fast integration work and mature HTTP/metadata tooling |
| Audio | ALSA device access; PipeWire/JACK for development/routing | Direct, low-latency production path with familiar Linux diagnostics |
| State | SQLite in WAL mode plus content-addressed files | Durable metadata and atomic model identity |
| IPC | Newline-delimited JSON over a Unix-domain socket | Inspectable, versioned, local-only control channel |
| Deployment | Raspberry Pi OS Lite 64-bit and systemd | Small base image and supervised boot services |

## Process rules

The audio callback may not allocate memory, read files, access SQLite or the network, take an unbounded lock, or log. Control changes are prepared off-thread and passed to the callback as fixed-size commands. Graph/model changes use a prepared graph swap at a buffer boundary.

The current continuous path preallocates capture, playback, mono, and pedal dry-mix workspaces before streaming. Restored pedal and amp NAM models are loaded before the stream begins and moved exclusively onto the audio thread. The fixed order is pedal/pre NAM followed by amp NAM. Bypass and adjustable DSP values are shared atomically, so UI changes require no callback lock or allocation. dB conversion occurs on the control thread and gain changes ramp across one block. Each live model replacement is prepared outside the audio thread, then delivered through its own non-blocking single-slot mailbox for a boundary swap. A fixed 30 Hz high-pass filter precedes the controllable chain, and a zero-lookahead −1 dBFS safety limiter follows even global bypass. Peak, clip, CPU, and XRun telemetry use atomics and are read by the UI at 10 Hz.

The control socket is `/run/pedal/control.sock` in production and `/tmp/pedal-control.sock` during desktop development. UI meter polling runs at 10 Hz and is capped at 20 Hz.

The catalog socket is `/run/pedal/catalog.sock` in production and `/tmp/pedal-catalog.sock` during development. It serves local metadata plus TONE3000 Select status, selected-tone model listing, and download operations. Search and previews stay in TONE3000's hosted Select experience. Flutter sends a downloaded absolute model path to the Rust control socket for authoritative validation and preparation. Failure of any online operation does not affect local listing or playback.

## TONE3000 boundary

The Python worker follows TONE3000's documented OAuth 2.0 Authorization Code flow with PKCE. API access and model downloads carry the user's bearer token; the worker refuses to forward that token to a different origin. Downloads are written to a temporary file, hashed with SHA-256, and atomically moved into the model library before indexing. Tokens, HTTP, file writes, and SQLite never enter the Rust audio callback.

V0's online discovery policy is intentionally narrow:

| Source | Accepted scope | Enforcement |
|---|---|---|
| TONE3000 hosted Select | NAM format, architecture 2 | Forced in authorize and model-list requests |
| TONE3000 download | Model URL returned by authenticated API | Same-origin check, bearer auth, optional expected hash, local SHA-256 |
| Local import | Any `.nam` file | NAM Core validates when prepared off the audio thread |

The authorization presentation is not coupled to the client. Starting Select creates a fresh PKCE session and a short LAN handoff address (`http://pedal.local:8787/connect`). A phone or computer opens that address, browses and previews on TONE3000, then returns the authorization code and selected tone ID to the callback listener. The UI polls only selection status and never receives bearer or refresh tokens. The phone must be able to reach the Pi during this one-time handoff; it is not needed after models have been downloaded.

## Offline boot contract

Network availability must never gate the audio path. Models, catalog metadata, presets, and last-known-good engine state live under `/var/lib/pedal`, not in temporary storage or the read-only application bundle. At startup the Rust engine restores `/var/lib/pedal/engine-state.json` and `/var/lib/pedal/presets.json` directly; it does not need the Python worker or SQLite to recover the selected model paths or saved rigs. State and preset writes use file synchronization plus an atomic rename so sudden power loss leaves either the old complete file or the new complete file.

```text
Power on (Wi-Fi optional)
        |
        v
Read persistent engine state ---> missing/corrupt? ---> safe default rig
        |
        v
Prepare local NAM model
        |
        v
Open USB audio + become playable
        |
        +---- online services connect later when available
```

Offline cold-boot acceptance criteria:

- A previously downloaded model remains present and hash-identifiable.
- The last selected preset and model path are restored without DNS or network timeouts.
- Playback startup does not wait for TONE3000 authentication or catalog refresh.
- Missing or corrupt state cannot prevent the engine and UI from starting.

## Initial signal chain

```text
Input trim -> DC/high-pass -> gate -> pedal drive -> pedal NAM -> dry/wet -> pedal level
           -> amp NAM -> bass/mid/treble -> amp volume -> cabinet IR
           -> modulation -> delay -> reverb -> output EQ -> limiter -> output
```

V0 will first make slots bypassable and reorderable. Initial built-in effects are compressor, overdrive, three-band EQ, chorus, delay, and reverb. A tuner is part of the input utility stage.

## Latency and reliability budgets

| Metric | Target | Acceptance method |
|---|---:|---|
| Sample rate | 48 kHz | Device and engine telemetry agree |
| Audio buffer | 64 samples preferred; 128 fallback | Stable 30-minute soak |
| Engine I/O latency | <= 8 ms round trip at 64 samples | Hardware loopback measurement |
| End-to-end monitored latency | <= 12 ms target, <= 15 ms ceiling | Guitar-input-to-output loopback |
| UI control acknowledgement | <= 50 ms p95 | Protocol timestamps |
| Meter update rate | <= 20 Hz | Client event count |
| XRuns | 0 in a 30-minute normal-load soak | Engine telemetry |

The Focusrite Scarlett 2i2 is the V0 reference interface. Selection is still based on ALSA capabilities and configurable name matching so other class-compliant 2-in/2-out interfaces can work without code changes. The exact latency cannot be committed until the Pi and physical interface are measured together. A 128-sample fallback is acceptable if the device or kernel is unstable at 64 samples.

Focusrite describes its USB interfaces as class-compliant and therefore potentially usable on Linux, but does not provide official Linux support. Firmware updates and vendor-specific routing or preamp controls must be configured from a supported macOS or Windows machine when required. V0 uses only standard USB Audio Class capture and playback.

## Milestones

| Milestone | Deliverable | Exit criteria |
|---|---|---|
| M0: shell | Repo, UI shell, protocol, mock, Pi service skeleton | UI can read state and toggle bypass |
| M1: audio loop | ALSA/PipeWire stereo pass-through and test harness | Clean 48 kHz loopback; no XRuns in soak |
| M2: NAM path | NAM Core bridge, model preparation and swap | Reference capture loads and plays safely |
| M3: pedalboard | Slots, initial effects, presets, IR convolution | Preset recall is click-free and repeatable |
| M4: library | TONE3000 hosted Select import | Downloaded model is verified, indexed, and loadable |
| M5: appliance | Read-only/recoverable deployment, watchdog, kiosk | Offline cold boot restores a downloaded tone and reaches playable state without keyboard |

## Deferred from V0

Cloud generation, stem separation, recording/time-machine features, wireless guitar transport, accounts, and remote control are explicitly out of scope.
