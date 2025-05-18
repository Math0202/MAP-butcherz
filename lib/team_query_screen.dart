import 'package:flutter/material.dart';
// Remove homepage import
// import 'package:hocky_na_org/home_page.dart';

import 'home_page.dart'; // Import the Login Screen
import 'login_screen.dart'; // Assuming "YES" goes to login or find club
import 'register_team_screen.dart'; // Import the new screen

class TeamQueryScreen extends StatelessWidget {
  final String email;
  
  const TeamQueryScreen({
    super.key,
    required this.email,
  });

  // Updated helper method for navigation for "YES" button
  void _navigateToLoginOrFindClub(BuildContext context) {
    // This should ideally go to a screen where users can search for their club
    // For now, let's assume it goes to the login screen, then they can find their team
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Homepage()), // Passing email to Homepage
    );
  }

  // Helper method for "NO" button
  void _navigateToCreateClub(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterTeamScreen(email: email)), // Passing email to RegisterTeamScreen
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.asset(
                    'assets/hocky_circle.jpg',
                    height: screenHeight * 0.4,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
                Text(
                  'Do you already have a registered club?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                // "Yes" Button - Navigates to Login or Find Club
                FilledButton(
                  onPressed: () {
                    _navigateToLoginOrFindClub(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  child: const Text('YES, FIND CLUB'),
                ),
                const SizedBox(height: 16),
                // "No" Button - Navigates to Register Team Screen
                OutlinedButton(
                  onPressed: () {
                    _navigateToCreateClub(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('NO, CREATE NEW CLUB'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 