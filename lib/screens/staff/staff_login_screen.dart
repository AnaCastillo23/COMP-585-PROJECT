import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_role.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({
    super.key,
    required this.onContinue,
  });

  final ValueChanged<UserRole> onContinue;

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    widget.onContinue(UserRole.staff);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _signInFirebase();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        switch (error.code) {
          case 'invalid-credential':
          case 'wrong-password':
          case 'user-not-found':
            _errorMessage = 'Incorrect email or password.';
            break;
          case 'invalid-email':
            _errorMessage = 'Please enter a valid email address.';
            break;
          case 'user-disabled':
            _errorMessage = 'This account has been disabled.';
            break;
          case 'network-request-failed':
            _errorMessage =
                'Check your internet connection and try again.';
            break;
          default:
            _errorMessage =
                error.message ?? 'Staff sign-in failed.';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Unable to verify staff access. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Firebase sign-in, then require role == 'staff' in Firestore.
  Future<void> _signInFirebase() async {
    final credential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Unable to sign in. Please try again.');
    }

    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!profile.exists || profile.data()?['role'] != 'staff') {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      setState(() {
        _errorMessage = 'This account is not authorized for staff access.';
      });
      return;
    }

    if (!mounted) return;

    _goToDashboard();
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
            final formPanel = _StaffLoginPanel(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              loading: _loading,
              hidePassword: _hidePassword,
              errorMessage: _errorMessage,
              onTogglePassword: () {
                setState(() => _hidePassword = !_hidePassword);
              },
              onSignIn: _signIn,
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
              'Manage university equipment and help students '
              'keep their projects moving.',
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

class _StaffLoginPanel extends StatelessWidget {
  const _StaffLoginPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.loading,
    required this.hidePassword,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onSignIn,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool loading;
  final bool hidePassword;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;

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
                  'Staff Sign In',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in with your authorized staff account.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(
                    labelText: 'Staff email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isEmpty) {
                      return 'Please enter your email.';
                    }

                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(email)) {
                      return 'Please enter a valid email address.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  autofillHints: const [AutofillHints.password],
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
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password.';
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
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: loading ? null : onSignIn,
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
                        : const Text('Sign in as staff'),
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
