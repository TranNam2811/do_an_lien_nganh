import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:smart_home/widgets/home.dart';
import 'package:smart_home/widgets/homepage.dart';
import 'package:smart_home/widgets/setting_page.dart';

class HomeNavBar extends StatefulWidget {
  const HomeNavBar({super.key});
  @override
  _NavigationMenuState createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<HomeNavBar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index >= 0 && index < 5) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return HomePage();
      case 1:
        return SettingsPage();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _buildContent(_selectedIndex),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        height: 70,
        padding: EdgeInsets.all(0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Expanded(
              child: InkWell(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: () {
                  _onItemTapped(0);
                },
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0 ? Colors.white : Colors.transparent, // Set background color
                    shape: BoxShape.rectangle, // Circle shape
                  ),
                  child: Icon(
                    Icons.home,
                    color: _selectedIndex == 0 ? Colors.blue : Colors.white,
                    size: 35,
                  ),
                ),
              ),
            ),

            ////////////////////////////////////////////////////////////////
            Expanded(
              child: InkWell(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: () {
                  _onItemTapped(1);
                },
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1 ? Colors.white : Colors.transparent, // Set background color
                    shape: BoxShape.rectangle, // Circle shape
                  ),
                  child: Icon(
                    Icons.settings,
                    color: _selectedIndex == 1 ? Colors.blue : Colors.white,
                    size: 35,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
