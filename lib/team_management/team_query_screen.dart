import 'package:flutter/material.dart';
// Remove homepage import
// import 'package:hocky_na_org/home_page.dart';

import '../veiws/coach/coach_home_page.dart'; // Import the Login Screen
import '../veiws/coach/register_team_screen.dart'; // Import the new screen
import '../services/team_service.dart';  // Import team service
import '../services/mongodb_service.dart'; // Import MongoDB service if needed
import 'package:mongo_dart/mongo_dart.dart' show modify, where; // For MongoDB operations

// Placeholder for your Team model - define this in your models directory
// class Team {
//   final String id;
//   final String name;
//   final String logoUrl;
//   final String coachName;
//   final String coachContact;
//   final String ownerEmail;
//   final DateTime createdAt;
//
//   Team({
//     required this.id,
//     required this.name,
//     required this.logoUrl,
//     required this.coachName,
//     required this.coachContact,
//     required this.ownerEmail,
//     required this.createdAt,
//   });
//
//   factory Team.fromJson(Map<String, dynamic> json) {
//     return Team(
//       id: json['_id'].toString(),
//       name: json['name'] ?? '',
//       logoUrl: json['logoUrl'] ?? '',
//       coachName: json['coachName'] ?? '',
//       coachContact: json['coachContact'] ?? '',
//       ownerEmail: json['ownerEmail'] ?? '',
//       createdAt: json['createdAt'] != null 
//           ? DateTime.parse(json['createdAt']) 
//           : DateTime.now(),
//     );
//   }
// }

// Placeholder for your TeamService - integrate with your actual service
// class TeamService {
//   Future<List<Team>> getAllTeams() async {
//     // Replace with your actual data fetching logic, e.g., from MongoDB
//     print("Fetching teams from service...");
//     await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
//     // Example:
//     // final db = MongoDBService.instance;
//     // final teamData = await db.getCollection('teams').find().toList();
//     // return teamData.map((json) => Team.fromJson(json)).toList();
//     return [
//       Team(name: 'The Alligators'),
//       Team(name: 'The Bears'),
//       Team(name: 'The Crocodiles'),
//     ];
//   }
// }

class TeamQueryScreen extends StatefulWidget {
  final String email;

  const TeamQueryScreen({super.key, required this.email});

  @override
  State<TeamQueryScreen> createState() => _TeamQueryScreenState();
}

class _TeamQueryScreenState extends State<TeamQueryScreen> {
  // List to hold teams, using Map<String, dynamic> for flexibility with mock data
  // Ideally, use a strongly-typed List<Team>
  List<Map<String, dynamic>> _teams = [];
  Map<String, dynamic>? _selectedTeam;
  bool _isLoadingTeams = false;
  bool _showTeamSelectionUI = false; // Controls visibility of dropdown section

  // Add this to use your TeamService
  final TeamService _teamService = TeamService();

