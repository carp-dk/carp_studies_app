part of carp_study_app;

/// The home page of the app.
///
/// Shown once the onboarding process is done.
class HomePage extends StatefulWidget {
  final Widget child;
  const HomePage({required this.child, super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  /// Ask for location permissions.
  ///
  /// The method opens the [LocationUsageDialog] if location permissions are
  /// needed and not yet granted.
  ///
  /// Android requires the app to show a modal window explaining "why" the app
  /// needs access to location. Best practice for doing this is explain on the
  /// [Request location permissions](https://developer.android.com/develop/sensors-and-location/location/permissions)
  /// Android Developer page.
  ///
  /// This approach is used on both Android and iOS, even though it is an
  /// Android recommendation / requirement.
  Future<void> askForLocationPermissions(BuildContext context) async {
    if (!context.mounted) return;

    if (bloc.usingLocationPermissions) {
      var granted = await LocationManager().isGranted();
      if (!granted) {
        await showGeneralDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black38,
            transitionBuilder: (ctx, anim1, anim2, child) => BackdropFilter(
                  filter: ui.ImageFilter.blur(
                      sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
                  child: FadeTransition(
                    opacity: anim1,
                    child: child,
                  ),
                ),
            pageBuilder: (context, anim1, anim2) => LocationUsageDialog().build(
                  context,
                  "pages.location.info",
                ));
        await LocationManager().requestPermission();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Setting up sensing, which entails;
    //  - asking for location permissions
    //  - configuring the study
    //  - starting sensing
    askForLocationPermissions(context)
        .then((_) => bloc.configureStudy().then((_) => bloc.start()));

    if (Platform.isAndroid) {
      // Check if HealthConnect is installed
      _checkHealthConnectInstallation();
    }
  }

  Future<void> _checkHealthConnectInstallation() async {
    bool isInstalled = await bloc._isHealthConnectInstalled();
    if (!isInstalled) {
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => InstallHealthConnectDialog(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    // Save the localization for the app
    bloc.localization = locale;

    // Listen for user task notification clicked in the OS
    AppTaskController().userTaskEvents.listen((userTask) {
      if (userTask.state == UserTaskState.notified) {
        debug('Notification for task id: ${userTask.id} was clicked.');
        userTask.onStart();
        if (userTask.hasWidget) context.push('/task/${userTask.id}');
      }
    });

    return Scaffold(
      backgroundColor:
          Theme.of(context).extension<CarpColors>()!.backgroundGray,
      body: SafeArea(
        child: widget.child,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).extension<CarpColors>()!.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).extension<CarpColors>()!.primary,
        //unselectedItemColor: Theme.of(context).primaryColor.withOpacity(0.8),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: const Icon(Icons.announcement),
              label: locale.translate('app_home.nav_bar_item.about'),
              activeIcon: const Icon(Icons.announcement)),
          BottomNavigationBarItem(
            icon: const Icon(Icons.playlist_add_check),
            label: locale.translate('app_home.nav_bar_item.tasks'),
            activeIcon: const Icon(Icons.playlist_add_check),
          ),
          BottomNavigationBarItem(
              icon: const Icon(Icons.leaderboard),
              label: locale.translate('app_home.nav_bar_item.data'),
              activeIcon: const Icon(Icons.leaderboard)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.devices_other),
              label: locale.translate('app_home.nav_bar_item.devices'),
              activeIcon: const Icon(Icons.devices_other)),
        ],
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(StudyPage.route)) {
      return 0;
    }
    if (location.startsWith(TaskListPage.route)) {
      return 1;
    }
    if (location.startsWith(DataVisualizationPage.route)) {
      return 2;
    }
    if (location.startsWith(DeviceListPage.route)) {
      return 3;
    }
    return -1;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(StudyPage.route);
        break;
      case 1:
        context.go(TaskListPage.route);
        break;
      case 2:
        context.go(DataVisualizationPage.route);
        break;
      case 3:
        context.go(DeviceListPage.route);
        break;
      case -1:
        context.go(CarpStudyAppState.homeRoute);
        break;
    }
  }
}
