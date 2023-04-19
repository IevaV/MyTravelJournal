import 'package:flutter/material.dart';
import 'package:flutter_lazy_indexed_stack/flutter_lazy_indexed_stack.dart';
import 'package:mytraveljournal/components/landing_view_components/content_card.dart';
import 'package:mytraveljournal/components/landing_view_components/section_banner.dart';
import 'package:mytraveljournal/components/ui_components/custom_bottom_navigation_bar.dart';
import 'package:mytraveljournal/constants/color_constants.dart';
import 'package:mytraveljournal/views/add_new_trip_view.dart';
import 'package:mytraveljournal/views/trip_memory_view.dart';
import 'dart:developer' as devtools show log;

import '../constants/routes.dart';

class LandingView extends StatefulWidget {
  const LandingView({super.key});

  @override
  State<LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<LandingView> {
  int _widgetIndex = 0;

  List<Widget> _getPlannedTripContentCards() {
    // get all planned trips for user
    // if no trips found then return one content card
    // else if trip is ongoing display some info
    // else if closest trip info
    List<Widget> plannedTripContentCards = [];
    plannedTripContentCards.add(const ContentCard());
    return plannedTripContentCards;
  }

  Widget switchFoatingActionButton(int index) {
    final IconData icon;
    if (index < 1) {
      icon = const IconData(0xe047, fontFamily: 'MaterialIcons');
    } else {
      icon = const IconData(0xe156, fontFamily: 'MaterialIcons');
    }
    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
      child: FloatingActionButton(
        onPressed: () {
          setState(() {
            _widgetIndex = 1;
          });
        },
        backgroundColor: ColorConstants.primaryRed,
        child: Icon(
          icon,
          size: 42,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_widgetIndex > 0) {
          setState(() {
            _widgetIndex--;
          });
          return await Future.value(false);
        } else {
          return await Future.value(true);
        }
      },
      child: Scaffold(
        backgroundColor: ColorConstants.yellowPlaceholderBackground,
        bottomNavigationBar: const CustomBottomNavigationbar(),
        floatingActionButton: switchFoatingActionButton(_widgetIndex),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: SafeArea(
          child: LazyIndexedStack(
            index: _widgetIndex,
            children: [
              Column(
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
              TripMemoryView(
                callback: () {
                  setState(() {
                    _widgetIndex = 2;
                  });
                },
              ),
              const AddNewTripView(),
            ],
          ),
        ),
      ),
    );
  }
}
