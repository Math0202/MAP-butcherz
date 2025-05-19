import 'package:flutter/material.dart';
import 'package:hocky_na_org/elements/custom_text_field.dart';
import 'package:hocky_na_org/home_page.dart'; // For navigation after registration

class RegisterTeamScreen extends StatefulWidget {
  const RegisterTeamScreen({super.key});

  @override
  State<RegisterTeamScreen> createState() => _RegisterTeamScreenState();
}

class _RegisterTeamScreenState extends State<RegisterTeamScreen> {
  // TODO: Add TextEditingControllers for team name, coach name, coach contact
  // final _teamNameController = TextEditingController();
  // final _coachNameController = TextEditingController();
  // final _coachContactController = TextEditingController();

  // Placeholder for selected logo
  String? _selectedLogoPath; // In a real app, this might be a File object

  @override
  void dispose() {
    // TODO: Dispose controllers
    // _teamNameController.dispose();
    // _coachNameController.dispose();
    // _coachContactController.dispose();
    super.dispose();
  }

  void _pickLogo() {
    // TODO: Implement image picker logic
    // For now, simulate picking a logo
    setState(() {
      _selectedLogoPath = 'assets/logo_placeholder.png'; // A placeholder image
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logo picker not implemented yet.')),
    );
  }

  void _registerTeam() {
    // TODO: Implement team registration logic (validate, API call)
    // For now, navigate to homepage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Homepage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Team'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your team details below',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // --- Team Name Field ---
              CustomTextField(
                // controller: _teamNameController,
                hintText: 'Team Name',
                prefixIcon: Icons.shield_outlined,
              ),
              const SizedBox(height: 20),

              // --- Team Logo Upload ---
              Text(
                'Team Logo',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: _selectedLogoPath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 50,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to upload logo',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect( // To ensure the image respects border radius
                            borderRadius: BorderRadius.circular(10.5), // slightly less than container
                            child: Image.asset( // In a real app, use Image.file or Image.network
                              _selectedLogoPath!,
                              fit: BoxFit.contain, // or BoxFit.cover depending on needs
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image, size: 50);
                              },
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Coach Details Section ---
              Text(
                'Coach Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                // controller: _coachNameController,
                hintText: 'Coach Full Name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                // controller: _coachContactController,
                hintText: 'Coach Contact (Email or Phone)',
                prefixIcon: Icons.contact_mail_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 40),

              // --- Register Button ---
              FilledButton(
                onPressed: _registerTeam,
                child: const Text('Register Team'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 