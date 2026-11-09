import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:charge_mate/app/routes.dart';
import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/utils/validators.dart';
import 'package:charge_mate/core/widgets/custom_button.dart';
import 'package:charge_mate/core/widgets/custom_text_field.dart';
import 'package:charge_mate/core/widgets/glassmorphic_card.dart';
import 'package:charge_mate/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:charge_mate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:charge_mate/features/auth/presentation/widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthErrorCleared());
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(LoginSubmitted(_email.text, _password.text));
  }

  void _fillDemo() {
    _email.text = MockAuthRemoteDataSource.demoEmail;
    _password.text = MockAuthRemoteDataSource.demoPassword;
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.pagePaddingHorizontal),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) => Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppDimensions.spacing32),
                    const AuthHeader(
                      title: 'Welcome back',
                      subtitle: 'Sign in to find chargers near you.',
                    ),
                    const SizedBox(height: AppDimensions.spacing32),
                    GlassmorphicCard(
                      padding: const EdgeInsets.all(AppDimensions.spacing20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.errorMessage != null) ...[
                            ErrorBanner(state.errorMessage!),
                            const SizedBox(height: AppDimensions.spacing16),
                          ],
                          CustomTextField(
                            label: 'Email',
                            controller: _email,
                            prefixIcon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: Validators.email,
                          ),
                          const SizedBox(height: AppDimensions.spacing16),
                          CustomTextField(
                            label: 'Password',
                            controller: _password,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            validator: (v) =>
                                Validators.required(v, 'Password'),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  context.push(AppRoutes.forgotPassword),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          CustomButton(
                            text: 'Sign In',
                            isLoading: state.isSubmitting,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08),
                    const SizedBox(height: AppDimensions.spacing16),
                    CustomButton(
                      text: 'Try the demo account',
                      icon: Icons.play_circle_outline_rounded,
                      isOutlined: true,
                      onPressed: state.isSubmitting ? null : _fillDemo,
                    ).animate().fadeIn(delay: 350.ms),
                    const SizedBox(height: AppDimensions.spacing24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('New to ChargeMate?',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.register),
                          child: const Text('Create account'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
