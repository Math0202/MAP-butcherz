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

  // Update the _fetchAvailablePlayers method to use the teamName parameter
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
        players = playersDocs.map((doc) {
          final docMap = doc as Map<String, dynamic>;
          print('Player document: ${docMap['name']}, Team: ${docMap['teamName']}, Position: ${docMap['position']}');
          return docMap;
        }).where((player) {
          // Filter players that have at least a name
          final hasName = player['name'] != null && player['name'].toString().isNotEmpty;
          return hasName;
        }).toList();
      }
      
      print('Found ${players.length} valid players for team ${widget.teamName}');
      
      setState(() {
        _availablePlayers = players;
      });
      
    } catch (e) {
      print('Error fetching players: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading players: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  // Show add game dialog
  Future<void> _showAddGameDialog() async {
    // Reset form before showing dialog
    _resetForm();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Game'),
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
                onPressed: () {
                  if (_formKey.currentState!.validate() && _validateTeams()) {
                    Navigator.pop(context);
                    _addGame();
                  }
                },
                child: const Text('ADD'),
              ),
            ],
          ),
    );
  }

  // Update the _showAddPlayersDialog method to remove the debug references to _getCurrentUserTeam
  void _showAddPlayersDialog(String gameId, String gameTitle) {
    final currentLineup = _gameLineups[gameId] ?? [];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Add Players to $gameTitle')),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.bug_report, color: Colors.orange),
                    onPressed: () async {
                      // Debug: Show all users in database
                      final usersCollection = MongoDBService.getCollection('users');
                      final allUsers = await usersCollection.find().toList();
                      
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Debug: All Users'),
                          content: SizedBox(
                            width: double.maxFinite,
                            height: 400,
                            child: ListView.builder(
                              itemCount: allUsers.length,
                              itemBuilder: (context, index) {
                                final user = allUsers[index];
                                return Card(
                                  child: ListTile(
                                    title: Text(user['name'] ?? 'No name'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Team: ${user['teamName'] ?? 'No team'}'),
                                        Text('Position: ${user['position'] ?? 'No position'}'),
                                        Text('Jersey: ${user['jerseyNumber'] ?? 'No jersey'}'),
                                        Text('Email: ${user['email'] ?? 'No email'}'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: 'Debug: Show All Users',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      await _fetchAvailablePlayers();
                      setDialogState(() {}); // Refresh the dialog
                    },
                    tooltip: 'Refresh Players',
                  ),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: Column(
              children: [
                // Debug info
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Debug: Found ${_availablePlayers.length} available players',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Team: ${widget.teamName}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Current lineup count
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentLineup.length >= 11 ? Colors.red[100] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Players Selected: ${currentLineup.length}/11',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: currentLineup.length >= 11 ? Colors.red[700] : Colors.blue[700],
                        ),
                      ),
                      if (currentLineup.length >= 11)
                        Icon(Icons.warning, color: Colors.red[700]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Current lineup
                if (currentLineup.isNotEmpty) ...[
                  Text(
                    'Current Lineup:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: currentLineup.length,
                      itemBuilder: (context, index) {
                        final player = currentLineup[index];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor: _getPositionColor(player['gamePosition']),
                            child: Text(
                              player['jerseyNumber']?.toString() ?? '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            player['name'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            player['gamePosition'] ?? 'No position',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                            onPressed: () {
                              setDialogState(() {
                                currentLineup.removeAt(index);
                                _gameLineups[gameId] = currentLineup;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Available players
                Text(
                  'Available Players:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Show message if no players found
                if (_availablePlayers.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No players found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Make sure players are added to your team roster',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _fetchAvailablePlayers();
                              setDialogState(() {});
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availablePlayers.length,
                      itemBuilder: (context, index) {
                        final player = _availablePlayers[index];
                        final isAlreadySelected = currentLineup.any(
                          (p) => p['_id'].toString() == player['_id'].toString(),
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 15,
                              backgroundColor: _getPositionColor(player['position']),
                              child: Text(
                                player['jerseyNumber']?.toString() ?? '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              player['name'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 14,
                                color: isAlreadySelected ? Colors.grey : null,
                              ),
                            ),
                            subtitle: Text(
                              '${player['position'] ?? 'No position'} • Team: ${player['teamName'] ?? 'No team'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: isAlreadySelected
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : (currentLineup.length >= 11
                                    ? const Icon(Icons.block, color: Colors.red)
                                    : IconButton(
                                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                                        onPressed: () => _showPositionSelectionDialog(
                                          player,
                                          gameId,
                                          setDialogState,
                                        ),
                                      )),
                          ),
                        );
                      },
                    ),
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
              onPressed: () {
                Navigator.of(context).pop();
                _saveGameLineup(gameId);
              },
              child: const Text('Save Lineup'),
            ),
          ],
        ),
      ),
    );
  }

  // Add method to show position selection for game
  void _showPositionSelectionDialog(
    Map<String, dynamic> player,
    String gameId,
    StateSetter setDialogState,
  ) {
    String selectedPosition = player['position'] ?? 'Forward';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Select Position for ${player['name']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current Position: ${player['position']}'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPosition,
                  decoration: const InputDecoration(
                    labelText: 'Game Position',
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
                    selectedPosition = value!;
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
                  _addPlayerToGameLineup(
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
    );
  }

  // Add method to add player to game lineup
  void _addPlayerToGameLineup(
    Map<String, dynamic> player,
    String gamePosition,
    String gameId,
    StateSetter setDialogState,
  ) {
    final currentLineup = _gameLineups[gameId] ?? [];

    if (currentLineup.length >= 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 11 players allowed per game'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final playerWithPosition = Map<String, dynamic>.from(player);
    playerWithPosition['gamePosition'] = gamePosition;

    setDialogState(() {
      currentLineup.add(playerWithPosition);
      _gameLineups[gameId] = currentLineup;
    });
  }

  // Add method to save game lineup to database
  Future<void> _saveGameLineup(String gameId) async {
    try {
      final lineup = _gameLineups[gameId] ?? [];
      final gamesCollection = MongoDBService.getCollection('matches');

      await gamesCollection.updateOne(
        {'_id': ObjectId.fromHexString(gameId)},
        {
          '\$set': {
            'lineup':
                lineup
                    .map(
                      (player) => {
                        'playerId': player['_id'].toString(),
                        'playerName': player['name'],
                        'jerseyNumber': player['jerseyNumber'],
                        'position': player['gamePosition'],
                      },
                    )
                    .toList(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lineup saved with ${lineup.length} players'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving lineup: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                  _buildGamesList(_upcomingGames, isUpcoming: true),

                  // Past Games Tab
                  _buildGamesList(_pastGames, isUpcoming: false),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGameDialog,
        tooltip: 'Add Game',
        child: const Icon(Icons.add),
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

        return _buildGameCard(game, isUpcoming: isUpcoming);
      },
    );
  }

  // Update the _buildGameCard method to remove delete and add player management
  Widget _buildGameCard(Map<String, dynamic> game, {required bool isUpcoming}) {
    final gameId = game['_id'].toString();
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
                    game['title'] ?? 'Game',
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
                      IconButton(
                        icon: const Icon(Icons.group_add, color: Colors.blue),
                        onPressed:
                            () => _showAddPlayersDialog(
                              gameId,
                              game['title'] ?? 'Game',
                            ),
                        tooltip: 'Manage Players',
                      ),
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
              Text(
                'Current Lineup (${currentLineup.length}/11):',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                          '#${player['jerseyNumber']} ${player['name']}',
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
