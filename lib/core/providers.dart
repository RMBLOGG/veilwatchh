import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/anime_model.dart';
import '../data/services/anime_api_service.dart';
import '../data/services/local_storage_service.dart';

// Services
final apiServiceProvider = Provider<AnimeApiService>((ref) => AnimeApiService());
final storageServiceProvider = Provider<LocalStorageService>((ref) => LocalStorageService());

// Home - Trending
final trendingProvider = FutureProvider.autoDispose<List<Anime>>((ref) async {
  return ref.read(apiServiceProvider).getTrending();
});

// Home - Popular
final popularProvider = FutureProvider.autoDispose<List<Anime>>((ref) async {
  final res = await ref.read(apiServiceProvider).getPopular();
  return res.items;
});

// Home - Recent Episodes
final recentProvider = FutureProvider.autoDispose<List<Anime>>((ref) async {
  return ref.read(apiServiceProvider).getRecentEpisodes();
});

// Anime Detail
final animeDetailProvider = FutureProvider.autoDispose.family<Anime, String>((ref, slug) async {
  return ref.read(apiServiceProvider).getAnimeDetail(slug);
});

// Episodes
final episodesProvider = FutureProvider.autoDispose.family<List<EpisodeItem>, String>((ref, animeSlug) async {
  return ref.read(apiServiceProvider).getEpisodes(animeSlug);
});

// Stream Sources
final streamSourcesProvider = FutureProvider.autoDispose.family<List<StreamSource>, String>((ref, episodeSlug) async {
  return ref.read(apiServiceProvider).getStreamSources(episodeSlug);
});

// Search
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Anime>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final res = await ref.read(apiServiceProvider).searchAnime(query);
  return res.items;
});

// Library
final libraryProvider = StateNotifierProvider<LibraryNotifier, List<Anime>>((ref) {
  return LibraryNotifier(ref.read(storageServiceProvider));
});

class LibraryNotifier extends StateNotifier<List<Anime>> {
  final LocalStorageService _storage;

  LibraryNotifier(this._storage) : super([]) {
    _load();
  }

  void _load() {
    state = _storage.getLibrary();
  }

  Future<void> toggle(Anime anime) async {
    if (_storage.isInLibrary(anime.id)) {
      await _storage.removeFromLibrary(anime.id);
    } else {
      await _storage.addToLibrary(anime);
    }
    _load();
  }

  bool isInLibrary(String id) => state.any((a) => a.id == id);
}

// Watch History
final watchHistoryProvider = StateNotifierProvider<WatchHistoryNotifier, List<WatchHistory>>((ref) {
  return WatchHistoryNotifier(ref.read(storageServiceProvider));
});

class WatchHistoryNotifier extends StateNotifier<List<WatchHistory>> {
  final LocalStorageService _storage;

  WatchHistoryNotifier(this._storage) : super([]) {
    _load();
  }

  void _load() {
    state = _storage.getWatchHistory();
  }

  Future<void> saveProgress(WatchHistory history) async {
    await _storage.saveWatchProgress(history);
    _load();
  }

  Future<void> clearAll() async {
    await _storage.clearHistory();
    _load();
  }
}

// Bottom Nav
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
