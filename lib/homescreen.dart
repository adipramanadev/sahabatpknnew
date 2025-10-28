import 'dart:async';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:sahabatpknnew/home.dart';
import 'models/flutterViz_bottom_navigationBar_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final pageController = PageController();
  Timer? _timer; // To handle the auto-slide functionality

  final List<FlutterVizBottomNavigationBarModel>
  flutterVizBottomNavigationBarItems = [
    FlutterVizBottomNavigationBarModel(icon: Icons.home, label: "HomeScreen"),
    FlutterVizBottomNavigationBarModel(icon: Icons.article, label: "News"),
    FlutterVizBottomNavigationBarModel(
      icon: Icons.card_membership,
      label: "Kartu",
    ),
    FlutterVizBottomNavigationBarModel(
      icon: Icons.info_outline,
      label: "About",
    ),
    FlutterVizBottomNavigationBarModel(
      icon: Icons.account_circle,
      label: "Account",
    ),
  ];

  // Function to automatically change page every 3 seconds
  void startAutoSlider() {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (pageController.hasClients) {
        int nextPage = pageController.page!.toInt() + 1;
        if (nextPage >= 3) {
          nextPage = 0; // Loop back to the first page
        }
        pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startAutoSlider(); // Start auto-slider when the screen is loaded
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffe2e5e7),
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topLeft,
              children: [
                Container(
                  margin: EdgeInsets.all(0),
                  padding: EdgeInsets.all(0),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.4,
                  decoration: BoxDecoration(
                    color: Color(0xffffffff),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: Color(0x4d9e9e9e), width: 1),
                  ),
                ),
                // Here, you can add the top part of your page, like the logo and page content
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: PersistentTabView(
        context,
        controller: PersistentTabController(initialIndex: 0),
        screens: [
          // Define each screen that corresponds to the bottom navigation tabs
          // NewsScreen(), // Screen for HomeScreen tab
          Center(child: Text('data')), // Screen for Account tab
          Center(child: Text('data')),
          Center(child: Text('data')),
          Center(child: Text('data')),
        ],
        items: [
          PersistentBottomNavBarItem(
            icon: Icon(Icons.home),
            title: ("HomeScreen"),
            activeColorPrimary: Colors.red,
            inactiveColorPrimary: Colors.grey,
          ),
          PersistentBottomNavBarItem(
            icon: Icon(Icons.article),
            title: ("News"),
            activeColorPrimary: Colors.red,
            inactiveColorPrimary: Colors.grey,
          ),
          PersistentBottomNavBarItem(
            icon: Icon(Icons.card_membership),
            title: ("Kartu"),
            activeColorPrimary: Colors.red,
            inactiveColorPrimary: Colors.grey,
          ),
          PersistentBottomNavBarItem(
            icon: Icon(Icons.info_outline),
            title: ("About"),
            activeColorPrimary: Colors.red,
            inactiveColorPrimary: Colors.grey,
          ),
          PersistentBottomNavBarItem(
            icon: Icon(Icons.account_circle),
            title: ("Account"),
            activeColorPrimary: Colors.red,
            inactiveColorPrimary: Colors.grey,
          ),
        ],
      ),
    );
  }
}

// Define all your screens
class HomeScreenScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('HomeScreen Screen')));
  }
}


class KartuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Kartu Screen')));
  }
}

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('About Screen')));
  }
}

class AccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Account Screen')));
  }
}
