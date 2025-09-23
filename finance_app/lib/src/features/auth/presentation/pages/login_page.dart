import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    // Listen to auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // Logo and Title
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'welcome'.tr(),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'sign_in_to_continue'.tr(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'email'.tr(),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'required_field'.tr();
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'invalid_email'.tr();
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'password'.tr(),
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'required_field'.tr();
                        }
                        if (value.length < 6) {
                          return 'password_too_short'.tr();
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _signIn(),
                    ),

                    const SizedBox(height: 24),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _signIn,
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text('sign_in'.tr()),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Forgot Password
                    TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                      },
                      child: Text('forgot_password'.tr()),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Or Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 32),

              // Sign Up Button
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.register);
                },
                child: Text('sign_up'.tr()),
              ),

              const SizedBox(height: 16),

              // Continue as Guest
              TextButton(
                onPressed: () async {
                  final success = await ref.read(authProvider.notifier).signInAsGuest();
                  if (success && mounted) {
                    Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);
                  }
                },
                child: Text('continue_as_guest'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}