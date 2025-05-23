import 'package:flutter/material.dart';
import 'package:hocky_na_org/services/mongodb_service.dart'; // Import MongoDBService
import 'package:intl/intl.dart'; // For date formatting
import 'package:mongo_dart/mongo_dart.dart' show ObjectId; // For ObjectId handling

// Updated Event Model
class Event {
  final String id;
  final String name;
  final String type; // "Tournament" or "League"
  final DateTime? startDate;
  final DateTime? endDate;
  final String venue;
  final String description;
  final String? logoUrl;
  bool isRegistered; // To track if the user's team is registered for this event

  Event({
    required this.id,
    required this.name,
    required this.type,
    this.startDate,
    this.endDate,
    required this.venue,
    required this.description,
    this.logoUrl,
    this.isRegistered = false,
  });

  // Helper to get a formatted date range string
  String get dateRangeDisplay {
    final DateFormat formatter = DateFormat('MMM d, yyyy');
    if (startDate != null && endDate != null) {
      if (startDate!.year == endDate!.year &&
          startDate!.month == endDate!.month &&
          startDate!.day == endDate!.day) {
        return formatter.format(startDate!); // Single day event
      }
      return '${formatter.format(startDate!)} - ${formatter.format(endDate!)}';
    } else if (startDate != null) {
      return formatter.format(startDate!);
    }
    return 'Date TBD';
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    dynamic idValue = map['_id'];
    String idString;
    if (idValue is ObjectId) {
      idString = idValue.toHexString();
    } else {
      idString = idValue?.toString() ?? ''; // Fallback
    }

    DateTime? parseDate(dynamic dateField) {
      print('Parsing date field: $dateField (type: ${dateField?.runtimeType})');
      if (dateField is DateTime) {
        return dateField;
      }
      if (dateField is String) {
        return DateTime.tryParse(dateField);
      }
      // Handle MongoDB ISODate which might come through as a Map
      if (dateField is Map && dateField.containsKey('\$date')) {
        var dateValue = dateField['\$date'];
        if (dateValue is String) {
          return DateTime.tryParse(dateValue);
        } else if (dateValue is int) {
          return DateTime.fromMillisecondsSinceEpoch(dateValue);
        }
      }
      return null;
    }
    
    var startDate = parseDate(map['startDate']);
    var endDate = parseDate(map['endDate']);
    
    // Debug
    print('Parsing event: ${map['name']} (${map['type']})');
    print('  startDate: ${map['startDate']} -> $startDate');
    print('  endDate: ${map['endDate']} -> $endDate');

    return Event(
      id: idString,
      name: map['name'] ?? 'Unnamed Event',
      type: map['type'] ?? 'Unknown',
      startDate: startDate,
      endDate: endDate,
      venue: map['venue'] ?? 'Venue TBD',
      description: map['description'] ?? 'No description available.',
      logoUrl: map['logoUrl'],
      isRegistered: map['isRegistered'] ?? false,
    );
  }
}

class EnterEventsScreen extends StatefulWidget {
  final String? teamName; // Make teamName nullable
  
  const EnterEventsScreen({super.key, this.teamName});

  @override
  State<EnterEventsScreen> createState() => _EnterEventsScreenState();
}

