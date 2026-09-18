use std::cell::Cell;
use std::error::Error;
use std::ffi::{CStr, CString, c_char, c_double, c_float, c_int};
use std::fmt;
use std::marker::PhantomData;
use std::path::Path;
use std::ptr::NonNull;

const STATUS_OK: c_int = 0;
const ERROR_CAPACITY: usize = 512;

#[repr(C)]
struct PedalNamModel {
    _private: [u8; 0],
}

unsafe extern "C" {
    fn pedal_nam_load(
        path: *const c_char,
        sample_rate: c_double,
        max_buffer_frames: c_int,
        output: *mut *mut PedalNamModel,
        error_message: *mut c_char,
        error_message_capacity: usize,
    ) -> c_int;
    fn pedal_nam_free(model: *mut PedalNamModel);
    fn pedal_nam_process(
        model: *mut PedalNamModel,
        input: *const c_float,
        output: *mut c_float,
        frames: c_int,
    ) -> c_int;
    fn pedal_nam_expected_sample_rate(model: *const PedalNamModel) -> c_double;
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NamError {
    pub status: i32,
    pub message: String,
}

impl fmt::Display for NamError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(formatter, "{} (NAM status {})", self.message, self.status)
    }
}

impl Error for NamError {}

pub struct NamModel {
    raw: NonNull<PedalNamModel>,
    max_buffer_frames: usize,
    input_workspace: Vec<f32>,
    faulted: bool,
    _not_sync: PhantomData<Cell<()>>,
}

// The model has exclusive ownership and is safe to move onto the audio thread.
unsafe impl Send for NamModel {}

impl NamModel {
    pub fn load(
        path: impl AsRef<Path>,
        sample_rate: f64,
        max_buffer_frames: usize,
    ) -> Result<Self, NamError> {
        let path = path.as_ref();
        let path_string = path.to_str().ok_or_else(|| NamError {
            status: 1,
            message: "NAM path is not valid UTF-8".to_owned(),
        })?;
        let path = CString::new(path_string).map_err(|_| NamError {
            status: 1,
            message: "NAM path contains a null byte".to_owned(),
        })?;
        let max_buffer_frames = c_int::try_from(max_buffer_frames).map_err(|_| NamError {
            status: 1,
            message: "maximum buffer size exceeds the C ABI range".to_owned(),
        })?;
        let mut raw = std::ptr::null_mut();
        let mut error = [0 as c_char; ERROR_CAPACITY];
        // SAFETY: All pointers are valid for the duration of the call and the output starts null.
        let status = unsafe {
            pedal_nam_load(
                path.as_ptr(),
                sample_rate,
                max_buffer_frames,
                &mut raw,
                error.as_mut_ptr(),
                error.len(),
            )
        };
        if status != STATUS_OK {
            // SAFETY: The C++ bridge always null-terminates this fixed-size error buffer.
            let message = unsafe { CStr::from_ptr(error.as_ptr()) }
                .to_string_lossy()
                .into_owned();
            return Err(NamError { status, message });
        }
        let raw = NonNull::new(raw).ok_or_else(|| NamError {
            status: 2,
            message: "NAM Core reported success without returning a model".to_owned(),
        })?;

        Ok(Self {
            raw,
            max_buffer_frames: max_buffer_frames as usize,
            input_workspace: vec![0.0; max_buffer_frames as usize],
            faulted: false,
            _not_sync: PhantomData,
        })
    }

    pub fn process(&mut self, samples: &mut [f32]) -> Result<(), NamError> {
        if samples.len() > self.max_buffer_frames {
            return Err(NamError {
                status: 1,
                message: "audio block exceeds the prepared NAM buffer size".to_owned(),
            });
        }
        // NAM supports distinct buffers. This workspace was allocated during model loading.
        self.input_workspace[..samples.len()].copy_from_slice(samples);
        // SAFETY: The model is exclusively borrowed; buffers are valid and have `samples.len()` frames.
        let status = unsafe {
            pedal_nam_process(
                self.raw.as_ptr(),
                self.input_workspace.as_ptr(),
                samples.as_mut_ptr(),
                samples.len() as c_int,
            )
        };
        if status == STATUS_OK {
            Ok(())
        } else {
            self.faulted = true;
            Err(NamError {
                status,
                message: "NAM processing failed".to_owned(),
            })
        }
    }

    pub fn expected_sample_rate(&self) -> f64 {
        // SAFETY: `self.raw` stays valid until Drop.
        unsafe { pedal_nam_expected_sample_rate(self.raw.as_ptr()) }
    }

    pub fn is_faulted(&self) -> bool {
        self.faulted
    }
}

impl Drop for NamModel {
    fn drop(&mut self) {
        // SAFETY: This is the unique pointer returned by `pedal_nam_load` and is freed exactly once.
        unsafe { pedal_nam_free(self.raw.as_ptr()) };
    }
}
