import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/anime_model.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Library ---

  List<Anime> getLibrary() {
    final raw = _prefs.getStringList(AppConstants.libraryKey) ?? [];
    return raw.map((e) => Anime.fromJson(jsonDecode(e))).toList();
  }

  Future<void> addToLibrary(Anime anime) async {
    final library = getLibrary();
    if (!library.any((a) => a.id == anime.id)) {
      library.add(anime);
      await _prefs.setStringList(
        AppConstants.libraryKey,
        library.map((e) => jsonEncode(e.toJson())).toList(),
      );
    }
  }

  Future<void> removeFromLibrary(String animeId) async {
    final library = getLibrary();
    library.removeWhere((a) => a.id == animeId);
    await _prefs.setStringList(
      AppConstants.libraryKey,
      library.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  bool isInLibrary(String animeId) {
    return getLibrary().any((a) => a.id == animeId);
  }

  // --- Watch History ---

  List<WatchHistory> getWatchHistory() {
    final raw = _prefs.getStringList(AppConstants.watchHistoryKey) ?? [];
    return raw
        .map((e) => WatchHistory.fromJson(jsonDecode(e)))
        .toList()
      ..sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
  }

  Future<void> saveWatchProgress(WatchHistory history) async {
    final list = getWatchHistory();
    list.removeWhere(
      (h) => h.animeId == history.animeId && h.episodeId == history.episodeId,
    );
    list.insert(0, history);
    // Keep max 100 entries
    if (list.length > 100) list.removeLast();
    await _prefs.setStringList(
      AppConstants.watchHistoryKey,
      list.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  WatchHistory? getEpisodeProgress(String animeId, String episodeId) {
    return getWatchHistory()
        .where((h) => h.animeId == animeId && h.episodeId == episodeId)
        .firstOrNull;
  }

  Future<void> clearHistory() async {
    await _prefs.remove(AppConstants.watchHistoryKey);
  }
}
