class UserState {
  static String? _currentUserEmail;
  
  // Get the current user's email
  static String? get currentUserEmail => _currentUserEmail;
  
  // Set the current user's email
  static void setCurrentUserEmail(String email) {
    _currentUserEmail = email;
    print("Current user email set to: $email");
  }
  
  // Clear the current user's email (for logout)
  static void clearCurrentUserEmail() {
    _currentUserEmail = null;
    print("Current user email cleared");
  }
  
  // Check if a user is logged in
  static bool get isLoggedIn => _currentUserEmail != null;
}