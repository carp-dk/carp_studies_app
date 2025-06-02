part of carp_study_app;

/// The page showing the list of devices and online services, ordered as:
///  * The Smartphone device (primary device)
///  * Any hardware devices (connected devices)
///  * Any online services (connected services)
class DeviceListPage extends StatefulWidget {
  static const String route = '/devices';
  const DeviceListPage({super.key});

  @override
  DeviceListPageState createState() => DeviceListPageState();
}

class DeviceListPageState extends State<DeviceListPage> {
  StreamSubscription<BluetoothAdapterState>? bluetoothStateStream;
  BluetoothAdapterState? bluetoothAdapterState;

  final List<DeviceViewModel> _smartphoneDevice = bloc.deploymentDevices
      .where((element) => element.deviceManager is SmartphoneDeviceManager)
      .toList();

  final List<DeviceViewModel> _hardwareDevices = bloc.deploymentDevices
      .where((element) =>
          element.deviceManager is HardwareDeviceManager &&
          element.deviceManager is! SmartphoneDeviceManager)
      .toList();

  final List<DeviceViewModel> _onlineServices = bloc.deploymentDevices
      .where((element) => element.deviceManager is OnlineServiceManager)
      .toList();

  @override
  void initState() {
    super.initState();
    bluetoothStateStream = FlutterBluePlus.adapterState.listen((state) {
      bluetoothAdapterState = state;
      setState(() {});
    });
  }

