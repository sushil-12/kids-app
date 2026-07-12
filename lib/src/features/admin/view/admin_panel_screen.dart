import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/admin_models.dart';
import '../view_model/admin_view_model.dart';

/// Parent-gated operator panel: enter the admin key, watch library stats,
/// trigger web crawls, and follow the status of every action.
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  CrawlContentType _crawlType = CrawlContentType.story;

  @override
  void initState() {
    super.initState();
    // Load stats + sources once the first frame is up, if a key already exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(adminControllerProvider).hasKey) {
        ref.read(adminControllerProvider.notifier).refreshAll();
      }
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AdminState state = ref.watch(adminControllerProvider);
    final AdminController vm = ref.read(adminControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Text(l10n.adminTitle),
        actions: <Widget>[
          if (state.hasKey)
            IconButton(
              tooltip: l10n.adminRefresh,
              icon: const Icon(Icons.refresh),
              onPressed: vm.refreshAll,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          _KeyCard(
            state: state,
            controller: _keyController,
            onSave: (String k) {
              vm.setKey(k);
              _keyController.clear();
              FocusScope.of(context).unfocus();
            },
            onClear: vm.clearKey,
          ),
          if (state.hasKey) ...<Widget>[
            const SizedBox(height: 16),
            _StatsCard(stats: state.stats),
            const SizedBox(height: 16),
            _CrawlCard(
              urlController: _urlController,
              selected: _crawlType,
              busy: state.busy,
              onTypeChanged: (CrawlContentType t) =>
                  setState(() => _crawlType = t),
              onSubmit: () {
                vm.triggerCrawl(_urlController.text, _crawlType);
                _urlController.clear();
                FocusScope.of(context).unfocus();
              },
            ),
            const SizedBox(height: 16),
            _SourcesCard(
              sources: state.sources,
              loading: state.sourcesLoading,
              onRefresh: vm.refreshSources,
            ),
            const SizedBox(height: 16),
            _LogCard(log: state.log),
          ],
        ],
      ),
    );
  }
}

/// Rounded card shell shared by every section.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KeyCard extends StatelessWidget {
  const _KeyCard({
    required this.state,
    required this.controller,
    required this.onSave,
    required this.onClear,
  });

  final AdminState state;
  final TextEditingController controller;
  final ValueChanged<String> onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (state.hasKey) {
      final String key = state.adminKey ?? '';
      final String masked = key.length <= 4
          ? '••••'
          : '${'•' * (key.length - 4)}${key.substring(key.length - 4)}';
      return _Section(
        title: l10n.adminKeyLabel,
        child: Row(
          children: <Widget>[
            const Icon(Icons.verified_user, color: AppColors.teal),
            const SizedBox(width: 8),
            Expanded(child: Text(masked)),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(foregroundColor: AppColors.coral),
              child: Text(l10n.adminClearKey),
            ),
          ],
        ),
      );
    }
    return _Section(
      title: l10n.adminKeyLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.adminNoKey,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              hintText: l10n.adminKeyHint,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: onSave,
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () => onSave(controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final AsyncValue<BackendStats> stats;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _Section(
      title: l10n.adminStatsTitle,
      child: stats.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
        ),
        error: (Object e, _) => Text(
          l10n.adminStatsError,
          style: const TextStyle(color: AppColors.coral),
        ),
        data: (BackendStats s) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _StatChip(label: l10n.adminStatStories, value: s.stories, color: AppColors.coral),
            _StatChip(label: l10n.adminStatPoems, value: s.poems, color: AppColors.purple),
            _StatChip(label: l10n.adminStatAbc, value: s.abcLessons, color: AppColors.teal),
            _StatChip(label: l10n.adminStatAiToday, value: s.openAiCallsToday, color: AppColors.orange),
            _StatChip(label: l10n.adminStatCrawledWeek, value: s.crawledThisWeek, color: AppColors.green),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$value',
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CrawlCard extends StatelessWidget {
  const _CrawlCard({
    required this.urlController,
    required this.selected,
    required this.busy,
    required this.onTypeChanged,
    required this.onSubmit,
  });

  final TextEditingController urlController;
  final CrawlContentType selected;
  final bool busy;
  final ValueChanged<CrawlContentType> onTypeChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _Section(
      title: l10n.adminCrawlTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: urlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: l10n.adminCrawlUrlHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<CrawlContentType>(
                  initialValue: selected,
                  decoration: InputDecoration(
                    labelText: l10n.adminCrawlType,
                    border: const OutlineInputBorder(),
                  ),
                  items: <DropdownMenuItem<CrawlContentType>>[
                    DropdownMenuItem<CrawlContentType>(
                      value: CrawlContentType.story,
                      child: Text(l10n.contentTypeStory),
                    ),
                    DropdownMenuItem<CrawlContentType>(
                      value: CrawlContentType.poem,
                      child: Text(l10n.contentTypePoem),
                    ),
                    DropdownMenuItem<CrawlContentType>(
                      value: CrawlContentType.abc,
                      child: Text(l10n.contentTypeAbc),
                    ),
                  ],
                  onChanged: (CrawlContentType? t) {
                    if (t != null) onTypeChanged(t);
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
                onPressed: busy ? null : onSubmit,
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.adminCrawlButton),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourcesCard extends StatelessWidget {
  const _SourcesCard({
    required this.sources,
    required this.loading,
    required this.onRefresh,
  });

  final List<CrawlSourceInfo> sources;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _Section(
      title: l10n.adminSourcesTitle,
      trailing: IconButton(
        tooltip: l10n.adminRefresh,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh, size: 20),
        onPressed: loading ? null : onRefresh,
      ),
      child: sources.isEmpty
          ? Text(
              l10n.adminSourcesEmpty,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : Column(
              children: sources
                  .map((CrawlSourceInfo s) => _SourceRow(source: s))
                  .toList(),
            ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source});

  final CrawlSourceInfo source;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _StatusChip(status: source.status),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  source.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '${source.contentType.token} · ${source.lastCrawled == null ? l10n.adminNeverCrawled : _shortDate(source.lastCrawled!)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.dark.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(String iso) {
    final DateTime? d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final DateTime l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final (Color color, String label) = switch (status) {
      'success' => (AppColors.teal, l10n.statusSuccess),
      'failed' => (AppColors.coral, l10n.statusFailed),
      _ => (AppColors.yellow, l10n.statusPending),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});

  final List<AdminLogEntry> log;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return _Section(
      title: l10n.adminLogTitle,
      child: log.isEmpty
          ? Text(l10n.adminLogEmpty, style: theme.textTheme.bodyMedium)
          : Column(
              children: log.take(30).map((AdminLogEntry e) {
                final Color color = switch (e.level) {
                  AdminLogLevel.success => AppColors.teal,
                  AdminLogLevel.error => AppColors.coral,
                  AdminLogLevel.info => AppColors.dark,
                };
                String two(int n) => n.toString().padLeft(2, '0');
                final String time =
                    '${two(e.time.hour)}:${two(e.time.minute)}:${two(e.time.second)}';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        time,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.dark.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.message,
                          style: theme.textTheme.bodyMedium?.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
