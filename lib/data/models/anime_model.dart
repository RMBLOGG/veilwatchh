// Models sesuai usage di seluruh project

class Anime {
  final String id; // slug
  final String title;
  final String? titleEnglish;
  final String? titleJapanese;
  final String poster;
  final String? banner;
  final double? rating;
  final List<String> genres;
  final String? type; // TV, Movie, ONA, dll
  final String? status;
  final int? totalEpisodes;
  final int? year;
  final bool isDubbed;
  final String? synopsis;

  const Anime({
    required this.id,
    required this.title,
    this.titleEnglish,
    this.titleJapanese,
    required this.poster,
    this.banner,
    this.rating,
    this.genres = const [],
    this.type,
    this.status,
    this.totalEpisodes,
    this.year,
    this.isDubbed = false,
    this.synopsis,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: json['slug'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      titleEnglish: json['title_english'] ?? json['titleEnglish'],
      titleJapanese: json['title_japanese'] ?? json['titleJapanese'],
      poster: json['poster'] ?? json['image'] ?? '',
      banner: json['banner'],
      rating: (json['rating'] as num?)?.toDouble() ??
          double.tryParse(json['rating']?.toString() ?? ''),
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => g is String ? g : (g['name'] ?? '').toString())
              .where((g) => g.isNotEmpty)
              .toList() ??
          [],
      type: json['type'],
      status: json['status'],
      totalEpisodes: (json['total_episodes'] as num?)?.toInt() ??
          (json['totalEpisodes'] as num?)?.toInt(),
      year: (json['year'] as num?)?.toInt(),
      isDubbed: json['is_dubbed'] ?? json['isDubbed'] ?? false,
      synopsis: json['synopsis'],
    );
  }

  // Untuk AnimeCard list endpoint (slug-based minimal response)
  factory Anime.fromCardJson(Map<String, dynamic> json) {
    return Anime(
      id: json['slug'] ?? '',
      title: json['title'] ?? '',
      poster: json['poster'] ?? '',
      type: json['type'],
      status: json['status_or_day'],
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': id,
        'title': title,
        'title_english': titleEnglish,
        'title_japanese': titleJapanese,
        'poster': poster,
        'banner': banner,
        'rating': rating,
        'genres': genres,
        'type': type,
        'status': status,
        'total_episodes': totalEpisodes,
        'year': year,
        'is_dubbed': isDubbed,
        'synopsis': synopsis,
      };
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
  final String id; // slug
  final String name; // e.g. "Episode 1164"
  final int number;
  final bool isFiller;

  const EpisodeItem({
    required this.id,
    required this.name,
    required this.number,
    this.isFiller = false,
  });

  factory EpisodeItem.fromJson(Map<String, dynamic> json) {
    final name = json['name'] ?? json['slug'] ?? '';
    final match = RegExp(r'\d+').firstMatch(name);
    final number = match != null ? int.tryParse(match.group(0)!) ?? 0 : 0;
    return EpisodeItem(
      id: json['slug'] ?? json['id'] ?? '',
      name: name,
      number: number,
      isFiller: json['is_filler'] ?? false,
    );
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
  final String name;
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

  bool get isM3u8 =>
      url.contains('.m3u8') ||
      url.contains('m3u8') ||
      name.toLowerCase().contains('hls');

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

class AnimeListResponse {
  final List<Anime> items;
  final ApiPagination? pagination;

  const AnimeListResponse({required this.items, this.pagination});
}

// Watch history (local storage)
class WatchHistory {
  final String animeId; // slug
  final String animeTitle;
  final String animePoster;
  final String episodeId; // slug
  final int episodeNumber;
  final int positionSeconds;
  final int durationSeconds;
  final DateTime watchedAt;

  const WatchHistory({
    required this.animeId,
    required this.animeTitle,
    required this.animePoster,
    required this.episodeId,
    required this.episodeNumber,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.watchedAt,
  });

  double get progress =>
      durationSeconds > 0 ? positionSeconds / durationSeconds : 0.0;

  Map<String, dynamic> toJson() => {
        'anime_id': animeId,
        'anime_title': animeTitle,
        'anime_poster': animePoster,
        'episode_id': episodeId,
        'episode_number': episodeNumber,
        'position_seconds': positionSeconds,
        'duration_seconds': durationSeconds,
        'watched_at': watchedAt.toIso8601String(),
      };

  factory WatchHistory.fromJson(Map<String, dynamic> json) => WatchHistory(
        animeId: json['anime_id'] ?? '',
        animeTitle: json['anime_title'] ?? '',
        animePoster: json['anime_poster'] ?? '',
        episodeId: json['episode_id'] ?? '',
        episodeNumber: json['episode_number'] ?? 0,
        positionSeconds: json['position_seconds'] ?? 0,
        durationSeconds: json['duration_seconds'] ?? 0,
        watchedAt: DateTime.tryParse(json['watched_at'] ?? '') ?? DateTime.now(),
      );
}
