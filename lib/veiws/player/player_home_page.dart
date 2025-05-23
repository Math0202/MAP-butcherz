import 'package:flutter/material.dart';
import 'package:hocky_na_org/veiws/coach/notifications_screen.dart'; // Import the NotificationsScreen
import 'package:hocky_na_org/veiws/coach/notifications_screen.dart'
    show NotificationItem;
import 'package:hocky_na_org/veiws/player/login_screen.dart';
import 'package:hocky_na_org/services/mongodb_service.dart'; // Add this import
import 'package:hocky_na_org/veiws/player/manage_roster_screen.dart';
import 'package:hocky_na_org/veiws/player/player_games.dart';
import 'package:mongo_dart/mongo_dart.dart'
    show where; // Ensure mongo_dart is imported for 'where'

class Homepage extends StatefulWidget {
  final String email;
  final String teamName;
  const Homepage({super.key, required this.email, required this.teamName});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;
  int _unreadNotificationsCount = 0; // State variable for the count

  // Define the pages to be shown for each tab
  late final List<Widget> _pages; // Make this late initialized

  // Controllers for the dialog input fields
  final _matchTitleController = TextEditingController();
  final _matchVenueController = TextEditingController();
  DateTime? _selectedMatchDate; // For date picker

  final _newsTitleController = TextEditingController();
  final _newsSubtitleController = TextEditingController();
  final _newsDescriptionController = TextEditingController();

  // State for team dropdowns
  List<String> _teamNames = [];
  String? _selectedTeamA;
  String? _selectedTeamB;
  bool _isLoadingTeams = false;

  // Define a GlobalKey for _HomeTabState
  final GlobalKey<_HomeTabState> _homeTabKey = GlobalKey<_HomeTabState>();

  @override
  void initState() {
    super.initState();
    // Initialize _pages in initState where widget.teamName is accessible
    _pages = [
      _HomeTab(key: _homeTabKey), // Assign the key to _HomeTab
      coachGames(teamName: widget.teamName),
      ManageRosterScreen(teamName: widget.teamName),
      _ProfileTab(teamName: widget.teamName, email: widget.email),
    ];

    _fetchUnreadNotificationsCount();
    _fetchTeamsForDropdown(); // Fetch teams once when the homepage initializes
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    _matchTitleController.dispose();
    _matchVenueController.dispose();
    _newsTitleController.dispose();
    _newsSubtitleController.dispose();
    _newsDescriptionController.dispose();
    super.dispose();
  }

  // Simulate fetching unread notifications count
  void _fetchUnreadNotificationsCount() {
    // In a real app, this would come from a shared service or database.
    // For demonstration, we use a copy of the logic/dummy data structure
    // from NotificationsScreen.
    final List<NotificationItem> dummyNotifications = [
      NotificationItem(
        id: '1',
        title: 'Match Reminder: Team A vs Team B',
        subtitle: 'Starts in 1 hour at City Arena',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        icon: Icons.sports_hockey,
        iconColor: Colors.blue,
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        title: 'New League Announcement!',
        subtitle: 'The Winter League registration is now open.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        icon: Icons.campaign,
        iconColor: Colors.green,
        isRead: false,
      ),
      NotificationItem(
        id: '3',
        title: 'Roster Update Approved',
        subtitle: 'Player John Smith added to your team.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        icon: Icons.group_add,
        iconColor: Colors.orange,
        isRead: true,
      ),
      // Add more dummy notifications if needed to match NotificationsScreen for accurate simulation
    ];
    if (mounted) {
      // Check if the widget is still in the tree
      setState(() {
        _unreadNotificationsCount =
            dummyNotifications.where((n) => !n.isRead).length;
      });
    }
  }

