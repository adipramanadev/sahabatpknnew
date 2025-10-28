import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlankPage extends StatefulWidget {
  @override
  State<BlankPage> createState() => _BlankPageState();
}

class _BlankPageState extends State<BlankPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //berikan function login na
      body: Center(
        //menampilkan tokennya
        child: FutureBuilder<String?>(
          future: _getAuthToken(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            } else {
              final token = snapshot.data;
              return Text("Login Sukses - Token: $token");
            }
          },
        ),
      ),
    );
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}