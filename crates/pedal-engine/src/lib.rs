#![recursion_limit = "256"]

use serde::{Deserialize, Serialize};
use serde_json::{Value, json};

pub mod audio;
pub mod dsp;
pub mod effects;
pub mod presets;
pub mod preview;
pub mod state;
pub mod tuner;

pub const API_VERSION: u8 = 1;

#[derive(Debug, Deserialize)]
pub struct Request {
    pub api: u8,
    pub id: String,
    #[serde(rename = "type")]
    pub message_type: String,
    #[serde(default)]
    pub payload: Value,
}

#[derive(Debug, Serialize)]
pub struct Response {
    pub api: u8,
    pub id: String,
    #[serde(rename = "type")]
    pub message_type: &'static str,
    pub payload: Value,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(default)]
pub struct EngineState {
    pub bypassed: bool,
    pub preset: String,
    pub preset_id: Option<String>,
    pub preset_dirty: bool,
    pub pre_bypassed: bool,
    pub pre_model: Option<String>,
    pub amp_bypassed: bool,
    pub model: Option<String>,
    pub pedal_drive_db: f32,
    pub pedal_mix: f32,
    pub pedal_level_db: f32,
    pub amp_bass_db: f32,
    pub amp_mid_db: f32,
    pub amp_treble_db: f32,
    pub amp_volume_db: f32,
    pub gate_enabled: bool,
    pub gate_threshold_db: f32,
    pub compressor_enabled: bool,
    pub compressor_threshold_db: f32,
    pub compressor_ratio: f32,
    pub eq_enabled: bool,
    pub eq_visible: bool,
    pub eq_low_db: f32,
    pub eq_mid_db: f32,
    pub eq_high_db: f32,
    pub chorus_enabled: bool,
    pub chorus_visible: bool,
    pub chorus_rate_hz: f32,
    pub chorus_depth: f32,
    pub chorus_mix: f32,
    pub delay_enabled: bool,
    pub delay_visible: bool,
    pub delay_time_ms: f32,
    pub delay_feedback: f32,
    pub delay_mix: f32,
    pub reverb_enabled: bool,
    pub reverb_visible: bool,
    pub reverb_decay_seconds: f32,
    pub reverb_mix: f32,
    pub looper_mode: String,
    pub looper_visible: bool,
    pub tuner_enabled: bool,
    pub sample_rate: u32,
    pub buffer_frames: u32,
}

impl Default for EngineState {
    fn default() -> Self {
        Self {
            bypassed: false,
            preset: "Default".to_owned(),
            preset_id: None,
            preset_dirty: false,
            pre_bypassed: false,
            pre_model: None,
            amp_bypassed: false,
            model: None,
            pedal_drive_db: 0.0,
            pedal_mix: 1.0,
            pedal_level_db: 0.0,
            amp_bass_db: 0.0,
            amp_mid_db: 0.0,
            amp_treble_db: 0.0,
            amp_volume_db: 0.0,
            gate_enabled: false,
            gate_threshold_db: -55.0,
            compressor_enabled: false,
            compressor_threshold_db: -18.0,
            compressor_ratio: 3.0,
            eq_enabled: false,
            eq_visible: false,
            eq_low_db: 0.0,
            eq_mid_db: 0.0,
            eq_high_db: 0.0,
            chorus_enabled: false,
            chorus_visible: false,
            chorus_rate_hz: 0.8,
            chorus_depth: 0.5,
            chorus_mix: 0.35,
            delay_enabled: false,
            delay_visible: false,
            delay_time_ms: 360.0,
            delay_feedback: 0.35,
            delay_mix: 0.25,
            reverb_enabled: false,
            reverb_visible: false,
            reverb_decay_seconds: 2.5,
            reverb_mix: 0.25,
            looper_mode: "stopped".to_owned(),
            looper_visible: false,
            tuner_enabled: false,
            sample_rate: 48_000,
            buffer_frames: 64,
        }
    }
}

