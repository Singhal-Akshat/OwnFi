import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../models/subscription_model.dart';
import '../../../../ui/settings/widgets/subscription_dialog.dart';

class SubscriptionsView extends ConsumerStatefulWidget {
  const SubscriptionsView({super.key});

  @override
  ConsumerState<SubscriptionsView> createState() => _SubscriptionsViewState();
}

class _SubscriptionsViewState extends ConsumerState<SubscriptionsView> {
  bool _showPaused = false;

  String _getRenewalText(DateTime renewalDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(renewalDate.year, renewalDate.month, renewalDate.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) {
      return 'Renews today';
    } else if (diff == 1) {
      return 'Renews tomorrow';
    } else if (diff < 0) {
      return 'Renewed';
    } else {
      return 'Renews in $diff days';
    }
  }

  double _calculateMonthlyEquivalent(Subscription sub) {
    if (sub.billingCycle == 'weekly') {
      return sub.amount * 52 / 12;
    } else if (sub.billingCycle == 'yearly') {
      return sub.amount / 12;
    } else {
      return sub.amount;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsState = ref.watch(subscriptionsProvider);

    return subscriptionsState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.neonTeal),
      ),
      error: (err, _) => Center(
        child: Text(
          'Error loading subscriptions: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
      data: (subscriptions) {
        final activeSubs = subscriptions.where((s) => s.isActive).toList();
        final pausedSubs = subscriptions.where((s) => !s.isActive).toList();

        // Calculate Monthly Aggregate Sum
        double totalMonthlyEquivalent = 0.0;
        for (final s in activeSubs) {
          totalMonthlyEquivalent += _calculateMonthlyEquivalent(s);
        }

        // Check for upcoming renewals in next 48 hours
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final upcomingAlerts = activeSubs.where((s) {
          if (s.nextRenewalDate == null) return false;
          final diff = s.nextRenewalDate!.difference(today).inDays;
          return diff >= 0 && diff <= 2;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL RECURRING EXPENSE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${totalMonthlyEquivalent.toIndianRupee()}/mo',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                GlassBlur(
                  borderRadius: 14,
                  child: IconButton(
                    icon: const Icon(Icons.add, color: AppColors.neonTeal),
                    onPressed: () {
                      SubscriptionDialog.show(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Upcoming Alerts Card Panel
            if (upcomingAlerts.isNotEmpty) ...[
              const Text(
                'UPCOMING RENEWALS (48H)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              ...upcomingAlerts.map((sub) {
                final diff = sub.nextRenewalDate!.difference(today).inDays;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassBlur(
                    borderRadius: 16,
                    cardColor: Colors.orangeAccent.withOpacity(0.08),
                    borderColor: Colors.orangeAccent.withOpacity(0.25),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.alarm_rounded,
                            color: Colors.orangeAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Renews ${diff == 0 ? "today" : (diff == 1 ? "tomorrow" : "in 2 days")} • ${sub.amount.toIndianRupee()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],

            const Text(
              'ACTIVE SUBSCRIPTIONS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            if (activeSubs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No active subscriptions tracked.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeSubs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final sub = activeSubs[index];
                  return Container(
                    decoration: AppTheme.glassDecoration(
                      borderRadius: 20,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onLongPress: () {
                        SubscriptionDialog.show(context, subscription: sub);
                      },
                      onTap: () {
                        SubscriptionDialog.show(context, subscription: sub);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.neonTeal.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.autorenew_rounded,
                                color: AppColors.neonTeal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sub.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${sub.amount.toIndianRupee()} / ${sub.billingCycle}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (sub.nextRenewalDate != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 3,
                                          height: 3,
                                          decoration: const BoxDecoration(
                                            color: AppColors.textMuted,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getRenewalText(sub.nextRenewalDate!),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.neonTeal,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: sub.isActive,
                              activeColor: AppColors.neonTeal,
                              onChanged: (val) {
                                ref
                                    .read(subscriptionsProvider.notifier)
                                    .toggleSubscriptionActive(sub.id);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () {
                                ref.read(subscriptionsProvider.notifier).removeSubscription(sub.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 25),

            // Paused panel
            if (pausedSubs.isNotEmpty) ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showPaused = !_showPaused;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _showPaused ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PAUSED SUBSCRIPTIONS (${pausedSubs.length})',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (_showPaused)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pausedSubs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final sub = pausedSubs[index];
                    return Container(
                      decoration: AppTheme.glassDecoration(
                        borderRadius: 20,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Opacity(
                        opacity: 0.5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_disabled_rounded,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sub.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${sub.amount.toIndianRupee()} / ${sub.billingCycle}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: sub.isActive,
                                activeColor: AppColors.neonTeal,
                                onChanged: (val) {
                                  ref
                                      .read(subscriptionsProvider.notifier)
                                      .toggleSubscriptionActive(sub.id);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () {
                                  ref.read(subscriptionsProvider.notifier).removeSubscription(sub.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}
