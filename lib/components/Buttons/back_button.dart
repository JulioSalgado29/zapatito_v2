import 'package:flutter/material.dart';

class BackButton01 extends StatelessWidget {
  
  const BackButton01({super.key});
  

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;
    
    return Container(
      margin: EdgeInsets.only(left: 5, top: isPortrait ? 20 : 8),
      decoration: BoxDecoration(
        color: Colors.transparent,// fondo semitransparente
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.keyboard_arrow_left, color: Colors.white, size: 20),
        label: const Text(
          'Atrás',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          minimumSize: const Size(0, 0), // evita restricciones de tamaño
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}