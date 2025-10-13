// lib/providers/event_provider.dart
import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventProvider with ChangeNotifier {
  final EventService _eventService = EventService();

  // State
  List<Event> _events = [];
  Event? _selectedEvent;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  PaginationInfo? _pagination;

  // Filters
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _showFeaturedOnly = false;

  // Getters
  List<Event> get events => _events;
  Event? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  PaginationInfo? get pagination => _pagination;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get showFeaturedOnly => _showFeaturedOnly;
  bool get hasNextPage => _pagination?.hasNextPage ?? false;

  // Filtered events based on current filters
  List<Event> get filteredEvents {
    List<Event> filtered = List.from(_events);

    if (_selectedCategory != 'all') {
      filtered =
          filtered
              .where((event) => event.category == _selectedCategory)
              .toList();
    }

    if (_showFeaturedOnly) {
      filtered = filtered.where((event) => event.isFeatured).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((event) {
            return event.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                event.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                event.location.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
          }).toList();
    }

    return filtered;
  }

  // Categories for filter dropdown
  List<String> get categories => [
    'all',
    'lacrosse_camp',
    'tournament',
    'clinic',
    'workshop',
    'training',
    'social',
    'fundraiser',
    'other',
  ];

  String getCategoryDisplayName(String category) {
    switch (category) {
      case 'all':
        return 'All Categories';
      case 'lacrosse_camp':
        return 'Lacrosse Camp';
      case 'tournament':
        return 'Tournament';
      case 'clinic':
        return 'Clinic';
      case 'workshop':
        return 'Workshop';
      case 'training':
        return 'Training';
      case 'social':
        return 'Social';
      case 'fundraiser':
        return 'Fundraiser';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  // Methods
  Future<void> loadEvents({bool refresh = false}) async {
    if (refresh) {
      _events.clear();
      _pagination = null;
    }

    _setLoading(true);
    _clearError();

    try {
      print('🔄 Loading events with filters:');
      print('   Category: $_selectedCategory');
      print('   Featured: $_showFeaturedOnly');
      print('   Search: $_searchQuery');

      final response = await _eventService.getEvents(
        page: 1,
        limit: 20,
        upcoming: false, // Show all events including past ones
        category: _selectedCategory != 'all' ? _selectedCategory : null,
        featured: _showFeaturedOnly ? true : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (response.success && response.data != null) {
        _events = response.data!;
        _pagination = response.pagination;
        print('✅ Loaded ${_events.length} events successfully');
      } else {
        print('❌ Failed to load events: ${response.error}');
        _setError(response.error ?? 'Failed to load events');
      }
    } catch (e) {
      print('❌ Exception in loadEvents: $e');
      _setError('Network error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreEvents() async {
    if (_isLoadingMore || !hasNextPage) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = (_pagination?.currentPage ?? 0) + 1;
      print('📄 Loading more events - page $nextPage');

      final response = await _eventService.getEvents(
        page: nextPage,
        limit: 20,
        category: _selectedCategory != 'all' ? _selectedCategory : null,
        featured: _showFeaturedOnly ? true : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (response.success && response.data != null) {
        _events.addAll(response.data!);
        _pagination = response.pagination;
        print('✅ Added ${response.data!.length} more events');
      } else {
        print('❌ Failed to load more events: ${response.error}');
        _setError(response.error ?? 'Failed to load more events');
      }
    } catch (e) {
      print('❌ Exception in loadMoreEvents: $e');
      _setError('Network error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadEventDetails(String eventId) async {
    print('🔍 Loading event details for ID: $eventId');

    _setLoading(true);
    _clearError();

    try {
      // ALWAYS fetch fresh data from API for event details
      // This ensures we get the latest isRegistrationOpen and hasAvailableSpots values
      print('🌐 Fetching fresh event details from API...');
      final response = await _eventService.getEventById(eventId);

      if (response.success && response.data != null) {
        print('✅ Successfully loaded event details');
        print('   Title: ${response.data!.title}');
        print('   Is Registration Open: ${response.data!.isRegistrationOpen}');
        print('   Has Available Spots: ${response.data!.hasAvailableSpots}');
        print(
          '   Available Tickets: ${response.data!.availableTicketTypes.length}',
        );

        _selectedEvent = response.data;

        // Update the event in the list if it exists, or add it
        final index = _events.indexWhere((event) => event.id == eventId);
        if (index != -1) {
          _events[index] = response.data!;
          print('   Updated event in cache');
        } else {
          _events.add(response.data!);
          print('   Added event to cache');
        }
      } else {
        print('❌ Failed to load event details: ${response.error}');
        _setError(response.error ?? 'Failed to load event details');
      }
    } catch (e) {
      print('❌ Exception in loadEventDetails: $e');
      _setError('Network error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Set selected event (for when navigating from events list)
  void setSelectedEvent(Event event) {
    print('📌 Setting selected event: ${event.title}');
    _selectedEvent = event;
    _clearError();
    notifyListeners();
  }

  // Clear selected event
  void clearSelectedEvent() {
    print('🧹 Clearing selected event');
    _selectedEvent = null;
    _clearError();
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    if (_selectedCategory != category) {
      print('🏷️ Setting category filter: $category');
      _selectedCategory = category;
      notifyListeners();
      loadEvents(refresh: true);
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      print('🔍 Setting search query: "$query"');
      _searchQuery = query;
      notifyListeners();
      // Debounce search - in a real app you might want to add a timer
      loadEvents(refresh: true);
    }
  }

  void toggleFeaturedOnly() {
    _showFeaturedOnly = !_showFeaturedOnly;
    print('⭐ Toggling featured filter: $_showFeaturedOnly');
    notifyListeners();
    loadEvents(refresh: true);
  }

  void clearFilters() {
    print('🧹 Clearing all filters');
    _selectedCategory = 'all';
    _searchQuery = '';
    _showFeaturedOnly = false;
    notifyListeners();
    loadEvents(refresh: true);
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    if (_isLoading == false) {
      notifyListeners();
    }
  }

  // Refresh method for pull-to-refresh
  Future<void> refresh() async {
    print('🔄 Refreshing events...');
    await loadEvents(refresh: true);
  }

  // Get event by ID from current loaded events
  Event? getEventById(String eventId) {
    try {
      return _events.firstWhere((event) => event.id == eventId);
    } catch (e) {
      return null;
    }
  }

  // Check if event exists in loaded events
  bool hasEvent(String eventId) {
    return _events.any((event) => event.id == eventId);
  }

  // Add or update event in the list
  void updateEvent(Event updatedEvent) {
    final index = _events.indexWhere((event) => event.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;

      // Update selected event if it's the same one
      if (_selectedEvent?.id == updatedEvent.id) {
        _selectedEvent = updatedEvent;
      }

      notifyListeners();
    }
  }

  // Remove event from the list
  void removeEvent(String eventId) {
    _events.removeWhere((event) => event.id == eventId);

    // Clear selected event if it was removed
    if (_selectedEvent?.id == eventId) {
      _selectedEvent = null;
    }

    notifyListeners();
  }
}

// Registration Provider for handling registration flow
class RegistrationProvider with ChangeNotifier {
  final EventService _eventService = EventService();

  // State
  RegistrationResponse? _registrationResponse;
  DiscountValidation? _discountValidation;
  bool _isRegistering = false;
  bool _isValidatingDiscount = false;
  String? _registrationError;
  String? _discountError;

  // Getters
  RegistrationResponse? get registrationResponse => _registrationResponse;
  DiscountValidation? get discountValidation => _discountValidation;
  bool get isRegistering => _isRegistering;
  bool get isValidatingDiscount => _isValidatingDiscount;
  String? get registrationError => _registrationError;
  String? get discountError => _discountError;
  bool get hasValidDiscount => _discountValidation?.valid ?? false;

  // Register for event
  Future<bool> registerForEvent({
    required String eventId,
    required RegistrationData registrationData,
  }) async {
    print('📝 Registering for event: $eventId');
    _isRegistering = true;
    _registrationError = null;
    notifyListeners();

    try {
      final response = await _eventService.registerForEvent(
        eventId: eventId,
        registrationData: registrationData,
      );

      if (response.success && response.data != null) {
        print('✅ Registration successful');
        _registrationResponse = response.data!;
        return true;
      } else {
        print('❌ Registration failed: ${response.error}');
        _registrationError = response.error ?? 'Registration failed';
        return false;
      }
    } catch (e) {
      print('❌ Registration exception: $e');
      _registrationError = 'Network error: $e';
      return false;
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }

  // Validate discount code
  Future<bool> validateDiscountCode({
    required String code,
    required String eventId,
    required String ticketType,
    String? userEmail,
  }) async {
    print('🎫 Validating discount code: $code');
    _isValidatingDiscount = true;
    _discountError = null;
    _discountValidation = null;
    notifyListeners();

    try {
      final response = await _eventService.validateDiscountCode(
        code: code,
        eventId: eventId,
        ticketType: ticketType,
        userEmail: userEmail,
      );

      if (response.success && response.data != null) {
        print('✅ Discount validation result: ${response.data!.valid}');
        _discountValidation = response.data!;
        return response.data!.valid;
      } else {
        print('❌ Discount validation failed: ${response.error}');
        _discountError = response.error ?? 'Invalid discount code';
        return false;
      }
    } catch (e) {
      print('❌ Discount validation exception: $e');
      _discountError = 'Network error: $e';
      return false;
    } finally {
      _isValidatingDiscount = false;
      notifyListeners();
    }
  }

  // Clear discount validation
  void clearDiscount() {
    print('🧹 Clearing discount validation');
    _discountValidation = null;
    _discountError = null;
    notifyListeners();
  }

  // Mark registration as paid (after payment processing)
  Future<bool> markAsPaid({
    required String registrationId,
    required double paidAmount,
    required String paymentMethod,
    String? paymentTransactionId,
  }) async {
    print('💰 Marking registration as paid: $registrationId');
    _isRegistering = true;
    _registrationError = null;
    notifyListeners();

    try {
      final response = await _eventService.markRegistrationAsPaid(
        registrationId: registrationId,
        paidAmount: paidAmount,
        paymentMethod: paymentMethod,
        paymentTransactionId: paymentTransactionId,
      );

      if (response.success && response.data != null) {
        print('✅ Payment marked as successful');
        _registrationResponse = response.data!;
        return true;
      } else {
        print('❌ Payment marking failed: ${response.error}');
        _registrationError = response.error ?? 'Payment processing failed';
        return false;
      }
    } catch (e) {
      print('❌ Payment marking exception: $e');
      _registrationError = 'Network error: $e';
      return false;
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }

  // Calculate final price with discount
  double calculateFinalPrice(double basePrice) {
    if (_discountValidation == null || !_discountValidation!.valid) {
      return basePrice;
    }

    double discount = 0;
    if (_discountValidation!.discountType == 'fixed') {
      discount = _discountValidation!.discountAmount;
    } else if (_discountValidation!.discountType == 'percentage') {
      discount = (basePrice * _discountValidation!.discountAmount / 100);
    }

    final finalPrice = (basePrice - discount).clamp(0.0, basePrice);
    print(
      '💰 Price calculation: \$${basePrice.toStringAsFixed(2)} - \$${discount.toStringAsFixed(2)} = \$${finalPrice.toStringAsFixed(2)}',
    );
    return finalPrice;
  }

  // Clear all registration data
  void clearRegistration() {
    print('🧹 Clearing registration data');
    _registrationResponse = null;
    _discountValidation = null;
    _registrationError = null;
    _discountError = null;
    notifyListeners();
  }
}
