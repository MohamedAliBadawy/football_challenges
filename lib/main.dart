import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:football_challenges/core/ads/ads_controller.dart';
import 'package:football_challenges/core/style/locale_provider.dart';
import 'package:football_challenges/core/style/theme.dart';
import 'package:football_challenges/core/style/theme_provider.dart';
import 'package:football_challenges/features/auth/auth_service.dart';
import 'package:football_challenges/features/offline_modes/same_phone/clubs_view.dart';
import 'package:football_challenges/features/offline_modes/same_phone/leagues_view.dart';
import 'package:football_challenges/features/offline_modes/same_phone/offline_chat_game.dart';
import 'package:football_challenges/features/offline_modes/same_phone/offline_game_appbar_provider.dart';
import 'package:football_challenges/features/offline_modes/same_phone/players_setup.dart';
import 'package:football_challenges/features/offline_modes/same_phone/selection_provider.dart';
import 'package:football_challenges/features/offline_modes/same_phone/selection_screen.dart';
import 'package:football_challenges/features/offline_modes/same_phone/team_management.dart';
import 'package:football_challenges/features/offline_modes/same_phone/team_provider.dart';
import 'package:football_challenges/features/offline_modes/same_phone/user_player_model.dart';
import 'package:football_challenges/features/online_modes/create_room.dart';
import 'package:football_challenges/features/online_modes/join_room.dart';
import 'package:football_challenges/features/online_modes/join_room_provider.dart';
import 'package:football_challenges/features/online_modes/online_rondo.dart';
import 'package:football_challenges/features/online_modes/online_team_management.dart';
import 'package:football_challenges/firebase_options.dart';
import 'package:football_challenges/models/league_model.dart';
import 'package:football_challenges/src/main_menu/buttons_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'core/app_lifecycle/app_lifecycle.dart';
import 'core/audio/audio_controller.dart';
import 'core/crashlytics/crashlytics.dart';
import 'src/games_services/games_services.dart';
import 'src/games_services/score.dart';
import 'core/in_app_purchase/in_app_purchase.dart';

import 'src/main_menu/main_menu_screen.dart';
import 'src/play_session/play_session_screen.dart';

import 'src/settings/persistence/local_storage_settings_persistence.dart';
import 'src/settings/persistence/settings_persistence.dart';
import 'src/settings/settings.dart';
import 'src/settings/settings_screen.dart';
import 'core/style/palette.dart';
import 'core/style/snack_bar.dart';
import 'src/win_game/win_game_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  FirebaseCrashlytics? crashlytics;
  if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      crashlytics = FirebaseCrashlytics.instance;
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Firebase couldn't be initialized: $e");
    }
  }

  await guardWithCrashlytics(
    guardedMain,
    crashlytics: crashlytics,
  );
}

/// Without logging and crash reporting, this would be `void main()`.
void guardedMain() {
  if (kReleaseMode) {
    // Don't log anything below warnings in production.
    Logger.root.level = Level.WARNING;
  }
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: '
        '${record.loggerName}: '
        '${record.message}');
  });

  WidgetsFlutterBinding.ensureInitialized();

  _log.info('Going full screen');
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  AdsController? adsController;
  if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
    //   /// Prepare the google_mobile_ads plugin so that the first ad loads
    //   /// faster. This can be done later or with a delay if startup
    //   /// experience suffers.
    adsController = AdsController(MobileAds.instance);
    adsController.initialize();
  }

  GamesServicesController? gamesServicesController;
  // if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
  //   gamesServicesController = GamesServicesController()
  //     // Attempt to log the player in.
  //     ..initialize();
  // }

  InAppPurchaseController? inAppPurchaseController;
/*   if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
    inAppPurchaseController = InAppPurchaseController(InAppPurchase.instance)
      // Subscribing to [InAppPurchase.instance.purchaseStream] as soon
      // as possible in order not to miss any updates.
      ..subscribe();
    // Ask the store what the player has bought already.
    inAppPurchaseController.restorePurchases();
  } */

  runApp(
    MyApp(
      settingsPersistence: LocalStorageSettingsPersistence(),
      inAppPurchaseController: inAppPurchaseController,
      adsController: adsController,
      gamesServicesController: gamesServicesController,
    ),
  );
}

