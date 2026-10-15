import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/theme/app_theme.dart';
import '../models/user_role.dart';
import 'student/create_account_screen.dart';
import 'staff/staff_login_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.onContinue});

  final ValueChanged<UserRole> onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;
            final brandPanel = _BrandPanel(compact: !isWide);
            final loginPanel = _LoginPanel(onContinue: onContinue);

            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 5, child: brandPanel),
                  Expanded(flex: 6, child: loginPanel),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 220, child: brandPanel),
                  loginPanel,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.csunRed,
      padding: EdgeInsets.all(compact ? 28 : 56),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: const Text(
              'CSUN',
              style: TextStyle(
                color: AppColors.csunRed,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Equipment Checkout',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 28 : 42,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 14),
            const Text(
              'Reserve university equipment, monitor due dates, and keep projects moving.',
              style: TextStyle(color: Colors.white, fontSize: 17, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoginPanel extends StatefulWidget {
  const _LoginPanel({required this.onContinue});

  final ValueChanged<UserRole> onContinue;

  @override
  State<_LoginPanel> createState() => _LoginPanelState();
}

class _LoginPanelState extends State<_LoginPanel> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _hidePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

      final user = credential.user;

      if (user == null) {
        throw Exception('Unable to sign in. Please try again.');
      }

      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = userDocument.data()?['role'];

      if (!userDocument.exists || role != 'student') {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        setState(() {
          _errorMessage =
              'This account is not registered as a student.';
        });
        return;
      }

      if (!mounted) return;

      widget.onContinue(UserRole.student);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        if (error.code == 'invalid-credential' ||
            error.code == 'wrong-password' ||
            error.code == 'user-not-found') {
          _errorMessage = 'Incorrect email or password.';
        } else if (error.code == 'invalid-email') {
          _errorMessage = 'Please enter a valid email address.';
        } else if (error.code == 'user-disabled') {
          _errorMessage = 'This account has been disabled.';
        } else {
          _errorMessage =
              error.message ?? 'Unable to sign in. Please try again.';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome, Matador',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in with your university account to continue.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'CSUN email',
                    hintText: 'student@my.csun.edu',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isEmpty) {
                      return 'Please enter your email.';
                    }

                    if (!email.toLowerCase().endsWith('@my.csun.edu')) {
                      return 'Use your @my.csun.edu email.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _hidePassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _hidePassword = !_hidePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password.';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _isLoading ? null : _signInStudent,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in as student'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StaffLoginScreen(
                                onContinue: widget.onContinue,
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('Sign in as staff'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateAccountScreen(
                                onContinue: widget.onContinue,
                              ),
                            ),
                          );
                        },
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}