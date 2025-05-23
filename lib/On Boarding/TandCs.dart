import 'package:flutter/material.dart';
// Remove homepage import if not needed elsewhere
// import 'package:hocky_na_org/home_page.dart';
import 'package:hocky_na_org/team_management/team_query_screen.dart';

import '../veiws/coach/login_screen.dart';
import '../veiws/player/register_screen.dart'; // Import the new screen

class TandCs extends StatefulWidget {
  const TandCs({Key? key}) : super(key: key);

  @override
  State<TandCs> createState() => _TandCsState();
}

class _TandCsState extends State<TandCs> {
  final ScrollController _scrollController = ScrollController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(
      _onScroll,
    ); // Best practice to remove listener
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if the user is close to the bottom (more user-friendly)
    if (_scrollController.position.extentAfter < 100) {
      // Enable when near the bottom
      if (!_isButtonEnabled) {
        // Only call setState if the state changes
        setState(() {
          _isButtonEnabled = true;
        });
      }
    } else {
      if (_isButtonEnabled) {
        // Only call setState if the state changes
        setState(() {
          _isButtonEnabled = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    return Scaffold(
      // Use AppBar for a standard title area
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        backgroundColor: Colors.white, // Clean white background
        foregroundColor: Colors.black, // Black title text
        elevation: 1, // Subtle shadow
        centerTitle: true, // Center title
      ),
      backgroundColor: Colors.grey[100], // Slightly lighter background
      body: SafeArea(
        // Ensures content avoids notches/system UI
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16.0,
            0,
            16.0,
            16.0,
          ), // Add horizontal and bottom padding
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretch children horizontally
            children: [
              // Scrollable Text Area
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  margin: const EdgeInsets.only(
                    top: 16.0,
                  ), // Add space above the box
                  decoration: BoxDecoration(
                    color: Colors.white, // White background for text box
                    borderRadius: BorderRadius.circular(
                      12.0,
                    ), // Rounded corners
                    boxShadow: [
                      // Subtle shadow for depth
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Scrollbar(
                    // Add a scrollbar for visual feedback
                    thumbVisibility: true, // Always show scrollbar thumb
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                      ), // Padding inside scroll view
                      child: Text(
                        // Your T&Cs text remains the same
                        """OnHockey Mobile App - Terms and Conditions for Hockey Players \n Last Updated: [30/01/2024]  \n Welcome to OnHockey, the ultimate mobile app for hockey enthusiasts. Please read these terms and conditions carefully before using our app.  \n 1. Acceptance of Terms  \n By downloading, installing, or using the OnHockey mobile app ("App"), you agree to comply with and be bound by these terms and conditions. If you do not agree to these terms, please do not use the App.  \n 2. User Registration \n To access certain features of the App, you may be required to register for an account. You agree to provide accurate, current, and complete information during the registration process and to update such information to keep it accurate, current, and complete.  \n 3. Use of the App  \n a. Eligibility: You must be at least 16 years old to use the App for inputting scores and for online payments unless permitted by an elder or guardian to do so.  \n b. License: We grant you a personal, non-exclusive, non-transferable, limited license to use the App solely for your personal and non-commercial purposes.  \n c. Prohibited Activities: You agree not to engage in any of the following activities:  \n - Violating any applicable laws or regulations.  \n - Using the App for any purpose that is illegal or prohibited by these terms.  \n - Interfering with the security features of the App.  \n - Attempting to access or use another user's account without authorization.  \n 4. Content and Submissions  \n a. User-Generated Content: You may have the opportunity to submit content, such as scores, stats, reviews, or comments. By submitting content, you grant us a worldwide, non-exclusive, royalty-free, sublicensable license to use, reproduce, adapt, publish, translate, and distribute such content.  \n b. Content Guidelines: You agree not to submit any content that is unlawful, obscene, defamatory, threatening, invasive of privacy, or infringing on intellectual property rights.  \n 5. Privacy Policy  \n Your use of the App is also governed by our Privacy Policy. Please review the Privacy Policy to understand our practices.  \n 6. Modifications  \n We reserve the right to modify or discontinue the App at any time without notice. We also reserve the right to update or modify these terms at any time.  \n 7. Termination  \n We may terminate or suspend your access to the App without prior notice for any reason, including a breach of these terms.  \n 8. Disclaimer of Warranties  \n The App is provided on an "as-is" basis. We make no warranties, express or implied, regarding the accuracy, completeness, reliability, or suitability of the App.  \n 9. Limitation of Liability  \n To the extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages.  \n 10. Governing Law  \n These terms and conditions are governed by and construed in accordance with the laws of The Republic of Namibia.  \n By using the App, you agree to these terms and conditions. If you have any questions, please contact us at [Onhockeytech@gmail.com].""",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          // Use theme's body style
                          color: Colors.black87, // Slightly softer black
                          height: 1.5, // Improve line spacing for readability
                        ),
                        // Removed TextAlign.center for better readability of long text
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20), // Space before the button
              // Modern Accept Button
              FilledButton(
                // Using Material 3 FilledButton
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _isButtonEnabled
                          ? theme
                              .colorScheme
                              .primary // Use primary color when enabled
                          : Colors.grey[400], // Grey out when disabled
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                  ), // Taller button
                  shape: RoundedRectangleBorder(
                    // Rounded corners
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    // Use theme's title style
                    fontWeight: FontWeight.bold,
                    color:
                        Colors.white, // Ensure text is white on colored button
                  ),
                ).copyWith(
                  // Ensure foreground (text) color is handled correctly when disabled
                  foregroundColor: MaterialStateProperty.resolveWith<Color?>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.white70; // Lighter text when disabled
                    }
                    return Colors.white; // Default white text
                  }),
                ),
                onPressed:
                    _isButtonEnabled
                        ? () => navigateToNextScreen(context)
                        : null, // onPressed is null when disabled
                child: const Text('BACK TO SIGNUP'), // Clearer button text
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to navigate to the next screen (Team Query Screen)
  void navigateToNextScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => const RegisterScreen(), // Navigate to TeamQueryScreen
      ),
    );
  }
}
