import 'package:flutter/material.dart';
import 'package:hocky_na_org/veiws/admin/admin_Updates.dart';
import 'package:hocky_na_org/team_management/manage_roster_screen.dart'; // Import the ManageRosterScreen
import 'package:hocky_na_org/veiws/coach/enter_events_screen.dart'; // Import the new screen
import 'package:hocky_na_org/veiws/coach/notifications_screen.dart'; // Import the NotificationsScreen
import 'package:hocky_na_org/veiws/coach/notifications_screen.dart'
    show NotificationItem;
import 'package:hocky_na_org/services/user_service.dart';
import 'package:hocky_na_org/veiws/coach/coach_login_screen.dart';
import 'package:hocky_na_org/services/mongodb_service.dart'; // Add this import
import 'package:mongo_dart/mongo_dart.dart' show where;

import 'admin_games.dart';
import 'home_tab.dart'; // Ensure mongo_dart is imported for 'where'

class adminHomePage extends StatefulWidget {
  const adminHomePage({super.key});

  @override
  State<adminHomePage> createState() => _adminHomePageState();
}

class _adminHomePageState extends State<adminHomePage> {
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
      adminHomeTab(), // Assign the key to _HomeTab
      AdminGames(),
      AdminUpdates(), // Placeholder for the Updates tab
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
            label: 'Clubs',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_hockey_outlined),
            selectedIcon: Icon(Icons.sports_hockey),
            label: 'Games',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notification_add_outlined),
            label: 'Anouncements',
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
