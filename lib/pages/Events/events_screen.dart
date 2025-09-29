// lib/pages/Events/events_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/events/event_card.dart';
import 'event_details_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Load events when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadEvents();
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more events when reaching bottom
      context.read<EventProvider>().loadMoreEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Theme.of(context).primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Events',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Search and Filters
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search events...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              _searchController.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      eventProvider.setSearchQuery('');
                                    },
                                  )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          // Debounce search - you might want to add a proper debouncer
                          eventProvider.setSearchQuery(value);
                        },
                      ),

                      const SizedBox(height: 12),

                      // Filter Row
                      Row(
                        children: [
                          // Category Dropdown
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: eventProvider.selectedCategory,
                                  isExpanded: true,
                                  items:
                                      eventProvider.categories
                                          .map(
                                            (category) => DropdownMenuItem(
                                              value: category,
                                              child: Text(
                                                eventProvider
                                                    .getCategoryDisplayName(
                                                      category,
                                                    ),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      eventProvider.setSelectedCategory(value);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Featured Filter
                          FilterChip(
                            label: const Text('Featured'),
                            selected: eventProvider.showFeaturedOnly,
                            onSelected: (selected) {
                              eventProvider.toggleFeaturedOnly();
                            },
                            selectedColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.2),
                            checkmarkColor: Theme.of(context).primaryColor,
                          ),

                          const SizedBox(width: 8),

                          // Clear Filters
                          if (eventProvider.selectedCategory != 'all' ||
                              eventProvider.searchQuery.isNotEmpty ||
                              eventProvider.showFeaturedOnly)
                            IconButton(
                              icon: const Icon(Icons.clear_all),
                              onPressed: () {
                                _searchController.clear();
                                eventProvider.clearFilters();
                              },
                              tooltip: 'Clear all filters',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Loading State
              if (eventProvider.isLoading && eventProvider.events.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading events...'),
                      ],
                    ),
                  ),
                ),

              // Error State
              if (eventProvider.error != null && eventProvider.events.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading events',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          eventProvider.error!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              () => eventProvider.loadEvents(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Events List
              if (eventProvider.filteredEvents.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final event = eventProvider.filteredEvents[index];
                    return EventCard(
                      event: event,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    EventDetailsScreen(eventId: event.id),
                          ),
                        );
                      },
                    );
                  }, childCount: eventProvider.filteredEvents.length),
                ),

              // Empty State
              if (!eventProvider.isLoading &&
                  eventProvider.filteredEvents.isEmpty &&
                  eventProvider.error == null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events found',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            eventProvider.clearFilters();
                          },
                          child: const Text('Clear all filters'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Load More Indicator
              if (eventProvider.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
      ),
    );
  }
}
