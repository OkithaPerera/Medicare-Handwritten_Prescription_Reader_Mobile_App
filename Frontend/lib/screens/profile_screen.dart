import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medicare/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedBloodGroup;
  DateTime? _selectedBirthdate;

  final List<String> _bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final String? email = await getUserEmail();
      if (email == null) {
        throw Exception("No email found. User might not be logged in.");
      }

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(email).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _ageController.text = userData['age']?.toString() ?? '';
          _selectedBloodGroup = userData['bloodGroup'];
          _birthdateController.text = userData['birthdate'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User profile not found.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: $e")),
      );
    }
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  void _selectBirthdate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedBirthdate = pickedDate;
        _birthdateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  void _saveProfile() async {
    try {
      final String? email = await getUserEmail();
      if (email == null) {
        throw Exception("No email found. User might not be logged in.");
      }

      final userData = {
        'name': _nameController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
        'bloodGroup': _selectedBloodGroup,
        'birthdate': _birthdateController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
      };

      await UserService.updateUserDetails(email, userData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving profile: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Profile Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  enabled: false, // Email is not editable
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),

              // Birthdate Picker
              TextFormField(
                controller: _birthdateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Birthdate',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                onTap: () => _selectBirthdate(context),
              ),
              SizedBox(height: 20),

              // Blood Group Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                items: _bloodGroups.map((group) {
                  return DropdownMenuItem(value: group, child: Text(group));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBloodGroup = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Blood Group",
                  prefixIcon: Icon(Icons.bloodtype),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 40),

              // Save Profile Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                ),
                onPressed: _saveProfile,
                child: Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
