import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/brutalist_components.dart';
import '../../../core/design/design_tokens.dart';
import '../../watch_activity/domain/watch_activity.dart';
import '../../watch_activity/domain/watch_activity_repository.dart';
import '../../watch_activity/domain/watch_streak_calculator.dart';
import '../domain/local_profile.dart';
import '../domain/local_profile_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.profileRepository,
    required this.watchActivityRepository,
    required this.onOpenHistory,
    required this.onOpenBookmarks,
    required this.onOpenSettings,
    this.clock,
    super.key,
  });

  final LocalProfileRepository profileRepository;
  final WatchActivityRepository watchActivityRepository;
  final Future<void> Function() onOpenHistory;
  final Future<void> Function() onOpenBookmarks;
  final VoidCallback onOpenSettings;
  final DateTime Function()? clock;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<_ProfileData> _profileData;

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _profileData = _loadProfileData();
  }

  Future<_ProfileData> _loadProfileData() async {
    final profile = await widget.profileRepository.getProfile();
    final activities = await widget.watchActivityRepository.getActivities();
    final now = _now;
    return _ProfileData(
      profile: profile,
      activities: activities,
      streak: const WatchStreakCalculator().calculate(
        activities,
        nowLocal: now,
      ),
      today: DateTime(now.year, now.month, now.day),
    );
  }

  Future<void> _editProfile(LocalProfile profile) async {
    final editedProfile = await showDialog<LocalProfile>(
      context: context,
      builder: (context) => _EditProfileDialog(profile: profile),
    );
    if (editedProfile == null) return;
    try {
      await widget.profileRepository.saveProfile(editedProfile);
      if (mounted) setState(_reload);
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'local profile persistence',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your profile.')),
      );
    }
  }

  Future<void> _openAndRefresh(Future<void> Function() openPage) async {
    await openPage();
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE')),
      body: FutureBuilder<_ProfileData>(
        future: _profileData,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: BrutalistErrorState(
                message: 'Your profile could not be loaded.',
                onRetry: () => setState(_reload),
              ),
            );
          }
          if (!snapshot.hasData) return const BrutalistLoadingState();
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(DesignTokens.space4),
            children: [
              _buildIdentity(context, data.profile),
              const SizedBox(height: DesignTokens.space3),
              _buildStatistics(context, data.streak),
              const SizedBox(height: DesignTokens.space4),
              _buildActivity(context, data),
              const SizedBox(height: DesignTokens.space4),
              const BrutalistSectionHeader(title: 'ACCOUNT'),
              const SizedBox(height: DesignTokens.space2),
              _ProfileOption(
                icon: Icons.history,
                title: 'Watch history',
                onTap: () => unawaited(_openAndRefresh(widget.onOpenHistory)),
              ),
              _ProfileOption(
                icon: Icons.bookmark_border,
                title: 'Bookmarks',
                onTap: () => unawaited(_openAndRefresh(widget.onOpenBookmarks)),
              ),
              _ProfileOption(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: widget.onOpenSettings,
              ),
              _ProfileOption(
                icon: Icons.edit_outlined,
                title: 'Edit profile',
                onTap: () => _editProfile(data.profile),
              ),
              const SizedBox(height: DesignTokens.space4),
              Divider(color: context.dividerColor),
              _ProfileOption(
                icon: Icons.logout,
                title: 'Sign out',
                subtitle: 'This profile is saved only on this device.',
                onTap: _showLocalOnlyNotice,
                destructive: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIdentity(BuildContext context, LocalProfile profile) {
    final initials = profile.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();
    return BrutalistCard(
      padding: const EdgeInsets.all(DesignTokens.space3),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: context.accentColor,
            foregroundColor: context.inkColor,
            child: Text(
              initials.isEmpty ? 'V' : initials,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '@${profile.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: context.mutedColor),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () => _editProfile(profile),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, WatchStreakSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _StatisticCard(
            label: 'CURRENT STREAK',
            value: '${summary.currentStreak}',
            suffix: 'days',
            icon: Icons.local_fire_department_outlined,
          ),
        ),
        const SizedBox(width: DesignTokens.space2),
        Expanded(
          child: _StatisticCard(
            label: 'BEST STREAK',
            value: '${summary.bestStreak}',
            suffix: 'days',
            icon: Icons.emoji_events_outlined,
          ),
        ),
        const SizedBox(width: DesignTokens.space2),
        Expanded(
          child: _StatisticCard(
            label: 'WATCH TIME',
            value: _formatEligibleTime(summary.totalWatchedSeconds),
            suffix: '',
            icon: Icons.schedule,
          ),
        ),
      ],
    );
  }

  Widget _buildActivity(BuildContext context, _ProfileData data) {
    final activityByDate = {
      for (final activity in data.activities) activity.dateKey: activity,
    };
    final todayUtc = DateTime.utc(
      data.today.year,
      data.today.month,
      data.today.day,
    );
    final firstVisibleDay = todayUtc.subtract(const Duration(days: 364));
    final gridStart = firstVisibleDay.subtract(
      Duration(days: firstVisibleDay.weekday - 1),
    );
    final colors = [
      context.dividerColor,
      const Color(0xFFDCEBC8),
      const Color(0xFF9ACD79),
      const Color(0xFF4F9D56),
      const Color(0xFF237A3B),
      const Color(0xFF14532D),
    ];

    return BrutalistCard(
      padding: const EdgeInsets.all(DesignTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WATCH ACTIVITY',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: DesignTokens.space1),
          Text(
            'Daily watch time · last 12 months',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: context.mutedColor),
          ),
          const SizedBox(height: DesignTokens.space3),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var week = 0; week < 53; week++)
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Column(
                      children: [
                        for (var weekday = 0; weekday < 7; weekday++)
                          _buildActivityCell(
                            context,
                            date: gridStart.add(
                              Duration(days: week * 7 + weekday),
                            ),
                            firstVisibleDay: firstVisibleDay,
                            today: todayUtc,
                            activityByDate: activityByDate,
                            colors: colors,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: DesignTokens.space1),
              for (final color in colors) ...[
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
              const SizedBox(width: DesignTokens.space1),
              Text('More', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          if (data.streak.earnedMilestones.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.space3),
            Wrap(
              spacing: DesignTokens.space1,
              runSpacing: DesignTokens.space1,
              children: [
                for (final milestone in data.streak.earnedMilestones)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.local_fire_department, size: 16),
                    label: Text('$milestone-day milestone'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityCell(
    BuildContext context, {
    required DateTime date,
    required DateTime firstVisibleDay,
    required DateTime today,
    required Map<String, WatchActivity> activityByDate,
    required List<Color> colors,
  }) {
    final inRange = !date.isBefore(firstVisibleDay) && !date.isAfter(today);
    final key = WatchActivity.dateKeyFor(date);
    final activity = inRange ? activityByDate[key] : null;
    final level = WatchActivity.heatmapLevelFor(activity?.watchedSeconds ?? 0);
    final label =
        '${_formatDate(date)} · '
        '${_formatEligibleTime(activity?.watchedSeconds ?? 0)} watched';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Tooltip(
        message: inRange ? label : '',
        child: Semantics(
          button: inRange,
          label: inRange ? label : null,
          child: InkWell(
            onTap: inRange
                ? () => _showActivityDetails(context, date, activity)
                : null,
            borderRadius: BorderRadius.circular(2),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: inRange ? colors[level] : Colors.transparent,
                border: Border.all(
                  color: inRange
                      ? context.dividerColor.withValues(alpha: 0.6)
                      : Colors.transparent,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showActivityDetails(
    BuildContext context,
    DateTime date,
    WatchActivity? activity,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_formatDate(date)),
        content: Text(
          '${_formatEligibleTime(activity?.watchedSeconds ?? 0)} of eligible '
          'watch time${activity?.isQualified == true ? ' · streak day' : ''}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocalOnlyNotice() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Local profile'),
        content: const Text(
          'This app does not use a signed-in account. Your profile and watch '
          'activity are stored on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.profile,
    required this.activities,
    required this.streak,
    required this.today,
  });

  final LocalProfile profile;
  final List<WatchActivity> activities;
  final WatchStreakSummary streak;
  final DateTime today;
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
  });

  final String label;
  final String value;
  final String suffix;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BrutalistCard(
      padding: const EdgeInsets.all(DesignTokens.space2),
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.accentColor),
          const SizedBox(height: DesignTokens.space1),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (suffix.isNotEmpty)
            Text(suffix, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: DesignTokens.space1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: context.mutedColor, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title, style: color == null ? null : TextStyle(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile});

  final LocalProfile profile;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.profile.displayName,
  );
  late final TextEditingController _usernameController = TextEditingController(
    text: widget.profile.username,
  );
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().replaceFirst(
      RegExp(r'^@'),
      '',
    );
    if (name.isEmpty || username.isEmpty) {
      setState(() => _error = 'Enter a name and username.');
      return;
    }
    Navigator.pop(context, LocalProfile(displayName: name, username: username));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('EDIT PROFILE'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
          textCapitalization: TextCapitalization.words,
        ),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(labelText: 'Username'),
          autocorrect: false,
        ),
        if (_error != null) ...[
          const SizedBox(height: DesignTokens.space2),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('CANCEL'),
      ),
      TextButton(onPressed: _save, child: const Text('SAVE')),
    ],
  );
}

String _formatEligibleTime(int seconds) {
  final totalMinutes = seconds ~/ 60;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${totalMinutes}m';
}

String _formatDate(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
