// ignore_for_file: avoid_redundant_argument_values

import "package:backtracker/Home.dart";
import "package:flutter/material.dart";
import "package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart";



// ----------------------------------------- Provided Style ----------------------------------------- //

class ProvidedStylesExample extends StatefulWidget {

  @override
  _ProvidedStylesExampleState createState() => _ProvidedStylesExampleState();
}

class _ProvidedStylesExampleState extends State<ProvidedStylesExample> {
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
    HomeScreen(),
    HomeScreen(),
    HomeScreen(),
    HomeScreen(),
  ];

  Color? _getSecondaryItemColorForSpecificStyles() =>
      _navBarStyle == NavBarStyle.style7 ||
          _navBarStyle == NavBarStyle.style10 ||
          _navBarStyle == NavBarStyle.style15 ||
          _navBarStyle == NavBarStyle.style16 ||
          _navBarStyle == NavBarStyle.style17 ||
          _navBarStyle == NavBarStyle.style18
          ? Colors.white
          : null;

  List<PersistentBottomNavBarItem> _navBarsItems() => [
    PersistentBottomNavBarItem(
      icon: const Icon(Icons.home),
      title: "Home",
      opacity: 0.7,
      activeColorPrimary: Colors.blue,
      activeColorSecondary: _navBarStyle == NavBarStyle.style7 ||
          _navBarStyle == NavBarStyle.style10
          ? Colors.white
          : null,
      inactiveColorPrimary: Colors.grey,
      scrollController: _scrollControllers.first,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(Icons.search),
      title: "Search",
      activeColorPrimary: Colors.teal,
      activeColorSecondary: _navBarStyle == NavBarStyle.style7 ||
          _navBarStyle == NavBarStyle.style10
          ? Colors.white
          : null,
      inactiveColorPrimary: Colors.grey,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(Icons.add),
      title: "Add",
      activeColorPrimary: Colors.blueAccent,
      inactiveColorPrimary: Colors.grey,
      activeColorSecondary: _getSecondaryItemColorForSpecificStyles(),
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(Icons.message),
      title: "Messages",
      activeColorPrimary: Colors.deepOrange,
      inactiveColorPrimary: Colors.grey,
      activeColorSecondary: _navBarStyle == NavBarStyle.style7 ||
          _navBarStyle == NavBarStyle.style10
          ? Colors.white
          : null,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(Icons.settings),
      title: "Settings",
      activeColorPrimary: Colors.indigo,
      inactiveColorPrimary: Colors.grey,
      activeColorSecondary: _navBarStyle == NavBarStyle.style7 ||
          _navBarStyle == NavBarStyle.style10
          ? Colors.white
          : null,
      scrollController: _scrollControllers.last,
    ),
  ];

  @override
  Widget build(final BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Navigation Bar Demo"),
      backgroundColor: Colors.grey.shade900,
    ),
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
      floatingActionButton: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Colors.orange),
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        onPressed: () {},
      ),
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
      backgroundColor: Colors.grey.shade900,
      isVisible: !_hideNavBar,
      animationSettings: const NavBarAnimationSettings(
        navBarItemAnimation: ItemAnimationSettings(
          // Navigation Bar's items animation properties.
          duration: Duration(milliseconds: 400),
          curve: Curves.ease,
        ),
        screenTransitionAnimation: ScreenTransitionAnimationSettings(
          // Screen transition animation on change of selected tab.
          animateTabTransition: true,
          duration: Duration(milliseconds: 300),
          screenTransitionAnimationType:
          ScreenTransitionAnimationType.fadeIn,
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

// ----------------------------------------- Custom Style ----------------------------------------- //

class CustomNavBarWidget extends StatelessWidget {
  const CustomNavBarWidget(
      this.items, {
        required this.selectedIndex,
        required this.onItemSelected,
        final Key? key,
      }) : super(key: key);
  final int selectedIndex;
  // List<PersistentBottomNavBarItem> is just for example here. It can be anything you want like List<YourItemWidget>
  final List<PersistentBottomNavBarItem> items;
  final ValueChanged<int> onItemSelected;

  Widget _buildItem(
      final PersistentBottomNavBarItem item, final bool isSelected) =>
      Container(
        alignment: Alignment.center,
        height: kBottomNavigationBarHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: IconTheme(
                data: IconThemeData(
                    size: 26,
                    color: isSelected
                        ? (item.activeColorSecondary ?? item.activeColorPrimary)
                        : item.inactiveColorPrimary ?? item.activeColorPrimary),
                child: isSelected ? item.icon : item.inactiveIcon ?? item.icon,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Material(
                type: MaterialType.transparency,
                child: FittedBox(
                    child: Text(
                      item.title ?? "",
                      style: TextStyle(
                          color: isSelected
                              ? (item.activeColorSecondary ??
                              item.activeColorPrimary)
                              : item.inactiveColorPrimary,
                          fontWeight: FontWeight.w400,
                          fontSize: 12),
                    )),
              ),
            )
          ],
        ),
      );

  @override
  Widget build(final BuildContext context) => Container(
    color: Colors.grey.shade900,
    child: SizedBox(
      width: double.infinity,
      height: kBottomNavigationBarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((final item) {
          final int index = items.indexOf(item);
          return Flexible(
            child: GestureDetector(
              onTap: () {
                onItemSelected(index);
              },
              child: _buildItem(item, selectedIndex == index),
            ),
          );
        }).toList(),
      ),
    ),
  );
}