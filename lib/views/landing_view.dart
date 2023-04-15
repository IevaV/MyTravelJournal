import 'package:flutter/material.dart';
import 'package:mytraveljournal/components/landing_view_components/content_card.dart';
import 'package:mytraveljournal/components/landing_view_components/section_banner.dart';
import 'package:mytraveljournal/constants/color_constants.dart';

class LandingView extends StatefulWidget {
  const LandingView({super.key});

  @override
  State<LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<LandingView> {
  int _selectedIndex = 0;

  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    Text(
      'Index 0: Home',
      style: optionStyle,
    ),
    Text(
      'Index 1: Business',
      style: optionStyle,
    ),
    Text(
      'Index 2: School',
      style: optionStyle,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _getPlannedTripContentCards() {
    // get all planned trips for user
    // if no trips found then return one content card
    // else if trip is ongoing display some info
    // else if closest trip info
    List<Widget> plannedTripContentCards = [];
    plannedTripContentCards.add(const ContentCard());
    return plannedTripContentCards;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.yellowPlaceholderBackground,
      bottomNavigationBar: BottomNavigationBar(
        iconSize: 36,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              IconData(0xe047, fontFamily: 'MaterialIcons'),
            ),
            label: 'Add Trip',
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Flexible(
              flex: 1,
              child: SectionBanner(bannerText: 'Planned trips'),
            ),
            Flexible(
                flex: 4,
                child: Row(
                  children: _getPlannedTripContentCards(),
                )),
            const Flexible(
              flex: 1,
              child: SectionBanner(bannerText: 'Memories'),
            ),
            Flexible(
                flex: 4,
                child: Row(children: _getPlannedTripContentCards())),
          ],
        ),
      ),
    );
  }
}