  @override
  void dispose() {
    bluetoothStateStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).extension<RPColors>()!.backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
              child: const CarpAppBar(hasProfileIcon: true),
            ),
            Container(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.translate('pages.devices.title'),
                        style: aboutStudyCardTitleStyle.copyWith(
                          color:
                              Theme.of(context).extension<RPColors>()!.grey900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(locale.translate("pages.devices.message"),
                          style: aboutCardSubtitleStyle.copyWith(
                            color: Theme.of(context)
                                .extension<RPColors>()!
                                .grey600,
                          )),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: CustomScrollView(
                slivers: [
                  ..._smartphoneDeviceList(locale),
                  if (_hardwareDevices.isNotEmpty)
                    ..._hardwareDevicesList(locale),
                  if (_onlineServices.isNotEmpty)
                    ..._onlineServicesList(locale),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The list of smartphones - which is a list with only one smartphone.
  List<Widget> _smartphoneDeviceList(RPLocalizations locale) => [
        DevicesPageListTitle(locale: locale, type: DevicesPageTypes.phone),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: _smartphoneDevice.length,
            (BuildContext context, int index) => ListenableBuilder(
              listenable: _smartphoneDevice[index],
              builder: (BuildContext context, Widget? widget) => Center(
                child: StudiesMaterial(
                  backgroundColor:
                      Theme.of(context).extension<RPColors>()!.grey50!,
                  child: _cardListBuilder(
                    leading: _smartphoneDevice[index].icon!,
                    title: (
                      "${_smartphoneDevice[index].phoneInfo["model"]!} "
                          "- ${_smartphoneDevice[index].phoneInfo["version"]!}",
                      _smartphoneDevice[index].batteryLevel ?? 0
                    ),
                    subtitle: _smartphoneDevice[index].phoneInfo['name']!,
                  ),
                ),
              ),
            ),
          ),
        ),
      ];

  /// The list of connected hardware devices (like a Polar sensor)
  List<Widget> _hardwareDevicesList(RPLocalizations locale) => [
        DevicesPageListTitle(locale: locale, type: DevicesPageTypes.devices),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: _hardwareDevices.length,
            (BuildContext context, int index) {
              DeviceViewModel device = _hardwareDevices[index];
              return _devicesPageCardStream(
                device.statusEvents,
                DeviceStatus.unknown,
                () => _cardListBuilder(
                  enableFeedback: true,
                  leading: device.icon!,
                  title: (
                    locale.translate(device.typeName),
                    device.batteryLevel ?? 0
                  ),
                  subtitle: device.name,
                  onTap: () async => await _hardwareDeviceClicked(device),
                  trailing: device.getDeviceStatusIcon is Icon
                      ? device.getDeviceStatusIcon as Icon
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                              color: CACHET.DEPLOYMENT_DEPLOYING,
                              borderRadius: BorderRadius.circular(100)),
                          child: Text(
                              locale
                                  .translate(
                                      device.getDeviceStatusIcon as String)
                                  .toUpperCase(),
                              style: aboutCardTitleStyle.copyWith(
                                  color: Colors.white)),
                        ),
                ),
              );
            },
          ),
        ),
      ];

  /// The list of online services (like a Location service)
  List<Widget> _onlineServicesList(RPLocalizations locale) => [
        DevicesPageListTitle(locale: locale, type: DevicesPageTypes.services),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: _onlineServices.length,
            (BuildContext context, int index) {
              DeviceViewModel service = _onlineServices[index];
              return _devicesPageCardStream(
                service.statusEvents,
                DeviceStatus.unknown,
                () => _cardListBuilder(
                  leading: service.icon!,
                  title: (locale.translate(service.typeName), null),
                  subtitle: null,
                  onTap: () async => await _onlineServiceClicked(service),
                  trailing: service.getServiceStatusIcon is String
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                              color: CACHET.DEPLOYMENT_DEPLOYING,
                              borderRadius: BorderRadius.circular(100)),
                          child: Text(
                            locale
                                .translate(
                                    service.getServiceStatusIcon as String)
                                .toUpperCase(),
                            style: aboutCardTitleStyle.copyWith(
                                color: Colors.white),
                          ),
                        )
                      : service.getServiceStatusIcon as Icon,
                ),
              );
            },
          ),
        ),
      ];

  Widget _cardListBuilder({
    bool enableFeedback = false,
    Icon? leading,
    (String, int?)? title,
    String? subtitle,
    void Function()? onTap,
    Widget? trailing,
  }) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        enableFeedback: enableFeedback,
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [leading!],
        ),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                title!.$1,
                style: deviceTitle.copyWith(
                  color: Theme.of(context).extension<RPColors>()!.grey900,
                ),
              ),
              SizedBox(width: 6),
              if (title.$2 != null && title.$2! > 0)
                BatteryPercentage(batteryLevel: title.$2 ?? 0),
            ],
          ),
        ),
        subtitle: subtitle != null && subtitle.isNotEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: deviceSubtitle.copyWith(
                      color: Theme.of(context).extension<RPColors>()!.grey700,
                    ),
                  ),
                ],
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (trailing != null) trailing,
          ],
        ),
        onTap: onTap,
      );

  Widget _devicesPageCardStream<T>(
    Stream<T> stream,
    T? initialData,
    Widget Function() childBuilder,
  ) =>
      Center(
        child: StudiesMaterial(
          backgroundColor: Theme.of(context).extension<RPColors>()!.grey50!,
          child: StreamBuilder<T>(
            stream: stream,
            initialData: initialData,
            builder: (context, AsyncSnapshot<T> snapshot) => childBuilder(),
          ),
        ),
      );

  Future<void> _onlineServiceClicked(DeviceViewModel service) async {
    if (service.status == DeviceStatus.connected ||
        service.status == DeviceStatus.connecting) {
      return;
    }

    if (!(await service.deviceManager.hasPermissions())) {
      if (service.type == HealthService.DEVICE_TYPE) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (context) => HealthServiceConnectPage1()),
        );
      } else {
        await service.deviceManager.requestPermissions();
      }
    }
    await service.deviceManager.connect();
  }

  Future<void> _hardwareDeviceClicked(DeviceViewModel device) async {
    // fast out if no Bluetooth
    if (!(await FlutterBluePlus.isSupported)) return;

    // turn on bluetooth if we can
    if (Platform.isAndroid) await FlutterBluePlus.turnOn();

    if (context.mounted) {
      if (bluetoothAdapterState == BluetoothAdapterState.off &&
          Platform.isIOS) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) => EnableBluetoothDialog(device: device),
        );
      } else if (bluetoothAdapterState == BluetoothAdapterState.on) {
        if (device.status == DeviceStatus.connected ||
            device.status == DeviceStatus.connecting) {
          bool disconnect = await showDialog<bool?>(
                context: context,
                barrierDismissible: true,
                builder: (context) => DisconnectionDialog(device: device),
              ) ??
              false;
          if (disconnect) await device.disconnectFromDevice();
        } else {
          Navigator.push(
              context,
              MaterialPageRoute<void>(
                // barrierDismissible: true,
                builder: (context) => HWDeviceConnectPage1(device: device),
              ));
        }
      } else if (bluetoothAdapterState == BluetoothAdapterState.unauthorized &&
          Platform.isIOS) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) => AuthorizationDialog(device: device),
        );
      }
    }
  }
}
