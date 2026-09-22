# Control protocol v1

Messages are UTF-8 JSON objects separated by newlines. Every request has `api`, `id`, `type`, and `payload`. Responses echo `id`; unsolicited events use a new engine-generated ID.

## Get state

```json
{"api":1,"id":"ui-1","type":"get_state","payload":{}}
```

```json
{"api":1,"id":"ui-1","type":"state","payload":{"engine":"ready","bypassed":false,"pre_bypassed":false,"amp_bypassed":false,"preset":"Default","preset_id":null,"preset_dirty":false,"pre_model":null,"model":null,"gate_enabled":false,"chorus_enabled":false,"delay_enabled":false,"reverb_enabled":false,"looper_mode":"stopped","tuner_enabled":false,"sample_rate":48000,"buffer_frames":64}}
```

## Set bypass

```json
{"api":1,"id":"ui-2","type":"set_bypass","payload":{"bypassed":true}}
```

The response is a fresh `state` snapshot. Invalid input returns an `error` message whose payload includes `code` and `message`. Unknown fields are ignored so compatible fields can be added within protocol v1.

Authoritative state changes are persisted by the engine outside the audio callback. On restart, the daemon restores the last complete state from `/var/lib/pedal/engine-state.json`; this operation has no network or catalog-service dependency.

## Select a prepared local model

```json
{"api":1,"id":"ui-3","type":"select_model","payload":{"path":"/var/lib/pedal/models/clean-combo.nam","preset":"Clean Combo","slot":"amp"}}
```

`slot` is `pre` for a pedal capture or `amp` for the main amp/full-rig capture; omission defaults to `amp` for compatibility. The engine requires an existing absolute `.nam` path. It validates and loads the model on the requesting control thread, then stages the prepared model in that slot's single-slot mailbox. The audio thread uses a non-blocking mailbox check and swaps ownership at the next block boundary. The previous model is retained for disposal by a non-audio thread. Invalid models leave both active models and persisted state unchanged.

The state response includes `pre_model` and `model` (the amp slot). At startup, both are restored locally and processed in this fixed order:

```text
input -> gate -> compressor -> pre/pedal NAM -> amp NAM -> EQ -> chorus -> delay -> reverb -> looper -> output
```

## Control or clear one slot

Each model slot can be bypassed independently without unloading its model:

```json
{"api":1,"id":"ui-4","type":"set_slot_bypass","payload":{"slot":"pre","bypassed":true}}
```

Set `slot` to `pre` or `amp`. The engine changes an atomic flag used directly by the audio thread and persists the choice for offline restart. Selecting a new model automatically engages that slot.

A slot can also be returned to clean passthrough:

```json
{"api":1,"id":"ui-5","type":"clear_model","payload":{"slot":"amp"}}
```

Clearing is staged through the same non-blocking mailbox as model selection. It removes only the requested slot, resets its slot bypass, and leaves the other model running. Both commands return a fresh `state` snapshot.

## Set an adjustable control

```json
{"api":1,"id":"ui-6","type":"set_control","payload":{"control":"amp_bass_db","value":3.5}}
```

The supported controls and ranges are:

| Control | Range | DSP position |
|---|---:|---|
| `pedal_drive_db` | 0 to +24 dB | Before the pedal NAM |
| `pedal_mix` | 0.0 to 1.0 | Pedal dry/wet blend |
| `pedal_level_db` | -24 to +12 dB | After the pedal blend |
| `amp_bass_db` | -12 to +12 dB | After the amp NAM |
| `amp_mid_db` | -12 to +12 dB | After the amp NAM |
| `amp_treble_db` | -12 to +12 dB | After the amp NAM |
| `amp_volume_db` | -24 to +12 dB | After the amp tone stack |
| `gate_threshold_db` | -80 to -10 dB | Noise gate threshold |
| `compressor_threshold_db` | -48 to 0 dB | Compressor threshold |
| `compressor_ratio` | 1 to 20 | Compressor ratio |
| `eq_low_db`, `eq_mid_db`, `eq_high_db` | -12 to +12 dB | Post-amp three-band EQ |
| `chorus_rate_hz` | 0.05 to 8 Hz | Chorus LFO speed |
| `chorus_depth`, `chorus_mix` | 0.0 to 1.0 | Chorus depth and blend |
| `delay_time_ms` | 20 to 1800 ms | Delay time |
| `delay_feedback`, `delay_mix` | 0.0 to 0.92 / 1.0 | Delay repeats and blend |
| `reverb_decay_seconds` | 0.3 to 12 s | Reverb decay |
| `reverb_mix` | 0.0 to 1.0 | Reverb blend |

