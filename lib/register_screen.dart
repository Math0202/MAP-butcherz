import 'package:flutter/material.dart';
import 'package:hocky_na_org/elements/custom_text_field.dart';
import 'package:hocky_na_org/login_screen.dart'; // To navigate back
import 'package:hocky_na_org/home_page.dart'; // Placeholder for navigation after sign up
import 'package:hocky_na_org/verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final ScrollController _scrollController = ScrollController();
  bool _isTermsAccepted = false;
  bool _showTermsSheet = false;

  // TODO: Add TextEditingControllers for email, username, password, confirm password
  // final _emailController = TextEditingController();
  // final _usernameController = TextEditingController();
  // final _passwordController = TextEditingController();
  // final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    // TODO: Dispose controllers
    // _emailController.dispose();
    // _usernameController.dispose();
    // _passwordController.dispose();
    // _confirmPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // No need to define specific colors anymore - use theme system
    
    return Scaffold(
      // Add AppBar with back navigation
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Create Account'),
        centerTitle: true,
        elevation: 0, // Remove shadow for a cleaner look
        backgroundColor: Colors.transparent, // Use transparent to match the background
      ),
      // Use theme's background color
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), // Reduced top padding since we have an AppBar now
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Optional: Remove or adjust the header since we now have a title in the AppBar
                // Text(
                //   'Create an account',
                //   style: theme.textTheme.headlineLarge,
                // ),
                // const SizedBox(height: 8),
                Text(
                  'Please fill the credentials',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 30), // Reduced spacing

                // --- Email Field ---
                CustomTextField(
                  // controller: _emailController,
                  hintText: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // --- Phone Number Field ---
                CustomTextField(
                  // controller: _usernameController,
                  hintText: 'Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone, // Use phone keyboard type
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  // controller: _usernameController,
                  hintText: 'Field position',
                  prefixIcon: Icons.location_pin,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  // controller: _usernameController,
                  hintText: 'Gender',
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  // controller: _usernameController,
                  hintText: 'Age',
                  prefixIcon: Icons.numbers_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                // --- Password Field ---
                CustomTextField(
                  // controller: _passwordController,
                  hintText: 'Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  keyboardType: TextInputType.visiblePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: theme.hintColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // --- Confirm Password Field ---
                CustomTextField(
                  // controller: _confirmPasswordController,
                  hintText: 'Confirm password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isConfirmPasswordVisible,
                  keyboardType: TextInputType.visiblePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: theme.hintColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                // --- Terms and Conditions Checkbox ---
                Row(
                  children: [
                    Checkbox(
                      value: _isTermsAccepted,
                      onChanged: (bool? value) {
                        setState(() {
                          _isTermsAccepted = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Show Terms and Conditions
                          _showTermsAndConditions(context);
                        },
                        child: Text(
                          'I accept the Terms and Conditions',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // --- Sign Up Button ---
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isTermsAccepted 
                        ? () {
                          // TODO: Implement Sign Up Logic (validation, API call, etc.)
                          
                          // Navigate to verification screen instead of Homepage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VerificationScreen(
                                contact: 'your mobile number', // Ideally this should be dynamically populated
                                isForgotPassword: false, // This is for signup flow
                              ),
                            ),
                          );
                        }
                        : null, // Disable button if terms not accepted
                    // Use theme styling instead of custom style
                    child: const Text('Sign up'),
                  ),
                ),
                const SizedBox(height: 30),

                // --- Already have an account? ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate back to Login Screen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Log in',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to show terms and conditions in a modal bottom sheet
  void _showTermsAndConditions(BuildContext context) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Make it larger
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7, // 70% of screen height
              minChildSize: 0.5, // Min 50% of screen height
              maxChildSize: 0.9, // Max 90% of screen height
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Header with close button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Terms and Conditions',
                            style: theme.textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    
                    // Divider below header
                    Divider(height: 1, color: theme.dividerColor),
                    
                    // Terms content (scrollable)
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Same terms content from TandCs.dart
                            Text(
                              '1. ACCEPTANCE OF TERMS',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'By accessing and using the Hockey NA Mobile App (the "App"), you accept and agree to be bound by the terms and conditions of this agreement. If you do not agree to these terms, please do not use the App.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              '2. USER ACCOUNT',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'To use certain features of the App, you may be required to register for an account. You agree to provide accurate, current, and complete information during the registration process and to update such information to keep it accurate, current, and complete.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              '3. PRIVACY POLICY',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your information. By using the App, you agree to the collection and use of information in accordance with our Privacy Policy.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              '4. USER CONDUCT',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You agree not to use the App to:\n• Violate any applicable laws or regulations\n• Infringe on the rights of others\n• Distribute harmful or offensive content\n• Impersonate any person or entity\n• Interfere with the operation of the App',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              '5. INTELLECTUAL PROPERTY',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All content, features, and functionality of the App are owned by Hockey NA and are protected by copyright, trademark, and other intellectual property laws.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              '6. TERMINATION',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We reserve the right to terminate or suspend your account and access to the App at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties, or for any other reason.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              '7. DISCLAIMER OF WARRANTIES',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              '8. LIMITATION OF LIABILITY',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'IN NO EVENT SHALL HOCKEY NA BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING, WITHOUT LIMITATION, LOSS OF PROFITS, DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES, RESULTING FROM YOUR ACCESS TO OR USE OF OR INABILITY TO ACCESS OR USE THE APP.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Accept button at the bottom
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isTermsAccepted,
                            onChanged: (bool? value) {
                              setState(() {
                                _isTermsAccepted = value ?? false;
                              });
                              setSheetState(() {}); // Update the sheet UI
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'I agree to the Terms and Conditions',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 16),
                          FilledButton(
                            onPressed: () {
                              if (!_isTermsAccepted) {
                                setState(() {
                                  _isTermsAccepted = true;
                                });
                              }
                              Navigator.of(context).pop();
                            },
                            child: const Text('Accept'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
} 