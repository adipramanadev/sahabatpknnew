import 'package:flutter/material.dart';

class SikapPKN extends StatefulWidget {
  const SikapPKN({Key? key}) : super(key: key);

  @override
  State<SikapPKN> createState() => _SikapPKNState();
}

class _SikapPKNState extends State<SikapPKN> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sikap PKN'),
      ),
      body: const Center(
        child: Text('Sikap PKN Content'),
      ),
    );
  }
}