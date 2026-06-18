import 'package:flutter/material.dart';
import '../../../../l10n/tr_extension.dart';

class OperatorCard extends StatelessWidget {
  final Map<String, dynamic>? operatorInfo;
  const OperatorCard({super.key, required this.operatorInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF54282E), Color(0xFF54282E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _OperatorLogo(
            logoUrl: operatorInfo?['logo_url'] as String?,
            name: operatorInfo?['name'] as String? ?? '',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    operatorInfo?['name'] ?? context.tr.myCompany,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6EE7B7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr.activeOperator,
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorLogo extends StatelessWidget {
  final String? logoUrl;
  final String name;
  const _OperatorLogo({required this.logoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final hasUrl = logoUrl != null && logoUrl!.startsWith('http');
    return Container(
      width: 58,
      height: 58,
      padding: hasUrl ? null : const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        image: hasUrl
            ? DecorationImage(image: NetworkImage(logoUrl!), fit: BoxFit.fill)
            : null,
      ),
      child: hasUrl
          ? null
          : Icon(Icons.business_rounded, color: Colors.white, size: 30),
    );
  }
}