impl EngineState {
    pub fn snapshot(&self) -> Value {
        json!({
            "engine": "ready",
            "bypassed": self.bypassed,
            "preset": self.preset,
            "preset_id": self.preset_id,
            "preset_dirty": self.preset_dirty,
            "pre_bypassed": self.pre_bypassed,
            "pre_model": self.pre_model,
            "amp_bypassed": self.amp_bypassed,
            "model": self.model,
            "pedal_drive_db": self.pedal_drive_db,
            "pedal_mix": self.pedal_mix,
            "pedal_level_db": self.pedal_level_db,
            "amp_bass_db": self.amp_bass_db,
            "amp_mid_db": self.amp_mid_db,
            "amp_treble_db": self.amp_treble_db,
            "amp_volume_db": self.amp_volume_db,
            "gate_enabled": self.gate_enabled,
            "gate_threshold_db": self.gate_threshold_db,
            "compressor_enabled": self.compressor_enabled,
            "compressor_threshold_db": self.compressor_threshold_db,
            "compressor_ratio": self.compressor_ratio,
            "eq_enabled": self.eq_enabled,
            "eq_visible": self.eq_visible,
            "eq_low_db": self.eq_low_db,
            "eq_mid_db": self.eq_mid_db,
            "eq_high_db": self.eq_high_db,
            "chorus_enabled": self.chorus_enabled,
            "chorus_visible": self.chorus_visible,
            "chorus_rate_hz": self.chorus_rate_hz,
            "chorus_depth": self.chorus_depth,
            "chorus_mix": self.chorus_mix,
            "delay_enabled": self.delay_enabled,
            "delay_visible": self.delay_visible,
            "delay_time_ms": self.delay_time_ms,
            "delay_feedback": self.delay_feedback,
            "delay_mix": self.delay_mix,
            "reverb_enabled": self.reverb_enabled,
            "reverb_visible": self.reverb_visible,
            "reverb_decay_seconds": self.reverb_decay_seconds,
            "reverb_mix": self.reverb_mix,
            "looper_mode": self.looper_mode,
            "looper_visible": self.looper_visible,
            "tuner_enabled": self.tuner_enabled,
            "sample_rate": self.sample_rate,
            "buffer_frames": self.buffer_frames,
        })
    }
}

pub fn handle_request(state: &mut EngineState, request: Request) -> Response {
    if request.api != API_VERSION {
        return error(
            request.id,
            "unsupported_api",
            "Only control API v1 is supported",
        );
    }

    match request.message_type.as_str() {
        "get_state" => Response {
            api: API_VERSION,
            id: request.id,
            message_type: "state",
            payload: state.snapshot(),
        },
        "set_bypass" => match request.payload.get("bypassed").and_then(Value::as_bool) {
            Some(bypassed) => {
                state.bypassed = bypassed;
                Response {
                    api: API_VERSION,
                    id: request.id,
                    message_type: "state",
                    payload: state.snapshot(),
                }
            }
            None => error(
                request.id,
                "invalid_payload",
                "set_bypass requires a boolean 'bypassed' field",
            ),
        },
        _ => error(
            request.id,
            "unknown_message",
            "Unknown control message type",
        ),
    }
}

pub fn parse_and_handle(state: &mut EngineState, line: &str) -> Response {
    match serde_json::from_str::<Request>(line) {
        Ok(request) => handle_request(state, request),
        Err(err) => error("unknown".to_owned(), "invalid_json", &err.to_string()),
    }
}

fn error(id: String, code: &str, message: &str) -> Response {
    Response {
        api: API_VERSION,
        id,
        message_type: "error",
        payload: json!({"code": code, "message": message}),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bypass_change_returns_fresh_snapshot() {
        let mut state = EngineState::default();
        let response = parse_and_handle(
            &mut state,
            r#"{"api":1,"id":"test-1","type":"set_bypass","payload":{"bypassed":true}}"#,
        );

        assert_eq!(response.message_type, "state");
        assert_eq!(response.payload["bypassed"], true);
        assert!(state.bypassed);
    }

    #[test]
    fn rejects_an_unknown_api_version() {
        let mut state = EngineState::default();
        let response = parse_and_handle(
            &mut state,
            r#"{"api":9,"id":"test-2","type":"get_state","payload":{}}"#,
        );

        assert_eq!(response.message_type, "error");
        assert_eq!(response.payload["code"], "unsupported_api");
    }
}
