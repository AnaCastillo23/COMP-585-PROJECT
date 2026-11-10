import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/slide_page_route.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_role.dart';
import 'package:flutter/services.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key, required this.onContinue});

  final ValueChanged<UserRole> onContinue;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _studentIdController = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  String? _errorMessage;

  static const _termsText = '''
1. Acceptance of Terms
By creating an account, you agree to use the CSUN Equipment Checkout system in accordance with university policies.

2. Equipment Responsibility
You are responsible for any equipment checked out under your account. Equipment must be returned by the due date in the same condition it was received.

3. Late and Damaged Items
Late returns may result in a temporary hold on your account. You may be responsible for the repair or replacement cost of lost or damaged equipment.

4. Account Use
Your account is for your use only. Do not share your login or check out equipment on behalf of another student.

5. Privacy
Your name, email, and student ID are used only to manage equipment checkouts and are visible only to you and authorized staff.

6. Changes
These terms may be updated at any time. Continued use of the system means you accept the updated terms.

This is sample text for a class project and is not a legal agreement.
''';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
  Future<void> _rollback(User? user) async {
  try {
    await user?.delete(); // remove the half-created Auth account
  } catch (_) {}
  try {
    await FirebaseAuth.instance.signOut();
  } catch (_) {}
}

Future<bool?> _showTerms() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var agreed = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Terms and Conditions'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: SingleChildScrollView(child: Text(_termsText)),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: agreed,
                    onChanged: (v) =>
                        setDialogState(() => agreed = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('I have read and agree to the terms'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Decline'),
              ),
              FilledButton(
                onPressed: agreed
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    // Ask for terms first. Nothing is created unless they accept.
    final accepted = await _showTerms();
    if (accepted != true || !mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final studentId = _studentIdController.text.trim();
    User? user;

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.text,
          );

      user = credential.user;

      if (user == null) {
        throw Exception('Unable to create your account.');
      }

      // Reserve the student ID and create the profile atomically.
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      batch.set(db.collection('studentIds').doc(studentId), {
        'uid': user.uid,
      });
      batch.set(db.collection('users').doc(user.uid), {
        'name': name,
        'email': email,
        'studentId': studentId,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } on FirebaseException catch (e) {
      await _rollback(user); // delete the half-created Auth account
      if (!mounted) return;

      setState(() {
        _errorMessage = e.code == 'permission-denied'
            ? 'That student ID is already registered.'
            : 'Account setup failed. Please try again.';
      });
      return; // `finally` still turns off the loading spinner
    }

    try {
      await user.updateDisplayName(name);
    } catch (_) {}

    if (!mounted) return;

    widget.onContinue(UserRole.student);
  } on FirebaseAuthException catch (error) {
    await _rollback(user);
    if (!mounted) return;

    setState(() {
      switch (error.code) {
        case 'email-already-in-use':
          _errorMessage = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          _errorMessage = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          _errorMessage = 'Your password must be at least 6 characters.';
          break;
        case 'network-request-failed':
          _errorMessage = 'Check your internet connection and try again.';
          break;
        default:
          _errorMessage = error.message ?? 'Unable to create your account.';
      }
    });
  } catch (_) {
    await _rollback(user);
    if (!mounted) return;
    setState(() => _errorMessage = 'Account setup failed. Please try again.');
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
              studentIdController: _studentIdController,
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
            final animatedFormPanel = SlideFormPanel(child: formPanel);
            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 5, child: brandPanel),
                  Expanded(flex: 6, child: animatedFormPanel),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 220, child: brandPanel),
                  animatedFormPanel,
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
              'Create your student account to reserve university '
              'equipment and keep your projects moving.',
              style: TextStyle(color: Colors.white, fontSize: 17, height: 1.5),
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
    required this.studentIdController,
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
  final TextEditingController studentIdController;
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
                  onPressed: loading ? null : () => Navigator.maybePop(context),
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
                  style: TextStyle(color: AppColors.muted, fontSize: 15),
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

                    if (!email.toLowerCase().endsWith('@my.csun.edu')) {
                      return 'Use your @my.csun.edu email.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: studentIdController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'CSUN student ID',
                    hintText: '9-digit ID',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    final id = value?.trim() ?? '';
                    if (id.isEmpty) return 'Please enter your student ID.';
                    if (!RegExp(r'^\d{9}$').hasMatch(id)) {
                      return 'Student ID must be 9 digits.';
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
                      tooltip: hidePassword ? 'Show password' : 'Hide password',
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
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading ? null : onCreateAccount,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
