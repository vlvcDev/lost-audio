//! Clean-input pitch detection for the tuner control surface.
//!
//! The analyser is inactive until the tuner screen opens. It takes a small
//! downsampled autocorrelation snapshot roughly twelve times a second, which
//! keeps the work comfortably outside the NAM-heavy path on Pi hardware.

use crate::dsp::MonoProcessor;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, AtomicU32, Ordering};

const ANALYSIS_FRAMES: usize = 1_024;
const DECIMATION: usize = 4;
const HISTORY_FRAMES: usize = ANALYSIS_FRAMES * DECIMATION;
const ANALYSIS_HOP: usize = 2_048;
const MIN_FREQUENCY_HZ: f32 = 55.0;
const MAX_FREQUENCY_HZ: f32 = 1_000.0;

struct AtomicFloat(AtomicU32);

impl AtomicFloat {
    fn new(value: f32) -> Self {
        Self(AtomicU32::new(value.to_bits()))
    }

    fn load(&self) -> f32 {
        f32::from_bits(self.0.load(Ordering::Relaxed))
    }

    fn store(&self, value: f32) {
        self.0.store(value.to_bits(), Ordering::Relaxed);
    }
}

pub struct TunerParameters {
    enabled: AtomicBool,
}

impl TunerParameters {
    pub fn new(enabled: bool) -> Self {
        Self {
            enabled: AtomicBool::new(enabled),
        }
    }

    pub fn update(&self, enabled: bool) {
        self.enabled.store(enabled, Ordering::Relaxed);
    }

    pub fn enabled(&self) -> bool {
        self.enabled.load(Ordering::Relaxed)
    }
}

pub struct TunerTelemetry {
    frequency_hz: AtomicFloat,
    confidence: AtomicFloat,
}

impl Default for TunerTelemetry {
    fn default() -> Self {
        Self {
            frequency_hz: AtomicFloat::new(0.0),
            confidence: AtomicFloat::new(0.0),
        }
    }
}

impl TunerTelemetry {
    pub fn snapshot(&self) -> (f32, f32) {
        (self.frequency_hz.load(), self.confidence.load())
    }

    fn clear(&self) {
        self.frequency_hz.store(0.0);
        self.confidence.store(0.0);
    }

    fn record(&self, frequency_hz: f32, confidence: f32) {
        self.frequency_hz.store(frequency_hz);
        self.confidence.store(confidence);
    }
}

pub struct TunerTapProcessor<P> {
    processor: P,
    parameters: Arc<TunerParameters>,
    telemetry: Arc<TunerTelemetry>,
    history: Vec<f32>,
    write_index: usize,
    history_filled: usize,
    frames_since_analysis: usize,
    sample_rate: f32,
}

impl<P> TunerTapProcessor<P> {
    pub fn new(
        processor: P,
        parameters: Arc<TunerParameters>,
        telemetry: Arc<TunerTelemetry>,
        sample_rate: u32,
    ) -> Self {
        Self {
            processor,
            parameters,
            telemetry,
            history: vec![0.0; HISTORY_FRAMES],
            write_index: 0,
            history_filled: 0,
            frames_since_analysis: 0,
            sample_rate: sample_rate as f32,
        }
    }

    fn capture(&mut self, samples: &[f32]) {
        if !self.parameters.enabled() {
            self.frames_since_analysis = 0;
            self.telemetry.clear();
            return;
        }
        for sample in samples {
            self.history[self.write_index] = *sample;
            self.write_index = (self.write_index + 1) % self.history.len();
            self.history_filled = (self.history_filled + 1).min(self.history.len());
        }
        self.frames_since_analysis += samples.len();
        if self.history_filled == self.history.len() && self.frames_since_analysis >= ANALYSIS_HOP {
            self.frames_since_analysis = 0;
            self.analyse();
        }
    }

    fn analyse(&self) {
        let mut window = [0.0_f32; ANALYSIS_FRAMES];
        for (index, sample) in window.iter_mut().enumerate() {
            let source = (self.write_index + index * DECIMATION) % self.history.len();
            *sample = self.history[source];
        }
        let rms = (window.iter().map(|sample| sample * sample).sum::<f32>()
            / ANALYSIS_FRAMES as f32)
            .sqrt();
        if rms < 0.0025 {
            self.telemetry.clear();
            return;
        }

        let analysis_rate = self.sample_rate / DECIMATION as f32;
        let minimum_lag = (analysis_rate / MAX_FREQUENCY_HZ) as usize;
        let maximum_lag = (analysis_rate / MIN_FREQUENCY_HZ) as usize;
        let mut best_lag = minimum_lag;
        let mut best_score = -1.0_f32;
        let mut previous = -1.0_f32;
        let mut after = -1.0_f32;
        for lag in minimum_lag..=maximum_lag {
            let mut cross = 0.0;
            let mut left_energy = 0.0;
            let mut right_energy = 0.0;
            for index in lag..ANALYSIS_FRAMES {
                let left = window[index];
                let right = window[index - lag];
                cross += left * right;
                left_energy += left * left;
                right_energy += right * right;
            }
            let score = cross / (left_energy * right_energy).sqrt().max(0.000_001);
            if score > best_score {
                previous = best_score;
                best_score = score;
                best_lag = lag;
                after = -1.0;
            } else if lag == best_lag + 1 {
                after = score;
            }
        }
        if best_score < 0.55 {
            self.telemetry.clear();
            return;
        }
        let refinement = if previous > -0.5 && after > -0.5 {
            (0.5 * (previous - after) / (previous - 2.0 * best_score + after)).clamp(-0.5, 0.5)
        } else {
            0.0
        };
        let frequency = analysis_rate / (best_lag as f32 + refinement);
        self.telemetry.record(frequency, best_score);
    }
}

impl<P: MonoProcessor> MonoProcessor for TunerTapProcessor<P> {
    fn process(&mut self, samples: &mut [f32]) {
        // Capture before applying any NAM/effect processor. The high-pass in
        // SafetyProcessor has already removed unusable DC without colouring
        // the guitar signal in a musically significant way.
        self.capture(samples);
        self.processor.process(samples);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::dsp::Passthrough;

    #[test]
    fn detects_a_clean_low_e_when_enabled() {
        let parameters = Arc::new(TunerParameters::new(true));
        let telemetry = Arc::new(TunerTelemetry::default());
        let mut tuner =
            TunerTapProcessor::new(Passthrough, parameters, Arc::clone(&telemetry), 48_000);
        let mut samples = (0..10_000)
            .map(|index| (index as f32 * 82.41 * std::f32::consts::TAU / 48_000.0).sin() * 0.25)
            .collect::<Vec<_>>();
        for block in samples.chunks_mut(64) {
            tuner.process(block);
        }
        let (frequency, confidence) = telemetry.snapshot();
        assert!((frequency - 82.41).abs() < 2.0, "detected {frequency}");
        assert!(confidence > 0.7);
    }

    #[test]
    fn does_not_report_a_pitch_while_disabled() {
        let parameters = Arc::new(TunerParameters::new(false));
        let telemetry = Arc::new(TunerTelemetry::default());
        let mut tuner =
            TunerTapProcessor::new(Passthrough, parameters, Arc::clone(&telemetry), 48_000);
        let mut samples = vec![0.25; HISTORY_FRAMES];
        tuner.process(&mut samples);
        assert_eq!(telemetry.snapshot(), (0.0, 0.0));
    }
}
