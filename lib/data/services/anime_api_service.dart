import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/anime_model.dart';

class AnimeApiService {
  static final AnimeApiService _instance = AnimeApiService._internal();
  factory AnimeApiService() => _instance;

  late final Dio _dio;

  AnimeApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConstants.baseUrl}${AppConstants.apiPrefix}',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      error: true,
    ));
  }

  // ─── Home ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getHome({int page = 1}) async {
    try {
      final res = await _dio.get(
        AppConstants.home,
        queryParameters: {'page': page},
      );
      final data = res.data;
      return {
        'ongoing': _parseAnimeList(data['ongoing']),
        'recent': _parseAnimeList(data['recent']),
        'pagination': data['pagination'] != null
            ? ApiPagination.fromJson(data['pagination'])
            : null,
      };
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Trending (ongoing dari home) ────────────────────────────────────────

  Future<List<Anime>> getTrending() async {
    final home = await getHome();
    return (home['ongoing'] as List<Anime>? ?? []).take(10).toList();
  }

  // ─── Listing ─────────────────────────────────────────────────────────────

  Future<AnimeListResponse> getPopular({int page = 1}) async =>
      _fetchList(AppConstants.popular, page: page);

  Future<AnimeListResponse> getOngoing({int page = 1}) async =>
      _fetchList(AppConstants.ongoing, page: page);

  Future<AnimeListResponse> getCompleted({int page = 1}) async =>
      _fetchList(AppConstants.completed, page: page);

  Future<AnimeListResponse> getLatest({int page = 1}) async =>
      _fetchList(AppConstants.latest, page: page);

  Future<AnimeListResponse> getMovies({int page = 1}) async =>
      _fetchList(AppConstants.movies, page: page);

  Future<AnimeListResponse> getAnimeList({int page = 1}) async =>
      _fetchList(AppConstants.animeList, page: page);

  // ─── Recent Episodes ─────────────────────────────────────────────────────

  Future<List<Anime>> getRecentEpisodes() async {
    final home = await getHome();
    return (home['recent'] as List<Anime>? ?? []).take(10).toList();
  }

  // ─── Search ──────────────────────────────────────────────────────────────

  Future<AnimeListResponse> searchAnime(String keyword, {int page = 1}) async {
    try {
      final encodedKeyword = Uri.encodeComponent(keyword);
      final res = await _dio.get(
        '${AppConstants.search}/$encodedKeyword',
        queryParameters: {'page': page},
      );
      return AnimeListResponse(
        items: _parseAnimeList(res.data['animes']),
        pagination: res.data['pagination'] != null
            ? ApiPagination.fromJson(res.data['pagination'])
            : null,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Genre ───────────────────────────────────────────────────────────────

  Future<List<GenreItem>> getGenres() async {
    try {
      final res = await _dio.get(AppConstants.genres);
      final List data = res.data['genres'] ?? res.data['data'] ?? [];
      return data.map((g) => GenreItem.fromJson(g)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AnimeListResponse> getByGenre(String slug, {int page = 1}) async {
    try {
      final res = await _dio.get(
        '${AppConstants.genreDetail}/$slug',
        queryParameters: {'page': page},
      );
      return AnimeListResponse(
        items: _parseAnimeList(res.data['animes'] ?? res.data['data']),
        pagination: res.data['pagination'] != null
            ? ApiPagination.fromJson(res.data['pagination'])
            : null,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Detail ──────────────────────────────────────────────────────────────

  Future<Anime> getAnimeDetail(String slug) async {
    try {
      final res = await _dio.get('${AppConstants.animeDetail}/$slug');
      final detail = res.data['detail'] as Map<String, dynamic>;
      // Convert AnimeDetail fields ke Anime
      final genres = (detail['genres'] as List<dynamic>?)
              ?.map((g) => (g['name'] ?? '').toString())
              .toList() ??
          [];
      return Anime(
        id: slug,
        title: detail['title'] ?? '',
        titleEnglish: detail['title_english'],
        titleJapanese: detail['title_japanese'] ?? detail['synonym'],
        poster: detail['poster'] ?? '',
        rating: double.tryParse(detail['rating']?.toString() ?? ''),
        genres: genres,
        type: detail['type'],
        status: detail['status'],
        synopsis: detail['synopsis'],
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Episodes ────────────────────────────────────────────────────────────

  Future<List<EpisodeItem>> getEpisodes(String animeSlug) async {
    try {
      final res = await _dio.get('${AppConstants.animeDetail}/$animeSlug');
      final detail = res.data['detail'] as Map<String, dynamic>;
      return (detail['episodes'] as List<dynamic>?)
              ?.map((e) => EpisodeItem.fromJson(e))
              .toList() ??
          [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Stream Sources ──────────────────────────────────────────────────────

  Future<List<StreamSource>> getStreamSources(String episodeSlug) async {
    try {
      final res = await _dio.get('${AppConstants.episode}/$episodeSlug');
      return (res.data['streams'] as List<dynamic>?)
              ?.map((s) => StreamSource.fromJson(s))
              .toList() ??
          [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<EpisodeDetail> getEpisodeDetail(String slug) async {
    try {
      final res = await _dio.get('${AppConstants.episode}/$slug');
      return EpisodeDetail.fromJson(res.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<AnimeListResponse> _fetchList(String path, {int page = 1}) async {
    try {
      final res = await _dio.get(
        path,
        queryParameters: {'page': page},
      );
      final rawList = res.data['animes'] ??
          res.data['data'] ??
          res.data['ongoing'] ??
          res.data['recent'] ??
          [];
      return AnimeListResponse(
        items: _parseAnimeList(rawList),
        pagination: res.data['pagination'] != null
            ? ApiPagination.fromJson(res.data['pagination'])
            : null,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  List<Anime> _parseAnimeList(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>)
        .map((e) => Anime.fromCardJson(e as Map<String, dynamic>))
        .toList();
  }

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception('Connection timeout. Cek koneksi internet.');
        case DioExceptionType.connectionError:
          return Exception('Tidak ada koneksi internet.');
        default:
          final msg =
              e.response?.data?['message'] ?? e.message ?? 'Unknown error';
          return Exception(msg);
      }
    }
    return Exception(e.toString());
  }
}
