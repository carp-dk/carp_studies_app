part of carp_study_app;

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class CarpStudyApp extends StatefulWidget {
  const CarpStudyApp({super.key});

  /// Reload language translations and re-build the entire app.
  static void reloadLocale(BuildContext context) async {
    CarpStudyAppState? state =
        context.findAncestorStateOfType<CarpStudyAppState>();
    state?.reloadLocale();
  }

  @override
  CarpStudyAppState createState() => CarpStudyAppState();
}

class CarpStudyAppState extends State<CarpStudyApp> {
  /// The landing page once the onboarding process is done.
  static const String firstRoute = StudyPage.route;
  static const String homeRoute = '/';

  /// Reload language translations and re-build the entire app.
  void reloadLocale() => setState(() => rpLocalizationsDelegate.reload());

  // This create the routing in the entire app.
  // Each page (like [LoginPage]) know the name of its own route.
  final GoRouter _router = GoRouter(
    initialLocation: homeRoute,
    navigatorKey: _rootNavigatorKey,
    errorBuilder: (context, state) => const ErrorPage(),
    routes: <RouteBase>[
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            HomePage(child: child),
        routes: [
          // This is the root route, handling the onboarding.
          // The flow of logic is:
          //  - do we run locally and need authentication
          //  - the user is authenticated, if not show login page
          //  - a study is deployed, if not show list of invitations for the user
          //  - the user has accepted the informed consent, if not show informed consent page
          //
          // Once the above is done, then show the "first route", which currently is
          // the "study" information page.
          GoRoute(
              path: homeRoute,
              parentNavigatorKey: _shellNavigatorKey,
              redirect: (context, state) async {
                // print(
                //     '''im home, ocome over babe. im alone. no i cant. but my parents arent home.
                //     host: ${state.uri.host}
                //      path: ${state.uri.path}
                //      pathSegments: ${state.uri.pathSegments}
                //      scheme: ${state.uri.scheme}
                //      userInfo: ${state.uri.userInfo}
                //      port: ${state.uri.port}
                //      query: ${state.uri.query}
                //      queryParameters[code]: ${state.uri.queryParameters['code']}''');

                if (state.uri.queryParameters.containsKey("session_state")) {
                  bool isConnected = await bloc.checkConnectivity();
                  if (isConnected) {
                    await bloc.backend.initialize();
                    if (!bloc.backend.isAuthenticated) {
                      await bloc.backend.authenticate();
                    }
                    // if (context.mounted) return CarpStudyAppState.homeRoute;
                  } else {
                    showDialog<bool>(
                      context: context,
                      builder: (context) => PopScope(
                        onPopInvokedWithResult: (didPop, result) async {
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) async {
                            if (didPop && result == true) {
                              Navigator.of(context).pop();
                            }
                          });
                        },
                        child: EnableInternetConnectionDialog(),
                      ),
                    );
                  }
                }

                if (bloc.deploymentMode != DeploymentMode.local) {
                  if (!bloc.backend.isAuthenticated) {
                    return LoginPage.route;
                  } else if (!bloc.hasStudyBeenDeployed) {
                    return InvitationListPage.route;
                  }
                }

                if (!bloc.hasInformedConsentBeenAccepted) {
                  return InformedConsentPage.route;
                }

                return firstRoute;
              }),
          GoRoute(
            path: TaskListPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              child: TaskListPage(
                model: bloc.appViewModel.taskListPageViewModel,
              ),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
          ),
          GoRoute(
            path: StudyPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              child: StudyPage(
                model: bloc.appViewModel.studyPageViewModel,
              ),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
          ),
          GoRoute(
            path: DataVisualizationPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              child: DataVisualizationPage(
                  bloc.appViewModel.dataVisualizationPageViewModel),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
          ),
          GoRoute(
            path: DeviceListPage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => const CustomTransitionPage(
              child: DeviceListPage(),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
          ),
          GoRoute(
            path: ProfilePage.route,
            parentNavigatorKey: _shellNavigatorKey,
            pageBuilder: (context, state) => CustomTransitionPage(
              child: ProfilePage(bloc.appViewModel.profilePageViewModel),
              transitionsBuilder: bottomNavigationBarAnimation,
            ),
          ),
        ],
      ),
      // GoRoute(
      //     path: '/anonymous',
      //     parentNavigatorKey: _rootNavigatorKey,
      //     redirect: (context, state) {
      //       if (bloc.backend.isAuthenticated) {
      //         print('im not a prin ${state.pathParameters}');
      //         return StudyPage.route;
      //       } else {
      //         print(
      //             'i am the printer the printer of worlds ${state.pathParameters}');
      //         // await bloc.backend.authenticateAnonymous();
      //         return bloc.study != null
      //             ? InformedConsentPage.route
      //             : (bloc.user == null ? LoginPage.route : null);
      //       }
      //     }),

