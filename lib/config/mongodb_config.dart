class MongoDBConfig {
  // Replace with your actual MongoDB connection string
  static const String connectionString = 'mongodb+srv://math0202:MILLshe%4073@cluster0.qgv6l7j.mongodb.net/hockyDB?retryWrites=true&w=majority&appName=Cluster0';
  
  // Collection names - ensure these match the actual collection names in your database
  static const String usersCollection = 'users';
  static const String verificationCodesCollection = 'verification_codes';
  static const String teamsCollection = 'teams';
}