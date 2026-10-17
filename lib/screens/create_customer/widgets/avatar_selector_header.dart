import 'package:flutter/material.dart';

class AvatarSelectorHeader extends StatelessWidget {
  final VoidCallback onTap;
  final String? initialLetter;

  const AvatarSelectorHeader({
    super.key,
    required this.onTap,
    this.initialLetter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: initialLetter != null && initialLetter!.isNotEmpty
                  ? Text(
                      initialLetter!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 42,
                      color: Color(0xFF1E3A8A),
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3A8A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
