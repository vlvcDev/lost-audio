use serde::{Deserialize, Serialize};
use serde_json::{Value, json};

pub mod audio;
pub mod dsp;
pub mod presets;
pub mod preview;
pub mod state;

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
