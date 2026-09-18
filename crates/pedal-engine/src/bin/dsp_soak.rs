use pedal_engine::dsp::{InterleavedLayout, Passthrough, process_interleaved_i32};
use std::time::{Duration, Instant};

const SAMPLE_RATE: usize = 48_000;
const FRAMES_PER_BLOCK: usize = 64;
const CAPTURE_CHANNELS: usize = 2;
const PLAYBACK_CHANNELS: usize = 2;
const AUDIO_SECONDS: usize = 60;

fn main() {
    let blocks = SAMPLE_RATE * AUDIO_SECONDS / FRAMES_PER_BLOCK;
    let deadline = Duration::from_secs_f64(FRAMES_PER_BLOCK as f64 / SAMPLE_RATE as f64);
    let mut input = vec![0_i32; FRAMES_PER_BLOCK * CAPTURE_CHANNELS];
    let mut output = vec![0_i32; FRAMES_PER_BLOCK * PLAYBACK_CHANNELS];
    let mut mono = vec![0.0_f32; FRAMES_PER_BLOCK];
    let mut processor = Passthrough;
    let mut phase = 0_u32;
    let mut checksum = 0_i64;
    let mut max_error = 0_i64;
    let mut worst_block = Duration::ZERO;
    let mut deadline_misses = 0_u64;

    let started = Instant::now();
    for _ in 0..blocks {
        for frame in 0..FRAMES_PER_BLOCK {
            phase = phase.wrapping_add(0x02aa_aaab);
            let guitar = (phase as i32) >> 8;
            input[frame * CAPTURE_CHANNELS] = guitar;
            input[frame * CAPTURE_CHANNELS + 1] = -guitar;
        }

        let block_started = Instant::now();
        process_interleaved_i32(
            &input,
            &mut output,
            &mut mono,
            InterleavedLayout {
                frames: FRAMES_PER_BLOCK,
                capture_channels: CAPTURE_CHANNELS,
                playback_channels: PLAYBACK_CHANNELS,
                guitar_input_channel: 0,
            },
            &mut processor,
        )
        .expect("synthetic buffers are valid");
        let elapsed = block_started.elapsed();
        worst_block = worst_block.max(elapsed);
        if elapsed > deadline {
            deadline_misses += 1;
        }

        for frame in 0..FRAMES_PER_BLOCK {
            let expected = i64::from(input[frame * CAPTURE_CHANNELS]);
            let actual = i64::from(output[frame * PLAYBACK_CHANNELS]);
            max_error = max_error.max((expected - actual).abs());
            checksum = checksum.wrapping_add(actual);
        }
    }

    println!(
        "Processed {AUDIO_SECONDS}s of synthetic audio in {:.2?}; worst block {:.2?}; deadline misses {}; max conversion error {}; checksum {}",
        started.elapsed(),
        worst_block,
        deadline_misses,
        max_error,
        checksum,
    );

    if max_error > 256 {
        eprintln!("Synthetic passthrough exceeded the 24-bit conversion tolerance");
        std::process::exit(1);
    }
}
