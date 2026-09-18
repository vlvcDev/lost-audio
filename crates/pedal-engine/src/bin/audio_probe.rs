use pedal_engine::audio::{AudioConfig, enumerate_pcm_devices, probe};
use std::env;

fn main() {
    let config = AudioConfig {
        requested_device: env::var("PEDAL_AUDIO_DEVICE").ok(),
        requested_capture_device: env::var("PEDAL_AUDIO_CAPTURE_DEVICE").ok(),
        requested_playback_device: env::var("PEDAL_AUDIO_PLAYBACK_DEVICE").ok(),
        ..AudioConfig::default()
    };

    println!("ALSA PCM devices:");
    match enumerate_pcm_devices() {
        Ok(devices) => {
            for device in devices {
                let directions = match (device.can_capture, device.can_playback) {
                    (true, true) => "duplex",
                    (true, false) => "capture",
                    (false, true) => "playback",
                    (false, false) => "unknown",
                };
                println!(
                    "  {:<9} {:<28} {}",
                    directions, device.name, device.description
                );
            }
        }
        Err(error) => {
            eprintln!("Could not enumerate ALSA devices: {error}");
            std::process::exit(1);
        }
    }

    println!("\nNegotiating 48 kHz, 64 frames (128-frame fallback)...");
    match probe(&config) {
        Ok(audio) => println!(
            "Ready: {} at {} Hz / {} frames / {} input(s) / {} output(s) / streams {}",
            audio.device.name,
            audio.sample_rate,
            audio.period_frames,
            audio.capture_channels,
            audio.playback_channels,
            if audio.streams_linked {
                "hardware-linked"
            } else {
                "independent"
            },
        ),
        Err(error) => {
            eprintln!("Audio probe failed: {error}");
            std::process::exit(2);
        }
    }
}
