import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CapturedPhotoPreview extends StatefulWidget {
  final XFile frontPhoto;
  final XFile? backPhoto;
  final double? latitude;
  final double? longitude;
  final bool isUploading;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const CapturedPhotoPreview({
    super.key,
    required this.frontPhoto,
    this.backPhoto,
    this.latitude,
    this.longitude,
    this.isUploading = false,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<CapturedPhotoPreview> createState() => _CapturedPhotoPreviewState();
}

class _CapturedPhotoPreviewState extends State<CapturedPhotoPreview> {
  // 0: Front side, 1: Back side
  int _selectedSideIndex = 0;

  @override
  Widget build(BuildContext context) {
    final hasGps = widget.latitude != null && widget.longitude != null;
    final hasBack = widget.backPhoto != null;
    final currentPhoto = (_selectedSideIndex == 0 || !hasBack)
        ? widget.frontPhoto
        : widget.backPhoto!;

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        if (isLandscape) {
          return _buildLandscapeReview(currentPhoto, hasGps, hasBack);
        }
        return _buildPortraitReview(currentPhoto, hasGps, hasBack);
      },
    );
  }

  Widget _buildPortraitReview(XFile currentPhoto, bool hasGps, bool hasBack) {
    return Column(
      children: [
        // Top instruction bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Card Photos (Front & Back)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Inspect both card sides before accepting into CRM',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Front / Back toggle tabs if both photos exist
        if (hasBack)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSideTab(
                      index: 0,
                      label: 'Front Side',
                      icon: Icons.credit_card,
                    ),
                  ),
                  Expanded(
                    child: _buildSideTab(
                      index: 1,
                      label: 'Back Side',
                      icon: Icons.flip_to_back,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Photo Preview Frame
        Expanded(
          child: _buildPhotoFrame(currentPhoto, hasGps),
        ),

        const SizedBox(height: 16),

        // Action Buttons: Reject vs Accept
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Row(
            children: [
              // Reject / Retake button
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: widget.isUploading ? null : widget.onReject,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Color(0xFFEF4444),
                  ),
                  label: const Text(
                    'Reject Both',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(
                      color: Color(0xFFFCA5A5),
                      width: 1.5,
                    ),
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Accept button
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: widget.isUploading ? null : widget.onAccept,
                  icon: widget.isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.cloud_upload_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                  label: Text(
                    widget.isUploading ? 'Uploading...' : 'Accept Both',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeReview(XFile currentPhoto, bool hasGps, bool hasBack) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Photo Preview taking maximum available space
          Expanded(
            child: _buildPhotoFrame(currentPhoto, hasGps),
          ),
          const SizedBox(width: 12),

          // Right: Action and review panel
          Container(
            width: 175,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (hasBack)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSideTab(
                            index: 0,
                            label: 'Front',
                            icon: Icons.credit_card,
                          ),
                        ),
                        Expanded(
                          child: _buildSideTab(
                            index: 1,
                            label: 'Back',
                            icon: Icons.flip_to_back,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Reject Button
                OutlinedButton.icon(
                  onPressed: widget.isUploading ? null : widget.onReject,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                  label: const Text(
                    'Reject',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 38),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Accept & Upload Button
                ElevatedButton.icon(
                  onPressed: widget.isUploading ? null : widget.onAccept,
                  icon: widget.isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_rounded, size: 16),
                  label: Text(
                    widget.isUploading ? 'Uploading...' : 'Accept Both',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 42),
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoFrame(XFile currentPhoto, bool hasGps) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Display captured image
          if (kIsWeb)
            Image.network(currentPhoto.path, fit: BoxFit.cover)
          else
            Image.file(
              File(currentPhoto.path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  _selectedSideIndex == 0
                      ? 'Front Card Preview'
                      : 'Back Card Preview',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),

          // Side indicator badge on photo
          Positioned(
            top: 14,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: Text(
                _selectedSideIndex == 0 ? 'FRONT' : 'BACK',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // GPS badge overlay
          if (hasGps)
            Positioned(
              top: 14,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF38BDF8),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Lat: ${widget.latitude!.toStringAsFixed(4)}, Long: ${widget.longitude!.toStringAsFixed(4)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Timestamp badge
          Positioned(
            bottom: 14,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatTime(DateTime.now()),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideTab({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedSideIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedSideIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
