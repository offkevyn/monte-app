import 'package:url_launcher/url_launcher.dart';

/// Opens a web address outside the app, behind an interface so screens and
/// tests do not depend on the platform plugin.
abstract interface class LinkOpener {
  /// `false` when nothing on the device could open it; never throws.
  Future<bool> open(Uri uri);
}

final class ExternalLinkOpener implements LinkOpener {
  const ExternalLinkOpener();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
