import 'package:flutter/material.dart';

import 'veiws/admin/admin_login_screen.dart';
import 'veiws/coach/coach_login_screen.dart';
import 'veiws/player/login_screen.dart';

class login_options extends StatefulWidget {
  const login_options({super.key});

  @override
  State<login_options> createState() => _login_optionsState();
}

class _login_optionsState extends State<login_options> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Options')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Handle login with email
              },
              child: GestureDetector(
                child: const Text('Player Login'),
                onTap:
                    () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const player_login(),
                        ),
                      ),
                    },
              ),
            ),
            ElevatedButton(
              onPressed:
                  () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    ),
                  },
              child: const Text('Coach Login'),
            ),
            ElevatedButton(
              onPressed:
                  () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const admin_login(),
                      ),
                    ),
                  },
              child: const Text('Admin Login'),
            ),
          ],
        ),
      ),
    );
  }
}
