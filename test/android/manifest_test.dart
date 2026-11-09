import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Flutter only adds INTERNET to the debug and profile manifests. Without
  // it in the main one, the release build still runs (the simulated bank
  // lives in the app) but every CoinGecko call fails as "no connection".
  test('the release build may use the network', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android.permission.INTERNET'));
  });
}
