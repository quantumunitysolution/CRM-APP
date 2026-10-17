import 'package:flutter/material.dart';
import '../../../models/customer.dart';
import '../../../services/card_upload_service.dart';
import '../../../services/customer_service.dart';
import 'widgets/avatar_selector_header.dart';
import 'widgets/customer_form_field.dart';
import 'widgets/customer_type_selector.dart';

class CreateCustomerScreen extends StatefulWidget {
  final VoidCallback? onCustomerCreated;
  final ExtractedCardDetails? initialCardDetails;

  const CreateCustomerScreen({
    super.key,
    this.onCustomerCreated,
    this.initialCardDetails,
  });

  @override
  State<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends State<CreateCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  CustomerStatus _selectedStatus = CustomerStatus.lead;
  bool _isSubmitting = false;

  String? _cardCategory;
  String? _cardWebsite;
  List<String> _cardPhoneNumbers = [];
  List<String> _cardOwnerNames = [];
  String? _cardFrontDriveUrl;
  String? _cardBackDriveUrl;
  double? _cardLatitude;
  double? _cardLongitude;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    if (widget.initialCardDetails != null) {
      _applyCardDetails(widget.initialCardDetails!);
    }
  }

  @override
  void didUpdateWidget(CreateCustomerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCardDetails != null && widget.initialCardDetails != oldWidget.initialCardDetails) {
      _applyCardDetails(widget.initialCardDetails!);
    }
  }

  void _applyCardDetails(ExtractedCardDetails details) {
    _cardCategory = details.category;
    _cardWebsite = details.website;
    _cardPhoneNumbers = details.phoneNumbers;
    _cardOwnerNames = details.ownerNames;
    _cardFrontDriveUrl = details.frontDriveUrl;
    _cardBackDriveUrl = details.backDriveUrl;
    _cardLatitude = details.latitude;
    _cardLongitude = details.longitude;

    if (details.ownerNames.isNotEmpty) {
      _nameController.text = details.ownerNames.join(', ');
    }
    if (details.businessName?.isNotEmpty == true) {
      _companyController.text = details.businessName!;
    }
    if (details.phoneNumbers.isNotEmpty) {
      _phoneController.text = details.phoneNumbers.first;
    }
    if (details.email?.isNotEmpty == true) {
      _emailController.text = details.email!;
    }
    if (details.address?.isNotEmpty == true) {
      _addressController.text = details.address!;
    }
    if (details.category?.isNotEmpty == true) {
      _notesController.text = 'Category: ${details.category!}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    // Build customer entity
    final newCustomer = Customer(
      id: 'cust_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      company: _companyController.text.trim(),
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      status: _selectedStatus,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
      category: _cardCategory ?? 'General Business',
      website: _cardWebsite,
      ownerNames: _cardOwnerNames.isNotEmpty ? _cardOwnerNames : [_nameController.text.trim()],
      phoneNumbers: _cardPhoneNumbers.isNotEmpty ? _cardPhoneNumbers : [_phoneController.text.trim()],
      frontDriveUrl: _cardFrontDriveUrl,
      backDriveUrl: _cardBackDriveUrl,
      latitude: _cardLatitude,
      longitude: _cardLongitude,
    );

    try {
      // =======================================================================
      // BACKEND INTEGRATION POINT:
      // In production, CustomerService.createCustomer(newCustomer)
      // calls POST /api/v1/customers with serialized JSON payload.
      // =======================================================================
      await _customerService.createCustomer(newCustomer);

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog(newCustomer);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save customer: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _companyController.clear();
    _addressController.clear();
    _notesController.clear();
    setState(() => _selectedStatus = CustomerStatus.lead);
  }

  void _showSuccessDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Text('Customer Created', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Customer "${customer.name}" for ${customer.company} has been added successfully.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            child: const Text('Add Another'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
              widget.onCustomerCreated?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              minimumSize: const Size(120, 40),
            ),
            child: const Text('View in List'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialLetter = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Customer Record',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Enter customer and lead profile details manually into CRM',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.initialCardDetails != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pre-filled from: ${widget.initialCardDetails?.businessName ?? "Business Card"}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Avatar placeholder with camera prompt
              AvatarSelectorHeader(
                initialLetter: initialLetter,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Avatar image upload placeholder'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Form fields
              CustomerFormField(
                label: 'Full Name',
                hint: 'e.g. Jane Doe',
                prefixIcon: Icons.person_outline,
                controller: _nameController,
                isRequired: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the customer name';
                  }
                  return null;
                },
              ),

              CustomerFormField(
                label: 'Company / Organization',
                hint: 'e.g. Horizon Technologies',
                prefixIcon: Icons.business_outlined,
                controller: _companyController,
                isRequired: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the company name';
                  }
                  return null;
                },
              ),

              CustomerFormField(
                label: 'Email Address',
                hint: 'e.g. jane.doe@company.com',
                prefixIcon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                isRequired: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the email address';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(val.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              CustomerFormField(
                label: 'Phone Number',
                hint: 'e.g. +1 (555) 019-2834',
                prefixIcon: Icons.phone_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                isRequired: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the contact number';
                  }
                  return null;
                },
              ),

              CustomerFormField(
                label: 'Office Address / Location (Optional)',
                hint: 'e.g. Suite 400, 100 Main St, Chicago, IL',
                prefixIcon: Icons.location_on_outlined,
                controller: _addressController,
              ),

              // Status Selector
              CustomerTypeSelector(
                selectedStatus: _selectedStatus,
                onStatusChanged: (status) => setState(() => _selectedStatus = status),
              ),

              // Notes / Requirements
              CustomerFormField(
                label: 'Internal Notes / Requirements',
                hint: 'Add initial requirements, meeting takeaways, or next steps...',
                prefixIcon: Icons.notes_outlined,
                controller: _notesController,
                maxLines: 4,
              ),

              const SizedBox(height: 10),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _resetForm,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add_alt_1, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Save Customer',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
