import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/anime_model.dart';

class AnimeCard extends StatelessWidget {
  final Anime anime;
  final VoidCallback onTap;
  final double? width;

  const AnimeCard({
    super.key,
    required this.anime,
    required this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width ?? 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: anime.poster,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _ShimmerBox(),
                      errorWidget: (_, __, ___) => Container(
                        color: VeilwatchColors.surfaceElevated,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: VeilwatchColors.textMuted,
                        ),
                      ),
                    ),
                    // Rating badge
                    if (anime.rating != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: VeilwatchColors.warning,
                                size: 11,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                anime.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Sub/Dub badge
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: anime.isDubbed
                              ? VeilwatchColors.accentDim
                              : Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          anime.isDubbed ? 'DUB' : 'SUB',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              anime.titleEnglish ?? anime.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: VeilwatchColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            if (anime.type != null) ...[
              const SizedBox(height: 2),
              Text(
                anime.type!,
                style: const TextStyle(
                  color: VeilwatchColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: VeilwatchColors.surfaceElevated,
      highlightColor: VeilwatchColors.border,
      child: Container(color: VeilwatchColors.surfaceElevated),
    );
  }
}

// Horizontal anime card (for recent episodes / history)
class AnimeCardHorizontal extends StatelessWidget {
  final Anime anime;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? subtitle;

  const AnimeCardHorizontal({
    super.key,
    required this.anime,
    required this.onTap,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: VeilwatchColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 80,
                child: CachedNetworkImage(
                  imageUrl: anime.poster,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: VeilwatchColors.border,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: VeilwatchColors.border,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: VeilwatchColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.titleEnglish ?? anime.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: VeilwatchColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: VeilwatchColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (anime.genres.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      anime.genres.take(2).join(' · '),
                      style: const TextStyle(
                        color: VeilwatchColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
