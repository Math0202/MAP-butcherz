import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hocky_na_org/elements/custom_text_field.dart'; // For add player dialog
import 'package:hocky_na_org/services/mongodb_service.dart';

// Player Model to match your users collection
class Player {
  final String id;
  final String firstName;
  final String lastName;
  final String position;
  final String gender;
  final String teamName;
  final String phoneNumber;
  final String email;
  final DateTime dateJoined;
  final bool isActive;

  Player({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.position,
    required this.gender,
    required this.teamName,
    required this.phoneNumber,
    required this.email,
    required this.dateJoined,
    required this.isActive,
  });

  // Full name getter for convenience
  String get fullName => '$firstName $lastName';

  // Factory constructor to create a Player from a MongoDB document
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['_id'].toString(),
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      position: map['position'] ?? '',
      gender: map['gender'] ?? 'Male', // Default to Male if not specified
      teamName: map['teamName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      dateJoined: map['dateJoined'] != null 
          ? DateTime.parse(map['dateJoined'].toString()) 
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}

class ManageRosterScreen extends StatefulWidget {
  final String teamName; // Add this parameter

  const ManageRosterScreen({
    Key? key, 
    required this.teamName,
  }) : super(key: key);

  @override
  State<ManageRosterScreen> createState() => _ManageRosterScreenState();
}

class _ManageRosterScreenState extends State<ManageRosterScreen> {
  List<Player> _players = [];
  bool _isLoading = true;

  // Controllers for the add player form
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedGender = 'Male'; // Default gender

  @override
  void initState() {
    super.initState();
    _fetchTeamPlayers();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Fetch players that belong to the current user's team
  Future<void> _fetchTeamPlayers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get MongoDB collection
      final usersCollection = MongoDBService.getCollection('users');
      
      // Find players with matching teamName
      final cursor = usersCollection.find({
        'teamName': widget.teamName,
        'isActive': true, // Only active players
      });
      
      // Convert the results to a list of Player objects
      final playersDocs = await cursor.toList();
      final players = playersDocs.map((doc) => Player.fromMap(doc as Map<String, dynamic>)).toList();
      
      setState(() {
        _players = players;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error fetching team players: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading players: $e')),
        );
      }
    }
  }

  void _addPlayer(Player newPlayer) {
    // TODO: Implement MongoDB add player
    setState(() {
      _players.add(newPlayer);
    });
  }

  void _editPlayer(Player playerToEdit) {
    // TODO: Implement edit player dialog/screen and logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit player: ${playerToEdit.fullName} (Not implemented)')),
    );
  }

  void _removePlayer(Player playerToRemove) {
    // TODO: Implement MongoDB remove player
    setState(() {
      _players.removeWhere((p) => p.id == playerToRemove.id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed player: ${playerToRemove.fullName}')),
    );
  }

  Future<void> _showAddPlayerDialog() async {
    // Reset form fields
    _firstNameController.clear();
    _lastNameController.clear();
    _positionController.clear();
    _phoneController.clear();
    _emailController.clear();
    _selectedGender = 'Male';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Player'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    CustomTextField(
                      controller: _firstNameController,
                      hintText: 'First Name',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: _lastNameController,
                      hintText: 'Last Name',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: _positionController,
                      hintText: 'Position (e.g., Forward)',
                      prefixIcon: Icons.sports_kabaddi,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: _phoneController,
                      hintText: 'Phone Number',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Email Address',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.people_outline),
                        border: OutlineInputBorder(),
                      ),
                      items: ['Male', 'Female'].map((gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                FilledButton(
                  child: const Text('Add Player'),
                  onPressed: () {
                    // Simple validation
                    if (_firstNameController.text.isEmpty || 
                        _lastNameController.text.isEmpty || 
                        _positionController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in all required fields')),
                      );
                      return;
                    }
                    
                    final player = Player(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      firstName: _firstNameController.text,
                      lastName: _lastNameController.text,
                      position: _positionController.text,
                      gender: _selectedGender,
                      teamName: widget.teamName,
                      phoneNumber: _phoneController.text,
                      email: _emailController.text,
                      dateJoined: DateTime.now(),
                      isActive: true,
                    );
                    
                    _addPlayer(player);
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.teamName} Roster'),
      ),
      body: _players.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: theme.hintColor),
                  const SizedBox(height: 16),
                  Text(
                    'No players in your roster yet.',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the "+" button to add a player.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];
                // Set avatar image based on gender
                final String avatarImage = player.gender.toLowerCase() == 'female' 
                    ? 'assets/player_avatar_female.png' 
                    : 'assets/player_avatar_male.png';
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: AssetImage(avatarImage),
                    ),
                    title: Text(
                      player.fullName, 
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Position: ${player.position}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                        ),
                        Text(
                          'Email: ${player.email}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editPlayer(player);
                        } else if (value == 'remove') {
                          _removePlayer(player);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'remove',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline, color: Colors.red),
                            title: Text('Remove', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Optional: Show player details
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('View details for ${player.fullName}')),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPlayerDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Player'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
} 