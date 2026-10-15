
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_role.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({
    super.key,
    required this.onContinue,
  });

  final ValueChanged<UserRole> onContinue;

  @override
  State<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    User? user;

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      user = credential.user;

      if (user == null) {
        throw Exception('Unable to create your account.');
      }

      await user.updateDisplayName(_nameController.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': user.email,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      widget.onContinue(UserRole.student);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        switch (error.code) {
          case 'email-already-in-use':
            _errorMessage =
                'An account already exists with this email.';
            break;
          case 'invalid-email':
            _errorMessage = 'Please enter a valid email address.';
            break;
          case 'weak-password':
            _errorMessage =
                'Your password must be at least 6 characters.';
            break;
          case 'network-request-failed':
            _errorMessage =
                'Check your internet connection and try again.';
            break;
          default:
            _errorMessage =
                error.message ?? 'Unable to create your account.';
        }
      });
    } catch (_) {
      // if profile creation fails, user can't be signed in
      // without a completed student profile.
      if (user != null) {
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {

        }
      }

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Account setup failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;

            final brandPanel = _BrandPanel(compact: !isWide);
            final formPanel = _CreateAccountPanel(
              formKey: _formKey,
              nameController: _nameController,
              emailController: _emailController,
              passwordController: _passwordController,
              confirmController: _confirmController,
              loading: _loading,
              hidePassword: _hidePassword,
              hideConfirmPassword: _hideConfirmPassword,
              errorMessage: _errorMessage,
              onTogglePassword: () {
                setState(() => _hidePassword = !_hidePassword);
              },
              onToggleConfirmPassword: () {
                setState(() {
                  _hideConfirmPassword = !_hideConfirmPassword;
                });
              },
              onCreateAccount: _createAccount,
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 5, child: brandPanel),
                  Expanded(flex: 6, child: formPanel),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 220, child: brandPanel),
                  formPanel,
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
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
              'Create your student account to reserve university '
              'equipment and keep your projects moving.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateAccountPanel extends StatelessWidget {
  const _CreateAccountPanel({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.loading,
    required this.hidePassword,
    required this.hideConfirmPassword,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onCreateAccount,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool loading;
  final bool hidePassword;
  final bool hideConfirmPassword;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton.icon(
                  onPressed: loading
                      ? null
                      : () => Navigator.maybePop(context),
                    style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to sign in'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Join Equipment Checkout',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a student account to get started.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'CSUN email',
                    hintText: 'student@my.csun.edu',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(email)) {
                      return 'Please enter a valid email address.';
                    }

                    if (!email.toLowerCase().endsWith(
                      '@my.csun.edu',
                    )) {
                      return 'Use your @my.csun.edu email.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: hidePassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: onTogglePassword,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Use at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmController,
                  obscureText: hideConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: hideConfirmPassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        hideConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: onToggleConfirmPassword,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password.';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading ? null : onCreateAccount,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Create account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}