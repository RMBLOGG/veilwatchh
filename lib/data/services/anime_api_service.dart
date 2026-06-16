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
        'ongoing': _parseCardList(data['ongoing']),
        'recent': _parseCardList(data['recent']),
        'pagination': data['pagination'] != null
            ? ApiPagination.fromJson(data['pagination'])
            : null,
      };
    } catch (e) {
      throw _handleError(e);
    }
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

  // ─── Search ──────────────────────────────────────────────────────────────

  Future<AnimeListResponse> searchAnime(String keyword, {int page = 1}) async {
    try {
      final encodedKeyword = Uri.encodeComponent(keyword);
      final res = await _dio.get(
        '${AppConstants.search}/$encodedKeyword',
        queryParameters: {'page': page},
      );
      return AnimeListResponse(
        items: _parseCardList(res.data['animes']),
        pagination: res.data['pagination'] != null
            ? ApiPagination.fromJson(res.data['pagination'])
            : null,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AnimeListResponse> advancedSearch({
    String? genre,
    String? status,
    String? type,
    String? season,
    int? year,
    String? order,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (genre != null) params['genre'] = genre;
      if (status != null) params['status'] = status;
      if (type != null) params['type'] = type;
      if (season != null) params['season'] = season;
      if (year != null) params['year'] = year;
      if (order != null) params['order'] = order;

      final res = await _dio.get(
        AppConstants.advancedSearch,
        queryParameters: params,
      );
      return AnimeListResponse(
        items: _parseCardList(res.data['animes']),
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
        items: _parseCardList(res.data['animes'] ?? res.data['data']),
        pagination: res.data['pagination'] != null
            ? ApiPagination.fromJson(res.data['pagination'])
            : null,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Detail ──────────────────────────────────────────────────────────────

  Future<AnimeDetail> getAnimeDetail(String slug) async {
    try {
      final res = await _dio.get('${AppConstants.animeDetail}/$slug');
      return AnimeDetail.fromJson(res.data['detail']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Episode / Stream ────────────────────────────────────────────────────

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
      // home endpoint pakai 'ongoing'/'recent', list endpoint pakai 'animes'/'data'
      final rawList = res.data['animes'] ??
          res.data['data'] ??
          res.data['ongoing'] ??
          res.data['recent'] ??
          [];
      return AnimeListResponse(
        items: _parseCardList(rawList),
        pagination: res.data['pagination'] != null
            ? ApiPagination.fromJson(res.data['pagination'])
            : null,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  List<AnimeCard> _parseCardList(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>)
        .map((e) => AnimeCard.fromJson(e as Map<String, dynamic>))
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
