import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/permission_service.dart';

class CameraPermissionDeniedView extends StatelessWidget {
  final PermissionStatus status;
  final VoidCallback onPermissionGranted;

  const CameraPermissionDeniedView({
    super.key,
    required this.status,
    required this.onPermissionGranted,
  });

  @override
  Widget build(BuildContext context) {
    final isPermanentlyDenied = status.isPermanentlyDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.no_photography_outlined,
                size: 40,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Camera Access Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isPermanentlyDenied
                  ? 'Camera permission has been permanently denied. Please open your device app settings and allow camera access to use the card scanner.'
                  : 'AnjaniCRM uses your camera to scan business cards, capture client document IDs, and attach them to records.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () async {
                final permissionService = PermissionService();
                if (isPermanentlyDenied) {
                  await permissionService.openAppSettingsPage();
                } else {
                  final result = await permissionService
                      .requestCameraPermission();
                  if (result.isGranted) {
                    onPermissionGranted();
                  }
                }
              },
              icon: Icon(
                isPermanentlyDenied ? Icons.settings : Icons.lock_open,
                size: 18,
              ),
              label: Text(
                isPermanentlyDenied
                    ? 'Open Device Settings'
                    : 'Grant Camera Permission',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
