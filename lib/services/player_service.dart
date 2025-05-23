import 'package:hocky_na_org/services/mongodb_service.dart';
import 'package:bson/bson.dart';

class PlayerService {
  // Get all available players (not assigned to any team)
  static Future<List<Map<String, dynamic>>> getAvailablePlayers() async {
    try {
      final playersCollection = MongoDBService.getCollection('all_players');
      
      // Find players without a team or with teamId as null/empty
      final availablePlayers = await playersCollection.find({
        '\$or': [
          {'teamId': null},
          {'teamId': ''},
          {'teamId': {'\$exists': false}},
        ]
      }).toList();
      
      return List<Map<String, dynamic>>.from(availablePlayers);
    } catch (e) {
      print('Error fetching available players: $e');
      return [];
    }
  }
  
  // Get players for a specific team
  static Future<List<Map<String, dynamic>>> getTeamPlayers(String teamName) async {
    try {
      final playersCollection = MongoDBService.getCollection('all_players');
      
      // Find players assigned to this team
      final teamPlayers = await playersCollection.find({
        'teamName': teamName
      }).toList();
      
      return List<Map<String, dynamic>>.from(teamPlayers);
    } catch (e) {
      print('Error fetching team players: $e');
      return [];
    }
  }
  
  // Sign a player to a team
  static Future<Map<String, dynamic>> signPlayerToTeam({
    required String playerId,
    required String teamName,
    required String teamId,
  }) async {
    try {
      final playersCollection = MongoDBService.getCollection('all_players');
      final teamsCollection = MongoDBService.getCollection('teams');
      
      // Update player's team information
      final playerResult = await playersCollection.updateOne(
        {'_id': playerId},
        {
          '\$set': {
            'teamName': teamName,
            'teamId': teamId,
            'signedAt': DateTime.now().toIso8601String(),
            'status': 'active',
          }
        }
      );
      
      if (playerResult.isSuccess) {
        // Update team's player count
        await teamsCollection.updateOne(
          {'name': teamName},
          {'\$inc': {'playersCount': 1}}
        );
        
        return {
          'success': true,
          'message': 'Player signed successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to sign player',
        };
      }
    } catch (e) {
      print('Error signing player: $e');
      return {
        'success': false,
        'message': 'Error signing player: $e',
      };
    }
  }
  
  // Create a new player
  static Future<Map<String, dynamic>> createNewPlayer({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String position,
    required int jerseyNumber,
    String? teamName,
    String? teamId,
  }) async {
    try {
      final playersCollection = MongoDBService.getCollection('all_players');
      
      // Check if email already exists
      final existingPlayer = await playersCollection.findOne({'email': email});
      if (existingPlayer != null) {
        return {
          'success': false,
          'message': 'A player with this email already exists',
        };
      }
      
      // Check if jersey number is taken in the team (if team is specified)
      if (teamName != null) {
        final existingJersey = await playersCollection.findOne({
          'teamName': teamName,
          'jerseyNumber': jerseyNumber,
        });
        if (existingJersey != null) {
          return {
            'success': false,
            'message': 'Jersey number $jerseyNumber is already taken in this team',
          };
        }
      }
      
      // Create new player
      final playerData = {
        'firstName': firstName,
        'lastName': lastName,
        'fullName': '$firstName $lastName',
        'email': email,
        'phone': phone,
        'position': position,
        'jerseyNumber': jerseyNumber,
        'teamName': teamName,
        'teamId': teamId,
        'status': teamName != null ? 'active' : 'available',
        'createdAt': DateTime.now().toIso8601String(),
        'signedAt': teamName != null ? DateTime.now().toIso8601String() : null,
      };
      
      final result = await playersCollection.insertOne(playerData);
      
      if (result.isSuccess) {
        // If player is assigned to a team, update team's player count
        if (teamName != null) {
          final teamsCollection = MongoDBService.getCollection('teams');
          await teamsCollection.updateOne(
            {'name': teamName},
            {'\$inc': {'playersCount': 1}}
          );
        }
        
        return {
          'success': true,
          'message': 'Player created successfully',
          'playerId': result.id.toString(),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create player',
        };
      }
    } catch (e) {
      print('Error creating player: $e');
      return {
        'success': false,
        'message': 'Error creating player: $e',
      };
    }
  }
  
  // Release a player from a team
  static Future<Map<String, dynamic>> releasePlayerFromTeam({
    required String playerId,
    required String teamName,
  }) async {
    try {
      final playersCollection = MongoDBService.getCollection('all_players');
      final teamsCollection = MongoDBService.getCollection('teams');
      
      // Update player to remove team assignment
      final playerResult = await playersCollection.updateOne(
        {'_id': playerId},
        {
          '\$unset': {
            'teamName': '',
            'teamId': '',
            'signedAt': '',
          },
          '\$set': {
            'status': 'available',
            'releasedAt': DateTime.now().toIso8601String(),
          }
        }
      );
      
      if (playerResult.isSuccess) {
        // Update team's player count
        await teamsCollection.updateOne(
          {'name': teamName},
          {'\$inc': {'playersCount': -1}}
        );
        
        return {
          'success': true,
          'message': 'Player released successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to release player',
        };
      }
    } catch (e) {
      print('Error releasing player: $e');
      return {
        'success': false,
        'message': 'Error releasing player: $e',
      };
    }
  }

  // Add this method to check for duplicate jersey numbers
  static Future<bool> isJerseyNumberTaken(String teamId, int jerseyNumber, {String? excludePlayerId}) async {
    try {
      final playersCollection = MongoDBService.getCollection('players');
      
      // Build query to check for existing jersey number
      Map<String, dynamic> query = {
        'teamId': teamId,
        'jerseyNumber': jerseyNumber,
      };
      
      // If we're updating a player, exclude their current record
      if (excludePlayerId != null) {
        query['_id'] = {'\$ne': ObjectId.fromHexString(excludePlayerId)};
      }
      
      final existingPlayer = await playersCollection.findOne(query);
      return existingPlayer != null;
    } catch (e) {
      print('Error checking jersey number: $e');
      return false; // Assume not taken if there's an error
    }
  }

  // Update the addPlayer method to include jersey number validation
  static Future<Map<String, dynamic>> addPlayer({
    required String teamId,
    required String name,
    required String position,
    required int jerseyNumber,
    required String contactInfo,
    String? emergencyContact,
    DateTime? dateOfBirth,
  }) async {
    try {
      // First check if jersey number is already taken
      final isJerseyTaken = await isJerseyNumberTaken(teamId, jerseyNumber);
      if (isJerseyTaken) {
        return {
          'success': false,
          'message': 'Jersey number $jerseyNumber is already taken by another player',
        };
      }

      final playersCollection = MongoDBService.getCollection('players');
      
      final playerData = {
        'teamId': teamId,
        'name': name,
        'position': position,
        'jerseyNumber': jerseyNumber,
        'contactInfo': contactInfo,
        'emergencyContact': emergencyContact,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final result = await playersCollection.insertOne(playerData);
      
      if (result.isSuccess) {
        return {
          'success': true,
          'message': 'Player added successfully',
          'playerId': result.id.toString(),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to add player: ${result.writeError?.errmsg ?? "Unknown error"}',
        };
      }
    } catch (e) {
      print('Error adding player: $e');
      return {
        'success': false,
        'message': 'An error occurred while adding the player: $e',
      };
    }
  }
} 