  // Helper method to update user's teamName in MongoDB
  Future<bool> _updateUserTeamNameInDb(String teamName) async {
    if (widget.email.isEmpty) {
      print("User email is empty, cannot update team name in DB.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User email not found. Could not save team association.')),
      );
      return false;
    }
    try {
      final usersCollection = MongoDBService.getCollection('users');
      final result = await usersCollection.updateOne(
        where.eq('email', widget.email),
        modify.set('teamName', teamName),
      );

      if (result.isSuccess) {
        print('Successfully updated teamName to "$teamName" for user ${widget.email}');
        return true;
      } else {
        print('Failed to update teamName for user ${widget.email}: ${result.writeError?.errmsg}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save team association: ${result.writeError?.errmsg ?? "Unknown error"}')),
        );
        return false;
      }
    } catch (e) {
      print('Error updating teamName in DB: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while saving team association: $e')),
      );
      return false;
    }
  }

  Future<void> _fetchTeams() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTeams = true;
      _teams = [];
      _selectedTeam = null;
    });

    try {
      // Fetch teams from database using your TeamService
      final fetchedTeams = await _teamService.getAllTeams();
      
      if (mounted) {
        setState(() {
          _teams = fetchedTeams;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching teams: $e. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTeams = false;
        });
      }
    }
  }

  void _onYesButtonPressed() {
    if (!mounted) return;
    setState(() {
      _showTeamSelectionUI = true; // Trigger UI change to show dropdown section
    });
    _fetchTeams(); // Fetch teams
  }

  void _proceedWithSelectedTeam() async { // Make async
    if (_selectedTeam != null && mounted) {
      final String teamName = _selectedTeam!['name'] as String;

      // Update teamName in DB first
      final bool updateSuccess = await _updateUserTeamNameInDb(teamName);

      if (updateSuccess && mounted) {
        Navigator.pushReplacement(
        context,
          MaterialPageRoute(
            builder: (context) => Homepage(
              email: widget.email,
              teamName: teamName,
            ),
          ),
        );
      } else if (mounted) {
        // Handle update failure, perhaps stay on the screen or show a more prominent error
        print("Staying on TeamQueryScreen due to DB update failure.");
      }
    }
  }

  void _navigateToCreateClub() async { // Make async
    if (!mounted) return;

    // Navigate to RegisterTeamScreen and wait for a result (the new team name)
    final newTeamName = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => RegisterTeamScreen(email: widget.email)),
    );

    if (newTeamName != null && newTeamName.isNotEmpty && mounted) {
      // If a team name was returned (meaning team creation was successful)
      print('New team created: $newTeamName. Updating user record.');

      // Update user's teamName in DB
      final bool updateSuccess = await _updateUserTeamNameInDb(newTeamName);

      if (updateSuccess && mounted) {
        // Navigate to Homepage with the new team name
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Homepage(
              email: widget.email,
              teamName: newTeamName,
            ),
          ),
        );
      } else if (mounted) {
         // Handle update failure
        print("Staying on TeamQueryScreen or previous screen due to DB update failure after team creation.");
      }
    } else if (mounted) {
      // User might have backed out of RegisterTeamScreen without creating a team
      print('No new team name returned from RegisterTeamScreen.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    // final screenWidth = MediaQuery.of(context).size.width; // Not used in this snippet

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.asset(
                    'assets/hocky_circle.jpg',
                    height: screenHeight * 0.3, // Adjusted height slightly
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Text(
                  'Do you already have a registered club?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),

                if (!_showTeamSelectionUI) ...[
                  // "Yes" Button - Triggers team selection UI
                FilledButton(
                    onPressed: _onYesButtonPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                    child: const Text('YES, FIND MY CLUB'),
                ),
                const SizedBox(height: 16),
                // "No" Button - Navigates to Register Team Screen
                OutlinedButton(
                    onPressed: _navigateToCreateClub,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('NO, CREATE NEW CLUB'),
                ),
                ] else ...[
                  // Team Selection UI
                  if (_isLoadingTeams) ...[
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 16),
                    Text('Loading teams...', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                  ] else if (_teams.isNotEmpty) ...[
                    Text('Select your team:', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedTeam,
                      hint: const Text('Choose your team'),
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      ),
                      items: _teams.map((team) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: team,
                          // Display team name and coach name for better identification
                          child: Text('${team['name']} (Coach: ${team['coachName']})'),
                        );
                      }).toList(),
                      onChanged: (Map<String, dynamic>? newValue) {
                        setState(() {
                          _selectedTeam = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a team' : null,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _selectedTeam != null ? _proceedWithSelectedTeam : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      child: const Text('PROCEED WITH SELECTED TEAM'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _navigateToCreateClub,
                      child: Text('OR CREATE A NEW CLUB', style: TextStyle(color: theme.colorScheme.primary)),
                    ),
                  ] else ...[
                    // No teams found
                    Text(
                      'No teams found. You can create a new one.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _navigateToCreateClub,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('CREATE NEW CLUB'),
                    ),
                  ],
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
