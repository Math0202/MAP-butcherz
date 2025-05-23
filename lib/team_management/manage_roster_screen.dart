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
      idString =
          idValue?.toString() ??
          Random()
              .nextInt(100000)
              .toString(); // Fallback, consider logging if _id is not ObjectId
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

  // Add position dropdown options
  String _selectedPosition = 'Forward';
  final List<String> _positions = [
    'Forward',
    'Defenseman',
    'Goaltender',
    'Center',
    'Left Wing',
    'Right Wing',
  ];

  // Add method to check if jersey number is taken
  Future<bool> _isJerseyNumberTaken(
    String jerseyNumber, {
    String? excludePlayerId,
  }) async {
    try {
      final usersCollection = MongoDBService.getCollection('users');

      Map<String, dynamic> query = {
        'teamName': widget.teamName,
        'jerseyNumber': jerseyNumber,
      };

      // If we're updating a player, exclude their current record
      if (excludePlayerId != null) {
        query['_id'] = {'\$ne': ObjectId.fromHexString(excludePlayerId)};
      }

      final existingPlayer = await usersCollection.findOne(query);
      return existingPlayer != null;
    } catch (e) {
      print('Error checking jersey number: $e');
      return false; // Assume not taken if there's an error
    }
  }

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
        {
          '_id': ObjectId.fromHexString(userIdHex),
        }, // Convert hex string back to ObjectId for query
        {
          r'$set': {
            'teamName':
                widget
                    .teamName, // This updates the player's team to the current user's team
            'position': position,
            'jerseyNumber': jerseyNumber,
            'joinDate': DateTime.now().toIso8601String(),
            // name, email, phone, gender are inherent to the user's profile
            // and are not typically updated when they join a team.
            // The Player object is constructed from the user's existing data.
          },
        },
      );

      if (result.isSuccess && result.nModified > 0) {
    ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name has been added to ${widget.teamName}.'),
          ),
        );
        _fetchTeamPlayers(); // Refresh the roster to show the newly added player
        _fetchAvailableUsers(); // Refresh available users list
      } else if (result.isSuccess && result.nModified == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Player $name is already up-to-date or not found with ID $userIdHex.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add $name: ${result.writeError?.errmsg ?? "Unknown database error"}',
            ),
          ),
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
  Future<void> _updatePlayerTeamDetails(
    String playerIdHex,
    String newPosition,
    String newJerseyNumber,
  ) async {
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
          },
        },
      );

      if (result.isSuccess && result.nModified > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player details updated successfully.')),
        );
        _fetchTeamPlayers(); // Refresh the roster
      } else if (result.isSuccess && result.nModified == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No changes made to player details or player not found.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update player details: ${result.writeError?.errmsg ?? "Unknown error"}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error updating player team details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while updating player details: $e'),
        ),
      );
    }
  }

  // Update the _editPlayer method to include position dropdown
  void _editPlayer(Player player) {
    // Pre-fill the controllers with current player data
    _editPlayerPositionController.text = player.position;
    _editPlayerJerseyNumberController.text = player.jerseyNumber;
    _selectedPosition =
        player.position; // Set the current position for dropdown

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text('Edit ${player.name}'),
              content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Position Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedPosition,
                          decoration: const InputDecoration(
                            labelText: 'Position',
                            prefixIcon: Icon(Icons.sports_hockey),
                            border: OutlineInputBorder(),
                          ),
                          items:
                              _positions.map((position) {
                                return DropdownMenuItem(
                                  value: position,
                                  child: Text(position),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedPosition = value!;
                              _editPlayerPositionController.text = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a position';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Jersey Number Field
                    CustomTextField(
                          controller: _editPlayerJerseyNumberController,
                          labelText: 'Jersey Number',
                          hintText: 'Enter jersey number (1-99)',
                          prefixIcon: Icons.numbers,
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 16),

                        // Player Info Display (read-only)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Player Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Name: ${player.name}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Email: ${player.email}'),
                                  ),
                                ],
                              ),
                              if (player.phone.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Phone: ${player.phone}'),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Reset the position selection
                        _selectedPosition = 'Forward';
                      },
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        // Validate jersey number
                        final jerseyNumber =
                            _editPlayerJerseyNumberController.text.trim();
                        if (jerseyNumber.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a jersey number.'),
                            ),
                          );
                          return;
                        }

                        final number = int.tryParse(jerseyNumber);
                        if (number == null || number < 1 || number > 99) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Jersey number must be between 1 and 99.',
                              ),
                            ),
                          );
                          return;
                        }

                        // Check if jersey number is already taken by another player
                        final isJerseyTaken = await _isJerseyNumberTaken(
                          jerseyNumber,
                          excludePlayerId: player.id,
                        );

                        if (isJerseyTaken) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Jersey number $jerseyNumber is already taken by another player.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Close dialog and update player
                        Navigator.of(context).pop();

                        _updatePlayerInfo(
                          player,
                          _selectedPosition,
                          jerseyNumber,
                        );
                      },
                      child: const Text('Update Player'),
                    ),
                  ],
                ),
          ),
    );
  }

  // Method to remove a player from the team (updates their DB record)
  Future<void> _removePlayerFromTeam(Player playerToRemove) async {
    if (!ObjectId.isValidHexId(playerToRemove.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid player ID for removal: ${playerToRemove.name}',
          ),
        ),
      );
      return;
    }
    try {
      final usersCollection = MongoDBService.getCollection('users');
      final result = await usersCollection.updateOne(
        {'_id': ObjectId.fromHexString(playerToRemove.id)}, // Query by ObjectId
        {
          r'$set': {
            'teamName':
                null, // Or an empty string, depending on your preference
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
          SnackBar(
            content: Text(
              '${playerToRemove.name} was not on the team or not found.',
            ),
          ),
        );
      } else {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing ${playerToRemove.name}: $e')),
      );
    }
  }

  void _showAddPlayerDialog() {
    // Reset form state
    _selectedAvailableUser = null;
    _addPlayerPositionController.clear();
    _addPlayerJerseyNumberController.clear();
    _selectedPosition = 'Forward'; // Reset to default

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Add Player to Roster'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // User Selection Dropdown
                        if (_isLoadingAvailableUsers)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          )
                        else if (_availableUsers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No available users found. Please register users first.',
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          decoration: const InputDecoration(
                            labelText: 'Select User',
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Choose a user to add'),
                          value: _selectedAvailableUser,
                          isExpanded: true,
                          items:
                              _availableUsers.map((user) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: user,
                                  child: Text(
                                    "${user['name'] ?? 'Unnamed User'} (${user['email'] ?? 'No Email'})",
                                  ),
                                );
                              }).toList(),
                          onChanged: (Map<String, dynamic>? newValue) {
                            setDialogState(() {
                              _selectedAvailableUser = newValue;
                            });
                          },
                          validator:
                              (value) =>
                                  value == null ? 'Please select a user' : null,
                        ),
                        const SizedBox(height: 16),

                        // Position Dropdown
                    DropdownButtonFormField<String>(
                          value: _selectedPosition,
                      decoration: const InputDecoration(
                            labelText: 'Position',
                            prefixIcon: Icon(Icons.sports_hockey),
                        border: OutlineInputBorder(),
                      ),
                          items:
                              _positions.map((position) {
                                return DropdownMenuItem(
                                  value: position,
                                  child: Text(position),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                              _selectedPosition = value!;
                        });
                      },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a position';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Jersey Number Field
                        CustomTextField(
                          controller: _addPlayerJerseyNumberController,
                          labelText: 'Jersey Number',
                          hintText: 'Enter jersey number (1-99)',
                          prefixIcon: Icons.numbers,
                          keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
                  actions: [
                TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                      onPressed: () async {
                        // Validate user selection
                        if (_selectedAvailableUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a user to add.'),
                            ),
                      );
                      return;
                    }
                    
                        // Validate jersey number
                        final jerseyNumber =
                            _addPlayerJerseyNumberController.text.trim();
                        if (jerseyNumber.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a jersey number.'),
                            ),
                          );
                          return;
                        }

                        final number = int.tryParse(jerseyNumber);
                        if (number == null || number < 1 || number > 99) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Jersey number must be between 1 and 99.',
                              ),
                            ),
                          );
                          return;
                        }

                        // Check if jersey number is already taken
                        final isJerseyTaken = await _isJerseyNumberTaken(
                          jerseyNumber,
                        );
                        if (isJerseyTaken) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Jersey number $jerseyNumber is already taken by another player.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Close dialog and add player
                        Navigator.of(context).pop();

                        _addPlayerToTeam(
                          _selectedAvailableUser!,
                          _selectedPosition,
                          jerseyNumber,
                        );
                      },
                      child: const Text('Add Player'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _addPlayerToTeam(
    Map<String, dynamic> user,
    String position,
    String jerseyNumber,
  ) async {
    try {
      final name = user['name'] ?? 'Unknown';
      dynamic userIdValue = user['_id'];

      print('Adding player: $name to team: ${widget.teamName}');
      print('User ID value: $userIdValue (type: ${userIdValue.runtimeType})');
      print('Position: $position, Jersey: $jerseyNumber');

      // Handle different ID formats
      ObjectId objectId;
      if (userIdValue is ObjectId) {
        objectId = userIdValue;
      } else if (userIdValue is String) {
        if (ObjectId.isValidHexId(userIdValue)) {
          objectId = ObjectId.fromHexString(userIdValue);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid player ID format for $name.')),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid player ID type for $name.')),
        );
        return;
      }

      final usersCollection = MongoDBService.getCollection('users');

      // Double-check jersey number isn't taken (race condition protection)
      final isJerseyTaken = await _isJerseyNumberTaken(jerseyNumber);
      if (isJerseyTaken) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Jersey number $jerseyNumber was just taken by another player.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await usersCollection.updateOne(
        {'_id': objectId},
        {
          '\$set': {
            'teamName': widget.teamName,
            'position': position,
            'jerseyNumber': jerseyNumber,
            'joinDate': DateTime.now().toIso8601String(),
          },
        },
      );

      if (result.isSuccess && result.nModified > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$name has been added to ${widget.teamName} as $position (#$jerseyNumber).',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _fetchTeamPlayers(); // Refresh the roster
        _fetchAvailableUsers(); // Refresh available users list
      } else if (result.isSuccess && result.nModified == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Player $name is already up-to-date or not found.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add $name: ${result.writeError?.errmsg ?? "Unknown database error"}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error adding player to team: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding player: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  // Add method to get position-specific colors
  Color _getPositionColor(String? position) {
    switch (position?.toLowerCase()) {
      case 'goaltender':
        return Colors.orange;
      case 'defenseman':
        return Colors.blue;
      case 'center':
        return Colors.purple;
      case 'left wing':
        return Colors.green;
      case 'right wing':
        return Colors.red;
      case 'forward':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Add the _updatePlayerInfo method
  Future<void> _updatePlayerInfo(
    Player player,
    String newPosition,
    String newJerseyNumber,
  ) async {
    try {
      print('Updating player: ${player.name}');
      print('New position: $newPosition, New jersey: $newJerseyNumber');

      final usersCollection = MongoDBService.getCollection('users');

      // Convert player ID to ObjectId
      ObjectId objectId;
      if (ObjectId.isValidHexId(player.id)) {
        objectId = ObjectId.fromHexString(player.id);
      } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid player ID for ${player.name}.')),
        );
        return;
      }

      final result = await usersCollection.updateOne(
        {'_id': objectId},
        {
          '\$set': {
            'position': newPosition,
            'jerseyNumber': newJerseyNumber,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        },
      );

      if (result.isSuccess && result.nModified > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${player.name} updated successfully! Position: $newPosition, Jersey: #$newJerseyNumber',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _fetchTeamPlayers(); // Refresh the roster
      } else if (result.isSuccess && result.nModified == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No changes made to ${player.name}.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update ${player.name}: ${result.writeError?.errmsg ?? "Unknown error"}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating player: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating player: $e'),
          backgroundColor: Colors.red,
        ),
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
                  final positionColor = _getPositionColor(player.position);

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
                    // Add position color to the entire card
                    color: positionColor.withOpacity(0.1),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: positionColor, width: 2),
                      ),
                  child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                      backgroundImage: AssetImage(avatarImage),
                              radius: 25,
                            ),
                            // Jersey number badge
                            if (player.jerseyNumber.isNotEmpty)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: positionColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      player.jerseyNumber,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                      player.name, 
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            // Position badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: positionColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                player.position,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            const SizedBox(height: 4),
                            // Jersey number and position info
                            Row(
                              children: [
                                if (player.jerseyNumber.isNotEmpty) ...[
                                  Icon(
                                    Icons.sports_hockey,
                                    size: 16,
                                    color: positionColor,
                                  ),
                                  const SizedBox(width: 4),
                        Text(
                                    '#${player.jerseyNumber}',
                                    style: TextStyle(
                                      color: positionColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                Icon(
                                  Icons.sports,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                        Text(
                                  player.position,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Email
                            Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    player.email,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                            // Phone (if available)
                            if (player.phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    player.phone,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
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
                              (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
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
                      ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('View details for ${player.name}'),
                            ),
                      );
                    },
                      ),
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
