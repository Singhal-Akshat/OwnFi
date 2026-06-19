import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_personal_tracker/core/theme.dart';
import 'package:my_personal_tracker/ui/settings/widgets/sync_review_helper.dart';

class SkippedMessagesLogDialog extends ConsumerWidget {
  final List<String> skippedList;

  const SkippedMessagesLogDialog({
    super.key,
    required this.skippedList,
  });

  static Future<void> show(BuildContext context, List<String> skippedList) {
    return showDialog<void>(
      context: context,
      builder: (context) => SkippedMessagesLogDialog(skippedList: skippedList),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassBlur(
        borderRadius: 24,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Regex Skipped Messages',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonTeal,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Scrollable list of SMS alerts that were automatically skipped by the regex parser.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: skippedList.length,
                  itemBuilder: (context, index) {
                    try {
                      final item = jsonDecode(skippedList[index]);
                      final body = item['body'] ?? '';
                      final dateStr = item['date'] ?? '';
                      final sender = item['sender'] ?? 'Unknown';
                      final date = DateTime.tryParse(dateStr) ?? DateTime.now();

                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          showSyncReviewDialog(
                            context,
                            ref,
                            [
                              {
                                'body': body,
                                'date': date,
                                'source': 'sms',
                                'approvedByRegex': true,
                              }
                            ],
                            showOnlyValidSmsEmail: true,
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        sender.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.playlist_add_check_rounded,
                                        size: 14,
                                        color: AppColors.neonTeal,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    DateFormat('dd MMM, hh:mm a').format(date),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                body,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } catch (_) {
                      return const SizedBox.shrink();
                    }
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
