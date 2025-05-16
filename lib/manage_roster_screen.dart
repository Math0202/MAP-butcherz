import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hocky_na_org/elements/custom_text_field.dart'; // For add player dialog

// Dummy Player Model (replace with your actual data model)
class Player {
  final String id;
  final String name;
  final String position;
  final String? jerseyNumber;
  final String? avatarUrl; // Optional: for player image

  Player({
    required this.id,
    required this.name,
    required this.position,
    this.jerseyNumber,
    this.avatarUrl,
  });
}

class ManageRosterScreen extends StatefulWidget {
  const ManageRosterScreen({super.key});

  @override
  State<ManageRosterScreen> createState() => _ManageRosterScreenState();
}

class _ManageRosterScreenState extends State<ManageRosterScreen> {
  // Dummy list of players (replace with actual data fetching)
  final List<Player> _players = [
    Player(id: '1', name: 'John Doe', position: 'Forward', jerseyNumber: '10', avatarUrl: 'assets/player_avatar_male.png'),
    Player(id: '2', name: 'Jane Smith', position: 'Defender', jerseyNumber: '5', avatarUrl: 'assets/player_avatar_female.png'),
    Player(id: '3', name: 'Mike Brown', position: 'Goalkeeper', jerseyNumber: '1'),
    Player(id: '4', name: 'Lisa Ray', position: 'Midfielder', jerseyNumber: '7', avatarUrl: 'assets/player_avatar_female.png'),
    Player(id: '5', name: 'Chris Green', position: 'Forward', jerseyNumber: '11'),
  ];

  // TODO: Add TextEditingControllers for the "Add Player" dialog
  // final _playerNameController = TextEditingController();
  // final _playerPositionController = TextEditingController();
  // final _playerJerseyController = TextEditingController();


  @override
  void dispose() {
    // TODO: Dispose controllers
    // _playerNameController.dispose();
    // _playerPositionController.dispose();
    // _playerJerseyController.dispose();
    super.dispose();
  }

  void _addPlayer(Player newPlayer) {
    setState(() {
      _players.add(newPlayer);
    });
    // TODO: API call to add player to backend
  }

  void _editPlayer(Player playerToEdit) {
    // TODO: Implement edit player dialog/screen and logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit player: ${playerToEdit.name} (Not implemented)')),
    );
  }

  void _removePlayer(Player playerToRemove) {
    setState(() {
      _players.removeWhere((p) => p.id == playerToRemove.id);
    });
    // TODO: API call to remove player from backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed player: ${playerToRemove.name}')),
    );
  }

  Future<void> _showAddPlayerDialog() async {
    // Reset controllers if they exist
    // _playerNameController.clear();
    // _playerPositionController.clear();
    // _playerJerseyController.clear();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: const Text('Add New Player'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                CustomTextField(
                  // controller: _playerNameController,
                  hintText: 'Player Full Name',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 15),
                CustomTextField(
                  // controller: _playerPositionController,
                  hintText: 'Position (e.g., Forward)',
                  prefixIcon: Icons.sports_kabaddi, // Example icon
                ),
                const SizedBox(height: 15),
                CustomTextField(
                  // controller: _playerJerseyController,
                  hintText: 'Jersey Number (Optional)',
                  prefixIcon: Icons.numbers_outlined,
                  keyboardType: TextInputType.number,
                ),
                // TODO: Add field for player avatar/image upload if needed
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
                // TODO: Validate input
                // String name = _playerNameController.text;
                // String position = _playerPositionController.text;
                // String jersey = _playerJerseyController.text;

                // For now, using placeholder data
                String name = "New Player";
                String position = "Position";
                String jersey = (Random().nextInt(99) + 1).toString();


                if (name.isNotEmpty && position.isNotEmpty) {
                  _addPlayer(Player(
                    id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple unique ID
                    name: name,
                    position: position,
                    jerseyNumber: jersey.isNotEmpty ? jersey : null,
                  ));
                  Navigator.of(dialogContext).pop();
                } else {
                  // Show error if fields are empty
                   ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Name and Position are required.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
     
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
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: player.avatarUrl != null ? AssetImage(player.avatarUrl!) : null,
                      child: player.avatarUrl == null
                          ? Text(
                              player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                              style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    title: Text(player.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Position: ${player.position}${player.jerseyNumber != null ? " | #${player.jerseyNumber}" : ""}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
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
                      // Optional: Navigate to player details screen
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('View details for ${player.name} (Not implemented)')),
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