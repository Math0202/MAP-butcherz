import 'package:flutter/material.dart';
// Remove homepage import
// import 'package:hocky_na_org/home_page.dart';
import 'package:hocky_na_org/login_screen.dart'; // Import the Login Screen

class TeamQueryScreen extends StatelessWidget {
  const TeamQueryScreen({super.key});

  // Updated helper method for navigation
  void _navigateToLogin(BuildContext context) {
    // Use pushReplacement if you don't want users going back to the query screen
    // Use push if you want them to be able to go back
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
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
                // "Yes" Button - Navigates to Login
                FilledButton(
                  onPressed: () {
                    // Navigate to Login Screen
                    _navigateToLogin(context);
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
                // "No" Button - Also navigates to Login for now (can change later)
                OutlinedButton(
                  onPressed: () {
                    // Navigate to Login Screen (or potentially a registration screen later)
                    _navigateToLogin(context);
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