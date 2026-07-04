import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class _PassengerMainScreenState extends State<PassengerMainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;
  late List<Widget> _screens;

  static const _primaryColor = AppColors.primaryBlue;
  static const _inactiveColor = Color(0xFFCBD5E1);
  static const _navBgColor = AppColors.surface;

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
        newSeatCount: widget.newSeatCount,
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
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
      floatingActionButton: _currentIndex == 0 ? _buildFab(context) : null,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        primaryColor: _primaryColor,
        inactiveColor: _inactiveColor,
        backgroundColor: _navBgColor,
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LlmChatScreen(),
          transitionDuration: AppAnimations.slow,
          transitionsBuilder: (_, animation, __, child) {
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
      ),
      backgroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: AppGradients.primaryBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/aiLogo.png',
            width: 20,
            height: 20,
            fit: BoxFit.cover,
          ),
        ),
      ),
      label: const Text(
        'Ask AI',
        style: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOutBack);
  }
}

// ─── Nav item data ────────────────────────────────────────────

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

// ─── Bottom nav bar ───────────────────────────────────────────

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
    final items = _items(context);
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (i) => _AnimatedNavItem(
                item: items[i],
                isActive: currentIndex == i,
                activeColor: primaryColor,
                inactiveColor: inactiveColor,
                onTap: () => onTap(i),
                index: i,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Individual animated nav item ────────────────────────────

class _AnimatedNavItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;
  final int index;

  const _AnimatedNavItem({
    required this.item,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    required this.index,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pressAnim,
        builder: (_, child) =>
            Transform.scale(scale: _pressAnim.value, child: child),
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.enter,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isActive ? 18 : 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.activeColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: AppAnimations.fast,
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  widget.isActive ? widget.item.activeIcon : widget.item.icon,
                  key: ValueKey(widget.isActive),
                  size: 23,
                  color: widget.isActive
                      ? widget.activeColor
                      : widget.inactiveColor,
                ),
              ),
              AnimatedSize(
                duration: AppAnimations.fast,
                curve: AppAnimations.enter,
                child: widget.isActive
                    ? Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Text(
                          widget.item.label,
                          style: TextStyle(
                            color: widget.activeColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
