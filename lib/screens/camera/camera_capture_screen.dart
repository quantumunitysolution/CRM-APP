import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

import '../../services/api_config.dart';
import '../../services/card_upload_service.dart';
import '../../services/permission_service.dart';
import 'widgets/camera_permission_denied_view.dart';
import 'widgets/camera_viewfinder.dart';
import 'widgets/capture_button.dart';
import 'widgets/captured_photo_preview.dart';
import 'widgets/captured_thumbnail_tray.dart';

class CameraCaptureScreen extends StatefulWidget {
  final VoidCallback? onNavigateToCreate;
  final ValueChanged<ExtractedCardDetails>? onAttachToLead;

  const CameraCaptureScreen({
    super.key,
    this.onNavigateToCreate,
    this.onAttachToLead,
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();
  PermissionStatus _permissionStatus = PermissionStatus.granted;
  bool _isCheckingPermission = true;

  // Real Hardware Camera Controllers
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;

  // Two-step card capture state: Front and Back photos
  XFile? _frontPhoto;
  XFile? _backPhoto;
  double? _capturedLatitude;
  double? _capturedLongitude;

  bool _isFlashOn = false;
  bool _isCapturing = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndRequestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isFlashOn &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      _cameraController!.setFlashMode(FlashMode.off);
    }
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(_cameras[_selectedCameraIndex]);
    }
  }

  /// On screen load, verify permission and request if not yet granted.
  Future<void> _checkAndRequestCameraPermission() async {
    final status = await _permissionService.getCameraPermissionStatus();

    if (!status.isGranted && !status.isPermanentlyDenied) {
      final requestedStatus = await _permissionService
          .requestCameraPermission();
      if (mounted) {
        setState(() {
          _permissionStatus = requestedStatus;
          _isCheckingPermission = false;
        });
        if (requestedStatus.isGranted) {
          _initCameraHardware();
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _permissionStatus = status;
          _isCheckingPermission = false;
        });
        if (status.isGranted) {
          _initCameraHardware();
        }
      }
    }
  }

  /// Discovers available device camera lenses and initializes the default camera.
  Future<void> _initCameraHardware() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty && mounted) {
        await _initCameraController(_cameras[_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint('Error discovering cameras: $e');
    }
  }

  Future<void> _initCameraController(CameraDescription description) async {
    await _cameraController?.dispose();

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera controller: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _handleToggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final newFlash = !_isFlashOn;
      await _cameraController!.setFlashMode(
        newFlash ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) {
        setState(() => _isFlashOn = newFlash);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newFlash ? 'Flashlight enabled' : 'Flashlight disabled',
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  /// Automatically turns off flashlight when done with photo capture or uploading
  Future<void> _turnOffFlashlight() async {
    if (_isFlashOn &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      try {
        await _cameraController!.setFlashMode(FlashMode.off);
      } catch (e) {
        debugPrint('Error turning off flashlight: $e');
      }
      if (mounted) {
        setState(() => _isFlashOn = false);
      }
    }
  }

  Future<void> _handleSwitchLens() async {
    if (_cameras.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No secondary camera found on this device'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initCameraController(_cameras[_selectedCameraIndex]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Switched to ${_cameras[_selectedCameraIndex].lensDirection.name} camera',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Two-step card capture handler:
  /// 1. Takes Front photo, displays thumbnail tray below capture button.
  /// 2. Takes Back photo, advances to review screen with Accept/Reject buttons.
  Future<void> _handleCapture() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    XFile? capturedFile;
    Position? currentPosition;

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        capturedFile = await _cameraController!.takePicture();
      } else {
        // Fallback simulation delay
        await Future.delayed(const Duration(milliseconds: 300));
        capturedFile = XFile(
          _frontPhoto == null
              ? 'front_card_sample.jpg'
              : 'back_card_sample.jpg',
        );
      }

      // Capture GPS location coordinates
      currentPosition = await _permissionService.getCurrentPosition();
    } catch (e) {
      debugPrint('Error during photo / GPS capture: $e');
    }

    if (mounted) {
      if (_frontPhoto == null) {
        // STEP 1 COMPLETE: Front photo captured, now wait for back photo
        setState(() {
          _isCapturing = false;
          _frontPhoto = capturedFile;
          _capturedLatitude = currentPosition?.latitude;
          _capturedLongitude = currentPosition?.longitude;
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.flip, color: Color(0xFF38BDF8), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Front captured! Please flip the card to capture the back side.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // STEP 2 COMPLETE: Back photo captured, advance to review step
        setState(() {
          _isCapturing = false;
          _backPhoto = capturedFile;
          if (_capturedLatitude == null && currentPosition != null) {
            _capturedLatitude = currentPosition.latitude;
            _capturedLongitude = currentPosition.longitude;
          }
        });
        // Automatically turn off flashlight after capturing both sides
        _turnOffFlashlight();
      }
    }
  }

  /// Retake the front photo if needed
  void _handleRetakeFront() {
    setState(() {
      _frontPhoto = null;
      _backPhoto = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Front card cleared. Ready to capture front again.'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Reject handler: Discards both card photos and restarts from step 1
  void _handleRejectBoth() {
    setState(() {
      _frontPhoto = null;
      _backPhoto = null;
      _capturedLatitude = null;
      _capturedLongitude = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card photos rejected. Ready to scan new card.'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Accept handler: Uploads both Front and Back photos to backend API and Google Drive
  Future<void> _handleAcceptBoth() async {
    if (_frontPhoto == null || _backPhoto == null) return;

    // Turn off flashlight on upload
    _turnOffFlashlight();

    setState(() => _isUploading = true);

    final front = _frontPhoto!;
    final back = _backPhoto!;
    final lat = _capturedLatitude;
    final long = _capturedLongitude;

    final result = await CardUploadService().uploadCardImages(
      frontPhoto: front,
      backPhoto: back,
      latitude: lat,
      longitude: long,
    );

    if (!mounted) return;

    setState(() => _isUploading = false);

    if (result.success) {
      setState(() {
        _frontPhoto = null;
        _backPhoto = null;
        _capturedLatitude = null;
        _capturedLongitude = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Card uploaded! AI extraction in progress. Check directory in a few moments.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );

      _showUploadSuccessDialog(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Upload Failed: ${result.error ?? result.message}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showUploadSuccessDialog(CardUploadResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.cloud_done_rounded,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result.isProcessing ? 'Card Uploaded!' : 'Upload Successful',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.isProcessing
                    ? 'Your card photos are now processing in the background.'
                    : result.cardDetails != null
                    ? 'Card photos analyzed with Google Gemini Vision AI!'
                    : result.isLocalFallback
                    ? 'Cards saved to local server storage.'
                    : 'Card photos uploaded to Google Drive!',
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 14),

              // Background Processing Info Card
              if (result.isProcessing) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Background Pipeline Active',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Front & Back photos received by server\n'
                        '• Google Gemini AI extracting contact details\n'
                        '• Google Drive uploading photos in parallel\n'
                        '• Card will appear in Contacts Directory shortly',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Structured Business Card Details from Gemini AI (if available)
              if (result.cardDetails != null) ...[
                _buildCardDetailsCard(result.cardDetails!),
                const SizedBox(height: 12),
              ],

              if (result.latitude != null && result.longitude != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'GPS: ${result.latitude!.toStringAsFixed(4)}, ${result.longitude!.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Front card link row
              if (result.frontViewLink != null)
                _buildLinkTile(
                  title: 'Front Card Link',
                  url: result.frontViewLink!,
                  icon: Icons.credit_card,
                ),

              const SizedBox(height: 8),

              // Back card link row
              if (result.backViewLink != null)
                _buildLinkTile(
                  title: 'Back Card Link',
                  url: result.backViewLink!,
                  icon: Icons.flip_to_back,
                ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.add_a_photo_outlined, size: 16),
            label: const Text('Scan Next Card'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required String title,
    required String url,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF1E3A8A)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard!'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 14, color: Color(0xFF0284C7)),
                      SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetailsCard(ExtractedCardDetails details) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Business Name & Category Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  size: 18,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.businessName?.isNotEmpty == true
                          ? details.businessName!
                          : 'Not Found',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (details.category?.isNotEmpty == true)
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          details.category!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 16, thickness: 0.8, color: Color(0xFFE2E8F0)),

          // Owners / Users
          if (details.ownerNames.isNotEmpty)
            _buildCardField(
              icon: Icons.person_rounded,
              iconColor: const Color(0xFF2563EB),
              label: 'Owner / Contact',
              value: details.ownerNames.join(', '),
              isCopyable: true,
            ),

          // Phone Numbers
          if (details.phoneNumbers.isNotEmpty)
            _buildCardField(
              icon: Icons.phone_rounded,
              iconColor: const Color(0xFF16A34A),
              label: 'Phone',
              value: details.phoneNumbers.join(', '),
              isCopyable: true,
            ),

          // Location Address
          if (details.address?.isNotEmpty == true)
            _buildCardField(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFFEA580C),
              label: 'Address',
              value: details.address!,
              isCopyable: true,
            ),

          // Email
          if (details.email?.isNotEmpty == true)
            _buildCardField(
              icon: Icons.email_rounded,
              iconColor: const Color(0xFFD97706),
              label: 'Email',
              value: details.email!,
              isCopyable: true,
            ),

          // Website
          if (details.website?.isNotEmpty == true)
            _buildCardField(
              icon: Icons.language_rounded,
              iconColor: const Color(0xFF0891B2),
              label: 'Website',
              value: details.website!,
              isCopyable: true,
            ),
        ],
      ),
    );
  }

  Widget _buildCardField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isCopyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label: ',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          if (isCopyable) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied to clipboard!'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.copy_rounded,
                  size: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: ApiConfig.serverHost);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: Color(0xFF1E3A8A)),
            SizedBox(width: 10),
            Text(
              'Server Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify backend IP or hostname (e.g. 192.168.1.3 or 10.0.2.2):',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Server Host / IP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.router, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await CardUploadService().checkHealth();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Server is ONLINE and reachable!'
                          : 'Server unreachable at current URL',
                    ),
                    backgroundColor: ok
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Test Connection'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ApiConfig.updateServerHost(controller.text.trim());
              }
              Navigator.of(context).pop();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBothCaptured = _frontPhoto != null && _backPhoto != null;
    final isWaitingForBack = _frontPhoto != null && _backPhoto == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isCheckingPermission
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
            : !_permissionStatus.isGranted
            ? CameraPermissionDeniedView(
                status: _permissionStatus,
                onPermissionGranted: () {
                  setState(() {
                    _permissionStatus = PermissionStatus.granted;
                  });
                  _initCameraHardware();
                },
              )
            : isBothCaptured
            // Review screen showing both Front & Back photos with Accept & Reject buttons
            ? CapturedPhotoPreview(
                frontPhoto: _frontPhoto!,
                backPhoto: _backPhoto,
                latitude: _capturedLatitude,
                longitude: _capturedLongitude,
                isUploading: _isUploading,
                onAccept: _handleAcceptBoth,
                onReject: _handleRejectBoth,
              )
            // Live camera viewfinder and two-step capture controls with adaptive orientation
            : OrientationBuilder(
                builder: (context, orientation) {
                  final isLandscape = orientation == Orientation.landscape;
                  if (isLandscape) {
                    return _buildLandscapeCameraView(isWaitingForBack);
                  }
                  return _buildPortraitCameraView(isWaitingForBack);
                },
              ),
      ),
    );
  }

  Widget _buildPortraitCameraView(bool isWaitingForBack) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Top context banner with step indicator (1/2 or 2/2) and server status button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isWaitingForBack
                        ? const Color(0xFF0D9488).withValues(alpha: 0.1)
                        : const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isWaitingForBack ? Icons.flip : Icons.camera_enhance,
                    color: isWaitingForBack
                        ? const Color(0xFF0D9488)
                        : const Color(0xFF1E3A8A),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isWaitingForBack
                            ? 'Scan Business Card: Back Side (2/2)'
                            : 'Scan Business Card: Front Side (1/2)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isWaitingForBack
                            ? 'Flip card over and align back side inside frame'
                            : 'Position front of card inside camera window',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Camera window with stable full size (never shrunk when list/tray appears below)
          Center(
            child: CameraViewfinder(
              controller: _cameraController,
              isCameraInitialized: _isCameraInitialized,
              isFlashOn: _isFlashOn,
              onToggleFlash: _handleToggleFlash,
              onSwitchLens: _handleSwitchLens,
            ),
          ),

          const SizedBox(height: 14),

          // Bottom camera capture button positioned below camera
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CaptureButton(onCapture: _handleCapture, isBusy: _isCapturing),
                const SizedBox(height: 8),
                Text(
                  isWaitingForBack
                      ? 'Tap to Capture Back'
                      : 'Tap to Capture Front',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Thumbnail tray / list below capture button (scrolls smoothly, does not resize camera)
          if (isWaitingForBack)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: CapturedThumbnailTray(
                frontPhoto: _frontPhoto!,
                onRetakeFront: _handleRetakeFront,
              ),
            )
          else
            const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLandscapeCameraView(bool isWaitingForBack) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Viewfinder taking full available height and proper aspect ratio
          Expanded(
            child: Center(
              child: CameraViewfinder(
                controller: _cameraController,
                isCameraInitialized: _isCameraInitialized,
                isFlashOn: _isFlashOn,
                onToggleFlash: _handleToggleFlash,
                onSwitchLens: _handleSwitchLens,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Right: Compact control column ergonomically placed for thumb tapping
          Container(
            width: 155,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                // Step badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isWaitingForBack
                        ? const Color(0xFF0D9488).withValues(alpha: 0.12)
                        : const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isWaitingForBack ? Icons.flip : Icons.camera_enhance,
                        size: 13,
                        color: isWaitingForBack
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF1E3A8A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isWaitingForBack ? 'Back (2/2)' : 'Front (1/2)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isWaitingForBack
                              ? const Color(0xFF0D9488)
                              : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),

                // Big capture button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CaptureButton(
                      onCapture: _handleCapture,
                      isBusy: _isCapturing,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isWaitingForBack ? 'Capture Back' : 'Capture Front',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),

                // Bottom utility button: Retake front or server host
                if (isWaitingForBack)
                  InkWell(
                    onTap: _handleRetakeFront,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 12,
                            color: Color(0xFFD97706),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Retake Front',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: _showServerConfigDialog,
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_outlined,
                          size: 12,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            ApiConfig.serverHost,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
