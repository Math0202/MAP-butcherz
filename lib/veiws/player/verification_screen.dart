import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hocky_na_org/veiws/player/player_home_page.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:hocky_na_org/services/mongodb_service.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String email;
  final String coachName;
  final String teamName;

  const VerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.email,
    required this.coachName,
    required this.teamName,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // Controllers for the code input fields
  final List<TextEditingController> _controllers = List.generate(
    5,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  // Timer for code expiry
  int _secondsRemaining = 300; // 5 minutes in seconds
  bool _isTimerActive = true;
  String _generatedCode = ''; // Store the generated code

  @override
  void initState() {
    super.initState();
    _startTimer();
    _generateAndSendCode();
  }

  // Generate a random 5-digit code and send it via API
  Future<void> _generateAndSendCode() async {
    // Generate random 5 digit code
    final random = Random();
    _generatedCode = List.generate(5, (_) => random.nextInt(10)).join();

    // URL encode the message
    final message = Uri.encodeComponent(
      "Your verification code is: $_generatedCode",
    );

    // Build API URL with generated code - using the correct format for MTC
    final apiUrl =
        'https://connectsms.mtc.com.na/api.asmx/SendSMS'
        '?from_number=0814800039'
        '&username=Ausgezeichnet'
        '&password=User@0046'
        '&destination=${widget.phoneNumber}'
        '&message=$message';

    try {
      // Call the API with a GET request
      print(
        "Sending SMS request to: ${apiUrl.replaceAll(RegExp(r'password=[^&]*'), 'password=XXXXX')}",
      );
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('SMS API response: $responseBody');

        // Check if the SMS was sent successfully
        if (responseBody.contains("<Status>0</Status>") ||
            responseBody.contains("success")) {
          print('SMS sent successfully with code: $_generatedCode');

          // Store verification code in MongoDB
          await MongoDBService.storeVerificationCode(
            contact: widget.phoneNumber,
            code: _generatedCode,
            expiresAt: DateTime.now().add(Duration(seconds: _secondsRemaining)),
          );

          // Remove auto-fill code for production
          // Users must manually enter the code they receive
        } else {
          // Extract error message if possible
          String errorMessage = "Unknown error";
          if (responseBody.contains("<ErrorMessage>")) {
            final startIndex =
                responseBody.indexOf("<ErrorMessage>") +
                "<ErrorMessage>".length;
            final endIndex = responseBody.indexOf("</ErrorMessage>");
            if (startIndex != -1 && endIndex != -1) {
              errorMessage = responseBody.substring(startIndex, endIndex);
            }
          }
          print('Failed to send SMS. Error: $errorMessage');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to send verification code: $errorMessage',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('Failed to send SMS. Status code: ${response.statusCode}');
        print('Response: ${response.body}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to send verification code. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error sending SMS: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending verification code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    return '$minutes minute${minutes != 1 ? 's' : ''} ${seconds} second${seconds != 1 ? 's' : ''}';
  }

  // Check if all code fields are filled
  bool get _isCodeComplete {
    return _controllers.every((controller) => controller.text.isNotEmpty);
  }

  // Get the full verification code
  String get _fullCode {
    return _controllers.map((controller) => controller.text).join();
  }

  // Verify the entered code against the stored code in MongoDB
  Future<bool> _verifyCode() async {
    try {
      final isCodeValid = await MongoDBService.verifyCode(
        contact: widget.phoneNumber,
        code: _fullCode,
      );

      print("Code validation result: $isCodeValid");
      return isCodeValid;
    } catch (e) {
      print("Error during verification: $e");
      return false;
    }
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
        title: const Text('Verify Your Number'),
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

                // Welcome message
                Text(
                  "Welcome, ${widget.coachName}",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),

                const SizedBox(height: 10),

                // Reassurance text
                Text(
                  "Please enter the verification code",
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

                // Code sent info message
                Text(
                  'Code was sent to ${widget.phoneNumber}',
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
                    color:
                        _secondsRemaining < 60
                            ? theme.colorScheme.error
                            : theme.hintColor,
                  ),
                ),

                const SizedBox(height: 40),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        _isCodeComplete
                            ? () async {
                              if (await _verifyCode()) {
                                // Code matches, proceed to next screen
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => Homepage(
                                          email: widget.email,
                                          teamName: widget.teamName,
                                        ),
                                  ),
                                );
                              } else {
                                // Show error for incorrect code
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Invalid verification code',
                                    ),
                                    backgroundColor: theme.colorScheme.error,
                                  ),
                                );
                              }
                            }
                            : null, // Disable if code is incomplete
                    child: const Text('Login'),
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
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
