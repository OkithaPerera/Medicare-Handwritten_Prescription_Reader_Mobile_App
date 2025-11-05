import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrescriptionHistoryScreen extends StatefulWidget {
  const PrescriptionHistoryScreen({super.key});

  @override
  _PrescriptionHistoryScreenState createState() =>
      _PrescriptionHistoryScreenState();
}

class _PrescriptionHistoryScreenState extends State<PrescriptionHistoryScreen> {
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    _userEmail = await getUserEmail();
    print("Loaded User Email: '$_userEmail'"); // Log loaded email
    setState(() {});
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  @override
  Widget build(BuildContext context) {
    print("Query Email: '$_userEmail'"); // Log query email
    return Scaffold(
      appBar: AppBar(
        title: Text('Prescription History',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _userEmail == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('prescriptions')
                  .where('email', isEqualTo: _userEmail)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  print("Firestore data received:");
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    print("Firestore Email: '${data['email']}'");
                    print("User Email: '$_userEmail'");
                    print("Emails match: ${data['email'] == _userEmail}");
                  }
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No prescriptions found!",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                  );
                }

                var prescriptions = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: prescriptions.length,
                  itemBuilder: (context, index) {
                    var data =
                        prescriptions[index].data() as Map<String, dynamic>;

                    String email = data['email'] ?? 'Unknown';
                    List<dynamic> medicines = data['medicines'] ?? [];
                    DateTime? timestamp =
                        (data['timestamp'] as Timestamp?)?.toDate();
                    String formattedDate = timestamp != null
                        ? DateFormat.yMMMd().add_jm().format(timestamp)
                        : "No Date";

                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Prescribed Medicines",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal),
                            ),
                            SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: medicines.map((medicine) {
                                return Row(
                                  children: [
                                    Icon(Icons.medical_services,
                                        color: Colors.blueAccent, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        medicine.toString(),
                                        style: TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                            Divider(height: 20, color: Colors.grey[300]),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person,
                                        color: Colors.grey, size: 20),
                                    SizedBox(width: 5),
                                    Text(email,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        color: Colors.grey, size: 18),
                                    SizedBox(width: 5),
                                    Text(formattedDate,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
