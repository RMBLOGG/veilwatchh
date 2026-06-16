import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/anime_model.dart';
import '../../widgets/common/anime_card.dart';
import '../../widgets/common/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: VeilwatchColors.bg,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: VeilwatchColors.bg,
            title: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Veil',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: VeilwatchColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: 'watch',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: VeilwatchColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Carousel - Trending
                _HeroCarousel(),
                const SizedBox(height: 24),

                // Continue Watching
                _ContinueWatchingSection(),

                // Popular
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(title: 'Popular'),
                ),
                const SizedBox(height: 12),
                _AnimeHorizontalList(provider: popularProvider),
                const SizedBox(height: 24),

                // Recent Episodes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(title: 'Recent Episodes'),
                ),
                const SizedBox(height: 12),
                _AnimeHorizontalList(provider: recentProvider),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCarousel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingProvider);

    return trending.when(
      loading: () => _HeroShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        final featured = list.take(5).toList();
        return CarouselSlider.builder(
          itemCount: featured.length,
          itemBuilder: (context, index, _) => _HeroItem(anime: featured[index]),
          options: CarouselOptions(
            height: 220,
            viewportFraction: 0.88,
            enlargeCenterPage: true,
            enlargeFactor: 0.12,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
          ),
        );
      },
    );
  }
}

class _HeroItem extends StatelessWidget {
  final Anime anime;
  const _HeroItem({required this.anime});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/anime/${anime.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: VeilwatchColors.accent.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: anime.banner ?? anime.poster,
                fit: BoxFit.cover,
              ),
              // Gradient overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
              // Info
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.titleEnglish ?? anime.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (anime.rating != null) ...[
                          const Icon(Icons.star_rounded,
                              color: VeilwatchColors.warning, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            anime.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (anime.genres.isNotEmpty)
                          Text(
                            anime.genres.take(2).join(' · '),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: VeilwatchColors.surfaceElevated,
      highlightColor: VeilwatchColors.border,
      child: Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: VeilwatchColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _AnimeHorizontalList extends ConsumerWidget {
  final ProviderListenable<AsyncValue<List<Anime>>> provider;
  const _AnimeHorizontalList({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);

    return state.when(
      loading: () => SizedBox(
        height: 195,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => Shimmer.fromColors(
            baseColor: VeilwatchColors.surfaceElevated,
            highlightColor: VeilwatchColors.border,
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: VeilwatchColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Failed to load',
          style: const TextStyle(color: VeilwatchColors.textMuted),
        ),
      ),
      data: (list) => SizedBox(
        height: 195,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => AnimeCard(
            anime: list[index],
            onTap: () => context.push('/anime/${list[index].id}'),
            width: 120,
          ),
        ),
      ),
    );
  }
}

class _ContinueWatchingSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(watchHistoryProvider);
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SectionHeader(title: 'Continue Watching'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: history.take(10).length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final h = history[index];
              return GestureDetector(
                onTap: () => context.push(
                  '/watch/${h.episodeId}?animeId=${h.animeId}&ep=${h.episodeNumber}&title=${Uri.encodeComponent(h.animeTitle)}',
                ),
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: VeilwatchColors.surfaceElevated,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: h.animePoster,
                          fit: BoxFit.cover,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          left: 8,
                          right: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ep ${h.episodeNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: h.progress,
                                backgroundColor: Colors.white24,
                                color: VeilwatchColors.accent,
                                minHeight: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
