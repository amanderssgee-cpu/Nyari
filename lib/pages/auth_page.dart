import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthPage extends StatefulWidget {
  final VoidCallback onSignedIn;
  const AuthPage({super.key, required this.onSignedIn});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        final user = userCredential.user;

        if (user != null) {
          await user.updateDisplayName(fullName);

          // ✅ Save user data to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'fullName': fullName,
                'email': email,
                'createdAt': FieldValue.serverTimestamp(),
              });
        }
      }

      widget.onSignedIn();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Sign In' : 'Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),

              if (!_isLogin) ...[
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator:
                      (val) =>
                          val != null && val.isNotEmpty
                              ? null
                              : 'Enter first name',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator:
                      (val) =>
                          val != null && val.isNotEmpty
                              ? null
                              : 'Enter last name',
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (val) =>
                        val != null && val.contains('@')
                            ? null
                            : 'Enter a valid email',
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator:
                    (val) =>
                        val != null && val.length >= 6
                            ? null
                            : 'Password must be 6+ characters',
              ),
              const SizedBox(height: 24),

              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                    ),
                    child: Text(_isLogin ? 'Sign In' : 'Sign Up'),
                  ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin
                      ? 'Don’t have an account? Sign up'
                      : 'Already have an account? Sign in',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
