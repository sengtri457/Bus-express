import 'package:flutter/material.dart';
import 'passenger_home_screen.dart';
import 'mytickets_screen.dart';
import 'passenger_profile_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      PassengerHomeScreen(
        onProfileTap: () {
          setState(() => _currentIndex = 2); // Switch to Profile Tab
        },
      ),
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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF1A73E8),
              unselectedItemColor: const Color(0xFF9CA3AF),
              selectedFontSize: 12,
              unselectedFontSize: 12,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.directions_bus_rounded),
                  activeIcon: Icon(Icons.directions_bus_rounded, size: 26),
                  label: 'Book Bus',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.confirmation_number_outlined),
                  activeIcon: Icon(Icons.confirmation_number_rounded, size: 26),
                  label: 'My Tickets',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded, size: 26),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
