/// Data that belongs to the signed-in customer and must go when they leave:
/// signing out, a session that expired, a rejected token, another CPF
/// signing in on the same device.
abstract interface class UserData {
  Future<void> clear();
}
