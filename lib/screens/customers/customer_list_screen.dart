import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/customer.dart';
import '../../../services/customer_service.dart';
import 'widgets/customer_card.dart';
import 'widgets/customer_search_bar.dart';

class CustomerListScreen extends StatefulWidget {
  final VoidCallback? onNavigateToCreate;

  const CustomerListScreen({
    super.key,
    this.onNavigateToCreate,
  });

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();

  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  StreamSubscription<List<Customer>>? _customersSubscription;

  @override
  void initState() {
    super.initState();
    _loadCustomers();

    // Listen for customer additions from Create Customer screen
    _customersSubscription = _customerService.customersStream.listen((updatedList) {
      if (mounted) {
        setState(() {
          _allCustomers = updatedList;
          _applyFilters();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    // =========================================================================
    // BACKEND INTEGRATION POINT:
    // Future integration with GET /api/v1/customers
    // =========================================================================
    final customers = await _customerService.getCustomers();
    if (mounted) {
      setState(() {
        _allCustomers = customers;
        _isLoading = false;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredCustomers = _allCustomers.where((c) {
        final matchesQuery = query.isEmpty ||
            c.name.toLowerCase().contains(query) ||
            c.company.toLowerCase().contains(query) ||
            c.category.toLowerCase().contains(query) ||
            c.phone.toLowerCase().contains(query) ||
            c.email.toLowerCase().contains(query);

        final matchesCategory = _selectedFilter == 'All' ||
            c.category.toLowerCase() == _selectedFilter.toLowerCase();

        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCustomers,
          color: const Color(0xFF1E3A8A),
          child: Column(
            children: [
              // Search Bar
              CustomerSearchBar(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                onClear: () {
                  _searchController.clear();
                  _applyFilters();
                },
              ),

              // Filter status chips
              _buildFilterChips(),

              // List Header stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${_filteredCustomers.length} ${_filteredCustomers.length == 1 ? "Customer" : "Customers"}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    InkWell(
                      onTap: _loadCustomers,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 14, color: Color(0xFF3B82F6)),
                            SizedBox(width: 4),
                            Text(
                              'Refresh',
                              style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Customer List View
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : _filteredCustomers.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 80, top: 4),
                            itemCount: _filteredCustomers.length,
                            itemBuilder: (context, index) {
                              return CustomerCard(customer: _filteredCustomers[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final uniqueCategories = _allCustomers
        .map((c) => c.category.trim())
        .where((cat) => cat.isNotEmpty)
        .toSet()
        .toList();
    final filters = ['All', ...uniqueCategories];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                    _applyFilters();
                  });
                }
              },
              selectedColor: const Color(0xFF1E3A8A),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_outlined,
                size: 48,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Customers Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing your search keywords or add a new customer manually.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            if (widget.onNavigateToCreate != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: widget.onNavigateToCreate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Customer Manually'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 44),
                  backgroundColor: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
