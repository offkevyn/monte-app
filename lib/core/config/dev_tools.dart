import 'package:flutter/services.dart';

/// Developer tools (the fake backend scenario picker) exist only in the dev
/// flavor (`flutter run`, or `--flavor dev`).
///
/// It is a compile-time constant: in the prod flavor every
/// `if (devToolsEnabled)` branch is removed by the compiler, so the picker
/// does not even ship in the production APK.
const bool devToolsEnabled = appFlavor == 'dev';
