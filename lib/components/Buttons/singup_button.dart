import 'package:flutter/material.dart';

class SingupButton extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const SingupButton({super.key, required this.text, required this.color, required this.textColor});
  
  @override
  Widget build(BuildContext context) {
    
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          elevation: 5.0,
          backgroundColor: color,
          padding: const EdgeInsets.all(15.0),
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              color: Colors.black, // Set your desired border color here
              width: 2, // Optional: Set the border width
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
          iconColor: Colors.white,
        ),
        onPressed: () => print('Signup Presionado'),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        )
      ),
    );
  }
}