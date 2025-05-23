import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hocky_na_org/elements/custom_text_field.dart'; // For add player dialog
import 'package:hocky_na_org/services/mongodb_service.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId; // Import ObjectId

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
    dynamic idValue = map['_id'];
    String idString;
    if (idValue is ObjectId) {
      idString = idValue.toHexString();
    } else {
      idString = idValue?.toString() ?? Random().nextInt(100000).toString(); // Fallback, consider logging if _id is not ObjectId
    }

    return Player(
      id: idString, // Ensure ID is a hex string if from ObjectId
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      teamName: map['teamName'] ?? '',
      position: map['position'] ?? '',
      jerseyNumber: map['jerseyNumber']?.toString() ?? '',
      joinDate:
          map['joinDate'] != null
          ? DateTime.parse(map['joinDate'].toString()) 
          : DateTime.now(),
      gender: map['gender'] ?? 'Male', // Default to male if not specified
    );
  }
}

class ManageRosterScreen extends StatefulWidget {
  final String teamName; // Add this parameter

  const ManageRosterScreen({Key? key, required this.teamName})
    : super(key: key);

  @override
  State<ManageRosterScreen> createState() => _ManageRosterScreenState();
}

class _ManageRosterScreenState extends State<ManageRosterScreen> {
  List<Player> _players = [];
  bool _isLoading = true;

  // Controllers for the add player form
  final _addPlayerPositionController = TextEditingController();
  final _addPlayerJerseyNumberController = TextEditingController();

  // Controllers for the edit player form
  final _editPlayerPositionController = TextEditingController();
  final _editPlayerJerseyNumberController = TextEditingController();

  // State for selecting an existing user
  List<Map<String, dynamic>> _availableUsers = [];
  Map<String, dynamic>? _selectedAvailableUser;
  bool _isLoadingAvailableUsers = false;

  @override
  void initState() {
    super.initState();
    _fetchTeamPlayers();
  }

