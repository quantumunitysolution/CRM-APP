import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/customer.dart';
import '../../../services/customer_service.dart';
import 'customer_category_badge.dart';

class CustomerDetailBottomSheet extends StatefulWidget {
  final String customerId;
  final Customer? initialCustomer;

  const CustomerDetailBottomSheet({
    super.key,
    required this.customerId,
    this.initialCustomer,
  });

  /// Static helper to display the bottom sheet cleanly from any context
  static Future<void> show(
    BuildContext context, {
    required String customerId,
    Customer? initialCustomer,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerDetailBottomSheet(
        customerId: customerId,
        initialCustomer: initialCustomer,
      ),
    );
  }

  @override
  State<CustomerDetailBottomSheet> createState() => _CustomerDetailBottomSheetState();
}

class _CustomerDetailBottomSheetState extends State<CustomerDetailBottomSheet> {
  late Future<Customer> _customerDetailsFuture;
  final CustomerService _customerService = CustomerService();

  @override
  void initState() {
    super.initState();
    _customerDetailsFuture = _customerService.getCustomerDetails(widget.customerId);
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final sheetHeight = mediaQuery.size.height * 0.85;

    return SizedBox(
      height: sheetHeight,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header bar with title and close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Business Card Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Body with FutureBuilder for backend call
              Expanded(
                child: FutureBuilder<Customer>(
                  future: _customerDetailsFuture,
                  initialData: widget.initialCustomer,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(48.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(strokeWidth: 2.5),
                              SizedBox(height: 16),
                              Text(
                                'Loading business card record...',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                'Error loading card: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final customer = snapshot.data!;
                    return _buildCustomerContent(context, customer);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerContent(BuildContext context, Customer customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile hero section
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: customer.avatarUrl != null
                    ? Image.network(
                        customer.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            customer.initials,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          customer.initials,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Business Name, Contact Person & Category Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.company.isNotEmpty ? customer.company : customer.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer.name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CustomerCategoryBadge(
                      category: customer.category,
                      fontSize: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Google Drive Card Links Section
          _buildDriveSection(context, customer),

          const SizedBox(height: 16),

          // All Contact Information
          _buildInfoSection(
            title: 'Contact Information',
            icon: Icons.contact_phone_outlined,
            children: [
              // Phone numbers
              if (customer.phoneNumbers.isNotEmpty)
                ...customer.phoneNumbers.map((phone) => _buildCopyableRow(
                      context,
                      icon: Icons.phone_outlined,
                      title: 'Phone Number',
                      value: phone,
                    ))
              else if (customer.phone.isNotEmpty)
                _buildCopyableRow(
                  context,
                  icon: Icons.phone_outlined,
                  title: 'Phone Number',
                  value: customer.phone,
                ),

              // Email
              if (customer.email.isNotEmpty)
                _buildCopyableRow(
                  context,
                  icon: Icons.email_outlined,
                  title: 'Email Address',
                  value: customer.email,
                ),

              // Website
              if (customer.website != null && customer.website!.isNotEmpty)
                _buildCopyableRow(
                  context,
                  icon: Icons.language_outlined,
                  title: 'Website',
                  value: customer.website!,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Location & GPS Information
          _buildInfoSection(
            title: 'Location & GPS Details',
            icon: Icons.location_on_outlined,
            children: [
              if (customer.address != null && customer.address!.isNotEmpty)
                _buildCopyableRow(
                  context,
                  icon: Icons.business_outlined,
                  title: 'Physical Address',
                  value: customer.address!,
                ),
              if (customer.latitude != null && customer.longitude != null)
                _buildCopyableRow(
                  context,
                  icon: Icons.my_location,
                  title: 'GPS Geo-Coordinates',
                  value: 'Lat: ${customer.latitude!.toStringAsFixed(7)}, Long: ${customer.longitude!.toStringAsFixed(7)}',
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Key Owners & Contacts Section
          if (customer.ownerNames.isNotEmpty)
            _buildInfoSection(
              title: 'Owner & Key Executives',
              icon: Icons.people_outline,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: customer.ownerNames.map((owner) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 14, color: Color(0xFF1E3A8A)),
                          const SizedBox(width: 6),
                          Text(
                            owner,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

          if (customer.ownerNames.isNotEmpty) const SizedBox(height: 16),

          // Extracted Card Notes & Business Details
          _buildInfoSection(
            title: 'Card Details & Extracted Notes',
            icon: Icons.description_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  customer.notes.isNotEmpty ? customer.notes : 'No extra notes recorded from business card.',
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Metadata Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_done_outlined, size: 18, color: Color(0xFF0D9488)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Card ID: ${customer.id}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Added: ${_formatDate(customer.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriveSection(BuildContext context, Customer customer) {
    final hasFront = customer.frontDriveUrl != null && customer.frontDriveUrl!.isNotEmpty;
    final hasBack = customer.backDriveUrl != null && customer.backDriveUrl!.isNotEmpty;
    final hasFolder = customer.driveUrl != null && customer.driveUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_done, size: 18, color: Color(0xFF15803D)),
              SizedBox(width: 8),
              Text(
                'Google Drive Card Scans',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF15803D),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasFront)
            _buildDriveLinkCard(
              context,
              label: 'Front Card Photo (Drive Link)',
              url: customer.frontDriveUrl!,
            ),
          if (hasBack) ...[
            const SizedBox(height: 8),
            _buildDriveLinkCard(
              context,
              label: 'Back Card Photo (Drive Link)',
              url: customer.backDriveUrl!,
            ),
          ],
          if (hasFolder) ...[
            const SizedBox(height: 8),
            _buildDriveLinkCard(
              context,
              label: 'Drive Folder / Backup',
              url: customer.driveUrl!,
            ),
          ],
          if (!hasFront && !hasBack && !hasFolder)
            const Text(
              'No Google Drive scan link associated yet.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
        ],
      ),
    );
  }

  Widget _buildDriveLinkCard(
    BuildContext context, {
    required String label,
    required String url,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 20, color: Color(0xFF15803D)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF14532D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF2563EB),
                    decoration: TextDecoration.underline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 18, color: Color(0xFF15803D)),
            tooltip: 'Copy Link',
            onPressed: () => _copyToClipboard(context, url, label),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF475569)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCopyableRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _copyToClipboard(context, value, title),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 17, color: const Color(0xFF64748B)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.copy_outlined, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
