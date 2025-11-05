import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final _usersCollection = FirebaseFirestore.instance.collection('users');

  /// Fetches user details from Firestore using their email.
  static Future<Map<String, dynamic>?> getUserDetails(String email) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(email).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        return null; // User does not exist
      }
    } catch (e) {
      print("Error fetching user details: ${e.toString()}");
      return null;
    }
  }

  /// Updates user details in Firestore.
  static Future<void> updateUserDetails(String email, Map<String, dynamic> updatedData) async {
    try {
      await _usersCollection.doc(email).update(updatedData);
      print("User details updated successfully.");
    } catch (e) {
      print("Error updating user details: ${e.toString()}");
    }
  }
}
