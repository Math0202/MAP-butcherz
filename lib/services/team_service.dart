import 'dart:convert';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:hocky_na_org/services/mongodb_service.dart';
import 'package:hocky_na_org/config/mongodb_config.dart';

class Team {
  final String? id;
  final String name;
  final String? logoUrl;
  final String coachName;
  final String coachContact;
  final String ownerEmail;
  final DateTime createdAt;

  Team({
    this.id,
    required this.name,
    this.logoUrl,
    required this.coachName,
    required this.coachContact,
    required this.ownerEmail,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'coachName': coachName,
      'coachContact': coachContact,
      'ownerEmail': ownerEmail,
      'createdAt': createdAt,
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['_id'].toString(),
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'],
      coachName: map['coachName'] ?? '',
      coachContact: map['coachContact'] ?? '',
      ownerEmail: map['ownerEmail'] ?? '',
      createdAt: map['createdAt'] ?? DateTime.now(),
    );
  }
}

class TeamService {
  static const String collectionName = 'teams';

  // Register a new team
  static Future<Map<String, dynamic>> registerTeam({
    required String name,
    required String coachName,
    required String coachContact,
    required String ownerEmail,
    File? logoFile,
  }) async {
    try {
      final teamsCollection = MongoDBService.getCollection('teams');
      
      // Check if team name already exists
      final existingTeam = await teamsCollection.findOne({'name': name});
      if (existingTeam != null) {
        return {
          'success': false,
          'message': 'A team with this name already exists',
        };
      }

      // Prepare team data
      Map<String, dynamic> teamData = {
        'name': name,
        'coachName': coachName,
        'coachPhone': coachContact,
        'coachEmail': ownerEmail,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
        'playersCount': 0, // Track number of players
        'maxPlayers': 25, // Default maximum players per team
      };

      // Handle logo upload if provided
      if (logoFile != null) {
        // You can implement logo upload logic here
        // For now, we'll just store the file path
        teamData['logoPath'] = logoFile.path;
      }

      // Insert the team
      final result = await teamsCollection.insertOne(teamData);
      
      if (result.isSuccess) {
        final teamId = result.id.toString();
        
        // Create players sub-collection for this team
        final playersResult = await createPlayersSubCollection(teamId);
        
        if (playersResult['success']) {
          return {
            'success': true,
            'message': 'Team registered successfully with players collection',
            'teamId': teamId,
            'playersCollectionId': playersResult['playersCollectionId'],
          };
        } else {
          // Team created but players collection failed
          return {
            'success': true,
            'message': 'Team registered but players collection setup failed',
            'teamId': teamId,
            'warning': playersResult['message'],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to register team: ${result.writeError?.errmsg ?? "Unknown error"}',
        };
      }
    } catch (e) {
      print('Error in registerTeam: $e');
      return {
        'success': false,
        'message': 'An error occurred while registering the team: $e',
      };
    }
  }

  // Get teams by owner email
  static Future<List<Team>> getTeamsByOwnerEmail(String ownerEmail) async {
    try {
      final collection = MongoDBService.getCollection(collectionName);
      final cursor = collection.find(where.eq('ownerEmail', ownerEmail));
      
      final teams = await cursor.map((doc) => Team.fromMap(doc)).toList();
      return teams;
    } catch (e) {
      print('Error fetching teams: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllTeams() async {
    try {
      // Use the static getCollection method, not instance method
      final teamsCollection = MongoDBService.getCollection(collectionName);
      final teamsDocs = await teamsCollection.find().toList();
      
      // Return the teams as List<Map<String, dynamic>>
      return teamsDocs.map((doc) => doc as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching teams: $e');
      return [];
    }
  }

  // Add this method to handle players sub-collection
  static Future<Map<String, dynamic>> createPlayersSubCollection(String teamId) async {
    try {
      final playersCollection = MongoDBService.getCollection('players');
      
      // Create an initial empty document for the team's players
      final result = await playersCollection.insertOne({
        'teamId': teamId,
        'teamPlayers': [], // Array to store player references
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      return {
        'success': true,
        'playersCollectionId': result.id.toString(),
      };
    } catch (e) {
      print('Error creating players sub-collection: $e');
      return {
        'success': false,
        'message': 'Failed to create players collection: $e',
      };
    }
  }
}