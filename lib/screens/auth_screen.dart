import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/brand.dart';
import '../data/auth_service.dart';
import '../widgets/sisonke_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() =>
      _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool login = true;
  bool loading = false;

  final TextEditingController email =
      TextEditingController();

  final TextEditingController password =
      TextEditingController();

  final TextEditingController name =
      TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();

    super.dispose();
  }

  Future<void> submit() async {
    final emailAddress = email.text.trim();
    final userPassword = password.text.trim();
    final firstName = name.text.trim();

    if (emailAddress.isEmpty ||
        userPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your email and password.',
          ),
        ),
      );

      return;
    }

    if (!login && firstName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your first name.',
          ),
        ),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final service = AuthService();

      if (login) {
        await service.signIn(
          email: emailAddress,
          password: userPassword,
        );
      } else {
        await service.signUp(
          email: emailAddress,
          password: userPassword,
          firstName: firstName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Account created successfully.',
              ),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(e.message),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 460,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: SisonkeLogo(
                      size: 74,
                    ),
                  ),

                  const SizedBox(
                    height: 32,
                  ),

                  Text(
                    login
                        ? 'Welcome back'
                        : 'Join Sisonke',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall,
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    login
                        ? 'Continue helping and connecting with your community.'
                        : 'Together, we can share information, solve problems and create opportunity.',
                    style: const TextStyle(
                      color:
                          SisonkeColors.muted,
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  if (!login) ...[
                    TextField(
                      controller: name,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'First name',
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),
                  ],

                  TextField(
                    controller: email,
                    keyboardType:
                        TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Email address',
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Password',
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  FilledButton(
                    onPressed:
                        loading ? null : submit,
                    style:
                        FilledButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(
                        54,
                      ),
                    ),
                    child: Text(
                      loading
                          ? 'PLEASE WAIT...'
                          : login
                              ? 'SIGN IN'
                              : 'CREATE ACCOUNT',
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        login = !login;
                      });
                    },
                    child: Text(
                      login
                          ? 'New to Sisonke? Create an account'
                          : 'Already have an account? Sign in',
                    ),
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
