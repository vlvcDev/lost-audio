use crate::EngineState;
use serde::{Deserialize, Serialize};
use std::fs::{self, File, OpenOptions};
use std::io::{self, Write};
use std::path::Path;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(default)]
pub struct PresetRig {
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
}

impl Default for PresetRig {
    fn default() -> Self {
        Self::from_state(&EngineState::default())
    }
}

impl PresetRig {
    pub fn from_state(state: &EngineState) -> Self {
        Self {
            pre_bypassed: state.pre_bypassed,
            pre_model: state.pre_model.clone(),
            amp_bypassed: state.amp_bypassed,
            model: state.model.clone(),
            pedal_drive_db: state.pedal_drive_db,
            pedal_mix: state.pedal_mix,
            pedal_level_db: state.pedal_level_db,
            amp_bass_db: state.amp_bass_db,
            amp_mid_db: state.amp_mid_db,
            amp_treble_db: state.amp_treble_db,
            amp_volume_db: state.amp_volume_db,
        }
    }

    pub fn apply_to(&self, state: &mut EngineState) {
        state.pre_bypassed = self.pre_bypassed;
        state.pre_model.clone_from(&self.pre_model);
        state.amp_bypassed = self.amp_bypassed;
        state.model.clone_from(&self.model);
        state.pedal_drive_db = self.pedal_drive_db;
        state.pedal_mix = self.pedal_mix;
        state.pedal_level_db = self.pedal_level_db;
        state.amp_bass_db = self.amp_bass_db;
        state.amp_mid_db = self.amp_mid_db;
        state.amp_treble_db = self.amp_treble_db;
        state.amp_volume_db = self.amp_volume_db;
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Preset {
    pub id: String,
    pub name: String,
    pub rig: PresetRig,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(default)]
pub struct PresetStore {
    pub version: u8,
    pub next_id: u64,
    pub presets: Vec<Preset>,
}

impl Default for PresetStore {
    fn default() -> Self {
        Self {
            version: 1,
            next_id: 1,
            presets: Vec::new(),
        }
    }
}

impl PresetStore {
    pub fn save_current(&mut self, name: String, state: &EngineState) -> &Preset {
        let id = format!("preset-{}", self.next_id);
        self.next_id += 1;
        self.presets.push(Preset {
            id,
            name,
            rig: PresetRig::from_state(state),
        });
        self.presets.last().expect("just inserted preset")
    }

    pub fn find(&self, id: &str) -> Option<&Preset> {
        self.presets.iter().find(|preset| preset.id == id)
    }

    pub fn rename(&mut self, id: &str, name: String) -> Option<&Preset> {
        let preset = self.presets.iter_mut().find(|preset| preset.id == id)?;
        preset.name = name;
        Some(preset)
    }

    pub fn delete(&mut self, id: &str) -> bool {
        let before = self.presets.len();
        self.presets.retain(|preset| preset.id != id);
        self.presets.len() != before
    }
}

pub fn load_or_default(path: &Path) -> PresetStore {
    match fs::read(path) {
        Ok(bytes) => serde_json::from_slice(&bytes).unwrap_or_else(|error| {
            eprintln!(
                "could not restore presets from {}: {error}; using an empty library",
                path.display()
            );
            PresetStore::default()
        }),
        Err(error) if error.kind() == io::ErrorKind::NotFound => PresetStore::default(),
        Err(error) => {
            eprintln!(
                "could not read presets from {}: {error}; using an empty library",
                path.display()
            );
            PresetStore::default()
        }
    }
}

pub fn save_atomic(path: &Path, store: &PresetStore) -> io::Result<()> {
    let parent = path
        .parent()
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "preset path has no parent"))?;
    fs::create_dir_all(parent)?;
    let temporary = path.with_extension("json.new");
    let bytes = serde_json::to_vec_pretty(store).map_err(io::Error::other)?;
    let mut file = OpenOptions::new()
        .create(true)
        .truncate(true)
        .write(true)
        .open(&temporary)?;
    file.write_all(&bytes)?;
    file.write_all(b"\n")?;
    file.sync_all()?;
    fs::rename(&temporary, path)?;
    File::open(parent)?.sync_all()?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{SystemTime, UNIX_EPOCH};

    #[test]
    fn store_round_trip_preserves_complete_rig_and_stable_id() {
        let unique = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("clock")
            .as_nanos();
        let path = std::env::temp_dir().join(format!("pedal-presets-{unique}.json"));
        let mut store = PresetStore::default();
        let state = EngineState {
            pre_model: Some("/models/drive.nam".to_owned()),
            model: Some("/models/amp.nam".to_owned()),
            pedal_mix: 0.4,
            amp_bass_db: 3.0,
            ..EngineState::default()
        };
        let id = store.save_current("Crunch".to_owned(), &state).id.clone();

        save_atomic(&path, &store).expect("save presets");
        let restored = load_or_default(&path);

        assert_eq!(restored, store);
        assert_eq!(restored.find(&id).expect("preset").rig.pedal_mix, 0.4);
        fs::remove_file(path).expect("remove preset fixture");
    }
}
