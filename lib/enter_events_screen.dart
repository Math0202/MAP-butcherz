import 'package:flutter/material.dart';

// Dummy Event Model (replace with your actual data model)
class Event {
  final String id;
  final String name;
  final String type; // "Tournament" or "League"
  final String dateRange;
  final String venue;
  final String description;
  final String? logoUrl; // Optional
  bool isRegistered; // To track if the user's team is registered

  Event({
    required this.id,
    required this.name,
    required this.type,
    required this.dateRange,
    required this.venue,
    required this.description,
    this.logoUrl,
    this.isRegistered = false,
  });
}

class EnterEventsScreen extends StatefulWidget {
  const EnterEventsScreen({super.key});

  @override
  State<EnterEventsScreen> createState() => _EnterEventsScreenState();
}

class _EnterEventsScreenState extends State<EnterEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy list of events (replace with actual data fetching)
  final List<Event> _allEvents = [
    Event(
      id: 't1',
      name: 'Summer Slam Hockey Tournament',
      type: 'Tournament',
      dateRange: 'July 15-18, 2024',
      venue: 'City Arena',
      description: 'Annual summer hockey challenge for all ages.',
      logoUrl: 'assets/tournament_logo_1.png',
      isRegistered: false,
    ),
    Event(
      id: 'l1',
      name: 'Metropolitan Hockey League - Season 5',
      type: 'League',
      dateRange: 'Sep 2024 - Mar 2025',
      venue: 'Various City Rinks',
      description: 'Join the city\'s premier hockey league.',
      logoUrl: 'assets/league_logo_1.png',
      isRegistered: true,
    ),
    Event(
      id: 't2',
      name: 'Youth Hockey Championship',
      type: 'Tournament',
      dateRange: 'Aug 5-7, 2024',
      venue: 'Community Sports Complex',
      description: 'A competitive tournament for U16 teams.',
      isRegistered: false,
    ),
    Event(
      id: 'l2',
      name: 'Weekend Warriors League',
      type: 'League',
      dateRange: 'Oct 2024 - Feb 2025',
      venue: 'IcePlex Center',
      description: 'Casual weekend league for adult players.',
      logoUrl: 'assets/league_logo_2.png',
      isRegistered: false,
    ),
    Event(
      id: 't3',
      name: 'Charity Cup Classic',
      type: 'Tournament',
      dateRange: 'Nov 10, 2024',
      venue: 'Grand Stadium',
      description: 'One-day tournament for a good cause.',
      logoUrl: 'assets/tournament_logo_2.png',
      isRegistered: true,
    ),
  ];

  List<Event> _getEventsByType(String type) {
    return _allEvents.where((event) => event.type == type).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _registerForEvent(Event event) {
    setState(() {
      event.isRegistered = true;
    });
    // TODO: API call to register team for the event
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Registered for ${event.name}! (Backend not implemented)',
        ),
      ),
    );
  }

  void _viewEventDetails(Event event) {
    // TODO: Navigate to a detailed event screen (schedules, venues, registered teams etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${event.name} (Not implemented)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Events'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          color: theme.scaffoldBackgroundColor,
          onPressed: () {},
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.hintColor,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [Tab(text: 'Tournaments'), Tab(text: 'Leagues')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventList(_getEventsByType('Tournament'), theme),
          _buildEventList(_getEventsByType('League'), theme),
        ],
      ),
    );
  }

  Widget _buildEventList(List<Event> events, ThemeData theme) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 70, color: theme.hintColor),
            const SizedBox(height: 16),
            Text(
              'No events available at the moment.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.logoUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            event.logoUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    const Icon(Icons.sports_hockey, size: 60),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.dateRange,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Venue: ${event.venue}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.description,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _viewEventDetails(event),
                      child: const Text('View Details'),
                    ),
                    const SizedBox(width: 8),
                    event.isRegistered
                        ? FilledButton.tonal(
                          onPressed: null, // Disabled
                          child: const Text('Registered'),
                        )
                        : FilledButton(
                          onPressed: () => _registerForEvent(event),
                          child: const Text('Register Team'),
                        ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
