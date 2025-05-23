import 'package:flutter/material.dart';
import 'package:hocky_na_org/services/mongodb_service.dart';
import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

class AdminGames extends StatefulWidget {
  const AdminGames({super.key});

  @override
  State<AdminGames> createState() => _AdminGamesState();
}

class _AdminGamesState extends State<AdminGames> with SingleTickerProviderStateMixin {
  // Tab controller for upcoming/past games
  late TabController _tabController;
  
  // State variables
  bool _isLoading = true;
  List<Map<String, dynamic>> _upcomingGames = [];
  List<Map<String, dynamic>> _pastGames = [];
  List<Map<String, dynamic>> _teams = [];
  
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchGames();
    _fetchTeams();
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
      final upcomingGamesData = await gamesCollection
          .find({'gameDate': {'\$gte': now.toIso8601String()}})
          .toList();
      
      // Fetch past games (game date < today)
      final pastGamesData = await gamesCollection
          .find({'gameDate': {'\$lt': now.toIso8601String()}})
          .toList();
      
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
        'status': gameDateTime.isAfter(DateTime.now()) ? 'upcoming' : 'completed',
        'createdAt': DateTime.now().toIso8601String(),
        'isHighlighted': false,  // Default not highlighted
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
    final gameDateTime = game['gameDate'] != null 
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
      builder: (context) => AlertDialog(
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
                  validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _venueController,
                  decoration: const InputDecoration(
                    labelText: 'Venue',
                    hintText: 'e.g., Main Hockey Stadium',
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter a venue' : null,
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
                  subtitle: Text(DateFormat('EEE, MMM d, yyyy').format(_gameDate)),
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
                  decoration: const InputDecoration(
                    labelText: 'Team A',
                  ),
                  value: _teamA,
                  items: _teams.map((team) {
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
                            content: Text('A team cannot play against itself'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    });
                  },
                  validator: (value) => value == null 
                    ? 'Please select Team A' 
                    : (value == _teamB ? 'Teams cannot be the same' : null),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Team B',
                  ),
                  value: _teamB,
                  items: _teams.map((team) {
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
                            content: Text('A team cannot play against itself'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    });
                  },
                  validator: (value) => value == null 
                    ? 'Please select Team B' 
                    : (value == _teamA ? 'Teams cannot be the same' : null),
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
          'status': gameDateTime.isAfter(DateTime.now()) ? 'upcoming' : 'completed',
        }
      };
      
      // Add scores if provided
      if (_resultTeamA != null && _resultTeamA!.isNotEmpty) {
        updateData['\$set']?['resultTeamA'] = (int.tryParse(_resultTeamA!) ?? 0) as String?;
      }
      
      if (_resultTeamB != null && _resultTeamB!.isNotEmpty) {
        updateData['\$set']?['resultTeamB'] = (int.tryParse(_resultTeamB!) ?? 0) as String?;
      }
      
      await gamesCollection.update(
        {'_id': game['_id']},
        updateData,
      );
      
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
        builder: (context) => AlertDialog(
          title: const Text('Delete Game'),
          content: Text('Are you sure you want to delete "${game['title']}"? This cannot be undone.'),
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
          SnackBar(content: Text('Game "${game['title']}" deleted successfully')),
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
      builder: (context) => AlertDialog(
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
                  validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _venueController,
                  decoration: const InputDecoration(
                    labelText: 'Venue',
                    hintText: 'e.g., Main Hockey Stadium',
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter a venue' : null,
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
                  subtitle: Text(DateFormat('EEE, MMM d, yyyy').format(_gameDate)),
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
                  decoration: const InputDecoration(
                    labelText: 'Team A',
                  ),
                  value: _teamA,
                  items: _teams.map((team) {
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
                            content: Text('A team cannot play against itself'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    });
                  },
                  validator: (value) => value == null 
                    ? 'Please select Team A' 
                    : (value == _teamB ? 'Teams cannot be the same' : null),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Team B',
                  ),
                  value: _teamB,
                  items: _teams.map((team) {
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
                            content: Text('A team cannot play against itself'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    });
                  },
                  validator: (value) => value == null 
                    ? 'Please select Team B' 
                    : (value == _teamA ? 'Teams cannot be the same' : null),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming Games'),
            Tab(text: 'Past Games'),
          ],
        ),
      ),
      body: _isLoading
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
  Widget _buildGamesList(List<Map<String, dynamic>> games, {required bool isUpcoming}) {
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
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game['title'] ?? 'Untitled Game',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Venue: ${game['venue'] ?? 'TBD'}',
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: $formattedDate at $formattedTime',
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editGame(game),
                          tooltip: 'Edit Game',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteGame(game),
                          tooltip: 'Delete Game',
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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
                if (game['description'] != null && game['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    game['description'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
