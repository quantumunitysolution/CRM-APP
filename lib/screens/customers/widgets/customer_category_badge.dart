import 'package:flutter/material.dart';

class CustomerCategoryBadge extends StatelessWidget {
  final String category;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const CustomerCategoryBadge({
    super.key,
    required this.category,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  Color _getCategoryBaseColor(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('tile') || lower.contains('ceramic') || lower.contains('sanitary')) {
      return const Color(0xFF0D9488); // Teal
    } else if (lower.contains('soft') || lower.contains('it') || lower.contains('tech')) {
      return const Color(0xFF2563EB); // Royal Blue
    } else if (lower.contains('textile') || lower.contains('cloth') || lower.contains('garment')) {
      return const Color(0xFF7C3AED); // Violet/Purple
    } else if (lower.contains('health') || lower.contains('pharma') || lower.contains('med')) {
      return const Color(0xFFE11D48); // Rose
    } else if (lower.contains('logistics') || lower.contains('transport') || lower.contains('freight')) {
      return const Color(0xFFD97706); // Amber
    } else if (lower.contains('food') || lower.contains('agri')) {
      return const Color(0xFF16A34A); // Green
    } else if (lower.contains('construct') || lower.contains('build') || lower.contains('marble')) {
      return const Color(0xFFEA580C); // Deep Orange
    }
    return const Color(0xFF475569); // Slate Gray fallback
  }

  @override
  Widget build(BuildContext context) {
    final cleanCategory = category.trim().isNotEmpty ? category.trim() : 'General';
    final baseColor = _getCategoryBaseColor(cleanCategory);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseColor.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              cleanCategory,
              style: TextStyle(
                color: baseColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
