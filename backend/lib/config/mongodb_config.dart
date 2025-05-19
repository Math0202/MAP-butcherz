class MongoDBConfig {
  // Replace with your MongoDB Atlas connection string from environment variables
  // Format: mongodb+srv://<username>:<password>@<cluster-url>/<database-name>?retryWrites=true&w=majority
  static const String connectionString = 'YOUR_MONGODB_CONNECTION_STRING';
  
  // Collection names - ensure these match the actual collection names in your database
  static const String usersCollection = 'users';
  static const String verificationCodesCollection = 'verification_codes';
} 