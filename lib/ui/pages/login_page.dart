part of carp_study_app;

class LoginPage extends StatefulWidget {
  static const String route = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey webViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 56),
              child: Image.asset(
                'assets/carp_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
            width: MediaQuery.of(context).size.width,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xff006398),
              borderRadius: BorderRadius.circular(100),
            ),
            child: TextButton(
              onPressed: () {
                showDialog<bool>(
                  context: context,
                  builder: (context) => PopScope(
                    onPopInvokedWithResult: (didPop, result) async {
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        if (didPop && result == true) {
                          Navigator.of(context).pop();
                        }
                      });
                    },
                    child: QRViewExample(),
                  ),
                );
              },
              child: Text(
                locale.translate("scan"),
                style: const TextStyle(color: Color(0xffffffff), fontSize: 22),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
            width: MediaQuery.of(context).size.width,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xff006398),
              borderRadius: BorderRadius.circular(100),
            ),
            child: TextButton(
              onPressed: () async {
                bool isConnected = await bloc.checkConnectivity();
                if (isConnected) {
                  await bloc.backend.initialize();
                  await bloc.backend.authenticate();
                  if (context.mounted) context.go(CarpStudyAppState.homeRoute);
                } else {
                  showDialog<bool>(
                    context: context,
                    builder: (context) => PopScope(
                      onPopInvokedWithResult: (didPop, result) async {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          if (didPop && result == true) {
                            Navigator.of(context).pop();
                          }
                        });
                      },
                      child: EnableInternetConnectionDialog(),
                    ),
                  );
                }
              },
              child: Text(
                locale.translate("pages.login.login"),
                style: const TextStyle(color: Color(0xffffffff), fontSize: 22),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (bloc.backend.isAuthenticated)
            TextButton(
              onPressed: () {
                showDialog<bool>(
                  context: context,
                  builder: (context) => const LogoutMessage(),
                ).then((value) async {
                  if (value == true) {
                    await bloc.backend.signOut();
                    setState(() {});
                  }
                });
              },
              child: Text(locale.translate('pages.login.logout')),
            )
        ]))));
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  qr.Barcode? result;
  qr.QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result != null)
                    Text(
                        'Barcode Type: ${(result!.format)}   Data: ${result!.code}')
                  else
                    const Text('Scan a code'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.toggleFlash();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getFlashStatus(),
                              builder: (context, snapshot) {
                                return Text('Flash: ${snapshot.data}');
                              },
                            )),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.flipCamera();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getCameraInfo(),
                              builder: (context, snapshot) {
                                if (snapshot.data != null) {
                                  return Text(
                                      'Camera facing ${(snapshot.data!)}');
                                } else {
                                  return const Text('loading');
                                }
                              },
                            )),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.pauseCamera();
                          },
                          child: const Text('pause',
                              style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.resumeCamera();
                          },
                          child: const Text('resume',
                              style: TextStyle(fontSize: 20)),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return qr.QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: qr.QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(qr.QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
      });

      final code = scanData.code;

    if (code != null && Uri.tryParse(code)?.hasAbsolutePath == true) {
      final Uri uri = Uri.parse(code);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        await controller.pauseCamera();
        Navigator.of(context).pop();
      } else {
        debugPrint('Could not launch $code');
      }
    }
    });
  }

  void _onPermissionSet(
      BuildContext context, qr.QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }
}
