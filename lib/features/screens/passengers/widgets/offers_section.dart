import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../see_all_promotions_screen.dart';

class OffersSection extends StatefulWidget {
  const OffersSection({super.key});

  @override
  State<OffersSection> createState() => _OffersSectionState();
}

class _OffersSectionState extends State<OffersSection> {
  String _selectedCategory = 'All';
  late PageController _pageController;
  int _currentPage = 0;

  final List<_OfferItem> _allOffers = [
    const _OfferItem(
      category: 'Bus',
      title: 'Save up to Rs 250 on bus tickets',
      validity: 'Valid till 31 May',
      code: 'FIRST',
      backgroundColor: Color(0xFFFFEAE9),
      badgeColor: Color(0xFF5B5251),
      isBus: true,
    ),
    const _OfferItem(
      category: 'Bus',
      title: 'Save up to Rs 200 on operators.',
      validity: 'Valid till 31 May',
      code: 'PRIMO200',
      backgroundColor: Color(0xFFFEF3C7),
      badgeColor: Color(0xFF5B5251),
      isBus: true,
    ),
    const _OfferItem(
      category: 'Train',
      title: 'Get 15% off on your first train booking',
      validity: 'Valid till 15 June',
      code: 'TRAIN15',
      backgroundColor: Color(0xFFE0F2FE),
      badgeColor: Color(0xFF1E293B),
      isBus: false,
    ),
    const _OfferItem(
      category: 'All',
      title: 'Flat Rs 100 cashback on any booking',
      validity: 'Valid till 10 June',
      code: 'CASHBACK100',
      backgroundColor: Color(0xFFF3E8FF),
      badgeColor: Color(0xFF1E293B),
      isBus: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_OfferItem> get _filteredOffers {
    if (_selectedCategory == 'All') return _allOffers;
    return _allOffers
        .where((o) => o.category == _selectedCategory || o.category == 'All')
        .toList();
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _currentPage = 0;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final offers = _filteredOffers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Offers for you',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SeeAllPromotionsScreen(),
                  ),
                );
              },
              child: const Text(
                'View more',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: ['All', 'Bus', 'Train'].map((category) {
            final isSelected = _selectedCategory == category;
            return GestureDetector(
              onTap: () => _onCategorySelected(category),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        offers.isEmpty
            ? Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                height: 170,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.xlR,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'No offers available for this category',
                    style: TextStyle(color: AppColors.textHint),
                  ),
                ),
              )
            : Column(
                children: [
                  SizedBox(
                    height: 170,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: offers.length,
                      onPageChanged: (page) => setState(() => _currentPage = page),
                      itemBuilder: (context, index) => _OfferCard(offer: offers[index]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentPage + 1}/${offers.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(
                            offers.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _currentPage == index ? 8 : 6,
                              height: _currentPage == index ? 8 : 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? AppColors.textHint
                                    : AppColors.border,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final _OfferItem offer;

  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: offer.backgroundColor,
        borderRadius: AppRadius.xlR,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.xlR,
        child: Stack(
          children: [
            Positioned(
              right: -35,
              bottom: -35,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
            Positioned(
              right: 15,
              top: -45,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: offer.badgeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            offer.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          offer.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer.validity,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_offer_outlined,
                                size: 12,
                                color: Color(0xFF1E293B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                offer.code,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _FallbackIllustration(isBus: offer.isBus),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackIllustration extends StatelessWidget {
  final bool isBus;
  const _FallbackIllustration({required this.isBus});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.4),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          isBus ? Icons.directions_bus_rounded : Icons.train_rounded,
          size: 38,
          color: const Color(0xFFDC2626).withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _OfferItem {
  final String category;
  final String title;
  final String validity;
  final String code;
  final Color backgroundColor;
  final Color badgeColor;
  final bool isBus;

  const _OfferItem({
    required this.category,
    required this.title,
    required this.validity,
    required this.code,
    required this.backgroundColor,
    required this.badgeColor,
    this.isBus = true,
  });
}
