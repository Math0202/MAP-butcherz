import 'package:flutter/material.dart';
import 'package:hocky_na_org/elements/custom_text_field.dart'; // Import custom text field
import 'package:hocky_na_org/elements/social_login_button.dart';
import 'package:hocky_na_org/veiws/admin/admin_home_page.dart';

class admin_login extends StatefulWidget {
  const admin_login({super.key});

  @override
  State<admin_login> createState() => _admin_loginState();
}

class _admin_loginState extends State<admin_login> {
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
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Hardcoded admin credentials
      const String adminEmail = 'super@admin.com';
      const String adminPassword = 'Password123';

      final enteredEmail = _emailController.text.trim();
      final enteredPassword = _passwordController.text;

      // Check if credentials match hardcoded admin credentials
      if (enteredEmail == adminEmail && enteredPassword == adminPassword) {
        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome Super Admin! Login successful.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate directly to admin home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const adminHomePage()),
        );
      } else {
        // Invalid credentials
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );

        // Clear the password field for security
        _passwordController.clear();
      }
    } catch (e) {
      print('Error during admin login: $e');
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
                  'Admin log in',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
