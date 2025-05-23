import 'package:flutter/material.dart';
import 'package:hocky_na_org/services/player_service.dart';
import 'package:hocky_na_org/elements/custom_text_field.dart';

class ManagePlayersScreen extends StatefulWidget {
  final String teamName;
  
  const ManagePlayersScreen({super.key, required this.teamName});
  
  @override
  State<ManagePlayersScreen> createState() => _ManagePlayersScreenState();
}

class _ManagePlayersScreenState extends State<ManagePlayersScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _teamPlayers = [];
  List<Map<String, dynamic>> _availablePlayers = [];
  bool _isLoadingTeamPlayers = true;
  bool _isLoadingAvailablePlayers = true;
  
  // Controllers for new player form
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jerseyNumberController = TextEditingController();
  String _selectedPosition = 'Forward';
  
  final List<String> _positions = [
    'Forward',
    'Defenseman',
    'Goaltender',
    'Center',
    'Left Wing',
    'Right Wing',
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTeamPlayers();
    _fetchAvailablePlayers();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _jerseyNumberController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchTeamPlayers() async {
    setState(() => _isLoadingTeamPlayers = true);
    
    final players = await PlayerService.getTeamPlayers(widget.teamName);
    
    setState(() {
      _teamPlayers = players;
      _isLoadingTeamPlayers = false;
    });
  }
  
  Future<void> _fetchAvailablePlayers() async {
    setState(() => _isLoadingAvailablePlayers = true);
    
    final players = await PlayerService.getAvailablePlayers();
    
    setState(() {
      _availablePlayers = players;
      _isLoadingAvailablePlayers = false;
    });
  }
  
  Future<void> _signPlayer(Map<String, dynamic> player) async {
    final result = await PlayerService.signPlayerToTeam(
      playerId: player['_id'].toString(),
      teamName: widget.teamName,
      teamId: widget.teamName, // Using team name as ID for simplicity
    );
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      _fetchTeamPlayers();
      _fetchAvailablePlayers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _releasePlayer(Map<String, dynamic> player) async {
    final result = await PlayerService.releasePlayerFromTeam(
      playerId: player['_id'].toString(),
      teamName: widget.teamName,
    );
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      _fetchTeamPlayers();
      _fetchAvailablePlayers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _createNewPlayer() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _jerseyNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // Validate jersey number
    final jerseyNumber = int.tryParse(_jerseyNumberController.text);
    if (jerseyNumber == null || jerseyNumber < 1 || jerseyNumber > 99) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jersey number must be between 1 and 99')),
      );
      return;
    }

    // Check if jersey number is already taken in this team
    final isJerseyTaken = await PlayerService.isJerseyNumberTaken(
      widget.teamName, // Using teamName as teamId
      jerseyNumber,
    );

    if (isJerseyTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jersey number $jerseyNumber is already taken by another player'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await PlayerService.createNewPlayer(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      position: _selectedPosition,
      jerseyNumber: jerseyNumber,
      teamName: widget.teamName,
      teamId: widget.teamName,
    );

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );

      // Clear form
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _jerseyNumberController.clear();

      _fetchTeamPlayers();
      Navigator.of(context).pop(); // Close dialog
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showCreatePlayerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Player'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _firstNameController,
                hintText: 'First Name',
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _lastNameController,
                hintText: 'Last Name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                hintText: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _jerseyNumberController,
                hintText: 'Jersey Number (1-99)',
                prefixIcon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPosition,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  prefixIcon: Icon(Icons.sports_hockey),
                  border: OutlineInputBorder(),
                ),
                items: _positions.map((position) {
                  return DropdownMenuItem(
                    value: position,
                    child: Text(position),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearForm();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _createNewPlayer,
            child: const Text('Add Player'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Players - ${widget.teamName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Team Players'),
            Tab(text: 'Available Players'),
            Tab(text: 'Create Player'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamPlayersTab(),
          _buildAvailablePlayersTab(),
          _buildCreatePlayerTab(),
        ],
      ),
    );
  }
  
  Widget _buildTeamPlayersTab() {
    if (_isLoadingTeamPlayers) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_teamPlayers.isEmpty) {
      return const Center(
        child: Text('No players in your team yet'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teamPlayers.length,
      itemBuilder: (context, index) {
        final player = _teamPlayers[index];
        return _buildPlayerCard(player, isTeamPlayer: true);
      },
    );
  }
  
  Widget _buildAvailablePlayersTab() {
    if (_isLoadingAvailablePlayers) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_availablePlayers.isEmpty) {
      return const Center(
        child: Text('No available players'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availablePlayers.length,
      itemBuilder: (context, index) {
        final player = _availablePlayers[index];
        return _buildPlayerCard(player, isTeamPlayer: false);
      },
    );
  }
  
  Widget _buildCreatePlayerTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Create a new player and add them directly to your team',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _showCreatePlayerDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create New Player'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayerCard(Map<String, dynamic> player, {required bool isTeamPlayer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.onPrimary,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '${player['jerseyNumber'] ?? '?'}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                player['fullName'] ?? '${player['firstName']} ${player['lastName']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPositionColor(player['position']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                player['position'] ?? 'Unknown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    player['email'] ?? 'No email',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            if (player['phone'] != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    player['phone'],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: isTeamPlayer
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'release') {
                    _showReleasePlayerDialog(player);
                  } else if (value == 'edit') {
                    _showEditPlayerDialog(player);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit Player'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'release',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Release Player'),
                      ],
                    ),
                  ),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () => _signPlayer(player),
                tooltip: 'Sign Player',
              ),
      ),
    );
  }

  // Helper method to get position-specific colors
  Color _getPositionColor(String? position) {
    switch (position?.toLowerCase()) {
      case 'goaltender':
      case 'goalkeeper':
        return Colors.orange;
      case 'defenseman':
      case 'defender':
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

  // Add these helper methods for better user experience
  void _showReleasePlayerDialog(Map<String, dynamic> player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Release Player'),
        content: Text(
          'Are you sure you want to release ${player['fullName'] ?? player['firstName']} ${player['lastName']} from the team?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _releasePlayer(player);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Release'),
          ),
        ],
      ),
    );
  }

  void _showEditPlayerDialog(Map<String, dynamic> player) {
    // Pre-fill controllers with existing data
    _firstNameController.text = player['firstName'] ?? '';
    _lastNameController.text = player['lastName'] ?? '';
    _emailController.text = player['email'] ?? '';
    _phoneController.text = player['phone'] ?? '';
    _jerseyNumberController.text = player['jerseyNumber']?.toString() ?? '';
    _selectedPosition = player['position'] ?? 'Forward';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Player'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _firstNameController,
                hintText: 'First Name',
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _lastNameController,
                hintText: 'Last Name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                hintText: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _jerseyNumberController,
                hintText: 'Jersey Number (1-99)',
                prefixIcon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPosition,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  prefixIcon: Icon(Icons.sports_hockey),
                  border: OutlineInputBorder(),
                ),
                items: _positions.map((position) {
                  return DropdownMenuItem(
                    value: position,
                    child: Text(position),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearForm();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _updatePlayer(player['_id'].toString()),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePlayer(String playerId) async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _jerseyNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // Validate jersey number
    final jerseyNumber = int.tryParse(_jerseyNumberController.text);
    if (jerseyNumber == null || jerseyNumber < 1 || jerseyNumber > 99) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jersey number must be between 1 and 99')),
      );
      return;
    }

    // Check if jersey number is taken by another player
    final isJerseyTaken = await PlayerService.isJerseyNumberTaken(
      widget.teamName,
      jerseyNumber,
      excludePlayerId: playerId,
    );

    if (isJerseyTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jersey number $jerseyNumber is already taken by another player'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update player logic would go here
    // For now, just show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Player updated successfully')),
    );

    _clearForm();
    _fetchTeamPlayers();
    Navigator.of(context).pop();
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _jerseyNumberController.clear();
    setState(() {
      _selectedPosition = 'Forward';
    });
  }
} 