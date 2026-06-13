#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::{Deserialize, Serialize};
use serde_json::Value as JsonValue;
use std::io::{BufRead, BufReader, Write};
use std::os::unix::net::UnixStream;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};
use tauri::{Emitter, Manager};

const PLAYER_STATUS_EVENT: &str = "native-player-status";

// ---------------------------------------------------------------------------
// State types
// ---------------------------------------------------------------------------

#[derive(Serialize)]
struct AppInfo {
    tauri: bool,
    os:    String,
    arch:  String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
enum NativePlaybackState {
    #[default]
    Idle,
    Playing,
    Paused,
    Stopped,
    Ended,
    Error,
}

impl NativePlaybackState {
    fn as_str(&self) -> &'static str {
        match self {
            Self::Idle    => "idle",
            Self::Playing => "playing",
            Self::Paused  => "paused",
            Self::Stopped => "stopped",
            Self::Ended   => "ended",
            Self::Error   => "error",
        }
    }

    fn is_terminal(&self) -> bool {
        matches!(self, Self::Stopped | Self::Ended)
    }
}

#[derive(Debug, Clone, Deserialize)]
struct NativePlayerSeekRequest {
    position_ms: i64,
}

#[derive(Debug, Clone, Deserialize)]
struct NativePlayerVolumeRequest {
    volume: i32,
}

#[derive(Debug, Clone, Serialize)]
struct NativePlayerCommandResponse {
    ok:      bool,
    state:   String,
    message: String,
}

#[derive(Debug, Clone, Serialize)]
struct NativePlayerStatusResponse {
    available:   bool,
    state:       String,
    playing:     bool,
    source:      Option<String>,
    title:       Option<String>,
    media_kind:  Option<String>,
    session_id:  Option<String>,
    position_ms: i64,
    duration_ms: i64,
    volume:      i32,
    updated_at_ms: u64,
}

#[derive(Debug, Clone, Default)]
struct NativePlayerSnapshot {
    state:       NativePlaybackState,
    source:      Option<String>,
    title:       Option<String>,
    media_kind:  Option<String>,
    session_id:  Option<String>,
    position_ms: i64,
    duration_ms: i64,
    volume:      i32,
    updated_at_ms: u64,
}

