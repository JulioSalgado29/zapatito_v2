import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final String routeName;
  const LoginButton({super.key, required this.text, required this.color, required this.textColor, required this.routeName});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20.0, bottom: 25),
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
        onPressed: () => Navigator.pushNamed(context, routeName),
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