      // GoRoute(
      //   path: '/anonymous',
      //   parentNavigatorKey: _rootNavigatorKey,
      //   redirect: (context, state) => InvitationListPage.route,
      // ),

      // GoRoute(
      //     path: '/anonymous',
      //     parentNavigatorKey: _rootNavigatorKey,
      //     redirect: (context, state) async {
      //       print(
      //           '''im home, ocome over babe. im alone. no i cant. but my parents arent home.
      //               host: ${state.uri.host}
      //                path: ${state.uri.path}
      //                pathSegments: ${state.uri.pathSegments}
      //                scheme: ${state.uri.scheme}
      //                userInfo: ${state.uri.userInfo}
      //                port: ${state.uri.port}
      //                query: ${state.uri.query}
      //                queryParameters[code]: ${state.uri.queryParameters['code']}''');
      //       final magicLink = state.uri.queryParameters['code'];

      //       if (state.uri.queryParameters.containsKey("session_state")) {
      //         bool isConnected = await bloc.checkConnectivity();
      //         if (isConnected) {
      //           await bloc.backend.initialize();
      //           if (!bloc.backend.isAuthenticated) {
      //             // await CarpAuthService().authenticateWithMagicLink(state.uri);
      //             // print('Authenticated with magic link');
      //             return InvitationListPage.route;
      //           }
      //         } else {
      //           showDialog<bool>(
      //             context: context,
      //             builder: (context) => PopScope(
      //               onPopInvokedWithResult: (didPop, result) async {
      //                 WidgetsBinding.instance.addPostFrameCallback((_) async {
      //                   if (didPop && result == true) {
      //                     Navigator.of(context).pop();
      //                   }
      //                 });
      //               },
      //               child: EnableInternetConnectionDialog(),
      //             ),
      //           );
      //         }
      //       }
      //     }),
      GoRoute(
        path: '/anonymous',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final queryParams = state.extra as Map<String, String>?;
          final code = queryParams?['code'];
          final sessionState = queryParams?['session_state'];
          print('''query params $queryParams
            code: $code 
            sessionState: $sessionState
            ''');

          // Trigger async authentication after first frame
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            bool isConnected = await bloc.checkConnectivity();
            if (isConnected) {
              print(
                  '''im home, ocome over babe. im alone. no i cant. but my parents arent home.
                      host: ${state.uri.host}
                      path: ${state.uri.path}
                      pathSegments: ${state.uri.pathSegments}
                      scheme: ${state.uri.scheme}
                      userInfo: ${state.uri.userInfo}
                      port: ${state.uri.port}
                      query: ${state.uri.query}
                      queryParameters[code]: ${state.uri.queryParameters['code']}''');
              // await bloc.backend.initialize();

              // if (!bloc.backend.isAuthenticated && code != null) {
              //   await CarpAuthService().authenticateWithMagicLink(state.uri);
              // }

              // Navigate to Invitations list page after successful auth
              if (bloc.backend.isAuthenticated) {
                print('Navigating to Invitations List Page');
                context.go(InvitationListPage.route);
              }
            } else {
              // Show no-internet dialog if needed
              showDialog<bool>(
                context: context,
                builder: (context) => EnableInternetConnectionDialog(),
              );
            }
          });

          // Show a loading screen while async work runs
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      GoRoute(
        path: StudyDetailsPage.route,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StudyDetailsPage(
          model: bloc.appViewModel.studyPageViewModel,
        ),
      ),
      GoRoute(
        path: ParticipantDataPage.route,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ParticipantDataPage(
            model: bloc.appViewModel.participantDataPageViewModel),
      ),
      GoRoute(
        path: '/task/:taskId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final taskId = state.pathParameters['taskId'] ?? '';
          final task = AppTaskController().getUserTask(taskId);
          return task?.widget ?? const ErrorPage();
        },
      ),
      GoRoute(
        path: InformedConsentPage.route,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => InformedConsentPage(
          model: bloc.appViewModel.informedConsentViewModel,
        ),
      ),
      GoRoute(
        path: LoginPage.route,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '${MessageDetailsPage.route}/:messageId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MessageDetailsPage(
            messageId: state.pathParameters['messageId'] ?? ''),
      ),
      GoRoute(
        path: '${InvitationDetailsPage.route}/:invitationId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => InvitationDetailsPage(
          model: bloc.appViewModel.invitationsListViewModel,
          invitationId: state.pathParameters['invitationId'] ?? '',
        ),
      ),
      GoRoute(
        path: InvitationListPage.route,
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => bloc.study != null
            ? InformedConsentPage.route
            : (bloc.user == null ? LoginPage.route : null),
        builder: (context, state) => InvitationListPage(
            model: bloc.appViewModel.invitationsListViewModel),
      ),
    ],
    debugLogDiagnostics: true,
  );

  /// Research Package translations, incl. both local language assets plus
  /// translations of informed consent and surveys downloaded from CARP
  final RPLocalizationsDelegate rpLocalizationsDelegate =
      RPLocalizationsDelegate(
    loaders: [
      const AssetLocalizationLoader(),
      bloc.localizationLoader,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final carpColors = Theme.of(context).extension<CarpColors>();
    return MaterialApp.router(
      scaffoldMessengerKey: bloc.scaffoldKey,
      supportedLocales: const [
        Locale('en'),
        Locale('da'),
        Locale('es'),
      ],
      localizationsDelegates: [
        // Research Package translations
        rpLocalizationsDelegate,
        // Built-in localization of basic text for Cupertino widgets
        GlobalCupertinoLocalizations.delegate,
        // Built-in localization of basic text for Material widgets
        GlobalMaterialLocalizations.delegate,
        // Built-in localization for text direction LTR/RTL
        GlobalWidgetsLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode
              // && supportedLocale.countryCode == locale?.countryCode
              ) {
            Intl.defaultLocale = supportedLocale.languageCode;
            return supportedLocale;
          }
        }
        return supportedLocales.first; // default to EN
      },
      // theme: ThemeData(
      //   extensions: [
      //     RPColors(
      //       primary: CarpColors().primary,
      //     ),
      //   ],
      // ),

      // theme: ThemeData(
      //   extensions: [
      //     researchPackageTheme.extension<RPColors>()!.copyWith(
      //           primary: CarpColors().primary,
      //         ),
      //   ],
      // ),

      // theme: researchPackageTheme,

      theme: researchPackageTheme.copyWith(
        extensions: [
          researchPackageTheme.extension<RPColors>()!.copyWith(
                primary: carpColors?.primary,
              ),
        ],
      ),

      darkTheme: researchPackageDarkTheme,
      debugShowCheckedModeBanner: true,
      routerConfig: _router,
    );
  }
}

FadeTransition bottomNavigationBarAnimation(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) =>
    FadeTransition(
      opacity: animation,
      child: child,
    );
