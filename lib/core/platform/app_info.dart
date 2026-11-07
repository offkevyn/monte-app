import 'package:package_info_plus/package_info_plus.dart';

/// Facts about the installed build, behind an interface so screens and
/// tests do not depend on the platform plugin.
abstract interface class AppInfo {
  /// `1.0.0`, read from the build (the pubspec version); `null` when the
  /// platform cannot tell.
  Future<String?> version();
}

final class PackageAppInfo implements AppInfo {
  const PackageAppInfo();

  @override
  Future<String?> version() async {
    try {
      return (await PackageInfo.fromPlatform()).version;
    } on Exception {
      return null;
    }
  }
}