  @override
  void dispose() {
    _addPlayerPositionController.dispose();
    _addPlayerJerseyNumberController.dispose();
    _editPlayerPositionController.dispose();
    _editPlayerJerseyNumberController.dispose();
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
          'teamName': {r'$regex': widget.teamName, r'$options': 'i'},
        });
        playersDocs = await cursor.toList();
        print('Case-insensitive query found ${playersDocs.length} players');
      }
      
      // If we found documents, convert them to Player objects
      if (playersDocs.isNotEmpty) {
        players =
            playersDocs.map((doc) {
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
        
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading players: $e')));
      }
    }
  }

  // New method to fetch users not on the current team or any team
  Future<void> _fetchAvailableUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAvailableUsers = true;
      _availableUsers = [];
      _selectedAvailableUser = null;
    });

    try {
      final usersCollection = MongoDBService.getCollection('users');
      // Fetch users who are not on this team OR have no team assigned
      // This ensures we don't show players already on the current roster in the "add" list.
      final cursor = usersCollection.find({
        r'$or': [
          {'teamName': null},
          {'teamName': ''},
        ],
      });

      final usersList = await cursor.toList();
      if (mounted) {
        setState(() {
          _availableUsers = usersList.cast<Map<String, dynamic>>();
          _isLoadingAvailableUsers = false;
        });
      }
    } catch (e) {
      print('Error fetching available users: $e');
      if (mounted) {
        setState(() {
          _isLoadingAvailableUsers = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading available users: $e')),
        );
      }
    }
  }

  // Modified _addPlayer to reflect adding an existing user to the team
  Future<void> _assignUserToTeam(
    String userIdHex, // Expecting a hex string for ObjectId
    String name,
    String email,
    String phone,
    String gender,
    String position,
    String jerseyNumber,
  ) async {
    try {
      final usersCollection = MongoDBService.getCollection('users');
      // Ensure userIdHex is a valid hex string before attempting to convert
      if (!ObjectId.isValidHexId(userIdHex)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid player ID format for $name.')),
        );
        return;
      }

      final result = await usersCollection.updateOne(
        {'_id': ObjectId.fromHexString(userIdHex)}, // Convert hex string back to ObjectId for query
        {
          r'$set': {
            'teamName': widget.teamName, // This updates the player's team to the current user's team
            'position': position,
            'jerseyNumber': jerseyNumber,
            'joinDate': DateTime.now().toIso8601String(),
            // name, email, phone, gender are inherent to the user's profile
            // and are not typically updated when they join a team.
            // The Player object is constructed from the user's existing data.
          }
        },
      );

      if (result.isSuccess && result.nModified > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name has been added to ${widget.teamName}.')),
        );
        _fetchTeamPlayers(); // Refresh the roster to show the newly added player
        _fetchAvailableUsers(); // Refresh available users list
      } else if (result.isSuccess && result.nModified == 0) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Player $name is already up-to-date or not found with ID $userIdHex.')),
        );
      }
      
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add $name: ${result.writeError?.errmsg ?? "Unknown database error"}')),
        );
      }
    } catch (e) {
      print('Error assigning user to team: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while adding $name: $e')),
      );
    }
  }

  // Method to update player's team-specific details in the database
  Future<void> _updatePlayerTeamDetails(String playerIdHex, String newPosition, String newJerseyNumber) async {
    if (!ObjectId.isValidHexId(playerIdHex)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid player ID format for update.')),
      );
      return;
    }

    try {
      final usersCollection = MongoDBService.getCollection('users');
      final result = await usersCollection.updateOne(
        {'_id': ObjectId.fromHexString(playerIdHex)},
        {
          r'$set': {
            'position': newPosition,
            'jerseyNumber': newJerseyNumber,
            // 'updatedAt': DateTime.now().toIso8601String(), // Optional: track updates
          }
        },
      );

      if (result.isSuccess && result.nModified > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player details updated successfully.')),
        );
        _fetchTeamPlayers(); // Refresh the roster
      } else if (result.isSuccess && result.nModified == 0) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes made to player details or player not found.')),
        );
      }
      
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update player details: ${result.writeError?.errmsg ?? "Unknown error"}')),
        );
      }
    } catch (e) {
      print('Error updating player team details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while updating player details: $e')),
      );
    }
  }

  // This method is called when "Edit" is selected from the popup menu.
  void _editPlayer(Player playerToEdit) {
    _showEditPlayerDialog(playerToEdit);
  }

  // Dialog to edit player's position and jersey number
  Future<void> _showEditPlayerDialog(Player playerToEdit) async {
    // Pre-fill controllers with current player data
    _editPlayerPositionController.text = playerToEdit.position;
    _editPlayerJerseyNumberController.text = playerToEdit.jerseyNumber;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must take an action
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Edit Player: ${playerToEdit.name}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                CustomTextField(
                  controller: _editPlayerPositionController,
                  labelText: 'Position on Team',
                  hintText: 'E.g., Forward, Defender',
                  prefixIcon: Icons.sports_hockey,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _editPlayerJerseyNumberController,
                  labelText: 'Jersey Number',
                  hintText: 'E.g., 10 (Optional)',
                  prefixIcon: Icons.numbers,
                  keyboardType: TextInputType.number,
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
              child: const Text('Save Changes'),
              onPressed: () {
                if (_editPlayerPositionController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Position cannot be empty.')),
                  );
                  return;
                }
                // Jersey number can be optional or have validation

                _updatePlayerTeamDetails(
                  playerToEdit.id, // playerToEdit.id should be the hex string of ObjectId
                  _editPlayerPositionController.text.trim(),
                  _editPlayerJerseyNumberController.text.trim(),
                );
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Method to remove a player from the team (updates their DB record)
  Future<void> _removePlayerFromTeam(Player playerToRemove) async {
    if (!ObjectId.isValidHexId(playerToRemove.id)) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid player ID for removal: ${playerToRemove.name}')),
      );
      return;
    }
    try {
      final usersCollection = MongoDBService.getCollection('users');
      final result = await usersCollection.updateOne(
        {'_id': ObjectId.fromHexString(playerToRemove.id)}, // Query by ObjectId
        {
          r'$set': {
            'teamName': null, // Or an empty string, depending on your preference
            'position': null,
            'jerseyNumber': null,
            // 'joinDate': null, // Optional: clear join date
          },
        },
      );

      if (result.isSuccess && result.nModified > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${playerToRemove.name} from the team.'),
          ),
        );
        _fetchTeamPlayers(); // Refresh the roster
        _fetchAvailableUsers(); // Also refresh the list of users available to be added
      } else if (result.isSuccess && result.nModified == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${playerToRemove.name} was not on the team or not found.')),
        );
      }
      
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to remove ${playerToRemove.name}: ${result.writeError?.errmsg ?? "Unknown error"}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error removing player from team: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing ${playerToRemove.name}: $e')));
    }
  }

  Future<void> _showAddPlayerDialog() async {
    // Reset form fields for the dialog
    _addPlayerPositionController.clear();
    _addPlayerJerseyNumberController.clear();
    // _selectedGender = 'Male'; // Gender is part of the user, not set per team assignment
    _selectedAvailableUser = null; // Reset selected user

    // Fetch available users when dialog is opened
    await _fetchAvailableUsers(); // Ensure this is awaited so the list is populated

    // if (!mounted) return; // Check mounted status if doing async work before showDialog

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must take an action
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder if the dialog's internal state needs to change
        // based on interactions within the dialog itself (e.g., DropdownButtonFormField)
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Player to Roster'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    if (_isLoadingAvailableUsers)
                      const Center(child: CircularProgressIndicator())
                    else if (_availableUsers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No available users found to add.\nEnsure users exist and are not already on a team or this team.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      )
                    else
                      DropdownButtonFormField<Map<String, dynamic>>(
                        decoration: const InputDecoration(
                          labelText: 'Select User',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Choose a user to add'),
                        value: _selectedAvailableUser,
                        isExpanded: true,
                        items: _availableUsers.map((user) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: user,
                            child: Text(
                                "${user['name'] ?? 'Unnamed User'} (${user['email'] ?? 'No Email'})"),
                          );
                        }).toList(),
                        onChanged: (Map<String, dynamic>? newValue) {
                          setDialogState(() { // Use setDialogState from StatefulBuilder
                            _selectedAvailableUser = newValue;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a user' : null,
                      ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _addPlayerPositionController,
                      labelText: 'Position on Team',
                      hintText: 'E.g., Forward, Defender',
                      prefixIcon: Icons.sports_hockey,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _addPlayerJerseyNumberController,
                      labelText: 'Jersey Number',
                      hintText: 'E.g., 10 (Optional)',
                      prefixIcon: Icons.numbers,
                      keyboardType: TextInputType.number,
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
                  child: const Text('Add to Team'),
                  onPressed: () {
                    if (_selectedAvailableUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please select a user to add.')),
                      );
                      return;
                    }
                    if (_addPlayerPositionController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please enter a position for the player.')),
                      );
                      return;
                    }

                    final userToAssign = _selectedAvailableUser!;
                    
                    // Correctly extract ObjectId and convert to hex string
                    final dynamic idValue = userToAssign['_id'];
                    String userIdHex = '';

                    if (idValue is ObjectId) {
                      userIdHex = idValue.toHexString();
                    } else if (idValue != null) {
                      // This case should ideally not happen if _id is always ObjectId from DB
                      // If it can be a string already, ensure it's a valid hex for ObjectId
                      String tempId = idValue.toString();
                      if (ObjectId.isValidHexId(tempId)) {
                        userIdHex = tempId;
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Selected user has an invalid ID format.')),
                         );
                         return;
                      }
                    }
                    
                    if (userIdHex.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selected user has no valid ID. Cannot add.')),
                      );
                      return;
                    }

                    final String userName = userToAssign['name'] ?? 'N/A';
                    final String userEmail = userToAssign['email'] ?? 'N/A'; // For display/logging
                    final String userPhone = userToAssign['phone'] ?? 'N/A'; // For display/logging
                    final String userGender = userToAssign['gender'] ?? 'Male'; // For display/logging

                    _assignUserToTeam(
                      userIdHex,
                      userName,
                      userEmail,
                      userPhone,
                      userGender,
                      _addPlayerPositionController.text.trim(),
                      _addPlayerJerseyNumberController.text.trim(),
                    );
                    Navigator.of(dialogContext).pop(); // Close the dialog
                  },
                ),
              ],
            );
          },
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
        SnackBar(
          content: Text('Database test successful. Check console logs.'),
        ),
      );
    } catch (e) {
      print('Error testing MongoDB connection: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      body:
          _players.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(
                      Icons.people_outline,
                      size: 80,
                      color: theme.hintColor,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'No players in your roster yet.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the "+" button to add a player.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
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
                  final String avatarImage =
                      player.gender.toLowerCase() == 'female'
                    ? 'assets/player_avatar_female.png' 
                    : 'assets/player_avatar_male.png';
                
                return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 8.0,
                    ),
                  elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: AssetImage(avatarImage),
                    ),
                    title: Text(
                      player.name, 
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Position: ${player.position}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                        ),
                        Text(
                          'Email: ${player.email}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editPlayer(player);
                        } else if (value == 'remove') {
                            _removePlayerFromTeam(player);
                        }
                      },
                        itemBuilder:
                            (BuildContext context) => <PopupMenuEntry<String>>[
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
                                  leading: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Remove',
                                    style: TextStyle(color: Colors.red),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Optional: Show player details
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('View details for ${player.name}'),
                          ),
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
