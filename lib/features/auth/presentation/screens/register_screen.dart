import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/core/utils/validators.dart';
import 'package:charge_mate/core/widgets/custom_button.dart';
import 'package:charge_mate/core/widgets/custom_text_field.dart';
import 'package:charge_mate/core/widgets/glassmorphic_card.dart';
import 'package:charge_mate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:charge_mate/features/auth/presentation/widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthErrorCleared());
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(RegisterSubmitted(
          fullName: _name.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
        ));
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
              builder: (context, state) => Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      title: 'Create account',
                      subtitle: 'Join the EV community in Sri Lanka.',
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
                            label: 'Full name',
                            controller: _name,
                            prefixIcon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                Validators.required(v, 'Full name'),
                          ),
                          const SizedBox(height: AppDimensions.spacing16),
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
                            label: 'Mobile number',
                            hint: '07X XXX XXXX',
                            controller: _phone,
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: Validators.phone,
                          ),
                          const SizedBox(height: AppDimensions.spacing16),
                          CustomTextField(
                            label: 'Password',
                            controller: _password,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            validator: Validators.password,
                          ),
                          const SizedBox(height: AppDimensions.spacing16),
                          CustomTextField(
                            label: 'Confirm password',
                            controller: _confirm,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            validator: (v) => v != _password.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                          const SizedBox(height: AppDimensions.spacing24),
                          CustomButton(
                            text: 'Create Account',
                            isLoading: state.isSubmitting,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08),
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
