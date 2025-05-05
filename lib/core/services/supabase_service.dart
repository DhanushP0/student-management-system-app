import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await client.auth.signUp(email: email, password: password);
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> updateEmail(String newEmail) async {
    await client.auth.updateUser(UserAttributes(email: newEmail));
  }

  Future<void> updateProfile({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await client.from('profiles').update(data).eq('id', id);
  }

  Future<Map<String, dynamic>?> getProfile(String id) async {
    final response =
        await client.from('profiles').select().eq('id', id).single();
    return response;
  }

  Future<void> deleteProfile(String id) async {
    await client.from('profiles').delete().eq('id', id);
  }
}
