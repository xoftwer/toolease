import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../shared/widgets/app_scaffold.dart';
import '../shared/widgets/action_card.dart';
import '../shared/widgets/app_card.dart';
import '../providers/settings_provider.dart';
import 'student_user_manual_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'ToolEase',
      showBackButton: false,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.1,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final registerEnabledAsync = ref.watch(
                        registerScreenEnabledProvider,
                      );
                      return registerEnabledAsync.when(
                        loading: () => ActionCard(
                          title: 'Register Student',
                          subtitle: 'Add new student',
                          icon: Icons.person_add_rounded,
                          color: AppColors.secondary,
                          isLarge: true,
                          onTap: () {},
                        ),
                        error: (_, __) => ActionCard(
                          title: 'Register Student',
                          subtitle: 'Add new student',
                          icon: Icons.person_add_rounded,
                          color: AppColors.secondary,
                          isLarge: true,
                          onTap: () =>
                              Navigator.pushNamed(context, '/register'),
                        ),
                        data: (isEnabled) => ActionCard(
                          title: 'Register Student',
                          subtitle: isEnabled
                              ? 'Add new student'
                              : 'Feature disabled',
                          icon: Icons.person_add_rounded,
                          color: isEnabled ? AppColors.secondary : Colors.grey,
                          isLarge: true,
                          onTap: isEnabled
                              ? () => Navigator.pushNamed(context, '/register')
                              : () => _showFeatureDisabledDialog(
                                  context,
                                  'Student Registration',
                                ),
                        ),
                      );
                    },
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final borrowEnabledAsync = ref.watch(
                        borrowScreenEnabledProvider,
                      );
                      return borrowEnabledAsync.when(
                        loading: () => ActionCard(
                          title: 'Borrow Items',
                          subtitle: 'Check out equipment',
                          icon: Icons.shopping_bag_rounded,
                          color: AppColors.primary,
                          isLarge: true,
                          onTap: () {},
                        ),
                        error: (_, __) => ActionCard(
                          title: 'Borrow Items',
                          subtitle: 'Check out equipment',
                          icon: Icons.shopping_bag_rounded,
                          color: AppColors.primary,
                          isLarge: true,
                          onTap: () => Navigator.pushNamed(context, '/borrow'),
                        ),
                        data: (isEnabled) => ActionCard(
                          title: 'Borrow Items',
                          subtitle: isEnabled
                              ? 'Check out equipment'
                              : 'Feature disabled',
                          icon: Icons.shopping_bag_rounded,
                          color: isEnabled ? AppColors.primary : Colors.grey,
                          isLarge: true,
                          onTap: isEnabled
                              ? () => Navigator.pushNamed(context, '/borrow')
                              : () => _showFeatureDisabledDialog(
                                  context,
                                  'Borrow Items',
                                ),
                        ),
                      );
                    },
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final returnEnabledAsync = ref.watch(
                        returnScreenEnabledProvider,
                      );
                      return returnEnabledAsync.when(
                        loading: () => ActionCard(
                          title: 'Return Items',
                          subtitle: 'Check in equipment',
                          icon: Icons.assignment_return_rounded,
                          color: AppColors.accent,
                          isLarge: true,
                          onTap: () {},
                        ),
                        error: (_, __) => ActionCard(
                          title: 'Return Items',
                          subtitle: 'Check in equipment',
                          icon: Icons.assignment_return_rounded,
                          color: AppColors.accent,
                          isLarge: true,
                          onTap: () => Navigator.pushNamed(context, '/return'),
                        ),
                        data: (isEnabled) => ActionCard(
                          title: 'Return Items',
                          subtitle: isEnabled
                              ? 'Check in equipment'
                              : 'Feature disabled',
                          icon: Icons.assignment_return_rounded,
                          color: isEnabled ? AppColors.accent : Colors.grey,
                          isLarge: true,
                          onTap: isEnabled
                              ? () => Navigator.pushNamed(context, '/return')
                              : () => _showFeatureDisabledDialog(
                                  context,
                                  'Return Items',
                                ),
                        ),
                      );
                    },
                  ),
                  ActionCard(
                    title: 'Admin Panel',
                    subtitle: 'Manage system',
                    icon: Icons.admin_panel_settings_rounded,
                    color: AppColors.error,
                    isLarge: true,
                    onTap: () => Navigator.pushNamed(context, '/login'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildUserManualButton(context),
            const SizedBox(height: AppSpacing.md),
            _buildRecentActivityCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManualButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const StudentUserManualScreen(),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.info.withValues(alpha: 0.1),
          foregroundColor: AppColors.info,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            side: BorderSide(
              color: AppColors.info.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.help_outline_rounded, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'User Manual',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return AppCard(
      variant: AppCardVariant.outlined,
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: AppColors.textSecondary,
                    size: AppSpacing.iconSizeMd,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Recent Activity', style: AppTypography.h6),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: AppSpacing.iconSizeXl,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text('No recent activity', style: AppTypography.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeatureDisabledDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.orange.shade600),
              const SizedBox(width: 12),
              const Text('Feature Disabled'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              '$featureName is currently disabled by the administrator. '
              'Please contact the admin if you need access to this feature.',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
