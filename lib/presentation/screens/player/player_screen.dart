import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/anime_model.dart';
import '../../../data/services/local_storage_service.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String episodeId;
  final String animeId;
  final int episodeNumber;
  final String animeTitle;

  const PlayerScreen({
    super.key,
    required this.episodeId,
    required this.animeId,
    required this.episodeNumber,
    required this.animeTitle,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  BetterPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _initPlayer(String url, bool isM3u8) {
    final dataSource = isM3u8
        ? BetterPlayerDataSource(
            BetterPlayerDataSourceType.network,
            url,
            videoFormat: BetterPlayerVideoFormat.hls,
          )
        : BetterPlayerDataSource(
            BetterPlayerDataSourceType.network,
            url,
          );

    _controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        aspectRatio: 16 / 9,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          controlBarColor: Colors.black54,
          iconsColor: Colors.white,
          progressBarPlayedColor: VeilwatchColors.accent,
          progressBarHandleColor: VeilwatchColors.accent,
          progressBarBackgroundColor: Colors.white24,
          loadingColor: VeilwatchColors.accent,
          enableSkips: true,
          forwardSkipTimeInMilliseconds: 10000,
          backwardSkipTimeInMilliseconds: 10000,
        ),
        eventListener: (event) {
          if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
            _saveProgress();
          }
        },
      ),
      betterPlayerDataSource: dataSource,
    );

    setState(() => _initialized = true);
  }

  void _saveProgress() {
    if (_controller == null) return;
    final pos = _controller!.videoPlayerController?.value.position.inSeconds ?? 0;
    final dur = _controller!.videoPlayerController?.value.duration?.inSeconds ?? 0;
    if (dur == 0) return;

    ref.read(watchHistoryProvider.notifier).saveProgress(
          WatchHistory(
            animeId: widget.animeId,
            animeTitle: widget.animeTitle,
            animePoster: '',
            episodeId: widget.episodeId,
            episodeNumber: widget.episodeNumber,
            positionSeconds: pos,
            durationSeconds: dur,
            watchedAt: DateTime.now(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(streamSourcesProvider(widget.episodeId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Player Area
          AspectRatio(
            aspectRatio: 16 / 9,
            child: sourcesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: VeilwatchColors.accent),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white54, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load stream',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              data: (sources) {
                if (sources.isEmpty) {
                  return const Center(
                    child: Text(
                      'No stream available',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                if (!_initialized) {
                  final best = sources.firstWhere(
                    (s) => s.quality == '1080p',
                    orElse: () => sources.first,
                  );
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _initPlayer(best.url, best.isM3u8),
                  );
                  return const Center(
                    child: CircularProgressIndicator(
                        color: VeilwatchColors.accent),
                  );
                }
                return BetterPlayer(controller: _controller!);
              },
            ),
          ),

          // Info & Controls
          Expanded(
            child: Container(
              color: VeilwatchColors.bg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back + title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: VeilwatchColors.textPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.animeTitle,
                                style: const TextStyle(
                                  color: VeilwatchColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Episode ${widget.episodeNumber}',
                                style: const TextStyle(
                                  color: VeilwatchColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quality selector
                  sourcesAsync.whenData((sources) {
                    if (sources.length <= 1) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quality',
                            style: TextStyle(
                              color: VeilwatchColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: sources.map((s) {
                              return GestureDetector(
                                onTap: () => _initPlayer(s.url, s.isM3u8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: VeilwatchColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: VeilwatchColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    s.quality,
                                    style: const TextStyle(
                                      color: VeilwatchColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).value ??
                      const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
