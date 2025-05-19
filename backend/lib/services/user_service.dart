import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'mongodb_service.dart';

class UserService {
  static const String _collection = 'users';
  
  // Password hashing
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // User registration
  static Future<ObjectId> registerUser({
    required String username,
    required String password,
    required String phoneNumber,
    required String email,
    String? fullName,
    bool isVerified = false,
  }) async {
    // Check if user already exists
    final existingUser = await MongoDBService.findOne(
      _collection,
      {'username': username}
    );
    
    if (existingUser != null) {
      throw Exception('Username already exists');
    }

    final user = {
      'username': username,
      'password': hashPassword(password),
      'phoneNumber': phoneNumber,
      'email': email,
      'fullName': fullName,
      'isVerified': isVerified,
      'createdAt': DateTime.now(),
      'lastLogin': null,
    };

    return await MongoDBService.insert(_collection, user);
  }

  // User authentication
  static Future<Map<String, dynamic>> authenticateUser(
    String username,
    String password
  ) async {
    final user = await MongoDBService.findOne(
      _collection,
      {
        'username': username,
        'password': hashPassword(password),
      }
    );

    if (user == null) {
      throw Exception('Invalid username or password');
    }

    // Update last login
    await MongoDBService.update(
      _collection,
      {'_id': user['_id']},
      {'\$set': {'lastLogin': DateTime.now()}}
    );

    return user;
  }

  // Phone verification
  static Future<void> updateVerificationStatus(
    ObjectId userId,
    bool isVerified
  ) async {
    await MongoDBService.update(
      _collection,
      {'_id': userId},
      {'\$set': {'isVerified': isVerified}}
    );
  }

  // Update user profile
  static Future<void> updateUserProfile(
    ObjectId userId,
    Map<String, dynamic> updates
  ) async {
    // Remove sensitive fields that shouldn't be updated directly
    updates.remove('password');
    updates.remove('_id');
    updates.remove('username');
    
    await MongoDBService.update(
      _collection,
      {'_id': userId},
      {'\$set': updates}
    );
  }

  // Change password
  static Future<void> changePassword(
    ObjectId userId,
    String currentPassword,
    String newPassword
  ) async {
    final user = await MongoDBService.findOne(
      _collection,
      {
        '_id': userId,
        'password': hashPassword(currentPassword)
      }
    );

    if (user == null) {
      throw Exception('Current password is incorrect');
    }

    await MongoDBService.update(
      _collection,
      {'_id': userId},
      {'\$set': {'password': hashPassword(newPassword)}}
    );
  }

  // Get user by ID
  static Future<Map<String, dynamic>?> getUserById(ObjectId userId) async {
    return await MongoDBService.findOne(_collection, {'_id': userId});
  }

  // Delete user account
  static Future<void> deleteUser(ObjectId userId) async {
    await MongoDBService.delete(_collection, {'_id': userId});
  }
} 