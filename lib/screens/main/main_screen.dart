import 'package:flutter/material.dart';
import '../../services/card_upload_service.dart';
import '../camera/camera_capture_screen.dart';
import '../create_customer/create_customer_screen.dart';
import '../customers/customer_list_screen.dart';
import 'widgets/app_drawer.dart';
import 'widgets/crm_app_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  ExtractedCardDetails? _pendingCardDetails;

  final List<Map<String, String>> _pageMetadata = [
    {
      'title': 'Camera Capture',
      'subtitle': 'Live viewfinder & card scanner',
    },
    {
      'title': 'Customer Directory',
      'subtitle': 'Manage and inspect client records',
    },
    {
      'title': 'New Customer',
      'subtitle': 'Enter customer information manually',
    },
  ];

  void _navigateToPage(int index) {
    if (index >= 0 && index < 3) {
      setState(() => _currentIndex = index);
    }
  }

  void _navigateToCreateWithCard(ExtractedCardDetails details) {
    setState(() {
      _pendingCardDetails = details;
      _currentIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _pageMetadata[_currentIndex];

    final pages = [
      CameraCaptureScreen(
        onNavigateToCreate: () => _navigateToPage(2),
        onAttachToLead: _navigateToCreateWithCard,
      ),
      CustomerListScreen(
        onNavigateToCreate: () => _navigateToPage(2),
      ),
      CreateCustomerScreen(
        initialCardDetails: _pendingCardDetails,
        onCustomerCreated: () {
          setState(() => _pendingCardDetails = null);
          _navigateToPage(1);
        },
      ),
    ];

    return Scaffold(
      appBar: CRMAppBar(
        title: currentPage['title']!,
        subtitle: currentPage['subtitle']!,
      ),
      drawer: AppDrawer(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigateToPage,
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
    );
  }
}
