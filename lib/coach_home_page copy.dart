import 'package:flutter/material.dart';
import 'package:hocky_na_org/team_management/manage_roster_screen.dart'; // Import the ManageRosterScreen
import 'package:hocky_na_org/veiws/coach/enter_events_screen.dart'; // Import the new screen
import 'package:hocky_na_org/veiws/coach/notifications_screen.dart'; // Import the NotificationsScreen
import 'package:hocky_na_org/veiws/coach/notifications_screen.dart'
    show NotificationItem;
import 'package:hocky_na_org/services/user_service.dart';
import 'package:hocky_na_org/veiws/coach/login_screen.dart';
import 'package:hocky_na_org/services/mongodb_service.dart'; // Add this import
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
      EnterEventsScreen(teamName: widget.teamName), // Pass teamName here
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
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          color: theme.scaffoldBackgroundColor,
          onPressed: () {},
        ),

        title: const Text('Hockey.org Namibia'),
        //centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              label: Text(_unreadNotificationsCount.toString()),
              isLabelVisible: _unreadNotificationsCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () async {
              // Make onPressed async
              await Navigator.push(
                // Await the result of NotificationsScreen
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
              // Refresh count when returning from NotificationsScreen
              _fetchUnreadNotificationsCount();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
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
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
              );

              if (shouldLogout == true) {
                // Navigate to login screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false, // Clear all routes
                );
              }
            },
          ),
        ],
      ),
      /*drawer: Drawer(
        // Add the Drawer widget here
        child: ListView(
          padding: EdgeInsets.zero, // Remove padding from ListView
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.onPrimary.withOpacity(
                      0.8,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'User Name', // Replace with actual user name
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    'user.email@example.com', // Replace with actual user email
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                _onItemTapped(0); // Navigate to Home tab
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_hockey_outlined),
              title: const Text('Matches'),
              onTap: () {
                _onItemTapped(1); // Navigate to Matches tab
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Teams'),
              onTap: () {
                _onItemTapped(2); // Navigate to Teams tab
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                _onItemTapped(3); // Navigate to Profile tab
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Enter Events'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EnterEventsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                // TODO: Navigate to Settings Screen
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                // TODO: Navigate to About Screen
                Navigator.pop(context); // Close the drawer
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(
                'Logout',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                // TODO: Implement Logout Logic
                Navigator.pop(context); // Close the drawer
                // Example: Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),*/
      body: _pages[_selectedIndex], // Show the selected tab content
      floatingActionButton:
          _selectedIndex == 0 ||
                  _selectedIndex ==
                      1 // Show FAB on Home and Matches/Events tab
              ? FloatingActionButton(
                onPressed: () {
                  _showPostOptions(context);
                },
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Post new content',
              )
              : null, // Hide FAB on other tabs
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
  // Accept the key
  const _HomeTab({Key? key}) : super(key: key);

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _upcomingMatches = [];
  List<Map<String, dynamic>> _latestNews = [];

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
  }

  // Public method to allow refreshing data from outside
  Future<void> refreshData() async {
    await _fetchHomeData();
  }

  Future<void> _fetchHomeData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch upcoming matches
      final matchesCollection = MongoDBService.getCollection('matches');
      final matchCursor = matchesCollection
          .find({'status': 'upcoming', 'isHighlighted': true})
          .take(3);

      // Fetch latest news - fix the aggregation pipeline
      final newsCollection = MongoDBService.getCollection('news');

      // Use find() with sort instead of aggregate for simpler handling
      final newsCursor = newsCollection.find().take(3);
      // Sort the news by dateTime field (newest first)
      final newsList = await newsCursor.toList();
      newsList.sort(
        (a, b) => DateTime.parse(
          b['dateTime'].toString(),
        ).compareTo(DateTime.parse(a['dateTime'].toString())),
      );

      // Process the results
      final matchesList = await matchCursor.toList();

      setState(() {
        _upcomingMatches =
            matchesList.map((doc) => doc as Map<String, dynamic>).toList();
        _latestNews =
            newsList.map((doc) => doc as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching home data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Your existing welcome content
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/player_avatar_male.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to Hocky.org NA',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your hockey management app',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // Upcoming Matches Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Text(
                  'Upcoming Matches',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to all matches screen
                  },
                  child: Text('---------------'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Display featured matches
          if (_upcomingMatches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No upcoming matches scheduled'),
            )
          else
            ..._upcomingMatches.map((match) {
              final matchDate = DateTime.parse(match['dateTime'].toString());
              final formattedDate =
                  '${_getWeekdayShort(matchDate)}, ${_getMonthShort(matchDate)} ${matchDate.day} • ${_formatTime(matchDate)}';

              return Column(
                children: [
                  _FeaturedItem(
                    title: match['title'],
                    subtitle: match['venue'],
                    description: '${match['teamA']} vs ${match['teamB']}',
                    dateTime: formattedDate,
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),

          const SizedBox(height: 32),

          // Latest News Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Text(
                  'Latest News',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to all news screen
                  },
                  child: Text('----------------------'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Display news items
          if (_latestNews.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No news available'),
            )
          else
            ..._latestNews.map((news) {
              final newsDate = DateTime.parse(news['dateTime'].toString());
              final daysAgo = DateTime.now().difference(newsDate).inDays;
              final formattedDate =
                  daysAgo == 0
                      ? 'Today'
                      : daysAgo == 1
                      ? 'Yesterday'
                      : '$daysAgo days ago';

              return Column(
                children: [
                  _FeaturedItem(
                    title: news['title'],
                    subtitle: news['subtitle'],
                    description: news['description'],
                    dateTime: 'Posted $formattedDate',
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Helper methods for date formatting
  String _getWeekdayShort(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  String _getMonthShort(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[date.month - 1];
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
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
                                builder: (context) => const LoginScreen(),
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
