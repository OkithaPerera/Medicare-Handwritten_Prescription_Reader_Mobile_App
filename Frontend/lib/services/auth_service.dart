import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static final _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Save email to SharedPreferences
  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userEmail', email);
    print("Email saved to SharedPreferences: $email");
  }

  // Retrieve email from SharedPreferences
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  // Clear email from SharedPreferences (e.g., on logout)
  static Future<void> clearUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail');
    print("User email removed from SharedPreferences.");
  }

  static Future<void> register(
    String email,
    String password,
    String confirmPassword,
    String birthdate, // New field
    String age, // Auto-calculated field
    String bloodGroup,
    String name,
    String address,
    String phone,
    BuildContext context,
  ) async {
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (email.isEmpty ||
        password.isEmpty ||
        birthdate.isEmpty ||
        age.isEmpty ||
        bloodGroup.isEmpty ||
        name.isEmpty ||
        address.isEmpty ||
        phone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    int? parsedAge = int.tryParse(age);
    if (parsedAge == null || parsedAge <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid age')));
      return;
    }

    String hashedPassword = sha256.convert(utf8.encode(password)).toString();

    try {
      await _usersCollection.doc(email).set({
        'email': email,
        'password': hashedPassword,
        'birthdate': birthdate, // Save birthdate
        'age': parsedAge, // Save calculated age
        'bloodGroup': bloodGroup,
        'name': name,
        'address': address,
        'phone': phone,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Registration Successful')));
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  static Future<void> login(
      String email, String password, BuildContext context) async {
    String hashedPassword = sha256.convert(utf8.encode(password)).toString();

    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(email).get();
      if (userDoc.exists) {
        String storedPassword = userDoc.get('password');
        if (hashedPassword == storedPassword) {
          // Save email to SharedPreferences after successful login
          await saveUserEmail(email);

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Login Successful')));
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Incorrect Password')));
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('User not found')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  static Future<bool> checkLoginStatus() async {
    // Check if email is stored in SharedPreferences to determine login status
    String? email = await getUserEmail();
    return email != null;
  }

  static Future<void> logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Remove the saved email
    await prefs.remove('userEmail');

    // Navigate to the login screen
    Navigator.pushReplacementNamed(context, '/login');
  }
}
