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
      // Check if team name already exists
      final collection = MongoDBService.getCollection(collectionName);
      final existingTeam = await collection.findOne(where.eq('name', name));
      
      if (existingTeam != null) {
        return {
          'success': false,
          'message': 'A team with this name already exists'
        };
      }

      String? logoUrl;
      if (logoFile != null) {
        // In a real implementation, you would:
        // 1. Upload the image to a storage service (Firebase Storage, AWS S3, etc.)
        // 2. Get back the public URL
        // For now, we'll just log that we would upload the file
        print('Would upload logo file: ${logoFile.path}');
        logoUrl = 'https://placeholder.com/team_logo.png'; // Placeholder URL
      }
      
      // Create team document
      final teamData = Team(
        name: name,
        logoUrl: logoUrl,
        coachName: coachName,
        coachContact: coachContact,
        ownerEmail: "tangenimatheus",
      ).toMap();
      
      // Insert team into database
      final result = await collection.insert(teamData);
      
      if (result != null) {
        final String teamId = result['_id'].toString();
        return {
          'success': true,
          'message': 'Team registered successfully',
          'teamId': teamId
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to register team - no result from database'
        };
      }
    } catch (e) {
      print('Error registering team: $e');
      return {
        'success': false,
        'message': 'An error occurred during team registration: ${e.toString()}'
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
}