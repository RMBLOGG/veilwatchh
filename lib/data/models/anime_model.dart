// Model sesuai response Sanka Vollerei / Animasu API

class AnimeCard {
  final String title;
  final String slug;
  final String poster;
  final String episode; // e.g. "Episode 21" atau "12 Episode"
  final String statusOrDay; // e.g. "🔥🔥🔥" atau "Selesai ✓"
  final String type; // TV, Movie, ONA, Special, dll

  const AnimeCard({
    required this.title,
    required this.slug,
    required this.poster,
    required this.episode,
    required this.statusOrDay,
    required this.type,
  });

  factory AnimeCard.fromJson(Map<String, dynamic> json) {
    return AnimeCard(
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      poster: json['poster'] ?? '',
      episode: json['episode'] ?? '',
      statusOrDay: json['status_or_day'] ?? '',
      type: json['type'] ?? '',
    );
  }

  bool get isOngoing => statusOrDay.contains('🔥');
  bool get isCompleted => statusOrDay.contains('Selesai');
}

class AnimeDetail {
  final String title;
  final String synonym;
  final String poster;
  final String rating;
  final String synopsis;
  final String? trailer;
  final List<GenreItem> genres;
  final String status;
  final String aired;
  final String type;
  final String duration;
  final String? author;
  final String? studio;
  final String? season;
  final List<EpisodeItem> episodes;

  const AnimeDetail({
    required this.title,
    required this.synonym,
    required this.poster,
    required this.rating,
    required this.synopsis,
    this.trailer,
    required this.genres,
    required this.status,
    required this.aired,
    required this.type,
    required this.duration,
    this.author,
    this.studio,
    this.season,
    required this.episodes,
  });

  factory AnimeDetail.fromJson(Map<String, dynamic> json) {
    return AnimeDetail(
      title: json['title'] ?? '',
      synonym: json['synonym'] ?? '',
      poster: json['poster'] ?? '',
      rating: json['rating'] ?? 'N/A',
      synopsis: json['synopsis'] ?? '',
      trailer: json['trailer'],
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => GenreItem.fromJson(g))
              .toList() ??
          [],
      status: json['status'] ?? '',
      aired: json['aired'] ?? '',
      type: json['type'] ?? '',
      duration: json['duration'] ?? '',
      author: json['author'],
      studio: json['studio'],
      season: json['season'],
      episodes: (json['episodes'] as List<dynamic>?)
              ?.map((e) => EpisodeItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class EpisodeItem {
  final String name; // e.g. "Episode 1164"
  final String slug; // e.g. "nonton-one-piece-episode-1164"

  const EpisodeItem({required this.name, required this.slug});

  factory EpisodeItem.fromJson(Map<String, dynamic> json) {
    return EpisodeItem(
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  int get number {
    final match = RegExp(r'\d+').firstMatch(name);
    return match != null ? int.tryParse(match.group(0)!) ?? 0 : 0;
  }
}

class GenreItem {
  final String name;
  final String slug;

  const GenreItem({required this.name, required this.slug});

  factory GenreItem.fromJson(Map<String, dynamic> json) {
    return GenreItem(
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}

class StreamSource {
  final String name; // e.g. "480p [1]", "720p [2]"
  final String url;

  const StreamSource({required this.name, required this.url});

  factory StreamSource.fromJson(Map<String, dynamic> json) {
    return StreamSource(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }

  String get quality {
    final match = RegExp(r'(\d+p)').firstMatch(name);
    return match?.group(1) ?? name;
  }

  int get server {
    final match = RegExp(r'\[(\d+)\]').firstMatch(name);
    return match != null ? int.tryParse(match.group(1)!) ?? 1 : 1;
  }
}

class EpisodeDetail {
  final String title;
  final List<StreamSource> streams;

  const EpisodeDetail({required this.title, required this.streams});

  factory EpisodeDetail.fromJson(Map<String, dynamic> json) {
    return EpisodeDetail(
      title: json['title'] ?? '',
      streams: (json['streams'] as List<dynamic>?)
              ?.map((s) => StreamSource.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class ApiPagination {
  final bool hasNext;
  final bool hasPrev;
  final int currentPage;

  const ApiPagination({
    required this.hasNext,
    required this.hasPrev,
    required this.currentPage,
  });

  factory ApiPagination.fromJson(Map<String, dynamic> json) {
    return ApiPagination(
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
      currentPage: json['currentPage'] ?? 1,
    );
  }
}

// Response wrapper untuk list endpoint
class AnimeListResponse {
  final List<AnimeCard> items;
  final ApiPagination? pagination;

  const AnimeListResponse({required this.items, this.pagination});
}

// Watch history (local storage)
class WatchHistory {
  final String animeSlug;
  final String animeTitle;
  final String animePoster;
  final String episodeSlug;
  final String episodeName;
  final int positionSeconds;
  final int durationSeconds;
  final DateTime watchedAt;

  const WatchHistory({
    required this.animeSlug,
    required this.animeTitle,
    required this.animePoster,
    required this.episodeSlug,
    required this.episodeName,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.watchedAt,
  });

  double get progress =>
      durationSeconds > 0 ? positionSeconds / durationSeconds : 0.0;

  Map<String, dynamic> toJson() => {
        'anime_slug': animeSlug,
        'anime_title': animeTitle,
        'anime_poster': animePoster,
        'episode_slug': episodeSlug,
        'episode_name': episodeName,
        'position_seconds': positionSeconds,
        'duration_seconds': durationSeconds,
        'watched_at': watchedAt.toIso8601String(),
      };

  factory WatchHistory.fromJson(Map<String, dynamic> json) => WatchHistory(
        animeSlug: json['anime_slug'],
        animeTitle: json['anime_title'],
        animePoster: json['anime_poster'],
        episodeSlug: json['episode_slug'],
        episodeName: json['episode_name'],
        positionSeconds: json['position_seconds'],
        durationSeconds: json['duration_seconds'],
        watchedAt: DateTime.parse(json['watched_at']),
      );
}
