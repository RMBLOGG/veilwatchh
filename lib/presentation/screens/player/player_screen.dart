import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/anime_model.dart';

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
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
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
    _chewieController?.dispose();
    _videoController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _initPlayer(String url, bool isM3u8) async {
    // Dispose previous controllers
    _chewieController?.dispose();
    await _videoController?.dispose();

    _videoController = isM3u8
        ? VideoPlayerController.networkUrl(
            Uri.parse(url),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
          )
        : VideoPlayerController.networkUrl(Uri.parse(url));

    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      aspectRatio: 16 / 9,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: VeilwatchColors.accent,
        handleColor: VeilwatchColors.accent,
        backgroundColor: Colors.white24,
        bufferedColor: Colors.white38,
      ),
    );

    // Save progress periodically
    _videoController!.addListener(_onVideoProgress);

    if (mounted) setState(() => _initialized = true);
  }

  void _onVideoProgress() {
    if (_videoController == null) return;
    final pos = _videoController!.value.position.inSeconds;
    final dur = _videoController!.value.duration.inSeconds;
    if (dur == 0 || pos % 10 != 0) return; // save every 10s

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
              error: (e, _) => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white54, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Failed to load stream',
                      style: TextStyle(color: Colors.white54),
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
                return Chewie(controller: _chewieController!);
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
