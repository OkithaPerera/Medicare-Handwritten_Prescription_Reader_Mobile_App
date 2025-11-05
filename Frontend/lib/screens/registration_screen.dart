import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController birthdateController = TextEditingController();
  final TextEditingController bloodGroupController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String? selectedBloodGroup;
  int? calculatedAge; // Store calculated age

  final List<String> bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-"
  ];

  Future<void> _selectBirthdate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        birthdateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
        calculatedAge = DateTime.now().year - pickedDate.year;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Logo & Title
          Padding(
            padding: const EdgeInsets.only(top: 30.0, bottom: 10.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 200,
                  ),
                ),
                Text('Welcome! Register Here..'),
                SizedBox(height: 10),
              ],
            ),
          ),

          // Scrollable Form Fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  CustomTextField(
                      controller: nameController,
                      hintText: 'Name',
                      icon: Icons.person),
                  SizedBox(height: 16.0),
                  CustomTextField(
                      controller: emailController,
                      hintText: 'Email',
                      icon: Icons.email),
                  SizedBox(height: 16.0),
                  CustomTextField(
                      controller: phoneController,
                      hintText: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone),
                  SizedBox(height: 16.0),
                  CustomTextField(
                      controller: addressController,
                      hintText: 'Address',
                      icon: Icons.home),
                  SizedBox(height: 16.0),
                  CustomTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      icon: Icons.lock,
                      obscureText: true),
                  SizedBox(height: 16.0),
                  CustomTextField(
                      controller: confirmPasswordController,
                      hintText: 'Confirm Password',
                      icon: Icons.lock,
                      obscureText: true),
                  SizedBox(height: 16.0),

                  // Birthdate Picker
                  TextFormField(
                    controller: birthdateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Birthdate',
                      prefixIcon: Icon(Icons.cake),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () => _selectBirthdate(context),
                  ),
                  SizedBox(height: 16.0),

                  // Display Auto-Filled Age
                  if (calculatedAge != null)
                    Text("Age: $calculatedAge years",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),

                  SizedBox(height: 16.0),

                  // Blood Group Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedBloodGroup,
                    items: bloodGroups.map((group) {
                      return DropdownMenuItem(value: group, child: Text(group));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedBloodGroup = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Blood Group",
                      prefixIcon: Icon(Icons.bloodtype),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 24.0),
                ],
              ),
            ),
          ),

          // Register Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomButton(
              text: 'Register',
              onPressed: () async {
                await AuthService.register(
                  emailController.text,
                  passwordController.text,
                  confirmPasswordController.text,
                  birthdateController.text, // Birthdate
                  calculatedAge?.toString() ?? '', // Auto-calculated Age
                  selectedBloodGroup ?? '',
                  nameController.text,
                  addressController.text,
                  phoneController.text,
                  context,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