class _EnterEventsScreenState extends State<EnterEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingEvents = true; // To track loading state
  List<Event> _allEvents = []; // Will be populated from DB

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEvents(); // Fetch events when the screen initializes
  }

  Future<void> _fetchEvents() async {
    if (!mounted) return;
    setState(() {
      _isLoadingEvents = true;
      _allEvents = [];
    });

    try {
      print('Attempting to fetch events from database...');
      final eventsCollection = MongoDBService.getCollection('events');
      print('Got events collection reference');

      // Fetch events - but only future events
      final now = DateTime.now();
      print('Current date for filtering: ${now.toIso8601String()}');
      
      // First let's try a simple find() to see if we can get ANY events
      final allEventsQuery = await eventsCollection.find().toList();
      print('Total events in database (unfiltered): ${allEventsQuery.length}');
      
      if (allEventsQuery.isEmpty) {
        print('No events found in database at all. Check if collection has data.');
        // If this is empty, your collection might be empty or have a different name
      }
      
      // Try the aggregation pipeline
      final pipeline = [
        {
          r'$match': {
            r'$or': [
              // Just match all documents for now to see if we get results
              {}
            ]
          }
        }
      ];
      
      print('Executing aggregation pipeline: $pipeline');
      final eventsData = await eventsCollection.aggregateToStream(pipeline).toList();
      print('Pipeline returned ${eventsData.length} events');
      
      // If the aggregation fails or returns no results, try a simple find() as fallback
      if (eventsData.isEmpty) {
        print('Trying fallback query without date filtering...');
        final fallbackData = await eventsCollection.find().toList();
        
        if (mounted) {
          final fetchedEvents = fallbackData
              .map((doc) {
                print('Processing document: $doc');
                final event = Event.fromMap(doc as Map<String, dynamic>);
                
                // Check if this team is registered for this event
                List<String> registeredTeams = [];
                if (doc.containsKey('registeredTeams') && doc['registeredTeams'] is List) {
                  registeredTeams = List<String>.from(doc['registeredTeams']);
                }
                
                // Set isRegistered flag based on whether user's team is in the list
                final teamName = widget.teamName;
                event.isRegistered = teamName != null && teamName.isNotEmpty && 
                                     registeredTeams.contains(teamName);
                
                return event;
              })
              .toList();
          
          setState(() {
            _allEvents = fetchedEvents;
            _isLoadingEvents = false;
          });
          
          print('Fallback fetched ${fetchedEvents.length} events');
          if (fetchedEvents.isNotEmpty) {
            print('First event: ${fetchedEvents[0].name}, type: ${fetchedEvents[0].type}');
            print('Events by type - Tournament: ${_getEventsByType("Tournament").length}, League: ${_getEventsByType("League").length}');
          }
        }
        return; // Exit after fallback
      }
      
      if (mounted) {
        final fetchedEvents = eventsData
            .map((doc) {
              print('Processing document from pipeline: $doc');
              final event = Event.fromMap(doc as Map<String, dynamic>);
              
              // Check if this team is registered for this event
              List<String> registeredTeams = [];
              if (doc.containsKey('registeredTeams') && doc['registeredTeams'] is List) {
                registeredTeams = List<String>.from(doc['registeredTeams']);
              }
              
              // Set isRegistered flag based on whether user's team is in the list
              final teamName = widget.teamName;
              event.isRegistered = teamName != null && teamName.isNotEmpty && 
                                   registeredTeams.contains(teamName);
              
              return event;
            })
            .toList();
        
        setState(() {
          _allEvents = fetchedEvents;
          _isLoadingEvents = false;
        });
        
        print('Successfully fetched ${fetchedEvents.length} events');
        if (fetchedEvents.isNotEmpty) {
          print('First event: ${fetchedEvents[0].name}, type: ${fetchedEvents[0].type}');
          print('Events by type - Tournament: ${_getEventsByType("Tournament").length}, League: ${_getEventsByType("League").length}');
        }
      }
    } catch (e) {
      print('Error fetching events: $e');
      print('Error stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: $e')),
        );
      }
    }
  }

  // Add a method to refresh events (can be called from pull-to-refresh or a refresh button)
  Future<void> refreshEvents() async {
    if (_isLoadingEvents) return; // Prevent multiple simultaneous fetches
    await _fetchEvents();
  }

  List<Event> _getEventsByType(String type) {
    return _allEvents.where((event) => event.type == type).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _registerForEvent(Event event) async {
    // Check if we actually have a team name
    final teamName = widget.teamName;
    if (teamName == null || teamName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be part of a team to register')),
      );
      return;
    }
    
    try {
      final eventsCollection = MongoDBService.getCollection('events');
      
      // First check if the team is already registered (double-check)
      final eventDoc = await eventsCollection.findOne({'_id': ObjectId.fromHexString(event.id)});
      
      if (eventDoc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event not found')),
        );
        return;
      }
      
      List<String> registeredTeams = [];
      if (eventDoc.containsKey('registeredTeams') && eventDoc['registeredTeams'] is List) {
        registeredTeams = List<String>.from(eventDoc['registeredTeams']);
      }
      
      if (registeredTeams.contains(teamName)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your team is already registered for this event')),
        );
        return;
      }
      
      // Add the team to registeredTeams array
      registeredTeams.add(teamName);
      
      // Update the event document
      final result = await eventsCollection.update(
        {'_id': ObjectId.fromHexString(event.id)},
        {
          r'$set': {
            'registeredTeams': registeredTeams,
          }
        },
      );
      
      if (result['ok'] == 1.0) {
        // Update local state
        setState(() {
          event.isRegistered = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully registered for ${event.name}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to register. Please try again.')),
        );
      }
    } catch (e) {
      print('Error registering for event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _viewEventDetails(Event event) {
    // TODO: Navigate to a detailed event screen (schedules, venues, registered teams etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${event.name} (Not implemented)'),
      ),
    );
  }

  void _debugEvents() {
    print('===== EVENT DEBUG INFO =====');
    print('Total events in _allEvents: ${_allEvents.length}');
    print('Events by type:');
    print('  - Tournament: ${_getEventsByType("Tournament").length}');
    print('  - League: ${_getEventsByType("League").length}');
    
    for (var event in _allEvents) {
      print('Event: ${event.name} (${event.type})');
      print('  ID: ${event.id}');
      print('  Date range: ${event.dateRangeDisplay}');
      print('  Raw dates: ${event.startDate} to ${event.endDate}');
    }
    print('===========================');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Event debug info printed to console')),
    );
  }

  Future<void> _checkEventsCollection() async {
    try {
      final eventsCollection = MongoDBService.getCollection('events');
      final count = await eventsCollection.count();
      
      print('Events collection contains $count documents');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Events collection has $count documents')),
      );
      
      if (count > 0) {
        // Get one sample document to check structure
        final sample = await eventsCollection.findOne();
        print('Sample event document: $sample');
        print('Sample keys: ${sample?.keys.toList()}');
      }
    } catch (e) {
      print('Error checking events collection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking collection: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Events'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.hintColor,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [Tab(text: 'Tournaments'), Tab(text: 'Leagues')],
        ),
        actions: [
          // Add refresh button to manually trigger refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshEvents,
            tooltip: 'Refresh events',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugEvents,
            tooltip: 'Debug events',
          ),
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: _checkEventsCollection,
            tooltip: 'Check DB',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshEvents,
        child: TabBarView(
          controller: _tabController,
          children: [
            _isLoadingEvents
                ? const Center(child: CircularProgressIndicator())
                : _buildEventList(_getEventsByType('Tournament'), theme),
            _isLoadingEvents
                ? const Center(child: CircularProgressIndicator())
                : _buildEventList(_getEventsByType('League'), theme),
          ],
        ),
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
                            event.dateRangeDisplay,
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
