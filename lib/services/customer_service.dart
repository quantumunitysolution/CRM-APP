import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/customer.dart';
import 'api_config.dart';

/// [CustomerService] manages all customer data operations.
/// 
/// Connects to the Node.js backend server and Google Apps Script to fetch live
/// business card records from Google Sheets, with seamless offline and cache fallback.
class CustomerService {
  // Singleton pattern for centralized in-memory customer repository
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal() {
    _customers = List.from(_initialSeedCustomers);
  }

  // In-memory data store for live additions
  late List<Customer> _customers;

  // Stream controller to broadcast updates when new customers are added
  final _customersStreamController = StreamController<List<Customer>>.broadcast();
  Stream<List<Customer>> get customersStream => _customersStreamController.stream;

  /// Fetches all customers from Google Sheets via backend API.
  Future<List<Customer>> getCustomers({bool forceRefresh = false}) async {
    try {
      final uri = Uri.parse(ApiConfig.customersUrl);
      final response = await http
          .get(uri, headers: ApiConfig.authHeaders)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic>? recordsJson = decoded is Map<String, dynamic>
            ? (decoded['records'] as List<dynamic>?)
            : (decoded is List ? decoded : null);

        if (recordsJson != null && recordsJson.isNotEmpty) {
          final liveCustomers = recordsJson
              .map((item) => Customer.fromJson(item as Map<String, dynamic>))
              .toList();

          _customers = liveCustomers;
          _customersStreamController.add(List.unmodifiable(_customers));
          return List.unmodifiable(_customers);
        }
      }
    } catch (e) {
      debugPrint('Live customer fetch from Google Sheet backend notice (using local cache): $e');
    }

