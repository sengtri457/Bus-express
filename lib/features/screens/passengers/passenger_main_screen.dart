import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/tr_extension.dart';
import '../../../core/theme/app_theme.dart';
import 'passenger_home_screen.dart';
import 'mytickets_screen.dart';
import 'passenger_profile_screen.dart';
import 'tracking_hub_screen.dart';
import 'llm_chat_screen.dart';

class PassengerMainScreen extends StatefulWidget {
  final int initialIndex;
  final String? newBookingId;

  const PassengerMainScreen({
    super.key,
    this.initialIndex = 0,
    this.newBookingId,
  });

  @override
  State<PassengerMainScreen> createState() => _PassengerMainScreenState();
}

class _PassengerMainScreenState extends State<PassengerMainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;
  late List<Widget> _screens;
  bool _isNavbarVisible = true;



  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _previousIndex = widget.initialIndex;
    _screens = [
      PassengerHomeScreen(
        onProfileTap: () => setState(() => _currentIndex = 3),
      ),
      const TrackingHubScreen(),
      MyTicketsScreen(
        newBookingId: widget.newBookingId,
      ),
      const PassengerProfileScreen(isTab: true),
    ];
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
      _isNavbarVisible = true; // Always restore navbar on tab switch
    });
  }

  void _openChatbot() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const LlmChatScreen(),
        transitionDuration: AppAnimations.slow,
        transitionsBuilder: (_, animation, _, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: AppAnimations.enter));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification) {
            if (notification.metrics.axis == Axis.vertical) {
              final scrollDelta = notification.scrollDelta;
              if (scrollDelta != null) {
                if (scrollDelta > 2 && _isNavbarVisible) {
                  setState(() {
                    _isNavbarVisible = false;
                  });
                } else if (scrollDelta < -2 && !_isNavbarVisible) {
                  setState(() {
                    _isNavbarVisible = true;
                  });
                }
              }
            }
          }

          // Also hide navbar when reached the absolute bottom of a scrollable view
          final metrics = notification.metrics;
          if (metrics.axis == Axis.vertical && metrics.pixels >= metrics.maxScrollExtent - 10) {
            if (_isNavbarVisible && metrics.maxScrollExtent > 0) {
              setState(() {
                _isNavbarVisible = false;
              });
            }
          }

          return false; // Allow scroll notification to continue bubbling
        },
        child: AnimatedSwitcher(
          duration: AppAnimations.medium,
          switchInCurve: AppAnimations.enter,
          switchOutCurve: AppAnimations.exit,
          transitionBuilder: (child, animation) {
            final inFromRight = _currentIndex > _previousIndex;
            final slideIn = Tween<Offset>(
              begin: Offset(inFromRight ? 0.04 : -0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppAnimations.enter,
            ));
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slideIn, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_currentIndex),
            child: _screens[_currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        offset: _isNavbarVisible ? Offset.zero : const Offset(0, 1.5),
        child: _BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          onChatbotTap: _openChatbot,
        ),
      ),
    );
  }
}

// ─── Bottom nav bar ───────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onChatbotTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onChatbotTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? bottomPadding : 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface, // Keep old background color
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.border, // Keep old border color
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    context,
                    index: 0,
                    icon: Icons.directions_bus_outlined,
                    activeIcon: Icons.directions_bus_rounded,
                    label: context.tr.navBookBus,
                  ),
                  _buildNavItem(
                    context,
                    index: 1,
                    icon: Icons.near_me_outlined,
                    activeIcon: Icons.near_me_rounded,
                    label: context.tr.navTracking,
                  ),
                  _buildNavItem(
                    context,
                    index: 2,
                    icon: Icons.confirmation_number_outlined,
                    activeIcon: Icons.confirmation_number_rounded,
                    label: context.tr.navMyTickets,
                  ),
                  _buildNavItem(
                    context,
                    index: 3,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: context.tr.navProfile,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Chatbot circular button
          GestureDetector(
            onTap: onChatbotTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface, // Matching old background
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Center(
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/AI.gif',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = currentIndex == index;
    const activeColor = AppColors.primaryBlue; // Keep old active color
    const inactiveColor = Color(0xFFCBD5E1); // Keep old inactive color

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isActive 
                  ? activeColor.withValues(alpha: 0.1) // Keep old active highlight
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: 20,
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: isActive ? activeColor : inactiveColor,
                        fontSize: 9.5,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
