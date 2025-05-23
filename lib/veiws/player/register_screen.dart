import 'package:flutter/material.dart';
import 'package:hocky_na_org/elements/custom_text_field.dart';
import 'package:hocky_na_org/veiws/coach/login_screen.dart'; // To navigate back
import 'package:hocky_na_org/veiws/coach/coach_home_page.dart'; // Placeholder for navigation after sign up
import 'package:hocky_na_org/veiws/player/verification_screen.dart';
import 'package:hocky_na_org/services/user_service.dart';

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
  bool _isLoading = false;

  // Add TextEditingControllers for user data
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fieldPositionController = TextEditingController();
  final _genderController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // For storing user ID after successful registration
  String? _registeredUserId;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _fieldPositionController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Validate form fields
  String? _validateForm() {
    if (_fullNameController.text.isEmpty) {
      return 'Full name is required';
    }
    if (_emailController.text.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      return 'Please enter a valid email address';
    }
    if (_phoneController.text.isEmpty) {
      return 'Phone number is required';
    }
    if (_passwordController.text.isEmpty) {
      return 'Password is required';
    }
    if (_passwordController.text.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Passwords do not match';
    }
    if (!_isTermsAccepted) {
      return 'You must accept the terms and conditions';
    }
    return null;
  }

  // Register user
  Future<void> _registerUser() async {
    // Validate form
    final validationError = _validateForm();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError))
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      print("Attempting to register user with email: ${_emailController.text} and phone: ${_phoneController.text}");
      
      final result = await UserService.registerUser(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        fieldPosition: _fieldPositionController.text.trim(),
        gender: _genderController.text.trim(),
        age: _ageController.text.trim(),
      );
      
      print("Registration result: $result");
      
      if (result['success'] == true) {
        // Store user ID for verification step
        _registeredUserId = result['userId'];
        print("User registered with ID: $_registeredUserId");
        
        // Navigate to verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(
              contact: _phoneController.text.trim(),
              isForgotPassword: false,
              userId: _registeredUserId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Registration failed'))
        );
      }
    } catch (e) {
      print("Registration exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e'))
      );
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
    final theme = Theme.of(context);
    
    return Scaffold(
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
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), // Reduced top padding since we have an AppBar now
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Hocky.na',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create an account to get started',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Full Name Field
                CustomTextField(
                  controller: _fullNameController,
                  hintText: 'Full Name',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                
                // Email Field
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                
                // Phone Field
                CustomTextField(
                  controller: _phoneController,
                  hintText: 'Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                
                // Field Position
                CustomTextField(
                  controller: _fieldPositionController,
                  hintText: 'Field Position (Optional)',
                  prefixIcon: Icons.sports_hockey_outlined,
                ),
                const SizedBox(height: 16),
                
                // Gender Field
                CustomTextField(
                  controller: _genderController,
                  hintText: 'Gender (Optional)',
                  prefixIcon: Icons.people_outline,
                ),
                const SizedBox(height: 16),
                
                // Age Field
                CustomTextField(
                  controller: _ageController,
                  hintText: 'Age (Optional)',
                  prefixIcon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: theme.hintColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Confirm Password Field
                CustomTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isConfirmPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: theme.hintColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Terms and Conditions Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _isTermsAccepted,
                      onChanged: (value) {
                        setState(() {
                          _isTermsAccepted = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Set isTermsAccepted to true when text is tapped
                          setState(() {
                            _showTermsSheet = true;
                          });
                          _showTermsAndConditions(context);
                        },
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodySmall,
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _registerUser,
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Sign In Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate back to login screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
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