The response contains the updated state. Invalid names, non-finite values, and out-of-range values are rejected without changing state. The engine converts dB to linear gain on the control thread, publishes the fixed-size values atomically, and ramps changes across an audio block to avoid a hard discontinuity. Controls persist with the rig for offline restart.

## Switch an effect or operate the looper

Each built-in effect is independently bypassable. `effect` is one of `gate`, `compressor`, `eq`, `chorus`, `delay`, or `reverb`.

```json
{"api":1,"id":"ui-7","type":"set_effect_bypass","payload":{"effect":"delay","bypassed":false}}
{"api":1,"id":"ui-8","type":"looper_action","payload":{"action":"record","bpm":100,"bars":4}}
```

Looper actions are `record`, `play`, `overdub`, and `stop`. `record` starts a four-beat audio-thread count-in, then records on beat one for the requested 1, 2, 4, or 8 bars (30–300 BPM). It automatically changes to playback on the selected bar boundary. Configurations longer than 30 seconds are rejected. The looper keeps up to 30 seconds of mono post-reverb audio in RAM. Its audio is intentionally not persisted: after a restart it reports `stopped` and begins with an empty loop.

## Open the clean-input tuner

```json
{"api":1,"id":"ui-9","type":"set_tuner_enabled","payload":{"enabled":true}}
```

The tuner receives the input after the protective 30 Hz high-pass but before the gate, NAM models, effects, and global bypass. It does not mute or otherwise alter the guitar signal. Clients should disable it after closing their tuner view; the engine also disables it when restarted.

## Presets

A preset stores both model paths, both slot bypass states, each effect's on/off state, and every adjustable control. Hardware negotiation, the global emergency bypass, and in-memory looper audio are not part of a preset.

```json
{"api":1,"id":"ui-8","type":"save_preset","payload":{"name":"Crunch"}}
{"api":1,"id":"ui-9","type":"list_presets","payload":{}}
{"api":1,"id":"ui-10","type":"load_preset","payload":{"id":"preset-1"}}
{"api":1,"id":"ui-11","type":"rename_preset","payload":{"id":"preset-1","name":"Lead"}}
{"api":1,"id":"ui-12","type":"delete_preset","payload":{"id":"preset-1"}}
```

`list_presets` returns a `presets` response containing stable IDs, names, and pedal/amp model paths. The other operations return authoritative engine state. Names are trimmed and limited to 64 characters. Loading prepares every referenced NAM model before staging either slot; a missing or invalid file leaves the current rig unchanged. `preset_dirty` becomes true when a saved rig's slot or control settings change, and resets after loading or saving a preset.

The library is atomically persisted to `/var/lib/pedal/presets.json`. Deleting the active preset removes it from the library but deliberately leaves the current sound loaded.

## Meter snapshot

```json
{"api":1,"id":"ui-7","type":"get_meters","payload":{}}
```

```json
{"api":1,"id":"ui-7","type":"meters","payload":{"input_db":-18.4,"output_db":-20.1,"clipped":false,"cpu_percent":3.2,"xruns":0,"tuner_hz":82.4,"tuner_confidence":0.93}}
```

Meters are display telemetry, not authoritative state. The Flutter client polls at 10 Hz, below the 20 Hz budget. Peaks and the clip flag cover the interval since the previous meter request; `xruns` is cumulative for the current engine process. `tuner_hz` and `tuner_confidence` are zero while the tuner is disabled or has no stable clean-input pitch. Clients must tolerate missing snapshots and reconnect normally.

## Render a hardware-free preview

```json
{"api":1,"id":"ui-12","type":"render_preview","payload":{"source":"built_in","processed":true}}
```

```json
{"api":1,"id":"ui-12","type":"preview","payload":{"path":"/tmp/pedal-preview.wav","duration_seconds":6.19}}
```

`source` may be `synthetic`, `built_in`, or `file`. A file source also supplies an absolute `path` to a WAV chosen by the local user. `processed` defaults to `true`; when false, the engine renders the resampled dry input for A/B listening. WAV inputs may be mono or multichannel 16/24/32-bit PCM or 32-bit float and are limited to the first 60 seconds. The built-in source is configured with `PEDAL_TEST_AUDIO_FILE`.

For processed playback, the engine renders offline through a newly prepared copy of the current pedal NAM, pedal controls, amp NAM, amp tone stack, bypass state, and safety stage. It writes a 48 kHz, 16-bit stereo WAV atomically outside the real-time audio thread. The destination remains engine-controlled through `PEDAL_PREVIEW_FILE`.

This is a development and auditioning aid, not a replacement for live interface testing. The Flutter Linux client plays the returned file through `pw-play`, falling back to `aplay`, and can stop the player without interrupting the engine.
The client allows up to two minutes for an offline render so unoptimized development builds and dual-NAM rigs can complete without a false timeout.
