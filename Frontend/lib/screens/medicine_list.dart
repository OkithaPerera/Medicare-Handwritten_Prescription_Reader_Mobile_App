import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:medicare/screens/medicine_instruction.dart';
import 'package:medicare/screens/medicine_sideeffect.dart';
import 'package:medicare/screens/medicine_summery.dart';
import 'package:medicare/screens/progress_dialog.dart';

class MedicineDetailsScreen extends StatefulWidget {
  final List<String> suggestedMedicines;

  MedicineDetailsScreen({required this.suggestedMedicines});

  @override
  _MedicineDetailsScreenState createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  String? selectedMedicine;
  BuildContext? _dialogContext; // Store the context for the dialog

  @override
  void initState() {
    super.initState();

    // Filter out INVALID values
    List<String> validMedicines = widget.suggestedMedicines
        .where((medicine) => medicine != "INVALID")
        .toList();

    if (validMedicines.isNotEmpty) {
      selectedMedicine = validMedicines.first;
    } else {
      selectedMedicine = null; // No valid medicines
    }
  }

  Future<void> _getMedicineSummary(
      BuildContext context, String medicineName) async {
    _dialogContext = context; // Store the context
    showProgressDialog(_dialogContext!, 'Wating for Medicine Summary..');
    String apiUrl =
        "http://172.20.10.11:8000/get_medicine_summuary?medicine_name=$medicineName";

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          dismissProgressDialog(_dialogContext!);
          var jsonResponse = json.decode(response.body);
          String medicineSummary = jsonResponse['medicine_summary'];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicineSummaryScreen(
                medicineSummary: medicineSummary,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          dismissProgressDialog(_dialogContext!);
          print('Error: Failed to fetch summary');
        }
      }
    } catch (e) {
      if (mounted) {
        dismissProgressDialog(_dialogContext!);
        print('Error occurred while fetching medicine summary: $e');
      }
    }
  }

  Future<void> _getMedicineInstructions(
      BuildContext context, String medicineName) async {
    _dialogContext = context;
    showProgressDialog(_dialogContext!, 'Wating for Instructions..');
    String apiUrl =
        "http://172.20.10.11:8000/get_usage_instructions?medicine_name=$medicineName";

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          dismissProgressDialog(_dialogContext!);
          var jsonResponse = json.decode(response.body);
          String medicineInstructions = jsonResponse['medicine_summary'];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicineInstructionsScreen(
                medicineInstructions: medicineInstructions,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          dismissProgressDialog(_dialogContext!);
          print('Error: Failed to fetch instructions');
        }
      }
    } catch (e) {
      if (mounted) {
        dismissProgressDialog(_dialogContext!);
        print('Error occurred while fetching medicine instructions: $e');
      }
    }
  }

  Future<void> _getMedicineSideEffects(
      BuildContext context, String medicineName) async {
    _dialogContext = context;
    showProgressDialog(_dialogContext!, 'Waiting for Side Effects..');
    String apiUrl =
        "http://172.20.10.11:8000/get_side_effects?medicine_name=$medicineName";

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          dismissProgressDialog(_dialogContext!);
          var jsonResponse = json.decode(response.body);
          String medicineSideEffects = jsonResponse['medicine_summary'];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicineSideEffectsScreen(
                medicineSideEffects: medicineSideEffects,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          dismissProgressDialog(_dialogContext!);
          print('Error: Failed to fetch side effects');
        }
      }
    } catch (e) {
      if (mounted) {
        dismissProgressDialog(_dialogContext!);
        print('Error occurred while fetching medicine side effects: $e');
      }
    }
  }

  @override
  void dispose() {
    if (_dialogContext != null && Navigator.of(_dialogContext!).canPop()) {
      Navigator.of(_dialogContext!).pop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Suggested Medicine:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              hint: Text("Choose a medicine"),
              value: selectedMedicine,
              onChanged: (String? newValue) {
                setState(() {
                  selectedMedicine = newValue;
                });
              },
              items: widget.suggestedMedicines
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (selectedMedicine != null && selectedMedicine != "INVALID") {
                  _getMedicineSummary(context, selectedMedicine!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid Medicine!')));
                }
              },
              child: Text('View Summary'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedMedicine != null && selectedMedicine != "INVALID") {
                  _getMedicineInstructions(context, selectedMedicine!);
                } else {
                  print('No valid medicine selected.');
                }
              },
              child: Text('View Instructions'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedMedicine != null && selectedMedicine != "INVALID") {
                  _getMedicineSideEffects(context, selectedMedicine!);
                } else {
                  print('No valid medicine selected.');
                }
              },
              child: Text('View Side Effects'),
            ),
          ],
        ),
      ),
    );
  }
}
