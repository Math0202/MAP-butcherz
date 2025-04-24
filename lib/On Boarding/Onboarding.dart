import 'package:flutter/material.dart';
import 'package:hocky_na_org/home_page.dart'; // Import the placeholder Homepage
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../login_screen.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController _controller = PageController();
  bool _onLastPage = false; // Last page will now be index 3

  void navigateToTandCs(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          //scrolling page view - Now with 4 pages
          PageView(
            onPageChanged: (index) => {
              setState(() {
                // Update check for the last page (index 3 for 4 pages)
                _onLastPage = (index == 3);
              })
            },
            controller: _controller,
            children: [
              // --- Page 1: Team Registration (FR1) ---
              _buildOnboardingPage(
                imagePath: 'assets/hocky.jpg', // Replace if needed
                title: 'Register Your Team',
                description:
                    'Easily register your hockey team with its name, logo, and coach details to get started.',
              ),
              // --- Page 2: Player Management (FR2) ---
              _buildOnboardingPage(
                imagePath: 'assets/love_hocky.jpg', // Replace if needed
                title: 'Manage Your Roster',
                description:
                    'Add players to your team, assign positions, and keep all player information up-to-date in one place.',
              ),
              // --- Page 3: Event Entries (FR3) ---
              _buildOnboardingPage(
                imagePath: 'assets/hocky2.jpg', // Replace if needed
                title: 'Enter Events',
                description:
                    'Browse upcoming tournaments and leagues, register your team for events, and view schedules and venues.',
              ),
              // --- Page 4: Real-Time Info (FR4) ---
              _buildOnboardingPage(
                // Consider a new image for this page if available
                imagePath: 'assets/hocky_green.jpg', // Placeholder, replace if needed
                title: 'Stay Updated',
                description:
                    'Get live match scores, important announcements, news alerts, and other updates pushed directly to your device.',
              ),
            ],
          ),

          //dot indicator and navigation buttons
          Container(
            alignment: const Alignment(0, 0.90),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //skip button
                  TextButton(
                    onPressed: () {
                      navigateToTandCs(context);
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                  //dots - Updated count to 4
                  SmoothPageIndicator(
                    controller: _controller,
                    count: 4, // Updated count
                    effect: ExpandingDotsEffect(
                      activeDotColor: Theme.of(context).colorScheme.primary,
                      dotColor: Colors.white70,
                      dotHeight: 10,
                      dotWidth: 10,
                    ),
                  ),

                  //next or done button
                  TextButton(
                    onPressed: () {
                      if (_onLastPage) {
                        navigateToTandCs(context);
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    child: Text(
                      _onLastPage ? 'Done' : 'Next',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build consistent onboarding pages
  Widget _buildOnboardingPage({
    required String imagePath,
    required String title,
    required String description,
  }) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          // Add a color filter for better text readability if needed
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3), // Adjust opacity as needed
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2), // Adjust spacing
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32, // Slightly smaller for potentially longer titles
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20), // Space between title and description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0), // Adjust padding
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500, // Slightly less bold than title
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(flex: 3), // Adjust spacing before bottom controls
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
