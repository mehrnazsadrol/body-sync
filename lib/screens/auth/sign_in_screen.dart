import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/bs_button.dart';
import '../../widgets/bs_common.dart';
import '../../widgets/bs_field.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _create = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      if (_create) {
        await auth.createUserWithEmailAndPassword(
            email: email, password: password);
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendly(FirebaseAuthException e) => switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Email or password is incorrect.',
        'email-already-in-use' =>
          'An account with this email already exists. Sign in instead.',
        'weak-password' => 'Password must be at least 6 characters.',
        'invalid-email' => 'Enter a valid email address.',
        'network-request-failed' =>
          'No connection. Check your internet and try again.',
        'too-many-requests' =>
          'Too many attempts. Wait a moment and try again.',
        _ => 'Sign-in failed (${e.code}).',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.bs;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(
                  horizontal: BSSpace.screen, vertical: BSSpace.s7),
              children: [
                Text(
                  'BodySync',
                  style: TextStyle(
                    fontFamily: BSType.font,
                    fontSize: BSType.display,
                    fontWeight: BSType.wBold,
                    height: BSType.lhTight,
                    letterSpacing: BSType.trTitle * BSType.display,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: BSSpace.s2),
                Text(
                  _create
                      ? 'Create an account to keep your log backed up and in sync across your devices.'
                      : 'Sign in to sync your log across devices.',
                  style: TextStyle(
                    fontFamily: BSType.font,
                    fontSize: BSType.body,
                    fontWeight: BSType.wRegular,
                    height: BSType.lhBody,
                    color: c.ink2,
                  ),
                ),
                const SizedBox(height: BSSpace.s6),
                BSField(
                  label: 'Email',
                  controller: _email,
                  placeholder: 'you@example.com',
                  numeric: false,
                ),
                const SizedBox(height: BSSpace.s3),
                BSField(
                  label: 'Password',
                  controller: _password,
                  placeholder: _create ? 'At least 6 characters' : null,
                  numeric: false,
                  obscure: true,
                ),
                if (_error != null)
                  BSBanner(
                    tone: BSBannerTone.err,
                    body: _error!,
                    margin: const EdgeInsets.only(top: BSSpace.s4),
                  ),
                const SizedBox(height: BSSpace.s5),
                BSButton(
                  _busy
                      ? 'One moment…'
                      : _create
                          ? 'Create account'
                          : 'Sign in',
                  size: BSButtonSize.lg,
                  block: true,
                  onTap: _busy ? null : _submit,
                ),
                const SizedBox(height: BSSpace.s2),
                BSButton(
                  _create
                      ? 'Have an account? Sign in'
                      : 'New here? Create an account',
                  variant: BSButtonVariant.quiet,
                  block: true,
                  onTap: _busy
                      ? null
                      : () => setState(() {
                            _create = !_create;
                            _error = null;
                          }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
