import 'package:flutter/material.dart';
import 'package:hocky_na_org/services/mongodb_service.dart'; // For database access
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

class adminHomeTab extends StatefulWidget {
  const adminHomeTab({super.key});

  @override
  State<adminHomeTab> createState() => _adminHomeTabState();
}

class _adminHomeTabState extends State<adminHomeTab> {
  // Text editing controllers for the add club dialog
  final _clubNameController = TextEditingController();
  final _locationController = TextEditingController();

  // Coach details controllers
  final _coachNameController = TextEditingController();
  final _coachEmailController = TextEditingController();
  final _coachPhoneController = TextEditingController();

  // State for clubs list
  bool _isLoading = true;
  List<Map<String, dynamic>> _clubs = [];

  @override
  void initState() {
    super.initState();
    _fetchClubs();
  }

  @override
  void dispose() {
    // Clean up controllers
    _clubNameController.dispose();
    _locationController.dispose();
    _coachNameController.dispose();
    _coachEmailController.dispose();
    _coachPhoneController.dispose();
    super.dispose();
  }

  // Fetch clubs from database
  Future<void> _fetchClubs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final teamsCollection = MongoDBService.getCollection('teams');
      final teams = await teamsCollection.find().toList();
      
      setState(() {
        _clubs = List<Map<String, dynamic>>.from(teams);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching clubs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Delete club and associated coach
  Future<void> _deleteClub(Map<String, dynamic> club) async {
    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Club'),
          content: Text('Are you sure you want to delete "${club['name']}"? This cannot be undone.'),
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
      
      // Delete the club
      final teamsCollection = MongoDBService.getCollection('teams');
      await teamsCollection.remove({'_id': club['_id']});
      
      // Optionally, update the coach's role or delete coach user
      if (club.containsKey('coachId') && club['coachId'] != null) {
        final usersCollection = MongoDBService.getCollection('users');
        final coachId = club['coachId'];
        
        try {
          // Try to find the coach user by ID first
          final coachQuery = coachId is ObjectId 
              ? {'_id': coachId} 
              : {'_id': ObjectId.fromHexString(coachId.toString())};
              
          // Update coach role to user
          await usersCollection.update(
            coachQuery,
            {'\$set': {'role': 'user'}},
          );
          
          print('Updated coach role for ID: $coachId');
        } catch (e) {
          // If we can't find by ID, try with email as fallback
          if (club.containsKey('coachEmail') && club['coachEmail'] != null) {
            await usersCollection.update(
              {'email': club['coachEmail']},
              {'\$set': {'role': 'user'}},
            );
            print('Updated coach role using email: ${club['coachEmail']}');
          } else {
            print('Could not update coach: $e');
          }
        }
      }
      
      // Refresh the clubs list
      _fetchClubs();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Club "${club['name']}" deleted successfully'),
          ),
        );
      }
    } catch (e) {
      print('Error deleting club: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting club: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Edit club and coach details
  Future<void> _editClub(Map<String, dynamic> club) async {
    // Set initial values for the controllers
    _clubNameController.text = club['name'] ?? '';
    _locationController.text = club['location'] ?? '';
    _coachNameController.text = club['coachName'] ?? '';
    _coachEmailController.text = club['coachEmail'] ?? '';
    _coachPhoneController.text = club['coachPhone'] ?? '';
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Club'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Club Info Section
              const Text(
                'Club Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _clubNameController,
                decoration: const InputDecoration(
                  labelText: 'Club Name',
                  hintText: 'Enter the club name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter club location/address',
                ),
              ),
              const SizedBox(height: 24),

              // Coach Information Section
              const Text(
                'Coach Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _coachNameController,
                decoration: const InputDecoration(
                  labelText: 'Coach Name',
                  hintText: 'Enter full name',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _coachEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter email address',
                ),
                keyboardType: TextInputType.emailAddress,
                // Disable email editing to avoid complications with user accounts
                enabled: false,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _coachPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              // Validate inputs
              final clubName = _clubNameController.text.trim();
              final location = _locationController.text.trim();
              final coachName = _coachNameController.text.trim();
              final coachPhone = _coachPhoneController.text.trim();
              
              if (clubName.isEmpty || coachName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Club name and coach name are required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Validate phone if provided
              if (coachPhone.isNotEmpty && !_isValidPhoneNumber(coachPhone)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid phone number'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Check if club name exists and is different from current
              if (clubName != club['name']) {
                final teamsCollection = MongoDBService.getCollection('teams');
                final existingClub = await teamsCollection.findOne({
                  'name': clubName,
                  '_id': {'\$ne': club['_id']},
                });
                
                if (existingClub != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('A club with the name "$clubName" already exists'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                  return;
                }
              }
              
              Navigator.pop(context, true);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        // Update club in the database
        final teamsCollection = MongoDBService.getCollection('teams');
        await teamsCollection.update(
          {'_id': club['_id']},
          {
            '\$set': {
              'name': _clubNameController.text.trim(),
              'location': _locationController.text.trim(),
              'coachName': _coachNameController.text.trim(),
              'coachPhone': _coachPhoneController.text.trim(),
            }
          },
        );
        
        // Update coach in the users collection
        if (club.containsKey('coachId')) {
          final usersCollection = MongoDBService.getCollection('users');
          await usersCollection.update(
            {'_id': ObjectId.parse(club['coachId'].toString())},
            {
              '\$set': {
                'name': _coachNameController.text.trim(),
                'phone': _coachPhoneController.text.trim(),
              }
            },
          );
        }
        
        // Refresh clubs list
        _fetchClubs();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Club "${_clubNameController.text.trim()}" updated successfully'),
            ),
          );
        }
      } catch (e) {
        print('Error updating club: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating club: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    
    // Clear controllers
    _clubNameController.clear();
    _locationController.clear();
    _coachNameController.clear();
    _coachEmailController.clear();
    _coachPhoneController.clear();
  }

  // Method to show dialog for adding a new club
  void _showAddClubDialog() {
    // Reset state and controllers
    _clubNameController.clear();
    _locationController.clear();
    _coachNameController.clear();
    _coachEmailController.clear();
    _coachPhoneController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Club'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Club Info Section
              const Text(
                'Club Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _clubNameController,
                decoration: const InputDecoration(
                  labelText: 'Club Name',
                  hintText: 'Enter the club name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter club location/address',
                ),
              ),
              const SizedBox(height: 24),

              // Coach Creation Section
              const Text(
                'Coach Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Coach form - always shown now
              TextField(
                controller: _coachNameController,
                decoration: const InputDecoration(
                  labelText: 'Coach Name',
                  hintText: 'Enter full name',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _coachEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter email address',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _coachPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              // Get club details
              final clubName = _clubNameController.text.trim();
              final location = _locationController.text.trim();

              // Validate club name
              if (clubName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Club name is required'),
                  ),
                );
                return;
              }

              // Validate coach information
              final coachName = _coachNameController.text.trim();
              final coachEmail = _coachEmailController.text.trim();
              final coachPhone = _coachPhoneController.text.trim();

              if (coachName.isEmpty || coachEmail.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Coach name and email are required'),
                  ),
                );
                return;
              }

              // Optional: Validate phone format if needed
              if (coachPhone.isNotEmpty && !_isValidPhoneNumber(coachPhone)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid phone number'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                // Check if a club with this name already exists
                final teamsCollection = MongoDBService.getCollection('teams');
                final existingClub = await teamsCollection.findOne({'name': clubName});
                
                if (existingClub != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('A club with the name "$clubName" already exists'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                  return;
                }
                
                // Check if a user with this email already exists
                final usersCollection = MongoDBService.getCollection('users');
                final existingUserByEmail = await usersCollection.findOne({'email': coachEmail});
                
                if (existingUserByEmail != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('A user with the email "$coachEmail" already exists'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                  return;
                }
                
                // Check if a user with this phone number already exists (only if phone is provided)
                if (coachPhone.isNotEmpty) {
                  final existingUserByPhone = await usersCollection.findOne({'phone': coachPhone});
                  
                  if (existingUserByPhone != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('A user with the phone number "$coachPhone" already exists'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                    return;
                  }
                }
                
                // Now proceed with creating the coach and club
                final newCoachData = {
                  'name': coachName,
                  'email': coachEmail,
                  'phone': coachPhone,
                  'role': 'coach',
                  'isVerified': true, // Admin-created accounts are pre-verified
                  'createdAt': DateTime.now(),
                  'password': 'Password123', // In a real app, use a secure random password
                  'mustChangePassword': true,
                };

                final result = await usersCollection.insert(newCoachData);
                final coachId = result.toString();
                
                // Create the club with coach reference
                await teamsCollection.insert({
                  'name': clubName,
                  'location': location,
                  'coachId': coachId,
                  'coachName': coachName,
                  'coachEmail': coachEmail,
                  'coachPhone': coachPhone, // Also store phone with the club record
                  'createdAt': DateTime.now(),
                  'isActive': true,
                });

                // Close dialog and show success message
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Club "$clubName" with coach "$coachName" added successfully!'),
                  ),
                );
              } catch (e) {
                print('Error creating club: $e');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding club: $e')),
                );
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  // Simple phone number validation
  bool _isValidPhoneNumber(String phone) {
    // Remove any non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    
    // Simple validation - adjust based on your requirements:
    // This example checks if the number has between 8-14 digits
    return digitsOnly.length >= 8 && digitsOnly.length <= 14;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clubs.isEmpty
              ? const Center(
                  child: Text(
                    'No clubs added yet!',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _clubs.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final club = _clubs[index];
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
                                        club['name'] ?? 'Unnamed Club',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Location: ${club['location'] ?? 'N/A'}',
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
                                      onPressed: () => _editClub(club),
                                      tooltip: 'Edit Club',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteClub(club),
                                      tooltip: 'Delete Club',
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Coach Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildCoachInfo(
                              'Name',
                              club['coachName'] ?? 'Not assigned',
                              Icons.person,
                            ),
                            _buildCoachInfo(
                              'Email',
                              club['coachEmail'] ?? 'N/A',
                              Icons.email,
                            ),
                            _buildCoachInfo(
                              'Phone',
                              club['coachPhone'] ?? 'N/A',
                              Icons.phone,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClubDialog,
        tooltip: 'Add Club',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper widget for displaying coach info
  Widget _buildCoachInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
