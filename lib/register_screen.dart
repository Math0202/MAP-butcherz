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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // No need to define specific colors anymore - use theme system
    
    return Scaffold(
      // Use theme's background color
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Text(
                  'Create an account',
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please fill the credentials',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 40),

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
                  keyboardType: TextInputType.phone, // Use phone keyboard type
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  // controller: _usernameController,
                  hintText: 'Gender',
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.phone, // Use phone keyboard type
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  // controller: _usernameController,
                  hintText: 'Age',
                  prefixIcon: Icons.numbers_outlined,
                  keyboardType: TextInputType.phone, // Use phone keyboard type
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
                const SizedBox(height: 40),

                // --- Sign Up Button ---
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
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
                    },
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
} 