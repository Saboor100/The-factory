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
        context.read<EventProvider>().updateEvent(_localEvent!); // update cache
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
                icon: const Icon(Icons.app_registration),
                label: const Text('Register Now'),
              )
              : null,
    );
  }

  Widget _buildContent() {
    // Loading state
    if (_isLocalLoading) {
      return const Scaffold(
        appBar: null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading event details...'),
            ],
          ),
        ),
      );
    }

    // Error state
    if (_localError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Event Details'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                const SizedBox(height: 24),
                Text(
                  'Error Loading Event',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _localError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Event ID: ${widget.eventId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loadEventDetails,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
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
        appBar: AppBar(
          title: const Text('Event Details'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'Event Not Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The event you\'re looking for doesn\'t exist or has been removed.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Success state - show event details
    return Scaffold(body: _buildEventDetails(context, _localEvent!));
  }

  Widget _buildEventDetails(BuildContext context, Event event) {
    return CustomScrollView(
      slivers: [
        // App Bar with Image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: Theme.of(context).primaryColor,
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
                    color: Colors.black54,
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
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                color: Colors.white,
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
                                Colors.black.withOpacity(0.3),
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

                const SizedBox(height: 100), // Space for floating button
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
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
            color: _getCategoryColor(event.category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _getCategoryColor(event.category)),
          ),
          child: Text(
            event.categoryDisplayName,
            style: TextStyle(
              color: _getCategoryColor(event.category),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                event.isRegistrationOpen ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: event.isRegistrationOpen ? Colors.green : Colors.red,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                event.isRegistrationOpen ? Icons.check_circle : Icons.cancel,
                size: 14,
                color: event.isRegistrationOpen ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                event.isRegistrationOpen
                    ? 'Registration Open'
                    : 'Registration Closed',
                style: TextStyle(
                  color: event.isRegistrationOpen ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
        const SizedBox(height: 16),
        _buildInfoRow(Icons.location_on, 'Location', event.location),
        const SizedBox(height: 16),
        _buildInfoRow(
          Icons.access_time,
          'Registration Deadline',
          '${event.registrationDeadline.day}/${event.registrationDeadline.month}/${event.registrationDeadline.year}',
        ),
        const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
        Text(
          'About This Event',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            event.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ),
        if (event.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Tags',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
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
        Text(
          'Ticket Types',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...event.ticketTypes.map((ticket) => _buildTicketTypeCard(ticket)),
      ],
    );
  }

  Widget _buildTicketTypeCard(TicketType ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '\$${ticket.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.description,
              style: TextStyle(color: Colors.grey[600], height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Available: ${ticket.availableSpots}/${ticket.maxCapacity}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        ticket.hasAvailableSpots
                            ? Colors.green[100]
                            : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
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
                            ticket.hasAvailableSpots
                                ? Colors.green
                                : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ticket.hasAvailableSpots ? 'Available' : 'Sold Out',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              ticket.hasAvailableSpots
                                  ? Colors.green
                                  : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizerInfo(Event event) {
    // Check if we have organizer information
    final hasOrganizerName = event.organizerName.isNotEmpty;
    final hasOrganizerEmail = event.organizerEmail.isNotEmpty;
    final hasOrganizerPhone =
        event.organizerPhone != null && event.organizerPhone!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Organizer',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
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
                          color: hasOrganizerName ? null : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

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
                  const SizedBox(height: 8),
                  _buildContactRow(Icons.phone, event.organizerPhone!),
                ] else ...[
                  const SizedBox(height: 8),
                  _buildContactRow(
                    Icons.phone,
                    'Phone not provided',
                    isPlaceholder: true,
                  ),
                ],

                // Debug info (remove this in production)
                if (!hasOrganizerName || !hasOrganizerEmail) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug Info:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                        Text(
                          'Name: "${event.organizerName}"',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                          ),
                        ),
                        Text(
                          'Email: "${event.organizerEmail}"',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                          ),
                        ),
                        if (event.organizerPhone != null)
                          Text(
                            'Phone: "${event.organizerPhone}"',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[700],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
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
          color: isPlaceholder ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isPlaceholder ? Colors.grey[500] : Colors.grey[700],
              fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
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
