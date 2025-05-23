import 'package:flutter/material.dart';
import 'package:hocky_na_org/services/mongodb_service.dart';
import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

class coachGames extends StatefulWidget {
  final String teamName;

  const coachGames({super.key, required this.teamName});

  @override
  State<coachGames> createState() => _coachGamesState();
}

class _coachGamesState extends State<coachGames>
    with SingleTickerProviderStateMixin {
  // Tab controller for upcoming/past games
  late TabController _tabController;

  // State variables
  bool _isLoading = true;
  List<Map<String, dynamic>> _upcomingGames = [];
  List<Map<String, dynamic>> _pastGames = [];
  List<Map<String, dynamic>> _teams = [];

  // Add these new variables for player management
  List<Map<String, dynamic>> _availablePlayers = [];
  Map<String, List<Map<String, dynamic>>> _gameLineups =
      {}; // gameId -> list of players

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _gameDate = DateTime.now();
  TimeOfDay _gameTime = TimeOfDay.now();
  String? _teamA;
  String? _teamB;
  String? _resultTeamA;
  String? _resultTeamB;

  // Add hockey positions
  final List<String> _positions = [
    'Goaltender',
    'Left Defense',
    'Right Defense',
    'Left Wing',
    'Center',
    'Right Wing',
    'Forward',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchGames();
    _fetchTeams();
    _fetchAvailablePlayers();
    _loadGameLineups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Fetch games from database
  Future<void> _fetchGames() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gamesCollection = MongoDBService.getCollection('matches');
      final now = DateTime.now();

      // Fetch upcoming games (game date >= today)
      final upcomingGamesData =
          await gamesCollection.find({
            'gameDate': {'\$gte': now.toIso8601String()},
          }).toList();

      // Fetch past games (game date < today)
      final pastGamesData =
          await gamesCollection.find({
            'gameDate': {'\$lt': now.toIso8601String()},
          }).toList();

      setState(() {
        _upcomingGames = List<Map<String, dynamic>>.from(upcomingGamesData);
        _pastGames = List<Map<String, dynamic>>.from(pastGamesData);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching games: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch teams for dropdowns
  Future<void> _fetchTeams() async {
    try {
      final teamsCollection = MongoDBService.getCollection('teams');
      final teamsData = await teamsCollection.find().toList();

      setState(() {
        _teams = List<Map<String, dynamic>>.from(teamsData);
      });
    } catch (e) {
      print('Error fetching teams: $e');
    }
  }

  // Update the _fetchAvailablePlayers method to use 'fullName' instead of 'name'
  Future<void> _fetchAvailablePlayers() async {
    try {
      print('Fetching players for team: ${widget.teamName}');

      final usersCollection = MongoDBService.getCollection('users');

      // Use the same approach as manage_roster_screen.dart
      var players = <Map<String, dynamic>>[];

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

      // Convert documents to list and filter valid players
      if (playersDocs.isNotEmpty) {
        players =
            playersDocs
                .map((doc) {
                  final docMap = doc as Map<String, dynamic>;

                  // Debug: Print all fields of the player document
                  print('=== Player Document Debug ===');
                  print('Full document: $docMap');
                  print('FullName: ${docMap['fullName']}');
                  print('Email: ${docMap['email']}');
                  print('Team: ${docMap['teamName']}');
                  print('Position: ${docMap['position']}');
                  print('Jersey: ${docMap['jerseyNumber']}');
                  print('ID: ${docMap['_id']}');
                  print('================================');

                  return docMap;
                })
                .where((player) {
                  // More lenient validation - check for fullName instead of name
                  final hasId = player['_id'] != null;
                  final hasEmail =
                      player['email'] != null &&
                      player['email'].toString().isNotEmpty;
                  final hasFullName =
                      player['fullName'] != null &&
                      player['fullName'].toString().isNotEmpty;

                  print(
                    'Player validation: hasId=$hasId, hasEmail=$hasEmail, hasFullName=$hasFullName',
                  );

                  // Accept players that have at least an ID and preferably a fullName or email
                  return hasId && (hasFullName || hasEmail);
                })
                .toList();
      }

      print(
        'Found ${players.length} valid players for team ${widget.teamName}',
      );

      // Debug: Print final player list
      for (int i = 0; i < players.length; i++) {
        final player = players[i];
        print(
          'Final Player $i: FullName=${player['fullName'] ?? 'No Name'}, Email=${player['email'] ?? 'No Email'}, Position=${player['position']}',
        );
      }

      if (mounted) {
        setState(() {
          _availablePlayers = players;
        });
      }
    } catch (e) {
      print('Error fetching players: $e');
      // Don't show SnackBar during initialization - just log the error
      // The error will be shown if this method is called from user interaction
    }
  }

  // Add validation method to check if teams are the same
  bool _validateTeams() {
    if (_teamA == _teamB && _teamA != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A team cannot play against itself'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  // Add a new game
  Future<void> _addGame() async {
    if (!_formKey.currentState!.validate()) return;

    // Check that teams are different
    if (!_validateTeams()) return;

    // Create combined date time
    final gameDateTime = DateTime(
      _gameDate.year,
      _gameDate.month,
      _gameDate.day,
      _gameTime.hour,
      _gameTime.minute,
    );

    try {
      final gamesCollection = MongoDBService.getCollection('matches');

      await gamesCollection.insert({
        'title': _titleController.text.trim(),
        'venue': _venueController.text.trim(),
        'description': _descriptionController.text.trim(),
        'gameDate': gameDateTime.toIso8601String(),
        'teamA': _teamA,
        'teamB': _teamB,
        'status':
            gameDateTime.isAfter(DateTime.now()) ? 'upcoming' : 'completed',
        'createdAt': DateTime.now().toIso8601String(),
        'isHighlighted': false, // Default not highlighted
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game added successfully')),
        );
      }

      // Clear form
      _resetForm();

      // Refresh games list
      _fetchGames();
    } catch (e) {
      print('Error adding game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Edit existing game
  Future<void> _editGame(Map<String, dynamic> game) async {
    // Set form values to the game data
    _titleController.text = game['title'] ?? '';
    _venueController.text = game['venue'] ?? '';
    _descriptionController.text = game['description'] ?? '';

    // Parse the game date
    final gameDateTime =
        game['gameDate'] != null
            ? DateTime.parse(game['gameDate'])
            : DateTime.now();

    _gameDate = gameDateTime;
    _gameTime = TimeOfDay(hour: gameDateTime.hour, minute: gameDateTime.minute);

    _teamA = game['teamA'];
    _teamB = game['teamB'];
    _resultTeamA = game['resultTeamA']?.toString();
    _resultTeamB = game['resultTeamB']?.toString();

    // Show edit dialog
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Game'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Game Title',
                        hintText: 'e.g., Championship Finals',
                      ),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _venueController,
                      decoration: const InputDecoration(
                        labelText: 'Venue',
                        hintText: 'e.g., Main Hockey Stadium',
                      ),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Please enter a venue' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional details about the game',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Game Date'),
                      subtitle: Text(
                        DateFormat('EEE, MMM d, yyyy').format(_gameDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _gameDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null && mounted) {
                          setState(() {
                            _gameDate = pickedDate;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('Game Time'),
                      subtitle: Text(_gameTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: _gameTime,
                        );
                        if (pickedTime != null && mounted) {
                          setState(() {
                            _gameTime = pickedTime;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Team A'),
                      value: _teamA,
                      items:
                          _teams.map((team) {
                            return DropdownMenuItem<String>(
                              value: team['name'],
                              child: Text(team['name']),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _teamA = value;
                          // Validate immediately when changing selection
                          if (_teamA == _teamB && _teamA != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'A team cannot play against itself',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        });
                      },
                      validator:
                          (value) =>
                              value == null
                                  ? 'Please select Team A'
                                  : (value == _teamB
                                      ? 'Teams cannot be the same'
                                      : null),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Team B'),
                      value: _teamB,
                      items:
                          _teams.map((team) {
                            return DropdownMenuItem<String>(
                              value: team['name'],
                              child: Text(team['name']),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _teamB = value;
                          // Validate immediately when changing selection
                          if (_teamA == _teamB && _teamB != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'A team cannot play against itself',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        });
                      },
                      validator:
                          (value) =>
                              value == null
                                  ? 'Please select Team B'
                                  : (value == _teamA
                                      ? 'Teams cannot be the same'
                                      : null),
                    ),

                    // Only show score fields for past games
                    if (gameDateTime.isBefore(DateTime.now())) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Game Results',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Score: ${_teamA ?? "Team A"}',
                                hintText: 'e.g., 3',
                              ),
                              keyboardType: TextInputType.number,
                              initialValue: _resultTeamA,
                              onChanged: (value) {
                                _resultTeamA = value;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Score: ${_teamB ?? "Team B"}',
                                hintText: 'e.g., 2',
                              ),
                              keyboardType: TextInputType.number,
                              initialValue: _resultTeamB,
                              onChanged: (value) {
                                _resultTeamB = value;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    await _updateGame(game);
                  }
                },
                child: const Text('SAVE'),
              ),
            ],
          ),
    );
  }

  // Update game in database
  Future<void> _updateGame(Map<String, dynamic> game) async {
    if (!_formKey.currentState!.validate()) return;

    // Check that teams are different
    if (!_validateTeams()) return;

    // Create combined date time
    final gameDateTime = DateTime(
      _gameDate.year,
      _gameDate.month,
      _gameDate.day,
      _gameTime.hour,
      _gameTime.minute,
    );

    try {
      final gamesCollection = MongoDBService.getCollection('matches');

      final updateData = {
        '\$set': {
          'title': _titleController.text.trim(),
          'venue': _venueController.text.trim(),
          'description': _descriptionController.text.trim(),
          'gameDate': gameDateTime.toIso8601String(),
          'teamA': _teamA,
          'teamB': _teamB,
          'status':
              gameDateTime.isAfter(DateTime.now()) ? 'upcoming' : 'completed',
        },
      };

      // Add scores if provided
      if (_resultTeamA != null && _resultTeamA!.isNotEmpty) {
        updateData['\$set']?['resultTeamA'] =
            (int.tryParse(_resultTeamA!) ?? 0) as String?;
      }

      if (_resultTeamB != null && _resultTeamB!.isNotEmpty) {
        updateData['\$set']?['resultTeamB'] =
            (int.tryParse(_resultTeamB!) ?? 0) as String?;
      }

      await gamesCollection.update({'_id': game['_id']}, updateData);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game updated successfully')),
        );
      }

      // Reset form
      _resetForm();

      // Refresh games list
      _fetchGames();
    } catch (e) {
      print('Error updating game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete game
  Future<void> _deleteGame(Map<String, dynamic> game) async {
    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Delete Game'),
              content: Text(
                'Are you sure you want to delete "${game['title']}"? This cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('DELETE'),
                ),
              ],
            ),
      );

      if (confirm != true) return;

      // Delete the game
      final gamesCollection = MongoDBService.getCollection('matches');
      await gamesCollection.remove({'_id': game['_id']});

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game "${game['title']}" deleted successfully'),
          ),
        );
      }

      // Refresh games list
      _fetchGames();
    } catch (e) {
      print('Error deleting game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Reset form fields
  void _resetForm() {
    _titleController.clear();
    _venueController.clear();
    _descriptionController.clear();
    _gameDate = DateTime.now();
    _gameTime = TimeOfDay.now();
    _teamA = null;
    _teamB = null;
    _resultTeamA = null;
    _resultTeamB = null;
  }

  // Update the _showPositionSelectionDialog method to use 'fullName'
  void _showPositionSelectionDialog(
    Map<String, dynamic> player,
    String gameId,
    StateSetter setDialogState,
  ) {
    String selectedPosition = _positions.first;

    // Handle null names - use 'fullName' instead of 'name'
    String displayName =
        player['fullName'] ?? player['email'] ?? 'Unknown Player';
    if (displayName.isEmpty) {
      displayName = 'Unknown Player';
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setPositionDialogState) => AlertDialog(
                  title: Text('Select Position for $displayName'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Show player info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Player: $displayName'),
                            Text(
                              'Current Position: ${player['position'] ?? 'None'}',
                            ),
                            Text('Jersey: ${player['jerseyNumber'] ?? 'None'}'),
                            if (player['email'] != null &&
                                player['email'].toString().isNotEmpty)
                              Text('Email: ${player['email']}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedPosition,
                        decoration: const InputDecoration(
                          labelText: 'Game Position',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _positions.map((position) {
                              return DropdownMenuItem<String>(
                                value: position,
                                child: Text(position),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setPositionDialogState(() {
                              selectedPosition = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _addPlayerToLineup(
                          player,
                          selectedPosition,
                          gameId,
                          setDialogState,
                        );
                      },
                      child: const Text('Add Player'),
                    ),
                  ],
                ),
          ),
    );
  }

  // Add method to add player to game lineup
  void _addPlayerToLineup(
    Map<String, dynamic> player,
    String gamePosition,
    String gameId,
    StateSetter setDialogState,
  ) {
    final currentLineup = _gameLineups[gameId] ?? [];

    // Check if player is already in lineup
    final isAlreadyInLineup = currentLineup.any(
      (p) => p['_id'].toString() == player['_id'].toString(),
    );

    if (isAlreadyInLineup) {
      _showErrorMessage('Player is already in the lineup');
      return;
    }

    // Check lineup limit
    if (currentLineup.length >= 11) {
      _showErrorMessage('Maximum 11 players allowed per game');
      return;
    }

    // Create player entry for lineup with 'fullName'
    final lineupPlayer = {
      '_id': player['_id'],
      'name': player['fullName'] ?? player['email'] ?? 'Unknown Player',
      'fullName': player['fullName'],
      'email': player['email'],
      'jerseyNumber': player['jerseyNumber'],
      'originalPosition': player['position'],
      'gamePosition': gamePosition,
      'teamName': player['teamName'],
    };

    currentLineup.add(lineupPlayer);

    setDialogState(() {
      _gameLineups[gameId] = currentLineup;
    });

    // Auto-save to database
    _saveGameLineup(gameId);
  }

  // Update _saveGameLineup method to handle ObjectId properly
  Future<void> _saveGameLineup(String gameId) async {
    try {
      final lineup = _gameLineups[gameId] ?? [];
      final gamesCollection = MongoDBService.getCollection('matches');

      // Prepare lineup data for database
      final lineupData =
          lineup
              .map(
                (player) => {
                  'playerId': player['_id'].toString(),
                  'playerName':
                      player['name'] ?? player['fullName'] ?? 'Unknown Player',
                  'fullName': player['fullName'],
                  'email': player['email'],
                  'jerseyNumber': player['jerseyNumber'],
                  'originalPosition': player['originalPosition'],
                  'gamePosition': player['gamePosition'],
                  'teamName': player['teamName'],
                  'addedAt': DateTime.now().toIso8601String(),
                },
              )
              .toList();

      print('Saving lineup for game $gameId with ${lineup.length} players');

      // Clean the gameId using helper method
      final cleanGameId = _cleanObjectId(gameId);
      print('Using clean gameId: $cleanGameId');

      // Update the match document with the lineup
      final result = await gamesCollection.updateOne(
        {'_id': ObjectId.fromHexString(cleanGameId)},
        {
          '\$set': {
            'lineup': lineupData,
            'lineupCount': lineup.length,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        },
      );

      if (result.isSuccess) {
        print(
          'Successfully saved lineup: ${result.nModified} documents modified',
        );
        _showSuccessMessage('Lineup saved with ${lineup.length} players');

        // Refresh the games to show updated lineup
        await _fetchGames();
      } else {
        print('Failed to save lineup: $result');
        _showErrorMessage('Failed to save lineup');
      }
    } catch (e) {
      print('Error saving lineup: $e');
      _showErrorMessage('Error saving lineup: $e');
    }
  }

  // Add method to load existing lineups from database
  Future<void> _loadGameLineups() async {
    try {
      final gamesCollection = MongoDBService.getCollection('matches');

      // Get all upcoming games with lineups
      final gamesWithLineups =
          await gamesCollection.find({
            'lineup': {
              '\$exists': true,
              '\$ne': null,
              '\$not': {'\$size': 0},
            },
          }).toList();

      print('Found ${gamesWithLineups.length} games with existing lineups');

      for (var game in gamesWithLineups) {
        final gameId = _cleanObjectId(game['_id']); // Use helper method
        final lineup = game['lineup'] as List<dynamic>? ?? [];

        // Convert lineup data back to the format expected by the UI
        final lineupPlayers =
            lineup.map((player) {
              final playerMap = player as Map<String, dynamic>;
              return {
                '_id': playerMap['playerId'],
                'name':
                    playerMap['playerName'] ??
                    playerMap['fullName'] ??
                    'Unknown Player',
                'fullName': playerMap['fullName'],
                'email': playerMap['email'],
                'jerseyNumber': playerMap['jerseyNumber'],
                'originalPosition': playerMap['originalPosition'],
                'gamePosition': playerMap['gamePosition'],
                'teamName': playerMap['teamName'],
              };
            }).toList();

        _gameLineups[gameId] = List<Map<String, dynamic>>.from(lineupPlayers);
        print('Loaded ${lineupPlayers.length} players for game $gameId');
      }

      if (mounted) {
        setState(() {
          // Trigger UI update
        });
      }
    } catch (e) {
      print('Error loading game lineups: $e');
    }
  }

  // Add position color method
  Color _getPositionColor(String? position) {
    switch (position?.toLowerCase()) {
      case 'goaltender':
        return Colors.orange;
      case 'left defense':
      case 'right defense':
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

  // Add method to safely show error messages
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // Add method to show success messages
  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  // Add method to remove player from lineup
  void _removePlayerFromLineup(
    String gameId,
    int playerIndex,
    StateSetter setDialogState,
  ) {
    final currentLineup = _gameLineups[gameId] ?? [];

    if (playerIndex >= 0 && playerIndex < currentLineup.length) {
      final removedPlayer = currentLineup.removeAt(playerIndex);

      setDialogState(() {
        _gameLineups[gameId] = currentLineup;
      });

      // Auto-save to database
      _saveGameLineup(gameId);

      _showSuccessMessage('Removed ${removedPlayer['name']} from lineup');
    }
  }

  // Add helper method to clean ObjectId strings
  String _cleanObjectId(dynamic id) {
    String idString = id.toString();
    if (idString.startsWith('ObjectId("') && idString.endsWith('")')) {
      return idString.substring(10, idString.length - 2);
    }
    return idString;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Upcoming Games'), Tab(text: 'Past Games')],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  // Upcoming Games Tab
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _upcomingGames.isEmpty
                      ? const Center(
                        child: Text(
                          'No upcoming games',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _upcomingGames.length,
                        itemBuilder: (context, index) {
                          final game = _upcomingGames[index];
                          return _buildGameCard(game, true);
                        },
                      ),

                  // Past Games Tab
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _pastGames.isEmpty
                      ? const Center(
                        child: Text(
                          'No past games',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _pastGames.length,
                        itemBuilder: (context, index) {
                          final game = _pastGames[index];
                          return _buildGameCard(game, false);
                        },
                      ),
                ],
              ),
    );
  }

  // Build list of games for a tab
  Widget _buildGamesList(
    List<Map<String, dynamic>> games, {
    required bool isUpcoming,
  }) {
    if (games.isEmpty) {
      return Center(
        child: Text(
          isUpcoming ? 'No upcoming games' : 'No past games',
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: games.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final game = games[index];
        final gameDate = DateTime.parse(game['gameDate']);

        // Format the date and time
        final formattedDate = DateFormat('EEE, MMM d, yyyy').format(gameDate);
        final formattedTime = DateFormat('h:mm a').format(gameDate);

        return _buildGameCard(game, isUpcoming);
      },
    );
  }

  // Update the _buildGameCard method to pass clean game IDs
  Widget _buildGameCard(Map<String, dynamic> game, bool isUpcoming) {
    // Clean the game ID
    String gameId = game['_id'].toString();
    if (gameId.startsWith('ObjectId("') && gameId.endsWith('")')) {
      gameId = gameId.substring(10, gameId.length - 2);
    }

    final currentLineup = _gameLineups[gameId] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game header with title and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    game['title'] ?? 'Untitled Game',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isUpcoming) ...[
                  // Only show player management for upcoming games
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              currentLineup.length >= 11
                                  ? Colors.green
                                  : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${currentLineup.length}/11',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Game details
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  game['gameDate'] != null
                      ? DateFormat(
                        'MMM d, yyyy',
                      ).format(DateTime.parse(game['gameDate']))
                      : 'Date TBD',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  game['gameDate'] != null
                      ? DateFormat(
                        'h:mm a',
                      ).format(DateTime.parse(game['gameDate']))
                      : 'Time TBD',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),

            if (game['venue'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      game['venue'],
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Teams and scores
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        game['teamA'] ?? 'Team A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!isUpcoming && game.containsKey('resultTeamA'))
                        Text(
                          '${game['resultTeamA']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const Text(
                  'vs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        game['teamB'] ?? 'Team B',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!isUpcoming && game.containsKey('resultTeamB'))
                        Text(
                          '${game['resultTeamB']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Show lineup preview for upcoming games
            if (isUpcoming && currentLineup.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Lineup (${currentLineup.length}/11):',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (currentLineup.length < 11)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Need ${11 - currentLineup.length} more',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    currentLineup.take(6).map((player) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPositionColor(player['gamePosition']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#${player['jerseyNumber']} ${player['name'] ?? player['fullName'] ?? 'Unknown'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
              ),
              if (currentLineup.length > 6)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '... and ${currentLineup.length - 6} more',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
            ],

            if (game['description'] != null &&
                game['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(game['description'], style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}
