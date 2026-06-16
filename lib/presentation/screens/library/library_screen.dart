import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/anime_card.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeilwatchColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: const Text(
                'Library',
                style: TextStyle(
                  color: VeilwatchColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: VeilwatchColors.accent,
              indicatorWeight: 2,
              labelColor: VeilwatchColors.accent,
              unselectedLabelColor: VeilwatchColors.textMuted,
              labelStyle: const TextStyle(
                fontFamily: 'Urbanist',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Saved'),
                Tab(text: 'History'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SavedTab(),
                  _HistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);

    if (library.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.bookmark,
              color: VeilwatchColors.textMuted.withOpacity(0.4),
              size: 56,
            ),
            const SizedBox(height: 12),
            const Text(
              'No saved anime yet',
              style: TextStyle(color: VeilwatchColors.textMuted),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        mainAxisSpacing: 16,
        crossAxisSpacing: 10,
      ),
      itemCount: library.length,
      itemBuilder: (context, index) => AnimeCard(
        anime: library[index],
        onTap: () => context.push('/anime/${library[index].id}'),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(watchHistoryProvider);

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.clock,
              color: VeilwatchColors.textMuted.withOpacity(0.4),
              size: 56,
            ),
            const SizedBox(height: 12),
            const Text(
              'No watch history',
              style: TextStyle(color: VeilwatchColors.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Clear button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: VeilwatchColors.surfaceElevated,
                      title: const Text(
                        'Clear history?',
                        style: TextStyle(color: VeilwatchColors.textPrimary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(watchHistoryProvider.notifier).clearAll();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: VeilwatchColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    color: VeilwatchColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final h = history[index];
              return GestureDetector(
                onTap: () => context.push(
                  '/watch/${h.episodeId}?animeId=${h.animeId}&ep=${h.episodeNumber}&title=${Uri.encodeComponent(h.animeTitle)}',
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VeilwatchColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.play_circle,
                        color: VeilwatchColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.animeTitle,
                              style: const TextStyle(
                                color: VeilwatchColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Episode ${h.episodeNumber}',
                              style: const TextStyle(
                                color: VeilwatchColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: h.progress,
                              backgroundColor: VeilwatchColors.border,
                              color: VeilwatchColors.accent,
                              minHeight: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
