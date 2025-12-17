// ignore_for_file: avoid_redundant_argument_values

import "package:backtracker/Home.dart";
import "package:flutter/material.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart";

import "colours.dart";
import "exercises.dart";



// ----------------------------------------- Provided Style ----------------------------------------- //

class NavBar extends StatefulWidget {

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  late PersistentTabController _controller;
  late bool _hideNavBar;
  final List<ScrollController> _scrollControllers = [
    ScrollController(),
    ScrollController(),
  ];

  NavBarStyle _navBarStyle = NavBarStyle.simple;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 1);
    _hideNavBar = false;
  }

  @override
  void dispose() {
    for (final element in _scrollControllers) {
      element.dispose();
    }
    super.dispose();
  }

  List<Widget> _buildScreens() => [
    HomeScreen(),
    Exercises(),
    HomeScreen(),
    HomeScreen(),
  ];

  List<PersistentBottomNavBarItem> _navBarsItems() => [
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.solidHome, size: 21,),
      title: "Home",
      opacity: 0.7,
      activeColorPrimary: dark,
      inactiveColorPrimary: mid,
      scrollController: _scrollControllers.first,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.dumbbell, size: 21,),
      title: "Exercises",
      activeColorPrimary: dark,
      inactiveColorPrimary: mid,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.chartLine, size: 21,),
      title: "Add",
      activeColorPrimary: dark,
      inactiveColorPrimary: mid,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.solidUser, size: 21,),
      title: "Profile",
      activeColorPrimary: dark,
      inactiveColorPrimary: mid,
    ),
  ];

  @override
  Widget build(final BuildContext context) => Scaffold(
    drawer: const Drawer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("This is the Drawer"),
          ],
        ),
      ),
    ),
    body: PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: false,
      stateManagement: true,
      hideNavigationBarWhenKeyboardAppears: true,
      popBehaviorOnSelectedNavBarItemPress: PopBehavior.once,
      hideOnScrollSettings: HideOnScrollSettings(
        hideNavBarOnScroll: true,
        scrollControllers: _scrollControllers,
      ),
      padding: const EdgeInsets.only(top: 8),
      onWillPop: (final context) async {
        await showDialog(
          context: context ?? this.context,
          useSafeArea: true,
          builder: (final context) => Container(
            height: 50,
            width: 50,
            color: Colors.white,
            child: ElevatedButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
        return false;
      },
      isVisible: !_hideNavBar,
      animationSettings: const NavBarAnimationSettings(
        navBarItemAnimation: ItemAnimationSettings(
          // Navigation Bar's items animation properties.
          duration: Duration(milliseconds: 400),
          curve: Curves.ease,
        ),
        onNavBarHideAnimation: OnHideAnimationSettings(
          duration: Duration(milliseconds: 100),
          curve: Curves.bounceInOut,
        ),
      ),
      confineToSafeArea: true,
      navBarHeight: kBottomNavigationBarHeight,
      navBarStyle:
      _navBarStyle, // Choose the nav bar style with this property
    ),
  );
}
