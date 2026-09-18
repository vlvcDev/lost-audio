use pedal_engine::audio::{AudioConfig, probe, run_loopback};
use std::env;
use std::time::Duration;

fn main() {
    let config = AudioConfig {
        requested_device: env::var("PEDAL_AUDIO_DEVICE").ok(),
        requested_capture_device: env::var("PEDAL_AUDIO_CAPTURE_DEVICE").ok(),
        requested_playback_device: env::var("PEDAL_AUDIO_PLAYBACK_DEVICE").ok(),
        guitar_input_channel: env::var("PEDAL_GUITAR_INPUT")
            .ok()
            .and_then(|value| value.parse().ok())
            .unwrap_or(0),
        ..AudioConfig::default()
    };
    let block_limit = env::var("PEDAL_LOOPBACK_BLOCKS")
        .ok()
        .and_then(|value| value.parse().ok());
    let duration_limit = env::var("PEDAL_LOOPBACK_TIMEOUT_MS")
        .ok()
        .and_then(|value| value.parse().ok())
        .map(Duration::from_millis);

    let negotiated = probe(&config).unwrap_or_else(|error| {
        eprintln!("Audio negotiation failed: {error}");
        std::process::exit(1);
    });
    println!(
        "Looping input {} to stereo through {} at {} Hz / {} frames. Press Ctrl+C to stop.",
        config.guitar_input_channel + 1,
        negotiated.device.name,
        negotiated.sample_rate,
        negotiated.period_frames,
    );

    match run_loopback(&config, block_limit, duration_limit) {
        Ok(stats) => println!(
            "Completed {} blocks / {} frames with {} recovery event(s){}.",
            stats.blocks,
            stats.frames,
            stats.recoveries,
            if stats.timed_out {
                " (time limit reached)"
            } else {
                ""
            }
        ),
        Err(error) => {
            eprintln!("Audio loopback stopped: {error}");
            std::process::exit(2);
        }
    }
}