Logger _log = Logger('main.dart');
Future<bool> roomCheck(String roomId) async {
  final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
  final roomDoc = await roomRef.get();
  if (roomDoc.exists) {
    final roomData = roomDoc.data()!;

    if (roomData['currentPlayersNum'] < roomData['playersNum']) {
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}

class MyApp extends StatelessWidget {
  static final _router = GoRouter(
    routes: [
      GoRoute(
          path: '/',
          builder: (context, state) =>
              const MainMenuScreen(key: Key('main menu')),
          routes: [
            GoRoute(
              path: 'join',
              builder: (context, state) => JoinRoomScreen(
                key: const Key('join'),
                roomId: "",
              ),
            ),
            GoRoute(
                path: 'create',
                builder: (context, state) =>
                    const CreateRoomScreen(key: Key('create')),
                routes: [
                  GoRoute(
                    path: 'leagues',
                    builder: (context, state) =>
                        const LeaguesScreen(key: Key('leagues selection')),
                  ),
                  GoRoute(
                      path: 'clubs',
                      builder: (context, state) {
                        final map = state.extra! as Map<String, dynamic>;
                        final clubsIds = map['clubsIds'] as List<int>;

                        return ClubsScreen(
                          key: const Key('clubs selection'),
                          clubsIds: clubsIds,
                        );
                      }),
                ]),
            GoRoute(
              path: 'room/:roomId',
              builder: (context, state) {
                if (state.extra == null) {
                  final roomId = state.pathParameters['roomId'].toString();

                  return JoinRoomScreen(
                    roomId: roomId,
                    key: const Key('room'),
                  );
                } else {
                  final map = state.extra as Map<String, dynamic>;
                  final roomId =
                      state.pathParameters['roomId'] ?? map['roomId'] as String;
                  return JoinRoomScreen(
                    roomId: roomId,
                    key: const Key('room'),
                  );
                }
              },
            ),
            GoRoute(
              path: 'online_team_management',
              builder: (context, state) {
                final map = state.extra as Map<String, dynamic>;

                return OnlineTeamManagementScreen(
                  isOwner: map['isOwner'] as bool,
                  roomId: map['roomId'] as String,
                  key: const Key('online_team_management'),
                );
              },
            ),
            GoRoute(
                path: 'online_rondo',
                builder: (context, state) {
                  final map = state.extra! as Map<String, dynamic>;
                  final roomId = map['roomId'] as String;
                  final leagues = map['leagues'] as List<int>;
                  final winScore = map['winScore'] as int;
                  final playerTime = map['playerTime'] as int;
                  final turns = map['turns'] as List;

                  return OnlineRondoScreen(
                    key: const Key('online_rondo'),
                    leagueIds: leagues,
                    playerTime: playerTime,
                    winScore: winScore,
                    roomId: roomId,
                    turns: turns,
                  );
                }),
            GoRoute(
                path: 'offline',
                builder: (context, state) =>
                    const SelectionScreen(key: Key('offline')),
                routes: [
                  GoRoute(
                    path: 'leagues',
                    builder: (context, state) => const LeaguesScreen(
                        key: Key('offline leagues selection')),
                  ),
                  GoRoute(
                      path: 'clubs',
                      builder: (context, state) {
                        final map = state.extra! as Map<String, dynamic>;
                        final clubsIds = map['clubsIds'] as List<int>;

                        return ClubsScreen(
                          key: const Key('clubs selection'),
                          clubsIds: clubsIds,
                        );
                      }),
                  GoRoute(
                      path: 'playerInput',
                      builder: (context, state) {
                        return const PlayerInputScreen(
                          key: Key('player setup'),
                        );
                      },
                      routes: [
                        GoRoute(
                          path: 'team_management',
                          builder: (context, state) {
                            return const TeamManagementScreen(
                              key: Key('team management'),
                            );
                          },
                        ),
                      ]),
                  GoRoute(
                      path: 'offline_chat_game',
                      builder: (context, state) {
                        final map = state.extra! as Map<String, dynamic>;
                        final initialClub = map['initialClub'] as int;
                        final leagueIds = map['leagueIds'] as List<int>;
                        final winScore = map['winScore'] as int;
                        final playerTime = map['playerTime'] as int;
                        final teamA = map['teamA'] as List<UserPlayer>;
                        final teamB = map['teamB'] as List<UserPlayer>;

                        return ChatScreen(
                          key: const Key('offline_chat_game '),
                          initialClub: initialClub,
                          leagueIds: leagueIds,
                          teamA: teamA,
                          teamB: teamB,
                          playerTime: playerTime,
                          winScore: winScore,
                        );
                      }),
                ]),
            GoRoute(
              path: 'won',
              builder: (context, state) {
                final map = state.extra! as Map<String, dynamic>;
                final players = map['players'] as List<dynamic>;
                final won = map['won'] as String;
                final lost = map['lost'] as String;
                return WinGameScreen(
                  key: const Key('win game'),
                  wonTeam: won,
                  lostTeam: lost,
                  players: players,
                );
              },
            ),
            GoRoute(
              path: 'settings',
              builder: (context, state) =>
                  SettingsScreen(key: const Key('settings')),
            ),
          ]),
    ],
  );

  final SettingsPersistence settingsPersistence;

  final GamesServicesController? gamesServicesController;

  final InAppPurchaseController? inAppPurchaseController;

  final AdsController? adsController;

  const MyApp({
    required this.settingsPersistence,
    required this.inAppPurchaseController,
    required this.adsController,
    required this.gamesServicesController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => SelectionProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => JoinRoomProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => AuthService(),
          ),
          ChangeNotifierProvider(
            create: (_) => OfflineGameAppbarProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => TeamProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => ButtonState(),
          ),
          ChangeNotifierProvider(
            create: (context) => ThemeProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => LocaleProvider(),
          ),
          Provider<GamesServicesController?>.value(
              value: gamesServicesController),
          Provider<AdsController?>.value(value: adsController),
          ChangeNotifierProvider<InAppPurchaseController?>.value(
              value: inAppPurchaseController),
          Provider<SettingsController>(
            lazy: false,
            create: (context) => SettingsController(
              persistence: settingsPersistence,
            )..loadStateFromPersistence(),
          ),
          ProxyProvider2<SettingsController, ValueNotifier<AppLifecycleState>,
              AudioController>(
            // Ensures that the AudioController is created on startup,
            // and not "only when it's needed", as is default behavior.
            // This way, music starts immediately.
            lazy: false,
            create: (context) => AudioController()..initialize(),
            update: (context, settings, lifecycleNotifier, audio) {
              if (audio == null) throw ArgumentError.notNull();
              audio.attachSettings(settings);
              audio.attachLifecycleNotifier(lifecycleNotifier);
              return audio;
            },
            dispose: (context, audio) => audio.dispose(),
          ),
          Provider(
            create: (context) => Palette(),
          ),
        ],
        child: Builder(builder: (context) {
          final palette = context.watch<Palette>();

          MaterialTheme theme = MaterialTheme(
            TextTheme(
              bodyMedium: TextStyle(
                color: palette.ink,
              ),
            ),
          );

          return Consumer2<ThemeProvider, LocaleProvider>(
              builder: (context, themeProvider, localeProvider, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (themeProvider.themeMode == ThemeMode.system) {
                themeProvider.setThemeFromSystem(context);
              }
            });
            return MaterialApp.router(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ar', 'EG'), // Arabic
                Locale('en', 'US'), // English
              ],
              locale: localeProvider.locale,
              title: 'Flutter Demo',
              theme: theme.light(),
              darkTheme: theme.dark(),
              themeMode: themeProvider.themeMode,
              routeInformationProvider: _router.routeInformationProvider,
              routeInformationParser: _router.routeInformationParser,
              routerDelegate: _router.routerDelegate,
              scaffoldMessengerKey: scaffoldMessengerKey,
            );
          });
        }),
      ),
    );
  }
}
