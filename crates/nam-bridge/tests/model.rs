use nam_bridge::NamModel;
use std::path::PathBuf;

fn example(name: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../vendor/NeuralAmpModelerCore/example_models")
        .join(name)
}

#[test]
fn loads_and_processes_the_reference_lstm() {
    let mut model = NamModel::load(example("lstm.nam"), 48_000.0, 64).expect("load LSTM model");
    let mut audio = [0.0_f32; 64];
    audio[0] = 0.1;

    model.process(&mut audio).expect("process one block");

    assert!(audio.iter().all(|sample| sample.is_finite()));
    assert_eq!(model.expected_sample_rate(), 48_000.0);
    assert!(!model.is_faulted());
}

#[test]
fn rejects_blocks_larger_than_the_prepared_maximum() {
    let mut model = NamModel::load(example("lstm.nam"), 48_000.0, 64).expect("load LSTM model");
    let mut audio = [0.0_f32; 65];

    assert!(model.process(&mut audio).is_err());
}

#[test]
fn rejects_a_model_sample_rate_mismatch() {
    let result = NamModel::load(example("lstm.nam"), 44_100.0, 64);

    assert!(result.is_err());
}
