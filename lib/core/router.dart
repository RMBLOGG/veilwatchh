import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/search/search_screen.dart';
import '../presentation/screens/detail/anime_detail_screen.dart';
import '../presentation/screens/player/player_screen.dart';
import '../presentation/screens/library/library_screen.dart';
import '../presentation/widgets/common/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => const NoTransitionPage(child: SearchScreen()),
        ),
        GoRoute(
          path: '/library',
          pageBuilder: (context, state) => const NoTransitionPage(child: LibraryScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/anime/:id',
      builder: (context, state) => AnimeDetailScreen(
        animeId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/watch/:episodeId',
      builder: (context, state) => PlayerScreen(
        episodeId: state.pathParameters['episodeId']!,
        animeId: state.uri.queryParameters['animeId'] ?? '',
        episodeNumber: int.tryParse(state.uri.queryParameters['ep'] ?? '1') ?? 1,
        animeTitle: state.uri.queryParameters['title'] ?? '',
      ),
    ),
  ],
);
