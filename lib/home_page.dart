import 'package:flutter/material.dart';
import 'package:hocky_na_org/manage_roster_screen.dart'; // Import the ManageRosterScreen
import 'package:hocky_na_org/enter_events_screen.dart'; // Import the new screen
import 'package:hocky_na_org/notifications_screen.dart'; // Import the NotificationsScreen
import 'package:hocky_na_org/notifications_screen.dart' show NotificationItem;
import 'package:hocky_na_org/services/user_service.dart';
import 'package:hocky_na_org/login_screen.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;
  int _unreadNotificationsCount = 0; // State variable for the count

  // Define the pages to be shown for each tab
  final List<Widget> _pages = [
    const _HomeTab(), // Dashboard/Home content
    const EnterEventsScreen(), // Games/Matches content
    const ManageRosterScreen(), // Teams content
    const _ProfileTab(), // Profile content
  ];

  @override
  void initState() {
    super.initState();
    _fetchUnreadNotificationsCount(); // Fetch initial count
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                builder: (context) => AlertDialog(
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
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(
                  'assets/player_avatar_male.png',
                ), // Replace with your image
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
          const _FeaturedItem(
            title: 'Upcoming Match',
            subtitle: 'Central Stadium',
            description: 'Blue Eagles vs Red Hawks',
            dateTime: 'Sun, June 15 • 2:30 PM',
          ),
          const SizedBox(height: 16),
          const _FeaturedItem(
            title: 'Latest News',
            subtitle: 'Hockey Association',
            description: 'Summer League Registration Open',
            dateTime: 'Posted 2 days ago',
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

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Placeholder user data
    const String userName = 'Alex Johnson';
    const String userEmail = 'alex.johnson@example.com';
    const String userAvatarUrl =
        'assets/player_avatar_male.png'; // Add a placeholder avatar

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: const AssetImage(userAvatarUrl), // Use AssetImage
            child:
                !userAvatarUrl.contains('assets/') // Fallback if image fails
                    ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
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
            icon: Icons.shield_outlined, // Icon for team management
            title: 'Manage My Roster', // Text for the new item
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageRosterScreen(),
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
              // TODO: Implement logout
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
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyLarge),
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
