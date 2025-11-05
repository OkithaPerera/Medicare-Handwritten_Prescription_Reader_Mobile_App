import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:medicare/screens/medicine_list.dart';
import 'package:medicare/screens/prescription_history_screen.dart';
import 'package:medicare/screens/progress_dialog.dart';
import 'package:medicare/services/auth_service.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker picker = ImagePicker();
  List<String> croppedImages = []; // Base64 image strings
  Set<String> selectedImages = {}; // Store selected images
  List<String> suggestedMedicines = [];
  final bool _isLoading = false;
  var uuid = Uuid();
  File? _uploadedPrescription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.teal),
                title: Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  XFile? image =
                      await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    _handleImage(File(image.path));
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.teal),
                title: Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  XFile? image =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    _handleImage(File(image.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendSelectedImages() async {
    showProgressDialog(
        context, 'Processing image... Waiting for the suggested medicines.');

    String apiUrl = "http://172.20.10.11:8000/run_prediction"; // API URL
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    for (String image in selectedImages) {
      var decodedImage = base64Decode(image);
      request.files.add(http.MultipartFile.fromBytes(
        'files',
        decodedImage,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpg'),
      ));
    }

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);

        if (jsonResponse['suggested_medicine'] != null) {
          List<String> medicines =
              List<String>.from(jsonResponse['suggested_medicine']);

          // Save prescription and medicines to Firestore
          await _savePrescriptionAndMedicines(medicines);

          // Navigate to MedicineDetailsScreen with the list of suggested medicines
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MedicineDetailsScreen(suggestedMedicines: medicines),
            ),
          ).then((_) {
            dismissProgressDialog(context);
            setState(() {
              croppedImages.clear();
              selectedImages.clear();
            });
          });
        } else {
          dismissProgressDialog(context);
        }
      } else {
        print('Upload failed with status: ${response.statusCode}');
        dismissProgressDialog(context);
      }
    } catch (e) {
      print('Error uploading images: $e');
      dismissProgressDialog(context);
    }
  }

  Future<void> _savePrescriptionAndMedicines(List<String> medicines) async {
    try {
      String? email = await AuthService
          .getUserEmail(); // Ensure email is resolved before using it

      if (email != null) {
        await _firestore.collection('prescriptions').add({
          'medicines': medicines,
          'timestamp': FieldValue.serverTimestamp(),
          'email': email,
        });

        print("Data saved successfully.");
      } else {
        print("Error: Email is null.");
      }
    } catch (e) {
      print('Error saving prescription and medicines: $e');
    }
  }

  Future<void> _handleImage(File imageFile) async {
    showProgressDialog(context, 'Processing your prescription...');
    String uploadUrl = "http://172.20.10.11:8000/get_prescription";
    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));
    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);
        if (jsonResponse['images'] != null) {
          setState(() {
            croppedImages = List<String>.from(jsonResponse['images']);
            selectedImages.clear();
          });
        }
      }
    } catch (e) {
      print('Error uploading image: $e');
    } finally {
      dismissProgressDialog(context);
    }
  }

  void _toggleImageSelection(String image) {
    setState(() {
      if (selectedImages.contains(image)) {
        selectedImages.remove(image);
      } else {
        selectedImages.add(image);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicare', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.blueGrey),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await AuthService.logout(context);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Lottie.asset('assets/animations/welcome.json', height: 150),
            SizedBox(height: 20),
            Text(
              'Welcome to Medicare!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.upload_file, size: 24),
              label: Text('Upload Prescription'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.white,
                textStyle: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onPressed: () {
                _showUploadOptions(context);
              },
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.history, size: 24),
              label: Text('View Past Prescriptions'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.white,
                textStyle: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PrescriptionHistoryScreen()));
              },
            ),
            SizedBox(height: 20),
            if (croppedImages.isNotEmpty) ...[
              Text(
                'Select Cropped Images:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: croppedImages.length,
                itemBuilder: (context, index) {
                  String image = croppedImages[index];
                  bool isSelected = selectedImages.contains(image);
                  return GestureDetector(
                    onTap: () {
                      _toggleImageSelection(image);
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            base64Decode(image),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Icon(Icons.check_circle,
                                color: Colors.green, size: 24),
                          ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
            ],
          ],
        ),
      ),
      floatingActionButton: croppedImages.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: selectedImages.isNotEmpty ? _sendSelectedImages : null,
              icon: Icon(Icons.send),
              label: Text("Send Images"),
              backgroundColor:
                  selectedImages.isNotEmpty ? Colors.teal : Colors.grey,
            )
          : null,
    );
  }
}
