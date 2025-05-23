import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:hocky_na_org/services/mongodb_service.dart';
import 'package:hocky_na_org/config/mongodb_config.dart';
import 'package:hocky_na_org/services/user_state.dart';

class UserService {
  // Hash password using SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert to bytes
    final digest = sha256.convert(bytes); // Apply SHA-256 hashing
    return digest.toString();
  }

  // Register a new user
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String phoneNumber,
    required String password,
    String? fullName,
    String? fieldPosition,
    String? gender,
    String? age,
  }) async {
    try {
      // Check if user already exists
      final collection = MongoDBService.getCollection(
        MongoDBConfig.usersCollection,
      );
      final existingUser = await collection.findOne(
        where.eq('email', email).or(where.eq('phoneNumber', phoneNumber)),
      );

      if (existingUser != null) {
        if (existingUser['email'] == email) {
          return {'success': false, 'message': 'Email already registered'};
        } else {
          return {
            'success': false,
            'message': 'Phone number already registered',
          };
        }
      }

      // Hash the password
      final hashedPassword = hashPassword(password);

      // Create user document
      final userData = {
        'email': email,
        'phoneNumber': phoneNumber,
        'password': hashedPassword,
        'fullName': fullName,
        'fieldPosition': fieldPosition,
        'gender': gender,
        'age': age,
        'verified': false,
        'createdAt': DateTime.now(),
      };

      try {
        // Insert user into database
        final result = await collection.insert(userData);

        // Debug info to see the structure of the response
        print("MongoDB insert result: $result");

        // In mongo_dart, if insert is successful, we'll have the inserted document with an _id
        if (result != null) {
          final String userId = result['_id'].toString();
          return {
            'success': true,
            'message': 'User registered successfully',
            'userId': userId,
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to register user - no result from database',
          };
        }
      } catch (dbError) {
        print("MongoDB insert error: $dbError");
        return {
          'success': false,
          'message': 'Database error: ${dbError.toString()}',
        };
      }
    } catch (e) {
      print('Error registering user: $e');
      return {
        'success': false,
        'message': 'An error occurred during registration: ${e.toString()}',
      };
    }
  }

  // Verify user account after verification code is confirmed
  static Future<bool> verifyUserAccount(String userId) async {
    try {
      print("Attempting to verify user account with ID: $userId");

      // Make sure we have a valid ObjectId format
      ObjectId objectId;
      try {
        objectId = ObjectId.fromHexString(userId);
        print("Parsed ObjectId: $objectId");
      } catch (e) {
        print("Failed to parse ObjectId from $userId: $e");
        return false;
      }

      final collection = MongoDBService.getCollection(
        MongoDBConfig.usersCollection,
      );

      // Add more specific debugging for the update operation
      print(
        "Running MongoDB update on collection: ${MongoDBConfig.usersCollection}",
      );
      print("Using query: ${where.id(objectId).toString()}");

      // Use a direct update with a map instead of modify builder, which can be problematic
      final updateDoc = {
        '\$set': {'verified': true, 'verifiedAt': DateTime.now()},
      };

      print("Update document: $updateDoc");

      final result = await collection.update(where.id(objectId), updateDoc);

      print("Update result: $result");

      // Check if the update was successful
      final success =
          result['ok'] == 1.0 && (result['nModified'] > 0 || result['n'] > 0);

      print(
        "User verification ${success ? 'succeeded' : 'failed'} for user $userId",
      );

      return success;
    } catch (e) {
      print("Error verifying user account: $e");
      return false;
    }
  }

  // Login user
  static Future<Map<String, dynamic>> loginUser({required String email}) async {
    try {
      print("Attempting to login user with email: $email");

      // Get user by email
      final collection = MongoDBService.getCollection(
        MongoDBConfig.usersCollection,
      );
      final user = await collection.findOne(where.eq('email', email));

      // Check if user exists
      if (user == null) {
        print("Login failed: User not found with email $email");
        return {'success': false, 'message': 'Invalid email or password'};
      }

      // Hash the provided password and compare with stored hash
      final hashedPassword = hashPassword('password');
      if (user['password'] != hashedPassword) {
        print("Login failed: Password incorrect for user $email");
        return {'success': false, 'message': 'Invalid email or password'};
      }

      // Get user's full name or use email as fallback
      final String fullName = user['fullName'] ?? email.split('@')[0];
      final phoneNumber = user['phoneNumber'] as String?;

      // Always send login notification SMS, regardless of verification status
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        try {
          print("Sending login security SMS to $phoneNumber");
          await MongoDBService.sendLoginNotificationSMS(phoneNumber, fullName);
          print("Login security SMS successfully queued");
        } catch (smsError) {
          print("Failed to send login notification SMS: $smsError");
          // Continue with login even if SMS fails
        }
      } else {
        print("No phone number available to send login security SMS");
      }

      // Check if user is verified AFTER sending the security SMS
      if (user['verified'] != true) {
        print("Login warning: Unverified user $email");
        return {
          'success': false,
          'message': 'Please verify your account first',
          'unverified': true,
          'email': email,
          'phoneNumber': phoneNumber,
        };
      }

      // Successful login
      print("Login successful for user $email");
      return {
        'success': true,
        'message': 'Login successful',
        'email': email,
        'user': user,
      };
    } catch (e) {
      print("Login error: $e");
      return {'success': false, 'message': 'An error occurred during login'};
    }
  }

  // Log out user
  static void logoutUser() {
    UserState.clearCurrentUserEmail();
  }
}
