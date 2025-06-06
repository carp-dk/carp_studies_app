part of carp_study_app;

/// State of Bluetooth connection UI.
enum CurrentStep { scan, instructions, done }

class BluetoothConnectionPage extends StatefulWidget {
  final DeviceViewModel device;

  const BluetoothConnectionPage({super.key, required this.device});

  @override
  State<StatefulWidget> createState() => _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
  @override
  initState() {
    super.initState();
    FlutterBluePlus.startScan();
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  CurrentStep currentStep = CurrentStep.scan;
  BluetoothDevice? selectedDevice;
  int selected = 40;

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Theme.of(context).colorScheme.secondary,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                child: const CarpAppBar(hasProfileIcon: true),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      _buildDialogTitle(locale),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: _buildStepContent(locale),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _buildActionButtons(locale),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogTitle(RPLocalizations locale) {
    final stepTitleMap = {
      CurrentStep.scan:
          locale.translate("pages.devices.connection.step.start.title") +
              (" ${widget.device.name} "),
      CurrentStep.instructions:
          locale.translate("pages.devices.connection.step.how_to.title") +
              (" ${selectedDevice?.platformName} ") +
              locale.translate("pages.devices.connection.step.how_to.device"),
      CurrentStep.done:
          locale.translate("pages.devices.connection.step.confirm.title") +
              (" ${selectedDevice?.platformName} "),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                stepTitleMap[currentStep] ?? '',
                style: healthServiceConnectMessageStyle.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(RPLocalizations locale) {
    final stepContentMap = {
      CurrentStep.scan: stepContent(currentStep, widget.device),
      CurrentStep.instructions: connectionInstructions(widget.device, context),
      CurrentStep.done: confirmDevice(selectedDevice, context),
    };

    return stepContentMap[currentStep] ?? Container();
  }

  List<Widget> _buildActionButtons(RPLocalizations locale) {
    Widget buildTranslatedButton(String key, VoidCallback onPressed,
        bool enabled, ButtonStyle? buttonStyle, TextStyle? buttonTextStyle) {
      return ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: Text(
          locale.translate(key).toUpperCase(),
          style: buttonTextStyle,
        ),
        style: buttonStyle,
      );
    }

    final stepButtonConfigs = {
      CurrentStep.scan: [
        buildTranslatedButton("cancel", () {
          context.pop(true);
        }, true, null, null),
        buildTranslatedButton(
          "next",
          () {
            if (selectedDevice != null) {
              setState(() => currentStep = CurrentStep.done);
            }
          },
          selectedDevice != null,
          ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).extension<RPColors>()!.primary,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
          TextStyle(
            color: Colors.white,
          ),
        ),
      ],
      CurrentStep.instructions: [
        buildTranslatedButton("settings", () {
          Platform.isAndroid
              ? OpenSettingsPlusAndroid().bluetooth()
              : OpenSettingsPlusIOS().bluetooth();
        }, true, null, null),
        buildTranslatedButton(
          "ok",
          () {
            setState(() => currentStep = CurrentStep.scan);
          },
          true,
          ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).extension<RPColors>()!.primary,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
          TextStyle(
            color: Colors.white,
          ),
        ),
      ],
      CurrentStep.done: [
        buildTranslatedButton("back", () {
          setState(() => currentStep = CurrentStep.scan);
        }, true, null, null),
        buildTranslatedButton(
          "done",
          () {
            FlutterBluePlus.stopScan();
            if (selectedDevice != null) {
              widget.device.connectToDevice(selectedDevice!);
              context.pop(true);
            }
          },
          true,
          ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).extension<RPColors>()!.primary,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
          TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    };
    return stepButtonConfigs[currentStep] ?? [];
  }

  Widget stepContent(
    CurrentStep currentStep,
    DeviceViewModel device,
  ) {
    if (currentStep == CurrentStep.scan) {
      return scanWidget(device, context);
    } else if (currentStep == CurrentStep.instructions) {
      return connectionInstructions(device, context);
    } else {
      return confirmDevice(selectedDevice, context);
    }
  }

  Widget scanWidget(DeviceViewModel device, BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(
            "${locale.translate("pages.devices.connection.step.scan.1")} "
            "${locale.translate(device.typeName)} "
            "${locale.translate("pages.devices.connection.step.scan.2")}",
            style: healthServiceConnectMessageStyle,
            textAlign: TextAlign.justify,
          ),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.scanResults,
              initialData: const [],
              builder: (context, snapshot) => SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  children: snapshot.data!
                      .where(
                          (element) => element.device.platformName.isNotEmpty)
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (bluetoothDevice) => ListTile(
                          selected: bluetoothDevice.key == selected,
                          title: Text(
                            bluetoothDevice.value.device.platformName,
                            style: healthServiceConnectTitleStyle,
                          ),
                          selectedTileColor: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.2),
                          onTap: () {
                            selectedDevice = bluetoothDevice.value.device;
                            setState(() {
                              selected = bluetoothDevice.key;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: locale
                        .translate("pages.devices.connection.step.start.1"),
                  ),
                  TextSpan(
                    text: locale
                        .translate("pages.devices.connection.instructions"),
                    style: TextStyle(
                      color: Theme.of(context).extension<RPColors>()!.primary,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        setState(() => currentStep = CurrentStep.instructions);
                      },
                  ),
                  TextSpan(
                    text: locale.translate(
                      "pages.devices.connection.step.start.2",
                    ),
                  ),
                ],
              ),
              style: healthServiceConnectMessageStyle.copyWith(
                  color: Theme.of(context).extension<RPColors>()!.grey900),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }

  Widget connectionInstructions(DeviceViewModel device, BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    AssetImage? assetImage;

    switch (widget.device.deviceManager) {
      case PolarDeviceManager _
          when widget.device.type == PolarDevice.DEVICE_TYPE &&
              (widget.device.polarDeviceType == PolarDeviceType.H10 ||
                  widget.device.polarDeviceType == PolarDeviceType.H9):
        assetImage =
            AssetImage('assets/instructions/polar_h9_h10_instructions.png');
        break;

      case PolarDeviceManager _
          when widget.device.type == PolarDevice.DEVICE_TYPE &&
              widget.device.polarDeviceType == PolarDeviceType.SENSE:
        assetImage =
            AssetImage('assets/instructions/polar_sense_instructions.png');
        break;

      case MovesenseDeviceManager _:
        assetImage =
            AssetImage('assets/instructions/movesense_instructions.png');
        break;

      default:
        assetImage = AssetImage('assets/instructions/connect_to_hw.png');
    }

    Image connectionImage = Image(
      image: assetImage,
      width: MediaQuery.of(context).size.height * 0.2,
      height: MediaQuery.of(context).size.height * 0.2,
    );
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                connectionImage,
                Text(
                  locale.translate(device.connectionInstructions!),
                  style: aboutCardContentStyle,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget confirmDevice(BluetoothDevice? device, BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Image(
                    image: const AssetImage('assets/icons/connection_done.png'),
                    width: MediaQuery.of(context).size.height * 0.2,
                    height: MediaQuery.of(context).size.height * 0.2),
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Text(
                    ("${locale.translate("pages.devices.connection.step.confirm.1")} '${device?.platformName}' ${locale.translate("pages.devices.connection.step.confirm.2")}")
                        .trim(),
                    style: aboutCardContentStyle,
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
