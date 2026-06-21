import 'package:flutter/material.dart';
import '../../../l10n/tr_extension.dart';
import 'passenger_home_screen.dart';
import 'mytickets_screen.dart';
import 'passenger_profile_screen.dart';
import 'tracking_hub_screen.dart';

class PassengerMainScreen extends StatefulWidget {
  final int initialIndex;
  final String? newBookingId;
  final int newSeatCount;

  const PassengerMainScreen({
    super.key,
    this.initialIndex = 0,
    this.newBookingId,
    this.newSeatCount = 1,
  });

  @override
  State<PassengerMainScreen> createState() => _PassengerMainScreenState();
}

class _PassengerMainScreenState extends State<PassengerMainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  static const _primaryColor = Color(0xFF2563EB);
  static const _inactiveColor = Color(0xFFCBD5E1);
  static const _navBgColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      PassengerHomeScreen(
        onProfileTap: () => setState(() => _currentIndex = 3),
      ),
      const TrackingHubScreen(),
      MyTicketsScreen(
        newBookingId: widget.newBookingId,
        newSeatCount: widget.newSeatCount,
      ),
      const PassengerProfileScreen(isTab: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        primaryColor: _primaryColor,
        inactiveColor: _inactiveColor,
        backgroundColor: _navBgColor,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color primaryColor;
  final Color inactiveColor;
  final Color backgroundColor;

  static List<_NavItem> _items(BuildContext context) => [
    _NavItem(
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus_rounded,
      label: context.tr.navBookBus,
    ),
    _NavItem(
      icon: Icons.near_me_outlined,
      activeIcon: Icons.near_me_rounded,
      label: 'Tracking',
    ),
    _NavItem(
      icon: Icons.confirmation_number_outlined,
      activeIcon: Icons.confirmation_number_rounded,
      label: context.tr.navMyTickets,
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: context.tr.navProfile,
    ),
  ];

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.primaryColor,
    required this.inactiveColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _items(context).length,
              (i) => _NavBarItem(
                item: _items(context)[i],
                isActive: currentIndex == i,
                activeColor: primaryColor,
                inactiveColor: inactiveColor,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                key: ValueKey(isActive),
                size: 22,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
