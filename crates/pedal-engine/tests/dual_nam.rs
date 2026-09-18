use pedal_engine::dsp::{MonoProcessor, SerialProcessor};
use std::path::{Path, PathBuf};

fn example_model() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../../vendor/NeuralAmpModelerCore/example_models/A2.nam")
}

#[test]
fn two_real_a2_models_process_in_pedal_then_amp_order() {
    let pre = nam_bridge::NamModel::load(example_model(), 48_000.0, 64).expect("load pedal NAM");
    let amp = nam_bridge::NamModel::load(example_model(), 48_000.0, 64).expect("load amp NAM");
    let mut chain = SerialProcessor::new(pre, amp);
    let mut block = [0.01_f32; 64];

    chain.process(&mut block);

    assert!(block.iter().all(|sample| sample.is_finite()));
}
