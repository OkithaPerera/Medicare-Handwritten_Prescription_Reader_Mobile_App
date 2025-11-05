import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  CustomButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF008037),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(fontSize: 18.0, color: Colors.white),
      ),
    );
  }
}
