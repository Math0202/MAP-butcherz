import 'package:flutter/material.dart';
import 'package:hocky_na_org/elements/custom_text_field.dart'; // Import custom text field
import 'package:hocky_na_org/elements/social_login_button.dart';
import 'package:hocky_na_org/services/user_service.dart';
import 'package:hocky_na_org/team_management/team_query_screen.dart'; // Import social button
import 'package:hocky_na_org/veiws/player/register_screen.dart';
import 'package:hocky_na_org/veiws/player/verification_screen.dart';

// Add these imports for HTTP requests and JSON encoding
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hocky_na_org/services/mongodb_service.dart';

class player_login extends StatefulWidget {
  const player_login({super.key});

  @override
  State<player_login> createState() => _player_loginState();
}

class _player_loginState extends State<player_login> {
  bool _keepMeSignedIn = false;
  bool _isLoading = false;

  // Add TextEditingControllers for email and password
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Login method
  Future<void> _login() async {
    // Basic validation
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch user data to check team assignment and get phone number
      final usersCollection = MongoDBService.getCollection('users');
      final user = await usersCollection.findOne({
        'email': _emailController.text.trim(),
      });

      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'User not found. Please check your email or register first.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Extract user information
      final String? phoneNumber = user['phoneNumber'] ?? user['phone'];
      final String? teamName = user['teamName'];
      final String? fullName = user['fullName'] ?? user['name'];

      print('User found: ${user['email']}');
      print('Phone: $phoneNumber');
      print('Team: $teamName');
      print('Name: $fullName');

      // Check if user has a team assigned
      if (teamName == null || teamName.toString().trim().isEmpty) {
        setState(() {
          _isLoading = false;
        });

        // Show notification that player doesn't have a team
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: const Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 48,
              ),
              title: const Text('No Team Assigned'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hello ${fullName ?? 'Player'}!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You are not currently assigned to any team. Please contact your coach or team administrator to be added to a team roster.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Tip: Make sure your coach has your correct email address',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to team query screen to select/join a team
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamQueryScreen(
                          email: _emailController.text.trim(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Browse Teams'),
                ),
              ],
            );
          },
        );
        return;
      }

      // Check if user has phone number for verification
      if (phoneNumber == null || phoneNumber.toString().trim().isEmpty) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Phone number not found. Please contact your coach to update your profile.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = false;
      });

      // Show welcome message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome ${fullName ?? 'Player'} from $teamName! SMS verification code will be sent to $phoneNumber',
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate directly to verification screen - it will handle SMS sending
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationScreen(
            phoneNumber: phoneNumber.toString(),
            email: _emailController.text.trim(),
            coachName: fullName ?? 'Player',
            teamName: teamName.toString(),
          ),
        ),
      );

    } catch (e) {
      print('Error during login: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 40.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Text(
                  'Player log in',
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your email to receive verification code',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 40),

                // --- Email Input ---
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 30),

                // --- Log In Button ---
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send Verification Code'),
                  ),
                ),
                const SizedBox(height: 30),

                // --- Create Account ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Create an account',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
