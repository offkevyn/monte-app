import 'package:flutter_test/flutter_test.dart';
import 'package:monte/app/session_expiry_handler.dart';
import 'package:monte/core/session/session_expiry.dart';
import 'package:monte/features/auth/domain/entities/cpf.dart';
import 'package:monte/features/auth/domain/usecases/auth_usecases.dart';
import 'package:monte/features/auth/presentation/current_session.dart';

import '../features/auth/domain/auth_domain_test.dart';

void main() {
  late SessionExpiry expiry;
  late FakeAuthRepository auth;
  late FakeUserData data;
  late CurrentSession session;
  late List<Cpf?> logins;
  late SessionExpiryHandler handler;

  setUp(() {
    expiry = SessionExpiry();
    auth = FakeAuthRepository()..stored = sessionFor();
    data = FakeUserData();
    session = CurrentSession()..start(sessionFor());
    logins = [];
    handler = SessionExpiryHandler(
      expiry: expiry,
      signOut: SignOut(auth, userData: [data]),
      session: session,
      goToLogin: logins.add,
    )..start();
  });

  tearDown(() async {
    await handler.stop();
    await expiry.dispose();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a rejected session: full sign out, then the login', () async {
    expiry.report();
    await settle();
    expect(session.isSignedIn, isFalse);
    expect(auth.calls, ['signOut']);
    expect(data.clears, 1);
    expect(logins, [demoCpf]);
  });

  test('four 401s at once (the dashboard) sign out once', () async {
    expiry
      ..report()
      ..report()
      ..report()
      ..report();
    await settle();
    expect(auth.calls, ['signOut']);
    expect(logins, hasLength(1));
  });

  test('a late 401 after leaving does nothing', () async {
    session.end();
    expiry.report();
    await settle();
    expect(auth.calls, isEmpty);
    expect(logins, isEmpty);
  });

  test('after stop it no longer listens', () async {
    await handler.stop();
    expiry.report();
    await settle();
    expect(logins, isEmpty);
  });
}