  Future<void> _fetchTeamsForDropdown() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTeams = true;
    });
    try {
      final teamsCollection = MongoDBService.getCollection('teams');
      // Fetch all team documents and extract their names
      final teamsCursor = teamsCollection.find(
        where.fields(['name']),
      ); // Only fetch the 'name' field
      final teamsList = await teamsCursor.toList();

      if (!mounted) return;
      setState(() {
        _teamNames =
            teamsList
                .map((doc) => doc['name'] as String)
                .where((name) => name.isNotEmpty) // Ensure names are not empty
                .toSet() // Remove duplicates
                .toList(); // Convert back to list
        _teamNames.sort(); // Sort team names alphabetically
        _isLoadingTeams = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('Error fetching teams for dropdown: $e');
      setState(() {
        _isLoadingTeams = false;
        // Optionally show an error to the user
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _selectMatchDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMatchDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedMatchDate) {
      // Also allow picking time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedMatchDate ?? DateTime.now(),
        ),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedMatchDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _showPostMatchDialog(BuildContext context) {
    _matchTitleController.clear();
    _matchVenueController.clear();
    _selectedMatchDate = null;
    _selectedTeamA = null;
    _selectedTeamB = null;

    if (_teamNames.isEmpty && !_isLoadingTeams) {
      _fetchTeamsForDropdown();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Post New Match/Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _matchTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Match Title/Name',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoadingTeams
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Team A (Home)',
                          ),
                          value: _selectedTeamA,
                          hint: const Text('Select Team A'),
                          isExpanded: true,
                          items:
                              _teamNames.map((String teamName) {
                                return DropdownMenuItem<String>(
                                  value: teamName,
                                  child: Text(teamName),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              _selectedTeamA = newValue;
                            });
                          },
                          validator:
                              (value) =>
                                  value == null ? 'Please select Team A' : null,
                        ),
                    const SizedBox(height: 8),
                    _isLoadingTeams
                        ? const SizedBox.shrink() // Don't show another loader if already loading
                        : DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Team B (Away)',
                          ),
                          value: _selectedTeamB,
                          hint: const Text('Select Team B'),
                          isExpanded: true,
                          items:
                              _teamNames.map((String teamName) {
                                return DropdownMenuItem<String>(
                                  value: teamName,
                                  child: Text(teamName),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              _selectedTeamB = newValue;
                            });
                          },
                          validator:
                              (value) =>
                                  value == null ? 'Please select Team B' : null,
                        ),
                    TextField(
                      controller: _matchVenueController,
                      decoration: const InputDecoration(labelText: 'Venue'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedMatchDate == null
                                ? 'No date chosen'
                                : 'Date: ${_selectedMatchDate!.toLocal().toString().substring(0, 16)}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedMatchDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              final TimeOfDay? pickedTime =
                                  await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                      _selectedMatchDate ?? DateTime.now(),
                                    ),
                                  );
                              if (pickedTime != null) {
                                setDialogState(() {
                                  // Use setDialogState to update dialog UI
                                  _selectedMatchDate = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                            }
                          },
                          child: const Text('Choose Date & Time'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FilledButton(
                  child: const Text('Post Match'),
                  onPressed:
                      (_selectedTeamA == null ||
                              _selectedTeamB == null ||
                              _selectedTeamA == _selectedTeamB)
                          ? null
                          : () async {
                            if (_matchTitleController.text.isEmpty ||
                                _selectedMatchDate == null ||
                                _matchVenueController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please fill all fields and select teams.',
                                  ),
                                ),
                              );
                              return;
                            }
                            final matchData = {
                              'title': _matchTitleController.text,
                              'teamA': _selectedTeamA,
                              'teamB': _selectedTeamB,
                              'venue': _matchVenueController.text,
                              'dateTime': _selectedMatchDate,
                              'status': 'upcoming',
                              'isHighlighted': true,
                              'createdAt': DateTime.now(),
                            };

                            // Show loading indicator or disable button during submission
                            // For simplicity, we'll just proceed.

                            try {
                              final matchesCollection =
                                  MongoDBService.getCollection('matches');
                              final result = await matchesCollection.insertOne(
                                matchData,
                              );
                              Navigator.of(context).pop(); // Close dialog

                              if (result.isSuccess) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Match posted successfully! Refreshing...',
                                    ),
                                  ),
                                );
                                // Wait for 3 seconds then refresh
                                await Future.delayed(
                                  const Duration(seconds: 3),
                                );
                                if (mounted && _selectedIndex == 0) {
                                  // Check if widget is still mounted
                                  _homeTabKey.currentState?.refreshData();
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to post match: ${result.writeError?.errmsg ?? "Unknown error"}',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              // Ensure dialog is popped if not already
                              if (Navigator.canPop(context))
                                Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error posting match: $e'),
                                ),
                              );
                              print('Error posting match to DB: $e');
                            }
                          },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPostNewsDialog(BuildContext context) {
    _newsTitleController.clear();
    _newsSubtitleController.clear();
    _newsDescriptionController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Post New News Article'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _newsTitleController,
                  decoration: const InputDecoration(labelText: 'News Title'),
                ),
                TextField(
                  controller: _newsSubtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle (e.g., Source)',
                  ),
                ),
                TextField(
                  controller: _newsDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description/Content',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              child: const Text('Post News'),
              onPressed: () async {
                if (_newsTitleController.text.isEmpty ||
                    _newsDescriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill title and description.'),
                    ),
                  );
                  return;
                }
                final newsData = {
                  'title': _newsTitleController.text,
                  'subtitle': _newsSubtitleController.text,
                  'description': _newsDescriptionController.text,
                  'dateTime': DateTime.now(),
                  'isImportant': false,
                };

                // Show loading indicator or disable button during submission

                try {
                  final newsCollection = MongoDBService.getCollection('news');
                  final result = await newsCollection.insertOne(newsData);
                  Navigator.of(context).pop(); // Close dialog

                  if (result.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'News article posted successfully! Refreshing...',
                        ),
                      ),
                    );
                    // Wait for 3 seconds then refresh
                    await Future.delayed(const Duration(seconds: 3));
                    if (mounted && _selectedIndex == 0) {
                      // Check if widget is still mounted
                      _homeTabKey.currentState?.refreshData();
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to post news: ${result.writeError?.errmsg ?? "Unknown error"}',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  // Ensure dialog is popped if not already
                  if (Navigator.canPop(context)) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error posting news: $e')),
                  );
                  print('Error posting news to DB: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.sports_hockey),
                title: const Text('Post New Match/Event'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _showPostMatchDialog(
                    context,
                  ); // Show the match posting dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.article),
                title: const Text('Post New News Article'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _showPostNewsDialog(context); // Show the news posting dialog
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _pages[_selectedIndex], // Show the selected tab content
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        backgroundColor: theme.colorScheme.surface,
        elevation: 3,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_hockey_outlined),
            selectedIcon: Icon(Icons.sports_hockey),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Teams',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Placeholder widgets for each tab
class _HomeTab extends StatefulWidget {
  const _HomeTab({Key? key}) : super(key: key);

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _isLoadingNews = true;
  bool _isLoadingMatches = true;
  List<Map<String, dynamic>> _newsPosts = [];
  List<Map<String, dynamic>> _upcomingMatches = [];

  @override
  void initState() {
    super.initState();
    _fetchNews();
    _fetchTeamMatches();
  }

  // Fetch news posts from MongoDB
  Future<void> _fetchNews() async {
    if (!mounted) return;

    setState(() {
      _isLoadingNews = true;
    });

    try {
      final newsCollection = MongoDBService.getCollection('news');
      // Fetch active news posts, sorted by timestamp (newest first)
      final newsCursor = await newsCollection.find({'isActive': true}).toList();

      if (mounted) {
        setState(() {
          _newsPosts = List<Map<String, dynamic>>.from(newsCursor);
          _newsPosts.sort((a, b) {
            final aDate = a['createdAt']?.toString() ?? '';
            final bDate = b['createdAt']?.toString() ?? '';
            return bDate.compareTo(aDate); // Descending order (newest first)
          });
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      print('Error fetching news: $e');
      if (mounted) {
        setState(() {
          _isLoadingNews = false;
        });
      }
    }
  }

  // Modified _fetchTeamMatches method to show ALL matches
  Future<void> _fetchTeamMatches() async {
    if (!mounted) return;

    final Homepage homePage =
        context.findAncestorWidgetOfExactType<Homepage>() as Homepage;
    final String teamName = homePage.teamName;

    print('DEBUGGING: Fetching ALL matches from database (no filters)');

    setState(() {
      _isLoadingMatches = true;
    });

    try {
      final matchesCollection = MongoDBService.getCollection('matches');

      // Get ALL matches from the database without any filters
      // Use proper Map<String, dynamic> syntax for empty query
      final allMatches =
          await matchesCollection.find(<String, dynamic>{}).toList();

      // Print all matches to console
      print('DEBUGGING: Found ${allMatches.length} total matches in database:');
      for (int i = 0; i < allMatches.length; i++) {
        final match = allMatches[i];
        print('----- Match ${i + 1} -----');
        match.forEach((key, value) {
          print('$key: $value');
        });
      }

      // Display ALL matches without any filtering
      if (mounted) {
        setState(() {
          _upcomingMatches = List<Map<String, dynamic>>.from(allMatches);

          // Sort the matches by date (if date exists)
          _upcomingMatches.sort((a, b) {
            try {
              final aDate = a['gameDate']?.toString() ?? '';
              final bDate = b['gameDate']?.toString() ?? '';
              if (aDate.isEmpty || bDate.isEmpty) return 0;
              return aDate.compareTo(bDate);
            } catch (e) {
              return 0;
            }
          });

          print(
            'DEBUGGING: Displaying ${_upcomingMatches.length} matches in UI',
          );
          _isLoadingMatches = false;
        });
      }
    } catch (e) {
      print('DEBUGGING: Error fetching matches: $e');
      if (mounted) {
        setState(() {
          _isLoadingMatches = false;
        });
      }
    }
  }

  Future<void> refreshData() async {
    await _fetchNews();
    await _fetchTeamMatches();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teamName =
        (context.findAncestorWidgetOfExactType<Homepage>() as Homepage)
            .teamName;

    return RefreshIndicator(
      onRefresh: refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            if (teamName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Welcome, $teamName Coach',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Upcoming Matches Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.sports_hockey, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'All Matches',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Matches List or Empty State
            _isLoadingMatches
                ? const Center(child: CircularProgressIndicator())
                : _upcomingMatches.isEmpty
                ? _buildEmptyState(
                  'No Matches Found',
                  'No matches are available in the database.',
                  Icons.event_busy,
                )
                : Column(
                  children:
                      _upcomingMatches.map((match) {
                        // Debug print each match as it's being rendered
                        print(
                          'Rendering match: ${match['title']} for team $teamName',
                        );
                        return _buildMatchCard(match, theme, teamName);
                      }).toList(),
                ),

            // Add debug info at the bottom
            if (_upcomingMatches.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Displaying ${_upcomingMatches.length} total matches',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

            const SizedBox(height: 24),

            // Latest News Section
            _buildSectionHeader(theme, 'Latest News', Icons.newspaper),

            if (_isLoadingNews)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_newsPosts.isEmpty)
              _buildEmptyState(
                'No news available',
                'Check back soon for updates from the administration.',
                Icons.feed,
              )
            else
              Column(
                children:
                    _newsPosts
                        .map((post) => _buildNewsCard(post, theme))
                        .toList(),
              ),

            // Additional padding at bottom
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Build section header with icon
  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Build match card
  Widget _buildMatchCard(
    Map<String, dynamic> match,
    ThemeData theme,
    String teamName,
  ) {
    // Better date parsing with fallback
    DateTime gameDate;
    try {
      gameDate = DateTime.parse(match['gameDate']);
    } catch (e) {
      print('Error parsing date for match ${match['title']}: $e');
      gameDate = DateTime.now(); // Fallback
    }

    final String formattedDate =
        "${gameDate.day.toString().padLeft(2, '0')}-${gameDate.month.toString().padLeft(2, '0')}-${gameDate.year}";
    final String formattedTime =
        "${gameDate.hour.toString().padLeft(2, '0')}:${gameDate.minute.toString().padLeft(2, '0')}";

    // Determine if the team is playing at home
    final bool isHomeTeam =
        (match['teamA'].toString().toLowerCase() == teamName.toLowerCase());

    print(
      'Match card: ${match['title']} - Date: $formattedDate, Time: $formattedTime, isHome: $isHomeTeam',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match header with date, time, venue
            Row(
              children: [
                Icon(Icons.event, size: 16, color: theme.hintColor),
                const SizedBox(width: 4),
                Text(
                  '$formattedDate at $formattedTime',
                  style: TextStyle(color: theme.hintColor, fontSize: 12),
                ),
                const Spacer(),
                if (match['venue'] != null)
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: theme.hintColor),
                      const SizedBox(width: 4),
                      Text(
                        match['venue'],
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Match title
            Text(
              match['title'] ?? 'Untitled Match',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Teams display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match['teamA'] ?? 'Team A',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isHomeTeam ? theme.colorScheme.primary : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text('vs', style: TextStyle(fontSize: 16)),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match['teamB'] ?? 'Team B',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: !isHomeTeam ? theme.colorScheme.primary : null,
                        ),
                        textAlign: TextAlign.center,
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

  // Build news card
  Widget _buildNewsCard(Map<String, dynamic> post, ThemeData theme) {
    final DateTime createdAt =
        post['createdAt'] != null
            ? DateTime.parse(post['createdAt'])
            : DateTime.now();

    final String formattedDate =
        "${createdAt.day.toString().padLeft(2, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.year}";
    final bool isHighlighted = post['isHighlighted'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isHighlighted
                ? BorderSide(color: theme.colorScheme.primary, width: 2)
                : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // News header with date and highlight indicator
            Row(
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(color: theme.hintColor, fontSize: 12),
                ),
                const Spacer(),
                if (isHighlighted)
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Featured',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // News title
            Text(
              post['title'] ?? 'Untitled',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            if (post['subtitle'] != null &&
                post['subtitle'].toString().trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                post['subtitle'],
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            if (post['content'] != null &&
                post['content'].toString().trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                post['content'],
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // View full button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Show full content in a dialog
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(post['title'] ?? 'Untitled'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (post['subtitle'] != null &&
                                    post['subtitle']
                                        .toString()
                                        .trim()
                                        .isNotEmpty) ...[
                                  Text(
                                    post['subtitle'],
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Text(post['content'] ?? ''),
                                const SizedBox(height: 16),
                                Text(
                                  'Posted on $formattedDate',
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                  );
                },
                child: const Text('Read More'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_hockey, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          Text('Matches', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'View upcoming and past games',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _TeamsTab extends StatelessWidget {
  const _TeamsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          Text('Teams', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Manage your teams and players',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

// Update ProfileTab to be stateful so it can fetch and store user data
class _ProfileTab extends StatefulWidget {
  final String teamName;
  final String email;

  const _ProfileTab({required this.teamName, required this.email});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';
  String _userGender = 'Male'; // Default to Male

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usersCollection = MongoDBService.getCollection('users');

      // Try to find user by email
      final user = await usersCollection.findOne({'email': widget.email});

      if (user != null) {
        final Map<String, dynamic> userData = user as Map<String, dynamic>;
        print('Found user profile: $userData');

        setState(() {
          // Direct check for fullName field which exists in your user document
          if (userData.containsKey('fullName')) {
            _userName = userData['fullName'];
          } else {
            _userName = userData['fullName']; // Fallback name
          }

          _userEmail = widget.email;

          // Make sure gender value is standardized for comparison
          String genderValue =
              (userData['gender'] ?? 'male').toString().toLowerCase();
          _userGender = genderValue == 'female' ? 'Female' : 'Male';

          _isLoading = false;
        });
      } else {
        print('User not found with email: ${widget.email}');
        setState(() {
          _userName = 'User';
          _userEmail = widget.email;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      setState(() {
        _userName = 'User';
        _userEmail = widget.email;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Choose avatar based on gender
    final String userAvatarUrl =
        _userGender.toLowerCase() == 'female'
            ? 'assets/player_avatar_female.png'
            : 'assets/player_avatar_male.png';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: AssetImage(userAvatarUrl),
            child:
                !userAvatarUrl.contains('assets/') // Fallback if image fails
                    ? Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 16),
          Text(
            _userName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userEmail,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 30),
          const Divider(),
          _ProfileMenuItem(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () {
              // TODO: Navigate to Edit Profile Screen
            },
          ),
          _ProfileMenuItem(
            icon: Icons.shield_outlined,
            title: 'Manage My Roster',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ManageRosterScreen(teamName: widget.teamName),
                ),
              );
            },
          ),
          _ProfileMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              // TODO: Navigate to Notifications Settings Screen
            },
          ),
          _ProfileMenuItem(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
              // TODO: Navigate to Change Password Screen
            },
          ),
          _ProfileMenuItem(
            icon: Icons.settings_outlined,
            title: 'App Settings',
            onTap: () {
              // TODO: Navigate to App Settings Screen
            },
          ),
          const Divider(),
          _ProfileMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              // TODO: Navigate to Help Screen
            },
          ),
          _ProfileMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            isDestructive: true,
            onTap: () {
              // Show confirmation dialog
              showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                            // Navigate to login screen
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const player_login(),
                              ),
                              (route) => false, // Clear all routes
                            );
                          },
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Helper widget for featured items on home tab
class _FeaturedItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String dateTime;

  const _FeaturedItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Truncate title if it's longer than 20 characters
    String displayTitle = title;
    if (title.length > 20) {
      displayTitle = '${title.substring(0, 20)}...';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  displayTitle, // Use the potentially truncated title
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  // maxLines and overflow are still good for handling edge cases
                  // or if the font size makes even 20 chars + ... too long.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyLarge,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            dateTime,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for profile menu items
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? Colors.red : theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: color,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    );
  }
}
