import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/utils/validators.dart';
import 'package:charge_mate/core/widgets/custom_button.dart';
import 'package:charge_mate/core/widgets/custom_text_field.dart';
import 'package:charge_mate/core/widgets/glassmorphic_card.dart';
import 'package:charge_mate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:charge_mate/features/auth/presentation/widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthErrorCleared());
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(PasswordResetRequested(_email.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: GlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.pagePaddingHorizontal),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state.resetEmailSent) return _success(context);
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(
                        title: 'Reset password',
                        subtitle:
                            "Enter your email and we'll send you a reset link.",
                        showLogo: false,
                      ),
                      const SizedBox(height: AppDimensions.spacing24),
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
                              validator: Validators.email,
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: AppDimensions.spacing24),
                            CustomButton(
                              text: 'Send Reset Link',
                              isLoading: state.isSubmitting,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _success(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppDimensions.spacing64),
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacing24),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              size: 56, color: AppColors.success),
        ).animate().scale(curve: Curves.easeOutBack),
        const SizedBox(height: AppDimensions.spacing24),
        Text('Check your inbox', style: AppTextStyles.headingLarge),
        const SizedBox(height: AppDimensions.spacing8),
        Text(
          'If an account exists for ${_email.text}, a reset link is on its way.',
          textAlign: TextAlign.center,
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacing32),
        CustomButton(text: 'Back to Sign In', onPressed: () => context.pop()),
      ],
    );
  }
}
