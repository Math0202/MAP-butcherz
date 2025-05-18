import 'package:mongo_dart/mongo_dart.dart';
import 'package:hocky_na_org/config/mongodb_config.dart';
import 'package:http/http.dart' as http;

class MongoDBService {
  static Db? _db;
  static bool _isInitialized = false;

  // Initialize the MongoDB connection
  static Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        _db = await Db.create(MongoDBConfig.connectionString);
        await _db!.open();
        _isInitialized = true;
        print('Connected to MongoDB successfully');
      } catch (e) {
        print('Failed to connect to MongoDB: $e');
        rethrow;
      }
    }
  }

  // Get a collection by name
  static DbCollection getCollection(String collectionName) {
    if (!_isInitialized) {
      throw Exception('MongoDB not initialized. Call initialize() first.');
    }
    return _db!.collection(collectionName);
  }

  // Store verification code
  static Future<void> storeVerificationCode({
    required String contact,
    required String code,
    required DateTime expiresAt,
  }) async {
    try {
      print("Storing verification code for contact: $contact, code: $code");
      final collection = getCollection(MongoDBConfig.verificationCodesCollection);
      
      // Remove any existing codes for this contact
      await collection.remove(where.eq('contact', contact));
      
      // Insert new verification code
      final insertResult = await collection.insert({
        'contact': contact,
        'code': code,
        'expiresAt': expiresAt,
        'createdAt': DateTime.now(),
      });
      
      print("Verification code stored. Result: $insertResult");
    } catch (e) {
      print('Error storing verification code: $e');
      rethrow;
    }
  }

  // Verify code
  static Future<bool> verifyCode({
    required String contact,
    required String code,
  }) async {
    try {
      final collection = getCollection(MongoDBConfig.verificationCodesCollection);
      
      print("Verifying code for contact: $contact, code: $code");
      
      // Find a verification code that matches and hasn't expired
      // The expiry check ensures expiresAt is in the future (current time is less than expiry time)
      final result = await collection.findOne(
        where.eq('contact', contact)
            .eq('code', code)
            .gt('expiresAt', DateTime.now())
      );
      
      final isValid = result != null;
      print("Verification result: ${isValid ? 'valid' : 'invalid'} - ${result.toString()}");
      
      return isValid;
    } catch (e) {
      print('Error verifying code: $e');
      return false;
    }
  }

  // Get user by email or phone
  static Future<Map<String, dynamic>?> getUserByEmailOrPhone(String emailOrPhone) async {
    try {
      final collection = getCollection(MongoDBConfig.usersCollection);
      
      final user = await collection.findOne(
        where.eq('email', emailOrPhone).or(where.eq('phoneNumber', emailOrPhone))
      );
      
      return user;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Close the connection
  static Future<void> close() async {
    if (_isInitialized && _db != null) {
      await _db!.close();
      _isInitialized = false;
    }
  }

  // Send login notification SMS
  static Future<void> sendLoginNotificationSMS(String phoneNumber, String fullName) async {
    try {
      print("Sending login notification SMS to: $phoneNumber for user: $fullName");
      
      // Format the message with more details
      final now = DateTime.now();
      final timeString = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
      final dateString = "${now.day}/${now.month}/${now.year}";
      
      final message = Uri.encodeComponent(
        "Hello $fullName, a device has logged into your Hocky app on $dateString at $timeString. "
        "If it was not you, please change your password immediately by contacting support."
      );
      
      // Build API URL for the MTC SMS gateway
      final apiUrl = 'https://connectsms.mtc.com.na/api.asmx/SendSMS'
          '?from_number=0814800039'
          '&username=Ausgezeichnet'
          '&password=User@0046'
          '&destination=$phoneNumber'
          '&message=$message';
      
      print("Sending notification SMS request to: ${apiUrl.replaceAll(RegExp(r'password=[^&]*'), 'password=XXXXX')}");
      
      // Make a GET request to the SMS API
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('SMS API response: $responseBody');
        
        // Check if the SMS was sent successfully
        if (responseBody.contains("<Status>0</Status>") || responseBody.contains("success")) {
          print('Login notification SMS sent successfully to $phoneNumber');
        } else {
          // Extract error message if possible
          String errorMessage = "Unknown error";
          if (responseBody.contains("<ErrorMessage>")) {
            final startIndex = responseBody.indexOf("<ErrorMessage>") + "<ErrorMessage>".length;
            final endIndex = responseBody.indexOf("</ErrorMessage>");
            if (startIndex != -1 && endIndex != -1) {
              errorMessage = responseBody.substring(startIndex, endIndex);
            }
          }
          print('Failed to send login notification SMS. Error: $errorMessage');
        }
      } else {
        print('Failed to send login notification SMS. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error sending login notification SMS: $e');
    }
  }
} 