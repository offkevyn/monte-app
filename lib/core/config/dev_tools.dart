/// Developer tools (the fake backend scenario picker) exist only in builds
/// made with `MONTE_DEV_TOOLS=true` (see `config/example.json`).
///
/// It is a compile-time constant: in a build without it, every
/// `if (devToolsEnabled)` branch is removed by the compiler, so the picker
/// does not even ship in the production APK.
const bool devToolsEnabled = bool.fromEnvironment('MONTE_DEV_TOOLS');
