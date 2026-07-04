import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/target_model.dart';
import '../bloc/target_bloc.dart';
import '../bloc/target_event.dart';
import '../bloc/target_state.dart';

class TargetsPage extends StatefulWidget {
  const TargetsPage({super.key});

  @override
  State<TargetsPage> createState() => _TargetsPageState();
}

class _TargetsPageState extends State<TargetsPage> {
  @override
  void initState() {
    super.initState();
    // TODO: Get companyId from auth context
    const companyId = 'current_company_id';
    context.read<TargetBloc>().add(const LoadTargetsEvent(companyId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Targets & Achievements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              const companyId = 'current_company_id';
              context.read<TargetBloc>().add(const LoadTargetsEvent(companyId));
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<TargetBloc, TargetState>(
        builder: (context, state) {
          if (state is TargetLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TargetError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(state.error.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      const companyId = 'current_company_id';
                      context
                          .read<TargetBloc>()
                          .add(const LoadTargetsEvent(companyId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is TargetsLoaded) {
            final targets = state.targets;

            if (targets.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.track_changes, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No targets found'),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                const companyId = 'current_company_id';
                context
                    .read<TargetBloc>()
                    .add(const LoadTargetsEvent(companyId));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary Cards
                  _buildSummarySection(targets),
                  const SizedBox(height: 24),

                  // Individual Targets
                  const Text(
                    'Your Targets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...targets.map((target) => _TargetCard(target: target)),
                ],
              ),
            );
          }

          return const Center(child: Text('No data'));
        },
      ),
    );
  }

  Widget _buildSummarySection(List<Target> targets) {
    // Calculate totals
    double totalTargetPrice = 0;
    double totalAchievedPrice = 0;
    int totalTargetQuantity = 0;
    int totalAchievedQuantity = 0;

    for (final target in targets) {
      totalTargetPrice += target.targetPrice ?? 0;
      totalAchievedPrice += target.achievedPrice;
      totalTargetQuantity += target.targetQuantity ?? 0;
      totalAchievedQuantity += target.achievedQuantity;
    }

    final pricePercentage = totalTargetPrice > 0
        ? (totalAchievedPrice / totalTargetPrice * 100).clamp(0.0, 100.0)
        : 0.0;
    final quantityPercentage = totalTargetQuantity > 0
        ? (totalAchievedQuantity / totalTargetQuantity * 100).clamp(0.0, 100.0)
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Revenue Target',
                value: '\$${totalAchievedPrice.toStringAsFixed(0)}',
                subtitle: 'of \$${totalTargetPrice.toStringAsFixed(0)}',
                percentage: pricePercentage,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Units Target',
                value: '$totalAchievedQuantity',
                subtitle: 'of $totalTargetQuantity',
                percentage: quantityPercentage.toDouble(),
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final double percentage;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final Target target;

  const _TargetCard({required this.target});

  @override
  Widget build(BuildContext context) {
    final percentage = _calculatePercentage();
    final isOnTrack = percentage >= 50; // Simple check for demo
    final color = isOnTrack ? AppColors.success : AppColors.warning;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target ${target.month}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        target.targetType,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (target.targetPrice != null && target.targetPrice! > 0)
              _buildProgressRow(
                'Revenue',
                target.achievedPrice,
                target.targetPrice!,
                '\$',
              ),
            if (target.targetQuantity != null && target.targetQuantity! > 0)
              _buildProgressRow(
                'Units',
                target.achievedQuantity.toDouble(),
                target.targetQuantity!.toDouble(),
                '',
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Period: ${target.month}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(
      String label, double achieved, double total, String prefix) {
    final progress = total > 0 ? (achieved / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '$prefix${achieved.toStringAsFixed(0)} / $prefix${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0
                  ? AppColors.success
                  : progress >= 0.5
                      ? AppColors.primary
                      : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  double _calculatePercentage() {
    double percentage = 0;
    int count = 0;

    if (target.targetPrice != null && target.targetPrice! > 0) {
      percentage += target.achievedPrice / target.targetPrice! * 100;
      count++;
    }

    if (target.targetQuantity != null && target.targetQuantity! > 0) {
      percentage += target.achievedQuantity / target.targetQuantity! * 100;
      count++;
    }

    return count > 0 ? (percentage / count).clamp(0, 100) : 0;
  }
}
