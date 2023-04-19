import 'package:flutter/material.dart';

import '../../constants/color_constants.dart';
import '../../constants/routes.dart';

class CustomBottomNavigationbar extends StatefulWidget {
  const CustomBottomNavigationbar({super.key});

  @override
  State<CustomBottomNavigationbar> createState() =>
      _CustomBottomNavigationbarState();
}

class _CustomBottomNavigationbarState extends State<CustomBottomNavigationbar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // if (index == 1) {
    //   Navigator.pushNamed(context, addNewTrip);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      iconSize: 36,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            IconData(0xe491, fontFamily: 'MaterialIcons'),
          ),
          label: 'My Profile',
        ),
      ],
      selectedItemColor: ColorConstants.assetColorWhite,
      backgroundColor: ColorConstants.primaryTurquoise,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      showSelectedLabels: false,
      showUnselectedLabels: false,
    );
  }
}
