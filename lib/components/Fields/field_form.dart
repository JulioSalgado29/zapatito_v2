import 'package:flutter/material.dart';

class FieldForm extends StatelessWidget {
  final String tittle;
  final bool isPassword;

  const FieldForm({super.key, required this.tittle, this.isPassword= false});
  @override
  
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            tittle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: TextField(
              obscureText: isPassword,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400)
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400)
                ),
                filled: true
              ),
            )
          )
        ],
      )
    );
  }
}