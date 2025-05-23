import 'package:flutter/material.dart';
import 'package:hocky_na_org/veiws/coach/coach_home_page.dart'; // For navigation after login
import 'package:hocky_na_org/elements/custom_text_field.dart'; // Import custom text field
import 'package:hocky_na_org/elements/social_login_button.dart';
import 'package:hocky_na_org/veiws/coach/verification_screen.dart'; // Import the Verification Screen
import 'package:hocky_na_org/services/user_service.dart';
import 'package:hocky_na_org/team_management/team_query_screen.dart'; // Import social button
import 'package:hocky_na_org/services/mongodb_service.dart';

// Add these imports for HTTP requests and JSON encoding
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  bool _keepMeSignedIn = false;
  bool _isLoading = false;

  // Add TextEditingControllers for email and password
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Check if email exists as a coach and get phone number
  Future<Map<String, dynamic>?> _checkCoachEmail(String email) async {
    try {
      final teamsCollection = MongoDBService.getCollection('teams');
      final coach = await teamsCollection.findOne({'coachEmail': email});

      if (coach != null) {
        return {
          'coachName': coach['coachName'],
          'coachPhone': coach['coachPhone'],
          'name': coach['name'],
        };
      }
      return null;
    } catch (e) {
      print('Error checking coach email: $e');
      return null;
    }
  }

  // Login method
  Future<void> _login() async {
    // Basic validation
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String email = _emailController.text.trim();

      // Check if email exists as a coach
      final coachData = await _checkCoachEmail(email);

      if (coachData != null && coachData['coachPhone'] != null) {
        // Coach found with phone number, navigate to verification
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => VerificationScreen(
                  phoneNumber: coachData['coachPhone'],
                  email: email,
                  coachName: coachData['coachName'],
                  teamName: coachData['name'],
                ),
          ),
        );
      } else {
        // No coach found with this email
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email not found. Please check with your club administrator.',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme
    // No need to define colors here anymore, they come from the theme!
    // final backgroundColor = Colors.grey[100]; // REMOVE
    // const textFieldColor = Colors.white; // REMOVE (or get from theme if needed)
    // final buttonColor = theme.colorScheme.primary; // REMOVE (use theme directly)
    // const textColor = Colors.black87; // REMOVE (use theme)
    // const hintColor = Colors.black54; // REMOVE (use theme)

    return Scaffold(
      // backgroundColor is handled by theme's scaffoldBackgroundColor
      body: SafeArea(
        child: SingleChildScrollView(
          // Allows scrolling when keyboard appears
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
                  'Coach Log in',
                  // Use headlineLarge style defined in the theme
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please enter your email to receive a verification code',
                  // Use bodyMedium style and maybe adjust color slightly if needed
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor, // Use theme's hint color
                  ),
                ),
                const SizedBox(height: 40),

                // --- Email Field ---
                CustomTextField(
                  hintText: 'Email',
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                ),
                const SizedBox(height: 20),

                // --- Keep Signed In ---
                Row(
                  children: [
                    SizedBox(
                      height: 24.0,
                      width: 24.0,
                      child: Checkbox(
                        value: _keepMeSignedIn,
                        onChanged: (bool? value) {
                          setState(() {
                            _keepMeSignedIn = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Keep me signed in',
                      // Use theme's bodyMedium style
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // --- Log In Button ---
                SizedBox(
                  width: double.infinity,
                  // FilledButtonTheme in main.dart handles styling
                  child: FilledButton(
                    onPressed: _isLoading ? null : _login,
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Continue'),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
