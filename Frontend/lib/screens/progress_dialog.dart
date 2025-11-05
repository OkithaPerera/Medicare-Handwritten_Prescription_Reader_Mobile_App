import 'package:flutter/material.dart';

void showProgressDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissal by tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Please Wait'),
        content: SingleChildScrollView(
          // Allow scrolling when content overflows
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(), // Show progress indicator
              SizedBox(width: 20),
              Expanded(
                // Allow the text to wrap properly
                child: Text(
                  message, // Display the custom message
                  softWrap: true, // Allow text to wrap
                  overflow: TextOverflow.fade, // Handle long text gracefully
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void dismissProgressDialog(BuildContext context) {
  Navigator.of(context).pop();
}
