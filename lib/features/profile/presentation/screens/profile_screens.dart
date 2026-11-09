import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:charge_mate/app/routes.dart';
import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/constants/app_constants.dart';
import 'package:charge_mate/core/utils/validators.dart';
import 'package:charge_mate/core/widgets/custom_button.dart';
import 'package:charge_mate/core/widgets/custom_text_field.dart';
import 'package:charge_mate/core/widgets/state_views.dart';
import 'package:charge_mate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:charge_mate/features/station/presentation/bloc/stations_bloc.dart';
import 'package:charge_mate/features/station/presentation/widgets/station_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) return const LoadingIndicator();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.secondary,
                  child: Text(user.initials, style: AppTextStyles.displaySmall),
                ),
                const SizedBox(height: 12),
                Text(user.fullName, style: AppTextStyles.headingMedium),
                Text(user.email,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _tile(Icons.person_outline_rounded, 'Edit profile',
              () => context.push(AppRoutes.editProfile)),
          _tile(Icons.favorite_border_rounded, 'Favourite stations',
              () => context.push(AppRoutes.favourites)),
          _tile(Icons.electric_car_outlined, 'My vehicles',
              () => context.go(AppRoutes.vehicles)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About', style: AppTextStyles.labelLarge),
                const SizedBox(height: 6),
                Text(
                  '${AppConstants.appName} v${AppConstants.appVersion}\n'
                  '${AppConstants.appTagline}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Sign out',
            icon: Icons.logout_rounded,
            isOutlined: true,
            onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
      text: context.read<AuthBloc>().state.user?.fullName);
  late final _phone =
      TextEditingController(text: context.read<AuthBloc>().state.user?.phone);
  late final _city = TextEditingController(
      text: context.read<AuthBloc>().state.user?.preferredCity ?? '');

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (a, b) => a.isSubmitting && !b.isSubmitting,
      listener: (context, state) {
        if (state.errorMessage == null) {
          context.pop();
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CustomTextField(
                label: 'Full name',
                controller: _name,
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => Validators.required(v, 'Name'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Mobile number',
                controller: _phone,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Preferred city',
                controller: _city,
                prefixIcon: Icons.location_city_rounded,
              ),
              const SizedBox(height: 32),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) => CustomButton(
                  text: 'Save',
                  isLoading: state.isSubmitting,
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    final u = state.user!;
                    context.read<AuthBloc>().add(ProfileUpdated(u.copyWith(
                          fullName: _name.text.trim(),
                          phone: _phone.text.trim(),
                          preferredCity: _city.text.trim(),
                        )));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favourite stations')),
      body: BlocBuilder<StationsBloc, StationsState>(
        builder: (context, state) {
          final favs = state.favouriteStations;
          if (favs.isEmpty) {
            return const MessageView(
              icon: Icons.favorite_border_rounded,
              title: 'No favourites yet',
              subtitle: 'Tap the heart on a station to save it here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: favs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => StationCard(
              station: favs[i],
              isFavourite: true,
              vehicleConnectors: state.vehicleConnectors,
              onFavourite: () =>
                  context.read<StationsBloc>().add(FavouriteToggled(favs[i].id)),
              onTap: () => context.push(AppRoutes.station(favs[i].id)),
            ),
          );
        },
      ),
    );
  }
}