    return List.unmodifiable(_customers);
  }

  /// Fetches a specific customer's detailed record by ID for the bottom sheet.
  Future<Customer> getCustomerDetails(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _customers.firstWhere(
      (c) => c.id == customerId,
      orElse: () => throw Exception('Customer not found: $customerId'),
    );
  }

  /// Adds a new customer manually entered by the user.
  /// When connecting to backend:
  /// ```dart
  /// final response = await http.post(
  ///   Uri.parse('$_baseUrl/customers'),
  ///   headers: _headers,
  ///   body: jsonEncode(customer.toJson()),
  /// );
  /// if (response.statusCode == 201) {
  ///   return Customer.fromJson(jsonDecode(response.body));
  /// }
  /// ```
  Future<Customer> createCustomer(Customer customer) async {
    // Simulating backend network response
    await Future.delayed(const Duration(milliseconds: 500));
    _customers.insert(0, customer);
    _customersStreamController.add(List.unmodifiable(_customers));
    return customer;
  }

  // Seed sample customers with realistic CRM data and Google Drive links
  static final List<Customer> _initialSeedCustomers = [
    Customer(
      id: 'cust_patel_01',
      name: 'Chetan Patel',
      company: 'PATEL CERAMIC',
      category: 'Tiles & Sanitary Wares',
      email: 'patel.ceramic@yahoo.com',
      phone: '+91 85304 68085',
      phoneNumbers: const ['+91 85304 68085', '+91 98252 10987'],
      ownerNames: const ['Chetan Patel'],
      website: 'https://patelceramics.in',
      address: '150 Feet Ring Road, Near Mavdi Chokdi, Near Moonlight Marble, Rajkot-360004 (Guj.) INDIA.',
      status: CustomerStatus.active,
      frontDriveUrl: 'https://drive.google.com/file/d/1vK9_Patel_Front_Card_2026/view?usp=sharing',
      backDriveUrl: 'https://drive.google.com/file/d/1wZ2_Patel_Back_Card_2026/view?usp=sharing',
      driveUrl: 'https://drive.google.com/drive/folders/1Patel_Ceramics_Rajkot_CRM',
      latitude: 22.2631995,
      longitude: 70.7896219,
      notes: 'Floor Tiles, Vitrified Tiles, Wall Tiles, Sanitary Wares, Tiles Chemicals. Met during Rajkot ceramic expo.',
      createdAt: DateTime.now(),
    ),
    Customer(
      id: 'cust_apex_02',
      name: 'Vikram Shah',
      company: 'APEX SOFTWARE LABS PVT. LTD.',
      category: 'Software & IT Services',
      email: 'contact@apexsoftware.io',
      phone: '+91 98251 44320',
      phoneNumbers: const ['+91 98251 44320', '+91 79 4001 8899'],
      ownerNames: const ['Vikram Shah', 'Ananya Sen'],
      website: 'https://apexsoftware.io',
      address: '402 Titanium City Centre, Anandnagar Road, Prahladnagar, Ahmedabad-380015 (Guj.) INDIA.',
      status: CustomerStatus.active,
      frontDriveUrl: 'https://drive.google.com/file/d/1Apex_Software_Front_Card/view?usp=sharing',
      backDriveUrl: 'https://drive.google.com/file/d/1Apex_Software_Back_Card/view?usp=sharing',
      driveUrl: 'https://drive.google.com/drive/folders/1Apex_Software_Drive_Folder',
      latitude: 23.0225,
      longitude: 72.5714,
      notes: 'Enterprise Flutter mobile apps, Cloud DevOps, and Generative AI solutions provider.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Customer(
      id: 'cust_maruti_03',
      name: 'Rajeshbhai Patel',
      company: 'MARUTI TEXTILES & EXPORTS',
      category: 'Textiles & Garments',
      email: 'marutitextiles@gmail.com',
      phone: '+91 94282 11090',
      phoneNumbers: const ['+91 94282 11090'],
      ownerNames: const ['Rajeshbhai Patel'],
      website: 'https://marutitextiles.com',
      address: 'Shop 214, Surat Textile Market (STM), Ring Road, Surat-395002 (Guj.) INDIA.',
      status: CustomerStatus.lead,
      frontDriveUrl: 'https://drive.google.com/file/d/1Maruti_Textiles_Front_Card/view?usp=sharing',
      backDriveUrl: 'https://drive.google.com/file/d/1Maruti_Textiles_Back_Card/view?usp=sharing',
      driveUrl: 'https://drive.google.com/drive/folders/1Maruti_Textiles_Drive',
      latitude: 21.1702,
      longitude: 72.8311,
      notes: 'Cotton fabrics, polyester blends, digital print sarees and dress materials manufacturer.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Customer(
      id: 'cust_quantum_04',
      name: 'Dr. Meera Joshi',
      company: 'QUANTUM HEALTHCARE & PHARMA',
      category: 'Healthcare & Pharma',
      email: 'info@quantumpharma.org',
      phone: '+91 80005 67890',
      phoneNumbers: const ['+91 80005 67890', '+91 265 264 5500'],
      ownerNames: const ['Dr. Meera Joshi'],
      website: 'https://quantumpharma.org',
      address: 'Plot B-12 GIDC Estate, Makarpura, Vadodara-390010 (Guj.) INDIA.',
      status: CustomerStatus.prospect,
      frontDriveUrl: 'https://drive.google.com/file/d/1Quantum_Pharma_Front_Card/view?usp=sharing',
      backDriveUrl: 'https://drive.google.com/file/d/1Quantum_Pharma_Back_Card/view?usp=sharing',
      driveUrl: 'https://drive.google.com/drive/folders/1Quantum_Pharma_Drive',
      latitude: 22.2587,
      longitude: 73.1924,
      notes: 'Pharmaceutical formulations, generic tablets, syrups and WHO-GMP approved plant.',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Customer(
      id: 'cust_shreeji_05',
      name: 'Haresh Makwana',
      company: 'SHREEJI LOGISTICS & SUPPLY',
      category: 'Logistics & Transport',
      email: 'dispatch@shreejilogistics.in',
      phone: '+91 97243 55667',
      phoneNumbers: const ['+91 97243 55667', '+91 99240 12399'],
      ownerNames: const ['Haresh Makwana'],
      website: 'https://shreejilogistics.in',
      address: 'Transport Nagar, Kuvadva Road, Rajkot-360003 (Guj.) INDIA.',
      status: CustomerStatus.active,
      frontDriveUrl: 'https://drive.google.com/file/d/1Shreeji_Logistics_Front_Card/view?usp=sharing',
      backDriveUrl: 'https://drive.google.com/file/d/1Shreeji_Logistics_Back_Card/view?usp=sharing',
      driveUrl: 'https://drive.google.com/drive/folders/1Shreeji_Logistics_Drive',
      latitude: 22.3039,
      longitude: 70.8022,
      notes: 'All-India cargo transport, full-truck load (FTL), GPS tracking & warehousing services.',
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
  ];
}
