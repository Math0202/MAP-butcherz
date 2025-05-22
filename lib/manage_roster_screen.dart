import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hocky_na_org/elements/custom_text_field.dart'; // For add player dialog
import 'package:hocky_na_org/services/mongodb_service.dart';

// Player Model to match your MongoDB document structure
class Player {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String teamName;
  final String position;
  final String jerseyNumber;
  final DateTime joinDate;
  // Add gender field with default value
  final String gender;

  Player({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.teamName,
    required this.position,
    required this.jerseyNumber,
    required this.joinDate,
    this.gender = 'Male', // Default to male if not specified
  });

  // Factory constructor to create a Player from your MongoDB document
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['_id']?.toString() ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      teamName: map['teamName'] ?? '',
      position: map['position'] ?? '',
      jerseyNumber: map['jerseyNumber']?.toString() ?? '',
      joinDate: map['joinDate'] != null 
          ? DateTime.parse(map['joinDate'].toString()) 
          : DateTime.now(),
      gender: map['gender'] ?? 'Male', // Default to male if not specified
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
      print('Fetching players for team: ${widget.teamName}');
      
      final usersCollection = MongoDBService.getCollection('users');
      
      // Try a more flexible query approach
      var players = <Player>[];
      
      // First try exact match
      var cursor = usersCollection.find({'teamName': widget.teamName});
      var playersDocs = await cursor.toList();
      print('Exact match query found ${playersDocs.length} players');
      
      if (playersDocs.isEmpty) {
        // Try case-insensitive match
        cursor = usersCollection.find({
          'teamName': {r'$regex': widget.teamName, r'$options': 'i'}
        });
        playersDocs = await cursor.toList();
        print('Case-insensitive query found ${playersDocs.length} players');
      }
      
      // If we found documents, convert them to Player objects
      if (playersDocs.isNotEmpty) {
        players = playersDocs.map((doc) {
          final docMap = doc as Map<String, dynamic>;
          print('Player document: $docMap');
          return Player.fromMap(docMap);
        }).toList();
      }
      
      // Update the UI with what we found
      if (mounted) {
        setState(() {
          _players = players;
          _isLoading = false;
        });
        print('Updated player roster with ${players.length} players');
      }
    } catch (e) {
      print('Error fetching team players: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
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
      SnackBar(content: Text('Edit player: ${playerToEdit.name} (Not implemented)')),
    );
  }

  void _removePlayer(Player playerToRemove) {
    // TODO: Implement MongoDB remove player
    setState(() {
      _players.removeWhere((p) => p.id == playerToRemove.id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed player: ${playerToRemove.name}')),
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
                      name: '${_firstNameController.text} ${_lastNameController.text}',
                      email: _emailController.text,
                      phone: _phoneController.text,
                      teamName: widget.teamName,
                      position: _positionController.text,
                      jerseyNumber: '',
                      joinDate: DateTime.now(),
                      gender: _selectedGender,
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

  Future<void> _testMongoDBConnection() async {
    try {
      final usersCollection = MongoDBService.getCollection('users');
      
      // Count all documents in the collection
      final count = await usersCollection.count();
      print('Total documents in users collection: $count');
      
      // Check the first document to see its structure
      final firstDoc = await usersCollection.findOne();
      print('First document in users collection: $firstDoc');
      
      // List all team names in the collection
      final teamNames = await usersCollection.distinct('teamName');
      print('Team names in the database: $teamNames');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database test successful. Check console logs.')),
      );
    } catch (e) {
      print('Error testing MongoDB connection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
        actions: [
          // Add a test button in the app bar
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _testMongoDBConnection,
            tooltip: 'Test DB Connection',
          ),
        ],
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      _fetchTeamPlayers(); // Refresh the data
                    },
                    child: const Text('Refresh Player List'),
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
                      player.name, 
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
                        SnackBar(content: Text('View details for ${player.name}')),
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