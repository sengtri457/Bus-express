import 'package:flutter/material.dart';

class LocationField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onBrowse;

  const LocationField({
    super.key,
    required this.controller,
    required this.hint,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
              label: Text(label),
              labelStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
            ),
          ),
        ),
        if (onBrowse != null)
          GestureDetector(
            onTap: onBrowse,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.list_rounded,
                size: 18,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
      ],
    );
  }
}
