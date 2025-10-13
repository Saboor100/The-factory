// lib/pages/Events/my_registrations_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_registration_model.dart';
import '../../services/event_service.dart';
import 'ticket_viewer_screen.dart';

class MyRegistrationsScreen extends StatefulWidget {
  const MyRegistrationsScreen({Key? key}) : super(key: key);

  @override
  State<MyRegistrationsScreen> createState() => _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState extends State<MyRegistrationsScreen> {
  final EventService _eventService = EventService();
  List<UserRegistration> _registrations = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all'; // all, upcoming, past, paid, pending

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  Future<void> _loadRegistrations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = userProvider.user.token;

      final response = await _eventService.getUserRegistrations();

      if (response.success && response.data != null) {
        setState(() {
          _registrations = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load registrations';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  List<UserRegistration> get _filteredRegistrations {
    final now = DateTime.now();

    return _registrations.where((reg) {
      switch (_filter) {
        case 'upcoming':
          return reg.event.startDate.isAfter(now);
        case 'past':
          return reg.event.endDate.isBefore(now);
        case 'paid':
          return reg.paymentStatus == 'paid';
        case 'pending':
          return reg.paymentStatus == 'pending';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('My Registrations'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRegistrations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Upcoming', 'upcoming'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Past', 'past'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Paid', 'paid'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'pending'),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFB8FF00),
                      ),
                    )
                    : _error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadRegistrations,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB8FF00),
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : _filteredRegistrations.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filter == 'all'
                                ? 'No registrations yet'
                                : 'No $_filter registrations',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadRegistrations,
                      color: const Color(0xFFB8FF00),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRegistrations.length,
                        itemBuilder: (context, index) {
                          return _buildRegistrationCard(
                            _filteredRegistrations[index],
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
      backgroundColor: const Color(0xFF2A2A2A),
      selectedColor: const Color(0xFFB8FF00),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.black,
    );
  }

  Widget _buildRegistrationCard(UserRegistration registration) {
    final isPaid = registration.paymentStatus == 'paid';
    final isUpcoming = registration.event.startDate.isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid ? const Color(0xFFB8FF00) : const Color(0xFF3A3A3A),
          width: isPaid ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          if (registration.event.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                registration.event.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: const Color(0xFF3A3A3A),
                    child: const Icon(
                      Icons.event,
                      size: 64,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Title
                Text(
                  registration.event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Registration Details
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      registration.confirmationNumber,
                      style: const TextStyle(
                        color: Color(0xFFB8FF00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Date
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      registration.event.formattedDateRange,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        registration.event.location,
                        style: const TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Ticket Type
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    registration.ticketType,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount Paid',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          '\$${registration.paidAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFB8FF00),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isPaid
                                ? const Color(0xFFB8FF00).withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isPaid ? const Color(0xFFB8FF00) : Colors.orange,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPaid ? Icons.check_circle : Icons.pending,
                            size: 16,
                            color:
                                isPaid
                                    ? const Color(0xFFB8FF00)
                                    : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPaid ? 'Paid' : 'Pending',
                            style: TextStyle(
                              color:
                                  isPaid
                                      ? const Color(0xFFB8FF00)
                                      : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            isPaid
                                ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => TicketViewerScreen(
                                            registrationId: registration.id,
                                            confirmationNumber:
                                                registration.confirmationNumber,
                                          ),
                                    ),
                                  );
                                }
                                : null,
                        icon: const Icon(Icons.qr_code, size: 20),
                        label: const Text('View Ticket'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB8FF00),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: const Color(0xFF3A3A3A),
                          disabledForegroundColor: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isUpcoming && isPaid)
                      IconButton(
                        onPressed: () {
                          // TODO: Add to calendar functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Add to calendar feature coming soon',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_month),
                        color: const Color(0xFFB8FF00),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF3A3A3A),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
