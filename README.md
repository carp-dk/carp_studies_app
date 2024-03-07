# CARP Studies App

The CARP Studies App is designed to run generic studies using the [CARP Mobile Sensing](https://pub.dev/packages/carp_mobile_sensing) (CAMS) Framework, which is part of the [Copenhagen Research Platform](https://carp.cachet.dk) (CARP) from the [Department of Health Technology](https://www.healthtech.dtu.dk/) at the Technical University of Denmark.

It follows a basic Business Logic Component (BLoC) combined with a Model-View-View-Model architecture, as described in the [CARP Mobile Sensing Demo App](https://github.com/cph-cachet/carp.sensing-flutter/tree/master/apps/carp_mobile_sensing_app).

Read more about the [CARP Studies app](https://carp.cachet.dk/carp-studies-app/) on the CARP Homepage.

## Deployment Mode

This study app can run in two basic modes - using CAWS or locally. Deployment mode is set using the environment variable `deployment-mode` file. In Flutter environment variables are set by specifying the `--dart-define` option in flutter run. For example;

```shell
flutter run --dart-define="deployment-mode=local" --dart-define="debug-level=debug"
```

would run the app in local deployment mode with debug level set to info.

In VSCode you can add a `launch.json` file to specify different deployment modes.

### Local Deployment

Local mode is intended for designing and debugging a study protocol, informed consent, translations, and messages. In local deployment mode, the app loads its configuration from json files stored in the `assets/carp/...` folder structure. This folder structure follows the default structure of the [CARP Study Generator Utility Package](https://github.com/cph-cachet/carp.sensing-flutter/tree/main/utilities/carp_study_generator), i.e. that

* `protocol.json` and `consent.json` files goes to `carp/resources`
* language file goes to `carp/lang`
* message files goes to `carp/messages`

> **Note:** Since the app buffers the protocol locally on the phone, you need to delete the app and its data on the phone when changing or updating the protocol.

### CAWS Deployment

When using CAWS, deployment mode can be set to either `dev`, `test`, or `production`. In all of these cases, the app will try to authenticate to CAWS and download all resources - study protocol, informed consent, translations, and messages - from CAWS. These resources should be added to CAWS before use, and each participant should be added to a study and deployed, before it can be downloaded to the app.
