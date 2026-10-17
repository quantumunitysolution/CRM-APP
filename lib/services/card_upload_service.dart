import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Structured business card details extracted by Gemini AI
class ExtractedCardDetails {
  final String? businessName;
  final List<String> ownerNames;
  final List<String> phoneNumbers;
  final String? address;
  final String? email;
  final String? website;
  final String? category;
  final String? frontDriveUrl;
  final String? backDriveUrl;
  final double? latitude;
  final double? longitude;

  const ExtractedCardDetails({
    this.businessName,
    this.ownerNames = const [],
    this.phoneNumbers = const [],
    this.address,
    this.email,
    this.website,
    this.category,
    this.frontDriveUrl,
    this.backDriveUrl,
    this.latitude,
    this.longitude,
  });

  ExtractedCardDetails copyWith({
    String? businessName,
    List<String>? ownerNames,
    List<String>? phoneNumbers,
    String? address,
    String? email,
    String? website,
    String? category,
    String? frontDriveUrl,
    String? backDriveUrl,
    double? latitude,
    double? longitude,
  }) {
    return ExtractedCardDetails(
      businessName: businessName ?? this.businessName,
      ownerNames: ownerNames ?? this.ownerNames,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      address: address ?? this.address,
      email: email ?? this.email,
      website: website ?? this.website,
      category: category ?? this.category,
      frontDriveUrl: frontDriveUrl ?? this.frontDriveUrl,
      backDriveUrl: backDriveUrl ?? this.backDriveUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory ExtractedCardDetails.fromJson(Map<String, dynamic> json) {
    return ExtractedCardDetails(
      businessName: json['businessName'] as String?,
      ownerNames:
          (json['ownerNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      phoneNumbers:
          (json['phoneNumbers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      address: json['address'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      category: json['category'] as String?,
      frontDriveUrl: json['frontDriveUrl'] as String?,
      backDriveUrl: json['backDriveUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Represents the response received from the backend card upload endpoint.
class CardUploadResult {
  final bool success;
  final String message;
  final double? latitude;
  final double? longitude;
  final String? frontId;
  final String? frontViewLink;
  final String? frontDownloadLink;
  final String? backId;
  final String? backViewLink;
  final String? backDownloadLink;
  final ExtractedCardDetails? cardDetails;
  final bool isLocalFallback;
  final String? error;
  final bool isProcessing;
  final String? jobId;

  const CardUploadResult({
    required this.success,
    required this.message,
    this.latitude,
    this.longitude,
    this.frontId,
    this.frontViewLink,
    this.frontDownloadLink,
    this.backId,
    this.backViewLink,
    this.backDownloadLink,
    this.cardDetails,
    this.isLocalFallback = false,
    this.error,
    this.isProcessing = false,
    this.jobId,
  });

  factory CardUploadResult.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final uploads = json['uploads'] as Map<String, dynamic>?;
    final front = uploads?['front'] as Map<String, dynamic>?;
    final back = uploads?['back'] as Map<String, dynamic>?;
    final cardDetailsJson = json['cardDetails'] as Map<String, dynamic>?;
    final isProcessing = json['isProcessing'] as bool? ??
        (json['status'] == 'queued' || json['status'] == 'processing');
    final jobId = json['jobId'] as String?;

    final lat = location?['latitude'] != null
        ? (location!['latitude'] as num).toDouble()
        : null;
    final lng = location?['longitude'] != null
        ? (location!['longitude'] as num).toDouble()
        : null;
    final frontView = front?['webViewLink'] as String?;
    final backView = back?['webViewLink'] as String?;

    ExtractedCardDetails? parsedDetails;
    if (cardDetailsJson != null) {
      parsedDetails = ExtractedCardDetails.fromJson(cardDetailsJson).copyWith(
        frontDriveUrl: frontView,
        backDriveUrl: backView,
        latitude: lat,
        longitude: lng,
      );
    }

    return CardUploadResult(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? 'Uploaded successfully',
      latitude: lat,
      longitude: lng,
      frontId: front?['id'] as String?,
      frontViewLink: frontView,
      frontDownloadLink: front?['webContentLink'] as String?,
      backId: back?['id'] as String?,
      backViewLink: backView,
      backDownloadLink: back?['webContentLink'] as String?,
      cardDetails: parsedDetails,
      isLocalFallback: front?['isLocalFallback'] as bool? ?? false,
      isProcessing: isProcessing,
      jobId: jobId,
    );
  }

  factory CardUploadResult.failure(String errorMessage) {
    return CardUploadResult(
      success: false,
      message: errorMessage,
      error: errorMessage,
      isProcessing: false,
    );
  }
}

/// Service to handle uploading card images and location to the backend API.
class CardUploadService {
  static final CardUploadService _instance = CardUploadService._internal();
  factory CardUploadService() => _instance;
  CardUploadService._internal();

  /// Checks if the backend server is reachable.
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.healthUrl))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend health check error: $e');
      return false;
    }
  }

  /// Uploads front and back photos with GPS coordinates to the server.
  Future<CardUploadResult> uploadCardImages({
    required XFile frontPhoto,
    required XFile backPhoto,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.uploadCardsUrl);
      final request = http.MultipartRequest('POST', uri);

      // Add API Key and headers
      request.headers.addAll(ApiConfig.authHeaders);

      // Add GPS coordinates
      if (latitude != null) {
        request.fields['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        request.fields['longitude'] = longitude.toString();
      }

      // Read file bytes for robust cross-platform multipart support (Web, Android, iOS, Windows)
      final frontBytes = await frontPhoto.readAsBytes();
      final backBytes = await backPhoto.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'frontImage',
          frontBytes,
          filename: frontPhoto.name.isNotEmpty
              ? frontPhoto.name
              : 'front_card.jpg',
        ),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'backImage',
          backBytes,
          filename: backPhoto.name.isNotEmpty
              ? backPhoto.name
              : 'back_card.jpg',
        ),
      );

      debugPrint('Uploading card photos to: ${ApiConfig.uploadCardsUrl}');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
      );
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 202) {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        return CardUploadResult.fromJson(decoded);
      } else {
        String errorMsg =
            'Server responded with status: ${streamedResponse.statusCode}';
        try {
          final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
          if (decoded.containsKey('message')) {
            errorMsg = decoded['message'] as String;
          } else if (decoded.containsKey('error')) {
            errorMsg = decoded['error'] as String;
          }
        } catch (_) {}
        return CardUploadResult.failure(errorMsg);
      }
    } catch (e) {
      debugPrint('Card upload exception: $e');
      return CardUploadResult.failure(
        'Failed to connect to backend server: $e',
      );
    }
  }
}