fn snapshot_to_status(s: &NativePlayerSnapshot) -> NativePlayerStatusResponse {
    NativePlayerStatusResponse {
        available:   true,
        state:       s.state.as_str().to_string(),
        playing:     matches!(s.state, NativePlaybackState::Playing),
        source:      s.source.clone(),
        title:       s.title.clone(),
        media_kind:  s.media_kind.clone(),
        session_id:  s.session_id.clone(),
        position_ms: s.position_ms,
        duration_ms: s.duration_ms,
        volume:      s.volume,
        updated_at_ms: s.updated_at_ms,
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
struct PendingPlayback {
    source:          String,
    session_id:      Option<String>,
    title:           Option<String>,
    media_kind:      Option<String>,
    tmdb_id:         Option<String>,
    trakt_id:        Option<String>,
    year:            Option<i32>,
    season:          Option<i32>,
    episode:         Option<i32>,
    /// Resume position as a percentage (0–100). Passed as `start=<pct>%` in the loadfile command.
    resume_percent: Option<f64>,
}

// ---------------------------------------------------------------------------
// mpv IPC event struct
// ---------------------------------------------------------------------------

#[derive(Debug, Deserialize)]
struct MpvEvent {
    event:  Option<String>,
    #[allow(dead_code)]
    id:     Option<u64>,
    name:   Option<String>,
    data:   Option<JsonValue>,
    reason: Option<String>,
    error:  Option<String>,
}

// ---------------------------------------------------------------------------
// Player core
// ---------------------------------------------------------------------------

struct NativePlayerCore {
    snapshot:         NativePlayerSnapshot,
    mpv_process:      Option<std::process::Child>,
    ipc_path:         Option<String>,
    ipc_writer:       Option<Arc<Mutex<UnixStream>>>,
    /// Mirrors mpv's `idle-active` property.  True when no file is loaded.
    /// Used to prevent the initial `pause=false` subscription response (which arrives
    /// while mpv is idle) from spuriously setting state to Playing.
    idle_active:      bool,
    /// Mirrors mpv's `pause` property value (independent of snapshot.state).
    /// Used by the `idle-active` handler to know what state to enter when a file starts.
    currently_paused: bool,
    /// Fallback seek target (0–100) sent as `seek <pct> absolute-percent exact` once
    /// `idle-active=false` fires, in case mpv ignored the per-file `start=<pct>%` option.
    pending_seek_percent: Option<f64>,
}

impl NativePlayerCore {
    fn new() -> Self {
        Self {
            snapshot: NativePlayerSnapshot {
                volume: 100,
                updated_at_ms: now_ms(),
                ..Default::default()
            },
            mpv_process:      None,
            ipc_path:         None,
            ipc_writer:       None,
            idle_active:          true,   // mpv starts in idle (no file loaded)
            currently_paused:     false,
            pending_seek_percent: None,
        }
    }
}

struct AppState {
    player:          Mutex<NativePlayerCore>,
    reader_stop:     Mutex<Option<Arc<AtomicBool>>>,
    pending_playback: Mutex<Option<PendingPlayback>>,
}

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_or(0, |d| d.as_millis() as u64)
}

fn command_response(
    state: &NativePlaybackState,
    message: impl Into<String>,
) -> NativePlayerCommandResponse {
    NativePlayerCommandResponse {
        ok:      true,
        state:   state.as_str().to_string(),
        message: message.into(),
    }
}

fn stop_reader_thread(app_state: &AppState) {
    if let Ok(mut guard) = app_state.reader_stop.lock() {
        if let Some(stop) = guard.take() {
            stop.store(true, Ordering::Relaxed);
        }
    }
}

// ---------------------------------------------------------------------------
// Binary / resource resolution
// ---------------------------------------------------------------------------

fn find_mpv_binary() -> PathBuf {
    let exe_dir = std::env::current_exe()
        .expect("cannot resolve current exe")
        .parent()
        .expect("exe has no parent dir")
        .to_path_buf();

    // 1. Production bundle: Contents/MacOS/mpv
    let bundled = exe_dir.join("mpv");
    if bundled.exists() {
        return bundled;
    }

    // 2. Dev build: src-tauri/bin/mpv-aarch64-apple-darwin (next to the exe output dir)
    let dev = exe_dir.join("mpv-aarch64-apple-darwin");
    if dev.exists() {
        return dev;
    }

    // 3. Also check the explicit bin/ directory relative to the manifest
    // This covers `cargo tauri dev` where exe is deep in target/
    if let Ok(manifest) = std::env::var("CARGO_MANIFEST_DIR") {
        let from_manifest = PathBuf::from(manifest)
            .join("bin")
            .join("mpv-aarch64-apple-darwin");
        if from_manifest.exists() {
            return from_manifest;
        }
    }

    panic!(
        "mpv binary not found. Run: python3 scripts/prepare_tauri_mpv_sidecar.py\n\
         Searched:\n  {}\n  {}",
        bundled.display(),
        dev.display()
    );
}

// Walk up from target/debug/ (or Contents/MacOS/) to find the src-tauri root.
// Works for: target/debug/mpv → parent×2 = src-tauri/
fn find_src_tauri_root(mpv_bin: &Path) -> Option<PathBuf> {
    let src_tauri = mpv_bin.parent()?.parent()?.parent()?;
    if src_tauri.join("bin").exists() { Some(src_tauri.to_path_buf()) } else { None }
}

fn find_lib_dir(mpv_bin: &Path) -> Option<PathBuf> {
    let bin_dir = mpv_bin.parent()?;

    // Production (same dir as mpv binary): @executable_path/macos-arm64/lib
    let direct = bin_dir.join("macos-arm64/lib");
    if direct.exists() { return Some(direct); }

    // Production bundle: Contents/MacOS/../Resources/bin/macos-arm64/lib
    let bundle = bin_dir.join("../Resources/bin/macos-arm64/lib");
    if bundle.exists() { return bundle.canonicalize().ok(); }

    // Dev: target/debug/mpv → src-tauri/bin/macos-arm64/lib
    if let Some(src_tauri) = find_src_tauri_root(mpv_bin) {
        let dev = src_tauri.join("bin/macos-arm64/lib");
        if dev.exists() { return Some(dev); }
    }

    None
}

// Returns the path to the mpv-config directory that contains:
//   scripts/uosc.lua
//   scripts/uosc_shared/...
// Passing --config-dir=<this_path> to mpv makes mp.find_config_file('scripts')
// return <this_path>/scripts/, which is exactly what uosc.lua needs on line 13
// to build its package.path for requiring uosc_shared modules.
fn find_mpv_config_dir(app: &tauri::AppHandle, mpv_bin: &Path) -> Option<PathBuf> {
    // Production: Tauri bundles resources/ under the app's resource_dir.
    if let Ok(resource_dir) = app.path().resource_dir() {
        let p = resource_dir.join("mpv-config");
        if p.join("scripts/uosc.lua").exists() { return Some(p); }
    }

    // Dev: src-tauri/resources/mpv-config/
    if let Some(src_tauri) = find_src_tauri_root(mpv_bin) {
        let p = src_tauri.join("resources/mpv-config");
        if p.join("scripts/uosc.lua").exists() { return Some(p); }
    }

    None
}

// Resolve the MoltenVK ICD JSON so the Vulkan loader can find libMoltenVK.
fn find_moltenvk_icd(mpv_bin: &Path) -> Option<PathBuf> {
    let bin_dir = mpv_bin.parent()?;

    // Production (same dir as mpv binary): @executable_path/macos-arm64/lib
    let direct = bin_dir.join("macos-arm64/lib/MoltenVK_icd.json");
    if direct.exists() { return Some(direct); }

    // Production bundle: Contents/MacOS/../Resources/bin/macos-arm64/lib
    let bundle = bin_dir.join("../Resources/bin/macos-arm64/lib/MoltenVK_icd.json");
    if bundle.exists() { return bundle.canonicalize().ok(); }

    // Dev: target/debug/mpv → src-tauri/bin/macos-arm64/lib
    if let Some(src_tauri) = find_src_tauri_root(mpv_bin) {
        let dev = src_tauri.join("bin/macos-arm64/lib/MoltenVK_icd.json");
        if dev.exists() { return Some(dev); }
    }

    None
}

// ---------------------------------------------------------------------------
// IPC helpers
// ---------------------------------------------------------------------------

fn connect_ipc(socket_path: &str) -> Result<UnixStream, String> {
    let deadline = Instant::now() + Duration::from_secs(10);
    let start = Instant::now();

    loop {
        match UnixStream::connect(socket_path) {
            Ok(stream) => {
                eprintln!("[mpv] IPC connected after {:.1}s", start.elapsed().as_secs_f64());
                return Ok(stream);
            }
            Err(_) if Instant::now() < deadline => {
                std::thread::sleep(Duration::from_millis(50));
            }
            Err(e) => {
                return Err(format!(
                    "IPC connect timeout after {:.1}s: {e}",
                    start.elapsed().as_secs_f64()
                ));
            }
        }
    }
}

fn send_ipc(writer: &Arc<Mutex<UnixStream>>, json: &str) {
    if let Ok(mut stream) = writer.lock() {
        let _ = stream.write_all(json.as_bytes());
        let _ = stream.write_all(b"\n");
        let _ = stream.flush();
    }
}

// ---------------------------------------------------------------------------
// IPC reader thread
// ---------------------------------------------------------------------------

fn start_ipc_reader(
    socket_path: String,
    app: tauri::AppHandle,
    stop: Arc<AtomicBool>,
) {
    std::thread::spawn(move || {
        let stream = match connect_ipc(&socket_path) {
            Ok(s) => s,
            Err(e) => {
                eprintln!("[mpv] IPC connect failed: {e}");
                return;
            }
        };
        eprintln!("[mpv] IPC connected to {socket_path}");

        // Clone stream for writing — store in app_state for command sends
        let writer = match stream.try_clone() {
            Ok(w) => Arc::new(Mutex::new(w)),
            Err(e) => {
                eprintln!("[mpv] IPC stream clone failed: {e}");
                return;
            }
        };

        // Store writer in NativePlayerCore
        {
            let state: tauri::State<AppState> = app.state();
            if let Ok(mut core) = state.player.lock() {
                core.ipc_writer = Some(writer.clone());
            };
        }

        // Subscribe to all properties we care about
        let subscriptions = [
            r#"{"command":["observe_property",1,"time-pos"]}"#,
            r#"{"command":["observe_property",2,"duration"]}"#,
            r#"{"command":["observe_property",3,"pause"]}"#,
            r#"{"command":["observe_property",4,"eof-reached"]}"#,
            r#"{"command":["observe_property",5,"idle-active"]}"#,
            r#"{"command":["observe_property",6,"volume"]}"#,
            r#"{"command":["observe_property",7,"fullscreen"]}"#,
            r#"{"command":["observe_property",8,"user-data/warp/action"]}"#,
        ];
        for cmd in &subscriptions {
            send_ipc(&writer, cmd);
        }

        // Start playback for the pending source.
        // The IPC reader is the sole loadfile sender.
        {
            let app_state: tauri::State<AppState> = app.state();
            let pending = app_state.pending_playback.lock().ok()
                .and_then(|g| g.as_ref().map(|pb| (pb.source.clone(), pb.resume_percent)));
            if let Some((src, resume_pct)) = pending {
                let cmd = match resume_pct {
                    Some(pct) if pct > 0.0 => {
                        eprintln!("[mpv] sent loadfile with start={:.0}%", pct);
                        serde_json::json!({"command": ["loadfile", src, "replace", 0, format!("start={:.0}%", pct)]}).to_string()
                    }
                    _ => {
                        eprintln!("[mpv] sent loadfile");
                        serde_json::json!({"command": ["loadfile", src, "replace"]}).to_string()
                    }
                };
                send_ipc(&writer, &cmd);
            } else {
                eprintln!("[mpv] no pending playback — mpv idle");
            }
        }

        let reader = BufReader::new(stream);
        for line in reader.lines() {
            if stop.load(Ordering::Relaxed) {
                eprintln!("[mpv] IPC reader: stop requested");
                break;
            }

            let line = match line {
                Ok(l) if !l.is_empty() => l,
                Ok(_) => continue,
                Err(_) => break,
            };

            let event: MpvEvent = match serde_json::from_str(&line) {
                Ok(e) => e,
                Err(_) => continue,
            };

            // Only handle property-change and end-file events
            let event_name = event.event.as_deref().unwrap_or("");
            if event_name != "property-change" && event_name != "end-file" {
                continue;
            }

            if event_name == "end-file" {
                let reason = event.reason.as_deref().unwrap_or("unknown");
                eprintln!("[mpv] end-file reason={reason}");

                // When mpv quits (uosc × button, keyboard q, or window close),
                // run teardown so state is reset and the zombie process is reaped.
                if reason == "quit" {
                    let app_clone = app.clone();
                    std::thread::spawn(move || {
                        let state: tauri::State<AppState> = app_clone.state();
                        let _ = teardown_player(&app_clone, &state);
                    });
                    break;
                }

                // A file failed to load (unrecognised format, network error, etc.).
                // Emit Error state so React can reset its scrobble refs, but keep
                // the IPC reader alive — mpv recovers by emitting idle-active=true.
                if reason == "error" {
                    let app_state: tauri::State<AppState> = app.state();
                    if let Ok(mut core) = app_state.player.lock() {
                        core.snapshot.state = NativePlaybackState::Error;
                        core.snapshot.updated_at_ms = now_ms();
                        let payload = snapshot_to_status(&core.snapshot);
                        let _ = app.emit(PLAYER_STATUS_EVENT, &payload);
                    }
                    continue;  // do NOT break — mpv sends idle-active=true next
                }

                let app_state: tauri::State<AppState> = app.state();
                if let Ok(mut core) = app_state.player.lock() {
                    core.snapshot.state = if reason == "stop" {
                        NativePlaybackState::Stopped
                    } else {
                        NativePlaybackState::Ended
                    };
                    core.snapshot.updated_at_ms = now_ms();
                    let payload = snapshot_to_status(&core.snapshot);
                    let _ = app.emit(PLAYER_STATUS_EVENT, &payload);
                }
                break;
            }

            // property-change
            let prop_name = event.name.as_deref().unwrap_or("");
            let data = &event.data;

            if let Some(err) = &event.error {
                if err != "success" {
                    continue;
                }
            }

            match prop_name {
                "time-pos" => {
                    if let Some(pos) = data.as_ref().and_then(|v| v.as_f64()) {
                        let app_state: tauri::State<AppState> = app.state();
                        if let Ok(mut core) = app_state.player.lock() {
                            core.snapshot.position_ms = (pos * 1000.0).round() as i64;
                            core.snapshot.updated_at_ms = now_ms();
                        };
                    }
                }

                "duration" => {
                    if let Some(dur) = data.as_ref().and_then(|v| v.as_f64()) {
                        let app_state: tauri::State<AppState> = app.state();
                        if let Ok(mut core) = app_state.player.lock() {
                            core.snapshot.duration_ms = (dur * 1000.0).round() as i64;
                            core.snapshot.updated_at_ms = now_ms();
                        };
                    }
                }

                "volume" => {
                    if let Some(vol) = data.as_ref().and_then(|v| v.as_f64()) {
                        let app_state: tauri::State<AppState> = app.state();
                        if let Ok(mut core) = app_state.player.lock() {
                            core.snapshot.volume = (vol.round() as i32).clamp(0, 100);
                            core.snapshot.updated_at_ms = now_ms();
                        };
                    }
                }

                "pause" => {
                    let paused = data.as_ref().and_then(|v| v.as_bool()).unwrap_or(false);
                    let app_state: tauri::State<AppState> = app.state();
                    if let Ok(mut core) = app_state.player.lock() {
                        // Always track the raw pause value so idle-active=false can
                        // use it to determine the initial Playing vs Paused state.
                        core.currently_paused = paused;

                        // Only update snapshot.state if a file is actually loaded.
                        // When mpv starts up it immediately sends pause=false while
                        // still idle; that spurious event must NOT transition state
                        // to Playing (which would fire a premature scrobbleStart).
                        if !core.snapshot.state.is_terminal() && !core.idle_active {
                            core.snapshot.state = if paused {
                                NativePlaybackState::Paused
                            } else {
                                NativePlaybackState::Playing
                            };
                            core.snapshot.updated_at_ms = now_ms();
                        }
                    };
                }

                "eof-reached" => {
                    let reached = data.as_ref().and_then(|v| v.as_bool()).unwrap_or(false);
                    if reached {
                        let app_state: tauri::State<AppState> = app.state();
                        if let Ok(mut core) = app_state.player.lock() {
                            core.snapshot.state = NativePlaybackState::Ended;
                            core.snapshot.updated_at_ms = now_ms();
                            let payload = snapshot_to_status(&core.snapshot);
                            let _ = app.emit(PLAYER_STATUS_EVENT, &payload);
                        }
                        break;
                    }
                }

                "idle-active" => {
                    let idle = data.as_ref().and_then(|v| v.as_bool()).unwrap_or(false);
                    let app_state: tauri::State<AppState> = app.state();
                    if let Ok(mut core) = app_state.player.lock() {
                        core.idle_active = idle;
                        if !core.snapshot.state.is_terminal() {
                            if idle {
                                // File stopped / not loaded — return to idle state.
                                core.snapshot.state = NativePlaybackState::Idle;
                            } else {
                                // File just started loading.  Transition to Playing or
                                // Paused based on the last known pause property value.
                                // This is the *authoritative* trigger for scrobbleStart —
                                // not the pause=false event which fires even while idle.
                                core.snapshot.state = if core.currently_paused {
                                    NativePlaybackState::Paused
                                } else {
                                    NativePlaybackState::Playing
                                };

                                // Seek to the resume position once the file starts loading.
                                // Flags must be a single combined string (mpv IPC requirement).
                                if let Some(pct) = core.pending_seek_percent.take() {
                                    if let Some(ref w) = core.ipc_writer {
                                        let cmd = serde_json::json!({
                                            "command": ["seek", pct, "absolute-percent+exact"]
                                        });
                                        send_ipc(w, &cmd.to_string());
                                        eprintln!("[mpv] resume seek to {:.3}% (absolute-percent+exact)", pct);
                                    }
                                }
                            }
                            core.snapshot.updated_at_ms = now_ms();
                        }
                    };
                }

                "fullscreen" => {
                    // mpv handles fullscreen natively — no overlay to manage.
                    // Just log for diagnostics.
                    let fs = data.as_ref().and_then(|v| v.as_bool()).unwrap_or(false);
                    eprintln!("[mpv] fullscreen={fs}");
                }

                "user-data/warp/action" => {
                    let action = data
                        .as_ref()
                        .and_then(|v| v.as_str())
                        .unwrap_or("")
                        .to_string();
                    if action.is_empty() {
                        continue;
                    }
                    eprintln!("[mpv] warp/action={action}");
                    match action.as_str() {
                        "close" => {
                            // Lua OSC requested close — perform teardown
                            let app_clone = app.clone();
                            std::thread::spawn(move || {
                                let state: tauri::State<AppState> = app_clone.state();
                                let _ = teardown_player(&app_clone, &state);
                            });
                            break;
                        }
                        "subtitle-manager" => {
                            let _ = app.emit("warp-subtitle-manager-open", ());
                        }
                        _ => {}
                    }
                }

                _ => {}
            }

            // Emit status update after every property change
            let app_state: tauri::State<AppState> = app.state();
            if let Ok(core) = app_state.player.lock() {
                let payload = snapshot_to_status(&core.snapshot);
                let _ = app.emit(PLAYER_STATUS_EVENT, &payload);
            };
        }

        eprintln!("[mpv] IPC reader thread exiting");
    });
}

// ---------------------------------------------------------------------------
// Teardown
// ---------------------------------------------------------------------------

fn teardown_player(
    app: &tauri::AppHandle,
    app_state: &tauri::State<AppState>,
) -> Result<(), String> {
    stop_reader_thread(app_state);

    // Send quit to mpv (best-effort — mpv may already be gone)
    {
        let core = app_state.player.lock().map_err(|_| "lock poisoned")?;
        if let Some(ref writer) = core.ipc_writer {
            send_ipc(writer, r#"{"command":["quit"]}"#);
        }
    }

    // mpv manages its own window — no NSWindow manipulation needed.
    // Just wait for the process to exit (or kill it), then clean up.

    // Wait for process (up to 3 s), then SIGKILL
    {
        let mut core = app_state.player.lock().map_err(|_| "lock poisoned")?;
        if let Some(mut child) = core.mpv_process.take() {
            let deadline = Instant::now() + Duration::from_secs(3);
            loop {
                match child.try_wait() {
                    Ok(Some(_)) => break,
                    Ok(None) if Instant::now() < deadline => {
                        std::thread::sleep(Duration::from_millis(100));
                    }
                    _ => {
                        let _ = child.kill();
                        let _ = child.wait();
                        break;
                    }
                }
            }
        }

        // Clean up socket file
        if let Some(path) = core.ipc_path.take() {
            let _ = std::fs::remove_file(&path);
        }

        core.ipc_writer             = None;
        core.idle_active            = true;
        core.currently_paused       = false;
        core.pending_seek_percent   = None;
        core.snapshot.state         = NativePlaybackState::Stopped;
        core.snapshot.updated_at_ms = now_ms();
    }

    // Emit the final Stopped status so the React scrobble hook fires scrobbleStop
    // with the last known playback position.  Without this emit the hook never
    // receives the terminal state when the player is closed via teardown.
    {
        if let Ok(core) = app_state.player.lock() {
            let payload = snapshot_to_status(&core.snapshot);
            let _ = app.emit(PLAYER_STATUS_EVENT, &payload);
        }
    }

    eprintln!("[mpv] teardown complete");
    Ok(())
}

// ---------------------------------------------------------------------------
// Tauri commands
// ---------------------------------------------------------------------------

#[tauri::command]
fn ping() -> String {
    "pong".to_string()
}

#[tauri::command]
fn app_info() -> AppInfo {
    AppInfo {
        tauri: true,
        os:   std::env::consts::OS.to_string(),
        arch: std::env::consts::ARCH.to_string(),
    }
}

#[tauri::command]
fn player_open_window(
    app: tauri::AppHandle,
    app_state: tauri::State<'_, AppState>,
    playback: PendingPlayback,
) -> Result<(), String> {
    eprintln!(
        "[mpv] player_open_window: source='{}' title={:?}",
        playback.source, playback.title
    );

    let resume_pct   = playback.resume_percent.filter(|&p| p > 0.0);
    let pb_source    = playback.source.clone();
    let pb_title     = playback.title.clone();
    let pb_media_kind = playback.media_kind.clone();
    let pb_session_id = playback.session_id.clone();
    if let Ok(mut guard) = app_state.pending_playback.lock() {
        *guard = Some(playback);
    }

    // Tear down any existing player first
    teardown_player(&app, &app_state).ok();

    // Resolve binary path
    let mpv_bin = find_mpv_binary();
    eprintln!("[mpv] binary={}", mpv_bin.display());

    // Use std::env::temp_dir() — on macOS TMPDIR=/var/folders/…/T/ while /tmp=/private/tmp
    let socket_path = std::env::temp_dir()
        .join(format!("warp-mpv-{}.sock", uuid_simple()))
        .to_string_lossy()
        .into_owned();
    eprintln!("[mpv] IPC socket={socket_path}");

    let mut cmd = std::process::Command::new(&mpv_bin);
    cmd.arg(format!("--input-ipc-server={socket_path}"));
    cmd.args([
        // --config-dir is set below; do NOT pass --no-config or --load-scripts=no
        // so that mp.find_config_file('scripts') works inside uosc.lua.
        "--osc=no",          // disable mpv's built-in OSC (uosc replaces it)
        "--border=no",       // borderless window
        "--keep-open=yes",
        "--idle=yes",
        // Hardware video decoding via VideoToolbox (macOS)
        "--hwdec=auto",
        // Disable the built-in youtube-dl/yt-dlp hook — we don't bundle yt-dlp and
        // the hook produces noisy "youtube-dl failed: not found" errors for any URL
        // that mpv doesn't recognise as a local file or plain HTTP stream.
        "--ytdl=no",
        // Vulkan rendering via bundled MoltenVK (VK_ICD_FILENAMES set below)
        "--vo=gpu",
        "--gpu-api=vulkan",
        "--log-file=/tmp/mpv_warp.log",
        "--msg-level=all=warn,stream=info,demux=info,vo=info",
    ]);

    // Point mpv at our bundled config directory so mp.find_config_file('scripts')
    // returns <config-dir>/scripts/ — the path uosc.lua uses to build package.path.
    // uosc.lua and uosc_shared/ live inside that scripts/ folder and auto-load.
    // This replaces --no-config without exposing the user's ~/.config/mpv settings.
    if let Some(config_dir) = find_mpv_config_dir(&app, &mpv_bin) {
        cmd.arg(format!("--config-dir={}", config_dir.display()));
        eprintln!("[mpv] config-dir={}", config_dir.display());
    } else {
        // Fallback: no uosc, fully isolated config
        cmd.args(["--no-config", "--load-scripts=no"]);
        eprintln!("[mpv] WARNING: mpv-config dir not found — running without OSC");
    }

    // Set DYLD_LIBRARY_PATH so dyld finds bundled dylibs in both dev and production.
    if let Some(lib_dir) = find_lib_dir(&mpv_bin) {
        cmd.env("DYLD_LIBRARY_PATH", &lib_dir);
        eprintln!("[mpv] DYLD_LIBRARY_PATH={}", lib_dir.display());
    } else {
        eprintln!("[mpv] WARNING: dylib dir not found — mpv may fail to load");
    }

    // Point the Vulkan loader at the bundled MoltenVK ICD JSON.
    if let Some(icd) = find_moltenvk_icd(&mpv_bin) {
        cmd.env("VK_ICD_FILENAMES", &icd);
        eprintln!("[mpv] VK_ICD_FILENAMES={}", icd.display());
    } else {
        eprintln!("[mpv] MoltenVK_icd.json not found — Vulkan may be unavailable");
    }

    let child = cmd.spawn().map_err(|e| format!("mpv spawn failed: {e}"))?;
    eprintln!("[mpv] spawned pid={}", child.id());

    {
        let mut core = app_state.player.lock().map_err(|_| "lock poisoned")?;
        core.mpv_process          = Some(child);
        core.ipc_path             = Some(socket_path.clone());
        core.idle_active          = true;   // fresh mpv starts idle
        core.currently_paused     = false;
        // Store resume percent for fallback seek when idle-active=false fires.
        core.pending_seek_percent = resume_pct;
        // teardown_player (called above) leaves snapshot.state = Stopped.
        // is_terminal() returns true for Stopped, which blocks every state
        // transition inside the IPC reader (idle-active, pause handlers).
        // Reset to Idle here so the first idle-active=false event can set
        // state = Playing and trigger scrobbleStart in React.
        core.snapshot.state       = NativePlaybackState::Idle;
        core.snapshot.position_ms = 0;
        core.snapshot.duration_ms = 0;
        core.snapshot.updated_at_ms = now_ms();
        // Pre-populate metadata so scrobble hooks have context immediately.
        core.snapshot.source     = Some(pb_source);
        core.snapshot.title      = pb_title;
        core.snapshot.media_kind = pb_media_kind;
        core.snapshot.session_id = pb_session_id;
    }

    // Start IPC reader thread (connects to socket with retry, subscribes to properties)
    let stop = Arc::new(AtomicBool::new(false));
    if let Ok(mut guard) = app_state.reader_stop.lock() {
        *guard = Some(stop.clone());
    }
    start_ipc_reader(socket_path, app.clone(), stop);

    Ok(())
}

#[tauri::command]
fn player_pause(
    app_state: tauri::State<'_, AppState>,
) -> Result<NativePlayerCommandResponse, String> {
    let writer = {
        let mut core = app_state.player.lock().map_err(|_| "lock poisoned")?;
        core.snapshot.state = NativePlaybackState::Paused;
        core.snapshot.updated_at_ms = now_ms();
        core.ipc_writer.clone()
    };
    if let Some(w) = writer {
        send_ipc(&w, r#"{"command":["set_property","pause",true]}"#);
    }
    let core = app_state.player.lock().map_err(|_| "lock poisoned")?;
    Ok(command_response(&core.snapshot.state, "paused"))
}

#[tauri::command]
fn player_resume(
    app_state: tauri::State<'_, AppState>,
) -> Result<NativePlayerCommandResponse, String> {
    let writer = {
        let mut core = app_state.player.lock().map_err(|_| "lock poisoned")?;
        core.snapshot.state = NativePlaybackState::Playing;
        core.snapshot.updated_at_ms = now_ms();
        core.ipc_writer.clone()
    };
    if let Some(w) = writer {
        send_ipc(&w, r#"{"command":["set_property","pause",false]}"#);
    }
    let core = app_state.player.lock().map_err(|_| "lock poisoned")?;
    Ok(command_response(&core.snapshot.state, "resumed"))
}

#[tauri::command]
fn player_stop(
    app_state: tauri::State<'_, AppState>,
) -> Result<NativePlayerCommandResponse, String> {
    let writer = {
        let mut core = app_state.player.lock().map_err(|_| "lock poisoned")?;
        core.snapshot.state = NativePlaybackState::Stopped;
        core.snapshot.updated_at_ms = now_ms();
        core.ipc_writer.clone()
    };
    if let Some(w) = writer {
        // "stop" returns mpv to idle without quitting
        send_ipc(&w, r#"{"command":["stop"]}"#);
    }
    let core = app_state.player.lock().map_err(|_| "lock poisoned")?;
    Ok(command_response(&core.snapshot.state, "stopped"))
}

#[tauri::command]
fn player_seek(
    app_state: tauri::State<'_, AppState>,
    request: NativePlayerSeekRequest,
) -> Result<NativePlayerCommandResponse, String> {
    let position_ms = request.position_ms.max(0);
    let seconds = format!("{:.3}", (position_ms as f64) / 1000.0);

    let writer = {
        let mut core = app_state.player.lock().map_err(|_| "lock poisoned")?;
        core.snapshot.position_ms = position_ms;
        core.snapshot.updated_at_ms = now_ms();
        core.ipc_writer.clone()
    };
    if let Some(w) = writer {
        let cmd = serde_json::json!({"command": ["seek", seconds, "absolute"]});
        send_ipc(&w, &cmd.to_string());
    }
    let core = app_state.player.lock().map_err(|_| "lock poisoned")?;
    Ok(command_response(&core.snapshot.state, format!("seeked to {position_ms}ms")))
}

#[tauri::command]
fn player_set_volume(
    app_state: tauri::State<'_, AppState>,
    request: NativePlayerVolumeRequest,
) -> Result<NativePlayerCommandResponse, String> {
    let volume = request.volume.clamp(0, 100);

    let writer = {
        let mut core = app_state.player.lock().map_err(|_| "lock poisoned")?;
        core.snapshot.volume = volume;
        core.snapshot.updated_at_ms = now_ms();
        core.ipc_writer.clone()
    };
    if let Some(w) = writer {
        let cmd = serde_json::json!({"command": ["set_property", "volume", volume]});
        send_ipc(&w, &cmd.to_string());
    }
    let core = app_state.player.lock().map_err(|_| "lock poisoned")?;
    Ok(command_response(&core.snapshot.state, format!("volume={volume}")))
}

#[tauri::command]
fn player_set_fullscreen(
    app_state: tauri::State<'_, AppState>,
    fullscreen: bool,
) -> Result<(), String> {
    let writer = {
        let core = app_state.player.lock().map_err(|_| "lock poisoned")?;
        core.ipc_writer.clone()
    };
    if let Some(w) = writer {
        let cmd = serde_json::json!({"command": ["set_property", "fullscreen", fullscreen]});
        send_ipc(&w, &cmd.to_string());
    }
    Ok(())
}

#[tauri::command]
fn player_load_subtitle(
    app_state: tauri::State<'_, AppState>,
    path: String,
) -> Result<(), String> {
    let writer = {
        let core = app_state.player.lock().map_err(|_| "lock poisoned")?;
        core.ipc_writer.clone()
    };
    if let Some(w) = writer {
        let cmd = serde_json::json!({"command": ["sub-add", path, "select"]});
        send_ipc(&w, &cmd.to_string());
    }
    Ok(())
}

#[tauri::command]
fn player_get_pending_playback(
    app_state: tauri::State<'_, AppState>,
) -> Option<PendingPlayback> {
    let guard = app_state.pending_playback.lock().ok()?;
    if let Some(ref p) = *guard {
        eprintln!(
            "[mpv] player_get_pending_playback: source='{}' title={:?}",
            p.source, p.title
        );
    }
    guard.clone()
}

#[tauri::command]
fn player_close_window(
    app: tauri::AppHandle,
    app_state: tauri::State<'_, AppState>,
) -> Result<(), String> {
    teardown_player(&app, &app_state)
}

// ---------------------------------------------------------------------------
// UUID helper (no external crate)
// ---------------------------------------------------------------------------

fn uuid_simple() -> String {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};
    let mut h = DefaultHasher::new();
    now_ms().hash(&mut h);
    std::thread::current().id().hash(&mut h);
    format!("{:016x}", h.finish())
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

fn main() {
    tauri::Builder::default()
        .manage(AppState {
            player:           Mutex::new(NativePlayerCore::new()),
            reader_stop:      Mutex::new(None),
            pending_playback: Mutex::new(None),
        })
        .setup(|_app| {
            // macOS security-scans newly-built binaries AND dylibs on first use.
            // Pre-warm at app launch with the same env vars used at play-time so that
            // all dylibs are cached before the user clicks play.
            let mpv_bin = find_mpv_binary();
            let lib_dir = find_lib_dir(&mpv_bin);
            let icd = find_moltenvk_icd(&mpv_bin);
            std::thread::spawn(move || {
                eprintln!("[mpv] pre-warming binary and dylibs (macOS first-run security scan)...");
                let mut cmd = std::process::Command::new(&mpv_bin);
                cmd.arg("--version")
                    .stdout(std::process::Stdio::null())
                    .stderr(std::process::Stdio::null());
                if let Some(dir) = lib_dir {
                    cmd.env("DYLD_LIBRARY_PATH", &dir);
                    eprintln!("[mpv] pre-warm DYLD_LIBRARY_PATH={}", dir.display());
                }
                if let Some(icd_path) = icd {
                    cmd.env("VK_ICD_FILENAMES", &icd_path);
                }
                let _ = cmd.status();
                eprintln!("[mpv] pre-warm complete");
            });
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            ping,
            app_info,
            player_open_window,
            player_pause,
            player_resume,
            player_stop,
            player_seek,
            player_set_volume,
            player_set_fullscreen,
            player_load_subtitle,
            player_get_pending_playback,
            player_close_window,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
