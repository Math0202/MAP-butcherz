import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hocky_na_org/elements/custom_text_field.dart';
import 'package:hocky_na_org/home_page.dart'; // For navigation after registration
import 'package:hocky_na_org/services/team_service.dart';
import 'package:hocky_na_org/services/user_state.dart';
import 'package:image_picker/image_picker.dart';

class RegisterTeamScreen extends StatefulWidget {
  final String email;

  const RegisterTeamScreen({super.key, required this.email});

  @override
  State<RegisterTeamScreen> createState() => _RegisterTeamScreenState();
}

class _RegisterTeamScreenState extends State<RegisterTeamScreen> {
  // Form controllers
  final _teamNameController = TextEditingController();
  final _coachNameController = TextEditingController();
  final _coachContactController = TextEditingController();

  // State variables
  File? _logoFile;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _teamNameController.dispose();
    _coachNameController.dispose();
    _coachContactController.dispose();
    super.dispose();
  }

  // Image picker for team logo
  Future<void> _pickLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _logoFile = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking logo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select image: ${e.toString()}')),
      );
    }
  }

  // Validate form fields
  String? _validateForm() {
    if (_teamNameController.text.isEmpty) {
      return 'Team name is required';
    }
    if (_coachNameController.text.isEmpty) {
      return 'Coach name is required';
    }
    if (_coachContactController.text.isEmpty) {
      return 'Coach contact information is required';
    }
    return null;
  }

  // Register team
  Future<void> _registerTeam(String email) async {
    // Validate form
    final validationError = _validateForm();
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await TeamService.registerTeam(
        name: _teamNameController.text.trim(),
        coachName: _coachNameController.text.trim(),
        coachContact: _coachContactController.text.trim(),
        ownerEmail: widget.email,
        logoFile: _logoFile,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Team registered successfully'),
          ),
        );

        // Navigate to homepage after success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => Homepage(
                  email: email,
                  teamName: _teamNameController.text.trim(),
                ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to register team';
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
      }
    } catch (e) {
      print("Error during team registration: $e");
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
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
      appBar: AppBar(title: const Text('Register New Team'), centerTitle: true),
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

              // Error message if present
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // --- Team Name Field ---
              CustomTextField(
                controller: _teamNameController,
                hintText: 'Team Name',
                prefixIcon: Icons.shield_outlined,
              ),
              const SizedBox(height: 20),

              // --- Team Logo Upload ---
              Text(
                'Team Logo',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
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
                    child:
                        _logoFile == null
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
                            : ClipRRect(
                              borderRadius: BorderRadius.circular(10.5),
                              child: Image.file(
                                _logoFile!,
                                fit: BoxFit.cover,
                                height: 140,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                  );
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
                controller: _coachNameController,
                hintText: 'Coach Full Name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _coachContactController,
                hintText: 'Coach Contact (Email or Phone)',
                prefixIcon: Icons.contact_mail_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 40),

              // --- Register Button ---
              FilledButton(
                onPressed:
                    _isLoading ? null : () => _registerTeam(widget.email),
                child:
                    _isLoading
                        ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                        : const Text('Register Team'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
