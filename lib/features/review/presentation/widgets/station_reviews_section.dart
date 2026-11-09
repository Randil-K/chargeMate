import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/widgets/custom_button.dart';
import 'package:charge_mate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:charge_mate/features/review/domain/entities/station_review.dart';
import 'package:charge_mate/features/review/presentation/bloc/review_cubit.dart';
import 'package:charge_mate/features/station/domain/entities/charging_station.dart';
import 'package:charge_mate/features/station/presentation/bloc/stations_bloc.dart';
import 'package:charge_mate/features/station/presentation/widgets/station_badges.dart';
import 'package:charge_mate/features/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'package:charge_mate/injection.dart';

class StationReviewsSection extends StatelessWidget {
  final ChargingStation station;
  const StationReviewsSection({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReviewCubit>(
      create: (_) => sl<ReviewCubit>()..load(station.id),
      child: _ReviewsContent(station: station),
    );
  }
}

class _ReviewsContent extends StatelessWidget {
  final ChargingStation station;
  const _ReviewsContent({required this.station});

  void _reportQuickStatus(BuildContext context, StationStatus status) {
    context.read<StationsBloc>().add(
          StationStatusUpdated(
            stationId: station.id,
            newStatus: status,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Thanks! Station reported as "${status.label}".',
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openWriteReviewSheet(BuildContext context) async {
    final reviewCubit = context.read<ReviewCubit>();
    final stationsBloc = context.read<StationsBloc>();
    final user = context.read<AuthBloc>().state.user;
    final vehicle = context.read<VehicleBloc>().state.primary;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _WriteReviewSheet(
        station: station,
        userName: user?.fullName ?? 'Kasun Perera',
        userInitials: user?.initials ?? 'KP',
        vehicleName: vehicle?.displayName,
        onSubmit: (review) async {
          final ok = await reviewCubit.submit(review);
          if (ok) {
            stationsBloc.add(
              StationStatusUpdated(
                stationId: station.id,
                newStatus: review.reportedStatus,
                newRating: review.rating.toDouble(),
              ),
            );
          }
          return ok;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Community status check', style: AppTextStyles.headingSmall),
        const SizedBox(height: 6),
        Text(
          'Help fellow Sri Lankan EV drivers by verifying the live status of this station.',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatusReportButton(
              label: 'Working',
              icon: Icons.check_circle_rounded,
              color: AppColors.accent,
              selected: station.status == StationStatus.operational,
              onTap: () =>
                  _reportQuickStatus(context, StationStatus.operational),
            ),
            const SizedBox(width: 8),
            _StatusReportButton(
              label: 'Issues',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              selected: station.status == StationStatus.issuesReported,
              onTap: () =>
                  _reportQuickStatus(context, StationStatus.issuesReported),
            ),
            const SizedBox(width: 8),
            _StatusReportButton(
              label: 'Offline',
              icon: Icons.cancel_rounded,
              color: AppColors.error,
              selected: station.status == StationStatus.offline,
              onTap: () => _reportQuickStatus(context, StationStatus.offline),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Driver reviews (${station.reviewCount})',
                style: AppTextStyles.headingSmall,
              ),
            ),
            TextButton.icon(
              onPressed: () => _openWriteReviewSheet(context),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Write review'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BlocBuilder<ReviewCubit, ReviewState>(
          builder: (context, state) {
            if (state.status == ReviewLoadStatus.loading &&
                state.reviews.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state.reviews.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'No reviews yet. Be the first to share your charging experience!',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              );
            }
            return Column(
              children: [
                for (final r in state.reviews) _ReviewTile(review: r),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatusReportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusReportButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.16)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: selected ? color : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final StationReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                child: Text(
                  review.userInitials,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: AppTextStyles.labelLarge),
                    Row(
                      children: [
                        if (review.vehicleName != null) ...[
                          const Icon(
                            Icons.electric_car_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              review.vehicleName!,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          DateFormat.yMMMd().format(review.createdAt),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 15,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.comment, style: AppTextStyles.bodyMedium),
          if (review.reportedStatus != null) ...[
            const SizedBox(height: 8),
            StatusBadge.station(review.reportedStatus!, compact: true),
          ],
        ],
      ),
    );
  }
}

class _WriteReviewSheet extends StatefulWidget {
  final ChargingStation station;
  final String userName;
  final String userInitials;
  final String? vehicleName;
  final Future<bool> Function(StationReview review) onSubmit;

  const _WriteReviewSheet({
    required this.station,
    required this.userName,
    required this.userInitials,
    required this.vehicleName,
    required this.onSubmit,
  });

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _rating = 5;
  StationStatus _status = StationStatus.operational;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _status = widget.station.status;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a short review comment.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final review = StationReview(
      id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
      stationId: widget.station.id,
      userName: widget.userName,
      userInitials: widget.userInitials,
      vehicleName: widget.vehicleName,
      rating: _rating,
      comment: text,
      reportedStatus: _status,
      createdAt: DateTime.now(),
    );
    final ok = await widget.onSubmit(review);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review posted! Thank you for helping the community.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Review ${widget.station.name}',
                  style: AppTextStyles.headingSmall,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          if (widget.vehicleName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Posting with vehicle: ${widget.vehicleName}',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ),
          Text('Your rating', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 32,
                  color: AppColors.warning,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text('Station status during your visit',
              style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final st in [
                StationStatus.operational,
                StationStatus.issuesReported,
                StationStatus.offline,
              ])
                ChoiceChip(
                  label: Text(st.label),
                  selected: _status == st,
                  onSelected: (_) => setState(() => _status = st),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'How was charging speed, cable condition, and parking access?',
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Submit Review',
            icon: Icons.send_rounded,
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
