import 'package:d2l_plus/constants/colors.dart';
import 'package:d2l_plus/screens/login_screen.dart';
import 'package:d2l_plus/tools/backender.dart';
import 'package:d2l_plus/tools/storage.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _netIdController = TextEditingController();

  final _backender = Backender();
  final _storage = SecureStorage();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Регулярные выражения для валидации
  final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  final _uppercaseRegex = RegExp(r'[A-Z]');
  final _lowercaseRegex = RegExp(r'[a-z]');
  final _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _netIdController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!_uppercaseRegex.hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!_lowercaseRegex.hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!_specialCharRegex.hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Отправляем запрос на регистрацию
        final success = await _backender.register(
          email: _emailController.text,
          password: _passwordController.text,
          netId: _netIdController.text,
        );

        if (success && mounted) {
          // Сразу авторизуем пользователя
          await _storage.logIn(
            _netIdController.text,
            password: _passwordController.text,
          );

          // Показываем сообщение об успехе и переходим на экран входа
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please log in.'),
              backgroundColor: UAColors.azurite,
            ),
          );

          Navigator.pushReplacementNamed(context, '/');
        }
      } catch (e) {
        // Показываем ошибку, если такая есть
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // Сбрасываем состояние загрузки
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UAColors.coolGray,
      appBar: AppBar(
        title: const Text('Create an Account'),
        backgroundColor: UAColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Декоративный элемент вверху
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 30,
                color: UAColors.blue,
              ),
            ),

            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Заголовок секции
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: UAColors.red,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.person_add,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Join University of Arizona',
                            style: TextStyle(
                              color: UAColors.blue,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your account to get started',
                            style: TextStyle(
                              color: UAColors.azurite,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Форма регистрации
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email поле
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your .edu email',
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: UAColors.azurite,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!_emailRegex.hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                // Проверка, что это .edu адрес
                                if (!value.endsWith('.edu')) {
                                  return 'Please use your .edu email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // NetID поле
                            // TextFormField(
                            //   controller: _netIdController,
                            //   decoration: const InputDecoration(
                            //     labelText: 'NetID',
                            //     hintText: 'Enter your NetID',
                            //     prefixIcon: Icon(
                            //       Icons.badge,
                            //       color: UAColors.azurite,
                            //     ),
                            //   ),
                            //   validator: (value) {
                            //     if (value == null || value.isEmpty) {
                            //       return 'Please enter your NetID';
                            //     }
                            //     return null;
                            //   },
                            // ),
                            // const SizedBox(height: 16),

                            // Пароль
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Create a strong password',
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: UAColors.azurite,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: UAColors.azurite,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 16),

                            // Подтверждение пароля
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: 'Re-enter your password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: UAColors.azurite,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: UAColors.azurite,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Пояснение по паролю
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: UAColors.coolGray.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Password requirements:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: UAColors.blue,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.check,
                                          size: 16, color: UAColors.azurite),
                                      SizedBox(width: 8),
                                      Text('At least 8 characters'),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.check,
                                          size: 16, color: UAColors.azurite),
                                      SizedBox(width: 8),
                                      Text(
                                          'At least one uppercase letter (A-Z)'),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.check,
                                          size: 16, color: UAColors.azurite),
                                      SizedBox(width: 8),
                                      Text(
                                          'At least one lowercase letter (a-z)'),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.check,
                                          size: 16, color: UAColors.azurite),
                                      SizedBox(width: 8),
                                      Text('At least one special character'),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Кнопка регистрации
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: UAColors.red,
                                  disabledBackgroundColor:
                                      UAColors.red.withOpacity(0.5),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Text('Register'),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Ссылка на вход
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account?',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                        context, '/');
                                  },
                                  child: const Text(
                                    'Log in',
                                    style: TextStyle(
                                      color: UAColors.azurite,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Нижний текст
                    const Center(
                      child: Text(
                        '© 2025 University of Arizona',
                        style: TextStyle(
                          color: UAColors.azurite,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
