import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:zapatito_v2/components/widgets.dart';

class ContainerShape01 extends StatelessWidget {
  const ContainerShape01({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WaveClipperOne(),
      child: Container(
        height: MediaQuery.of(context).size.height * .15,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(gradient: Designwidgets().linearGradientMain(context)),
      )
    );
  }
}