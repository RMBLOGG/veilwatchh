import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/anime_model.dart';

class AnimeDetailScreen extends ConsumerWidget {
  final String animeId;
  const AnimeDetailScreen({super.key, required this.animeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animeAsync = ref.watch(animeDetailProvider(animeId));
    final episodesAsync = ref.watch(episodesProvider(animeId));
    final inLibrary = ref.watch(libraryProvider.select(
      (lib) => lib.any((a) => a.id == animeId),
    ));

    return Scaffold(
      backgroundColor: VeilwatchColors.bg,
      body: animeAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: VeilwatchColors.accent),
        ),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: VeilwatchColors.textSecondary)),
        ),
        data: (anime) => CustomScrollView(
          slivers: [
            // Banner App Bar
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: VeilwatchColors.bg,
              leading: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: () => ref.read(libraryProvider.notifier).toggle(anime),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      inLibrary ? Iconsax.bookmark_25 : Iconsax.bookmark,
                      color: inLibrary ? VeilwatchColors.accent : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: anime.banner ?? anime.poster,
                      fit: BoxFit.cover,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            VeilwatchColors.bg,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      anime.titleEnglish ?? anime.title,
                      style: const TextStyle(
                        color: VeilwatchColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (anime.titleJapanese != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        anime.titleJapanese!,
                        style: const TextStyle(
                          color: VeilwatchColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Meta row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (anime.rating != null)
                          _MetaBadge(
                            icon: Icons.star_rounded,
                            label: anime.rating!.toStringAsFixed(1),
                            color: VeilwatchColors.warning,
                          ),
                        if (anime.type != null)
                          _MetaBadge(label: anime.type!),
                        if (anime.status != null)
                          _MetaBadge(label: anime.status!),
                        if (anime.totalEpisodes != null)
                          _MetaBadge(label: '${anime.totalEpisodes} eps'),
                        if (anime.year != null)
                          _MetaBadge(label: anime.year.toString()),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Genres
                    if (anime.genres.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: anime.genres
                            .map((g) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: VeilwatchColors.border),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    g,
                                    style: const TextStyle(
                                      color: VeilwatchColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),

                    const SizedBox(height: 16),

                    // Synopsis
                    if (anime.synopsis != null) ...[
                      const Text(
                        'Synopsis',
                        style: TextStyle(
                          color: VeilwatchColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ExpandableSynopsis(text: anime.synopsis!),
                      const SizedBox(height: 20),
                    ],

                    // Episodes
                    const Text(
                      'Episodes',
                      style: TextStyle(
                        color: VeilwatchColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Episodes List
            episodesAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                        color: VeilwatchColors.accent),
                  ),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Failed to load episodes',
                    style: TextStyle(color: VeilwatchColors.textMuted),
                  ),
                ),
              ),
              data: (episodes) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.6,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ep = episodes[index];
                      return GestureDetector(
                        onTap: () => context.push(
                          '/watch/${ep.id}?animeId=$animeId&ep=${ep.number}&title=${Uri.encodeComponent(anime.titleEnglish ?? anime.title)}',
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: VeilwatchColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: ep.isFiller
                                ? Border.all(
                                    color: VeilwatchColors.warning
                                        .withOpacity(0.4))
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            ep.number.toString(),
                            style: const TextStyle(
                              color: VeilwatchColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: episodes.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const _MetaBadge({required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: VeilwatchColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color ?? VeilwatchColors.textSecondary, size: 13),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color ?? VeilwatchColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableSynopsis extends StatefulWidget {
  final String text;
  const _ExpandableSynopsis({required this.text});

  @override
  State<_ExpandableSynopsis> createState() => _ExpandableSynopsisState();
}

class _ExpandableSynopsisState extends State<_ExpandableSynopsis> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: const TextStyle(
            color: VeilwatchColors.textSecondary,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show less' : 'Read more',
            style: const TextStyle(
              color: VeilwatchColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
