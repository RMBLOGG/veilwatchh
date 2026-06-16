class AppConstants {
  // Base URL - Sanka Vollerei / Animasu
  static const baseUrl = 'https://www.sankavollerei.com/anime';
  static const apiPrefix = '/animasu';

  // Endpoints (path setelah baseUrl + apiPrefix)
  static const home = '/home';
  static const popular = '/popular';
  static const ongoing = '/ongoing';
  static const completed = '/completed';
  static const latest = '/latest';
  static const movies = '/movies';
  static const search = '/search'; // + /:keyword
  static const animeList = '/animelist';
  static const advancedSearch = '/advanced-search';
  static const genres = '/genres';
  static const genreDetail = '/genre'; // + /:slug
  static const animeDetail = '/detail'; // + /:slug
  static const episode = '/episode'; // + /:slug

  // Storage Keys
  static const watchHistoryKey = 'watch_history';
  static const libraryKey = 'library';
  static const settingsKey = 'settings';

  // UI
  static const cardAspectRatio = 2 / 3;
  static const bannerAspectRatio = 16 / 9;
  static const pageSize = 10; // API pakai pagination per 10
}
