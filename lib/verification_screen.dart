import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hocky_na_org/home_page.dart'; // For navigation after verification
import 'dart:math'; // For random number generation
import 'package:http/http.dart' as http; // For API request

class VerificationScreen extends StatefulWidget {
  final String? contact; // Email or phone where code was sent
  final bool isForgotPassword; // Determines if this is for forgot password flow or signup

  const VerificationScreen({
    super.key, 
    this.contact,
    this.isForgotPassword = false,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // Controllers for the code input fields
  final List<TextEditingController> _controllers = List.generate(
    5, 
    (_) => TextEditingController()
  );
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());
  
  // Timer for code expiry
  int _secondsRemaining = 300; // 5 minutes in seconds
  bool _isTimerActive = true;
  String _generatedCode = ''; // Store the generated code

  @override
  void initState() {
    super.initState();
    // Start a timer to update the countdown
    _startTimer();
    _generateAndSendCode(); // Generate and send verification code
  }

  // Generate a random 5-digit code and send it via API
  Future<void> _generateAndSendCode() async {
    // Generate random 5 digit code
    final random = Random();
    _generatedCode = List.generate(5, (_) => random.nextInt(10)).join();
    
    // Format phone number (extract from contact if available or use demo number)
    final phoneNumber = widget.contact?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0818031157';
    
    // Build API URL with generated code
    final apiUrl = 'https://connectsms.mtc.com.na/api.asmx/SendSMS?from_number=xxxxxxxxxx&username=xxxxxxxxxxxx&password=xxxxxxxxxxxx&destination=xxxxxxxxxx&message=$_generatedCode';
    
    try {
      // Call the API
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        print('SMS sent successfully with code: $_generatedCode');
        
        // For testing purposes, pre-fill the code fields (remove this in production)
        if (mounted) {
          setState(() {
            for (int i = 0; i < 5; i++) {
              if (i < _generatedCode.length) {
                // Uncomment for auto-filling in development
                // _controllers[i].text = _generatedCode[i];
              }
            }
          });
        }
      } else {
        print('Failed to send SMS. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error sending SMS: $e');
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      setState(() {
        if (_secondsRemaining > 0 && _isTimerActive) {
          _secondsRemaining--;
          _startTimer();
        } else {
          _isTimerActive = false;
        }
      });
    });
  }

  @override
  void dispose() {
    // Clean up controllers and focus nodes
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Format remaining time as MM:SS
  String get _formattedTimeRemaining {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '$minutes minute${minutes != 1 ? 's' : ''}';
  }

  // Check if all code fields are filled
  bool get _isCodeComplete {
    return _controllers.every((controller) => controller.text.isNotEmpty);
  }

  // Get the full verification code
  String get _fullCode {
    return _controllers.map((controller) => controller.text).join();
  }

  // Verify the entered code against the generated code
  bool _verifyCode() {
    return _fullCode == _generatedCode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.isForgotPassword ? 'Forgot Password' : 'Verify Your Number'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Reassurance text
                Text(
                  widget.isForgotPassword 
                      ? "Don't worry about your account" 
                      : "Please enter the verification code",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                
                const SizedBox(height: 40),
                
                // Verification code input boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) => _buildCodeInput(index)),
                ),
                
                const SizedBox(height: 30),
                
                // Code sent to info message
                Text(
                  'Code was sent to your ${widget.contact != null ? widget.contact! : "email"}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Code expiry message
                Text(
                  'This code expires in $_formattedTimeRemaining',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _secondsRemaining < 60 ? theme.colorScheme.error : theme.hintColor,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Verify button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isCodeComplete 
                        ? () {
                            if (_verifyCode()) {
                              // Code matches, proceed to next screen
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const Homepage()),
                              );
                            } else {
                              // Show error for incorrect code
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Invalid verification code'),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          } 
                        : null, // Disable if code is incomplete
                    child: const Text('Verify code'),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Resend code button
                TextButton(
                  onPressed: () {
                    _generateAndSendCode();
                    setState(() {
                      _secondsRemaining = 300;
                      _isTimerActive = true;
                      
                      for (var controller in _controllers) {
                        controller.clear();
                      }
                      if (_focusNodes.isNotEmpty) {
                        _focusNodes[0].requestFocus();
                      }
                    });
                    
                    // Show confirmation snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'A new verification code has been sent',
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                        backgroundColor: theme.colorScheme.surface,
                      ),
                    );
                  },
                  child: const Text('Re-send code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeInput(int index) {
    return SizedBox(
      width: 48,
      height: 55,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          filled: true,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.isNotEmpty && index < 4) {
            _focusNodes[index + 1].requestFocus();
          }
          setState(() {}); // Update to check if code is complete
        },
      ),
    );
  }
} 