import 'package:flutter/material.dart';
import 'package:hocky_na_org/home_page.dart'; // For navigation after login
import 'package:hocky_na_org/elements/custom_text_field.dart'; // Import custom text field
import 'package:hocky_na_org/elements/social_login_button.dart';
import 'package:hocky_na_org/register_screen.dart'; // Import the Register Screen
import 'package:hocky_na_org/verification_screen.dart'; // Import the Verification Screen
import 'package:hocky_na_org/services/user_service.dart';
import 'package:hocky_na_org/team_query_screen.dart'; // Import social button

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

  // Login method
  Future<void> _login() async {
    // Basic validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Show a notification that a security SMS will be sent
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'For your security, a notification will be sent to your registered phone number',
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final result = await UserService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success'] == true) {
        // Navigate to appropriate screen after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
        );
      } else if (result['unverified'] == true) {
        // User exists but is not verified, send to verification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your account is not verified, your clan will be notified',
            ),
          ),
        );

        // Navigate to verification screen with the user's ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    TeamQueryScreen(email: _emailController.text.trim()),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Login failed')),
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
                  'Log in',
                  // Use headlineLarge style defined in the theme
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please fill in your credentials',
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

                // --- Password Field ---
                CustomTextField(
                  hintText: 'Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  keyboardType: TextInputType.visiblePassword,
                  controller: _passwordController,
                  suffixIcon: IconButton(
                    // Use theme's hint color for the icon
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
                  // Let CustomTextField use InputDecorationTheme defaults
                  // textFieldColor: textFieldColor, // REMOVE
                  // hintColor: hintColor, // REMOVE
                ),
                const SizedBox(height: 16),

                // --- Keep Signed In & Forgot Password ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 24.0,
                          width: 24.0,
                          // CheckboxTheme in main.dart handles styling
                          child: Checkbox(
                            value: _keepMeSignedIn,
                            onChanged: (bool? value) {
                              setState(() {
                                _keepMeSignedIn = value ?? false;
                              });
                            },
                            // activeColor: buttonColor, // REMOVE
                            // checkColor: Colors.white, // REMOVE
                            // side: BorderSide(color: hintColor), // REMOVE
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
                    TextButton(
                      onPressed: () {
                        // Navigate to verification screen for password reset
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const VerificationScreen(
                                  isForgotPassword: true,
                                ),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot password?',
                        // Use theme's bodyMedium style
                        style: theme.textTheme.bodyMedium,
                      ),
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
                            : const Text('Log in'),
                  ),
                ),
                const SizedBox(height: 30),

                // --- Create Account ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      // Use theme's bodyMedium style
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to Register Screen
                        Navigator.push(
                          // Use push to allow going back
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
                        // Use theme's bodyMedium style, maybe make primary color?
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary, // Make it stand out
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // --- Divider ---
                Row(
                  children: [
                    // Use theme's divider color
                    Expanded(
                      child: Divider(color: theme.dividerColor, thickness: 0.8),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'or continue with',
                        // Use theme's bodySmall style and hint color
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: theme.dividerColor, thickness: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // --- Social Logins ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SocialLoginButton(
                        label: 'Google',
                        iconAsset: 'assets/google_icon.png',
                        onPressed: () {
                          // TODO: Implement Google Sign-In
                        },
                        // Let SocialLoginButton use theme defaults or define its own theme-aware style
                        // buttonColor: textFieldColor, // REMOVE
                        // textColor: textColor, // REMOVE
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SocialLoginButton(
                        label: 'Apple',
                        iconAsset: 'assets/apple_icon.jpg',
                        isApple: true,
                        onPressed: () {
                          // TODO: Implement Apple Sign-In
                        },
                        // Let SocialLoginButton use theme defaults or define its own theme-aware style
                        // buttonColor: textFieldColor, // REMOVE
                        // textColor: textColor, // REMOVE
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
