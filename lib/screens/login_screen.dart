import 'dart:io';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class LoginScreen extends StatefulWidget {
  final Function(String) onLoginSuccess;
  final Function(String, {bool isError}) showSnackBar;
  final String? customLogoPath;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.showSnackBar,
    this.customLogoPath,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      final user = await DatabaseHelper.instance.validateUser(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (user != null) {
        widget.onLoginSuccess(_usernameController.text.trim());
        widget.showSnackBar('أهلاً بك! تم تسجيل الدخول بنجاح');
      } else {
        widget.showSnackBar('خطأ في اسم المستخدم أو كلمة المرور', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _loginFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: widget.customLogoPath != null && File(widget.customLogoPath!).existsSync()
                        ? EdgeInsets.zero
                        : const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.customLogoPath != null && File(widget.customLogoPath!).existsSync()
                          ? Colors.transparent
                          : const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: widget.customLogoPath != null && File(widget.customLogoPath!).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.file(
                              File(widget.customLogoPath!),
                              width: 82,
                              height: 82,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.gavel,
                            color: Color(0xFFFFD700),
                            size: 50,
                          ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'بوابة المحامين الإلكترونية',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'نظام إدارة مكتب المحاماة والاستشارات القانونية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم',
                      prefixIcon: Icon(Icons.person_outline, color: Color(0xFFD4AF37)),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال اسم المستخدم';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFD4AF37)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'يرجى إدخال كلمة المرور';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF121212),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _handleLogin,
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'اسم المستخدم والكلمة الافتراضية: admin',
                    style: TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
