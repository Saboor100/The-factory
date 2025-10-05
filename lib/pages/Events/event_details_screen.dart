// lib/pages/Events/event_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'event_registration_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isLocalLoading = false;
  String? _localError;
  Event? _localEvent;

  @override
  void initState() {
    super.initState();
    print('🚀 EventDetailsScreen initiated with eventId: ${widget.eventId}');
    _loadEventDetails();
  }

  Future<void> _loadEventDetails() async {
    setState(() {
      _isLocalLoading = true;
      _localError = null;
    });

    try {
      final eventService = EventService();
      final response = await eventService.getEventById(widget.eventId);

      if (response.success && response.data != null) {
        _localEvent = response.data!;
        context.read<EventProvider>().updateEvent(_localEvent!);
      } else {
        _localError = response.error ?? 'Failed to load';
      }
    } catch (e) {
      _localError = 'Network error: $e';
    } finally {
      setState(() {
        _isLocalLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: _buildContent(),
      floatingActionButton:
          _localEvent != null &&
                  _localEvent!.isRegistrationOpen &&
                  _localEvent!.hasAvailableSpots
              ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              EventRegistrationScreen(event: _localEvent!),
                    ),
                  );
                },
                backgroundColor: const Color(0xFFB8FF00),
                foregroundColor: Colors.black,
                icon: const Icon(Icons.app_registration),
                label: const Text(
                  'Register Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
              : null,
    );
  }

  Widget _buildContent() {
    // Loading state
    if (_isLocalLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFB8FF00)),
              SizedBox(height: 16),
              Text(
                'Loading event details...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
    if (_localError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          title: const Text('Event Details'),
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Error Loading Event',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _localError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Event ID: ${widget.eventId}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loadEventDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB8FF00),
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'Retry',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Go Back',
                        style: TextStyle(color: Color(0xFFB8FF00)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Event not found state
    if (_localEvent == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          title: const Text('Event Details'),
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 80, color: Colors.grey[600]),
              const SizedBox(height: 24),
              Text(
                'Event Not Found',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The event you\'re looking for doesn\'t exist or has been removed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8FF00),
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Success state
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: _buildEventDetails(context, _localEvent!),
    );
  }

  Widget _buildEventDetails(BuildContext context, Event event) {
    return CustomScrollView(
      slivers: [
        // App Bar with Image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              event.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
            background:
                event.imageUrl != null
                    ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          event.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage(event);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFB8FF00),
                              ),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                    : _buildPlaceholderImage(event),
          ),
        ),

        // Event Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badges
                _buildStatusBadges(event),
                const SizedBox(height: 20),

                // Basic Info
                _buildBasicInfo(event),
                const SizedBox(height: 24),

                // Description
                _buildDescription(event),
                const SizedBox(height: 24),

                // Ticket Types
                if (event.ticketTypes.isNotEmpty) ...[
                  _buildTicketTypes(event),
                  const SizedBox(height: 24),
                ],

                // Organizer Info
                _buildOrganizerInfo(event),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage(Event event) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(event.category),
            _getCategoryColor(event.category).withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, size: 80, color: Colors.white.withOpacity(0.9)),
            const SizedBox(height: 12),
            Text(
              event.categoryDisplayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadges(Event event) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (event.isFeatured)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'FEATURED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getCategoryColor(event.category),
              width: 2,
            ),
          ),
          child: Text(
            event.categoryDisplayName,
            style: TextStyle(
              color: _getCategoryColor(event.category),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                event.isRegistrationOpen
                    ? const Color(0xFFB8FF00)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  event.isRegistrationOpen
                      ? const Color(0xFFB8FF00)
                      : Colors.red,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                event.isRegistrationOpen ? Icons.check_circle : Icons.cancel,
                size: 14,
                color: event.isRegistrationOpen ? Colors.black : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                event.isRegistrationOpen
                    ? 'Registration Open'
                    : 'Registration Closed',
                style: TextStyle(
                  color: event.isRegistrationOpen ? Colors.black : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfo(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.calendar_today, 'Date', event.formattedDateRange),
        const SizedBox(height: 12),
        _buildInfoRow(Icons.location_on, 'Location', event.location),
        const SizedBox(height: 12),
        _buildInfoRow(
          Icons.access_time,
          'Registration Deadline',
          '${event.registrationDeadline.day}/${event.registrationDeadline.month}/${event.registrationDeadline.year}',
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          Icons.people,
          'Total Registrations',
          '${event.totalRegistrations} participants',
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFB8FF00).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFFB8FF00)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About This Event',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3A3A3A)),
          ),
          child: Text(
            event.description,
            style: TextStyle(
              height: 1.6,
              color: Colors.grey[300],
              fontSize: 15,
            ),
          ),
        ),
        if (event.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Tags',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                event.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFB8FF00),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB8FF00),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTicketTypes(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ticket Types',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...event.ticketTypes.map((ticket) => _buildTicketTypeCard(ticket)),
      ],
    );
  }

  Widget _buildTicketTypeCard(TicketType ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ticket.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8FF00).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${ticket.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB8FF00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ticket.description,
            style: TextStyle(color: Colors.grey[400], height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Available: ${ticket.availableSpots}/${ticket.maxCapacity}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      ticket.hasAvailableSpots
                          ? const Color(0xFFB8FF00)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        ticket.hasAvailableSpots
                            ? const Color(0xFFB8FF00)
                            : Colors.red,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ticket.hasAvailableSpots
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 12,
                      color:
                          ticket.hasAvailableSpots ? Colors.black : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ticket.hasAvailableSpots ? 'Available' : 'Sold Out',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            ticket.hasAvailableSpots
                                ? Colors.black
                                : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerInfo(Event event) {
    final hasOrganizerName = event.organizerName.isNotEmpty;
    final hasOrganizerEmail = event.organizerEmail.isNotEmpty;
    final hasOrganizerPhone =
        event.organizerPhone != null && event.organizerPhone!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organizer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3A3A3A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8FF00).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFFB8FF00),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasOrganizerName
                          ? event.organizerName
                          : 'Event Organizer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: hasOrganizerName ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email
              if (hasOrganizerEmail)
                _buildContactRow(Icons.email, event.organizerEmail)
              else
                _buildContactRow(
                  Icons.email,
                  'Email not provided',
                  isPlaceholder: true,
                ),

              // Phone
              if (hasOrganizerPhone) ...[
                const SizedBox(height: 12),
                _buildContactRow(Icons.phone, event.organizerPhone!),
              ] else ...[
                const SizedBox(height: 12),
                _buildContactRow(
                  Icons.phone,
                  'Phone not provided',
                  isPlaceholder: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String value, {
    bool isPlaceholder = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isPlaceholder ? Colors.grey[700] : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isPlaceholder ? Colors.grey[700] : Colors.grey[300],
              fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'lacrosse_camp':
        return Colors.blue;
      case 'tournament':
        return Colors.red;
      case 'clinic':
        return Colors.green;
      case 'workshop':
        return Colors.orange;
      case 'training':
        return Colors.purple;
      case 'social':
        return Colors.pink;
      case 'fundraiser':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
