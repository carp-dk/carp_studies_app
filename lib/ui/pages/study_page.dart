part of carp_study_app;

class StudyPage extends StatefulWidget {
  static const String route = '/study';
  final StudyPageViewModel model;
  const StudyPage({super.key, required this.model});

  @override
  StudyPageState createState() => StudyPageState();
}

class StudyPageState extends State<StudyPage> {
  @override
  Widget build(BuildContext context) {
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
            Flexible(
              child: StreamBuilder<int>(
                stream: widget.model.messageStream,
                builder: (context, AsyncSnapshot<int> snapshot) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await bloc.refreshMessages();
                      final status = await Sensing().tryDeployment();
                      if (status == StudyStatus.Deployed) {
                        bloc.start();
                      }
                      bloc.deploymentService.getStudyDeploymentStatus(
                          widget.model.studyDeploymentId);
                    },
                    child: ListView.builder(
                      // This is +3 bc the first two cards are the study card and the study status card
                      itemCount: bloc.messages.length + 3,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _hasUpdateCard();
                        }
                        if (index == 1) {
                          return _studyCard(
                            context,
                            widget.model.studyDescriptionMessage,
                            onTap: () {
                              context.push(StudyDetailsPage.route);
                            },
                          );
                        }
                        if (index == 2) {
                          return _studyStatusCard();
                        }
                        // This is -3 bc the first two cards are the study card and the study status card and we don't want to show them in the list
                        return _announcementCard(
                            context, bloc.messages[index - 3]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hasUpdateCard() {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return FutureBuilder<bool?>(
        future: bloc.getAppHasUpdate(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return StudiesMaterial(
              backgroundColor: Theme.of(context).extension<RPColors>()!.grey50!,
              elevation: 10,
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).extension<RPColors>()!.grey600!,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(16.0)),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            locale.translate('pages.about.app_update'),
                            style: aboutCardSubtitleStyle.copyWith(
                              color: Theme.of(context)
                                  .extension<RPColors>()!
                                  .grey900,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: ElevatedButton(
                          onPressed: () async {
                            _redirectToUpdateStore();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CACHET.DEPLOYMENT_DEPLOYING,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            locale.translate("get"),
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return SizedBox.shrink();
          }
        });
  }

  Widget _studyCard(
    BuildContext context,
    Message message, {
    Function? onTap,
  }) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    // Initialization the language of the timeago package
    timeago.setLocaleMessages('da', timeago.DaMessages());
    timeago.setLocaleMessages('es', timeago.EsMessages());

    return StudiesMaterial(
      backgroundColor: Theme.of(context).extension<RPColors>()!.grey50!,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap();
          } else {
            context.push('${MessageDetailsPage.route}/${message.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (message.image != null && message.image != '')
                Center(
                  child: Container(
                    height: 150,
                    color: Theme.of(context).colorScheme.secondary,
                    child: widget.model.getMessageImage(message.image),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(locale.translate(message.title!),
                    style: aboutStudyCardTitleStyle.copyWith(
                        color:
                            Theme.of(context).extension<RPColors>()!.primary)),
              ),
              if (message.subTitle != null && message.subTitle!.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        locale.translate(message.subTitle!),
                        style: aboutCardContentStyle.copyWith(
                          color:
                              Theme.of(context).extension<RPColors>()!.grey700,
                        ),
                      ),
                    ),
                  ],
                ),
              if (message.message != null && message.message!.isNotEmpty)
                Row(children: [
                  Expanded(
                      child: Text(
                    "${locale.translate(message.message!).substring(0, (message.message!.length > 150) ? 150 : null)}...",
                    style: aboutCardContentStyle.copyWith(
                        color:
                            Theme.of(context).extension<RPColors>()!.grey900),
                    textAlign: TextAlign.start,
                  )),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  void _redirectToUpdateStore() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    Uri url;
    if (Platform.isAndroid) {
      url = Uri.parse(
          'https://play.google.com/store/apps/details?id=${packageInfo.packageName}');
    } else if (Platform.isIOS) {
      url = Uri.parse('https://apps.apple.com/app/id1569798025');
    } else {
      throw 'Unsupported platform';
    }
    var canLaunch = await canLaunchUrl(url);
    if (canLaunch) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _studyStatusCard() {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return FutureBuilder<StudyDeploymentStatus?>(
      future: bloc.studyDeploymentStatus,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            child: Text('Error: ${snapshot.error}'),
          ); // Show an error message if the future fails
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ); // Handle the case where data is null
        }

        final deploymentStatus = snapshot.data!.status;

        return Card(
          margin: const EdgeInsets.all(16.0),
          color: Theme.of(context).extension<RPColors>()!.grey50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).extension<RPColors>()!.grey600!,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(16.0)),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 22.0),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0, vertical: 4),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    studyStatusColors[deploymentStatus],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Text(
                                deploymentStatus ==
                                        StudyDeploymentStatusTypes
                                            .DeployingDevices
                                    ? locale.translate(
                                        'pages.about.status.deploying_devices')
                                    : deploymentStatus
                                        .toString()
                                        .split('.')
                                        .last,
                                maxLines: 2,
                                style: aboutCardSubtitleStyle.copyWith(
                                    color: studyStatusColors[deploymentStatus]),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(
                              getStatusText(locale, deploymentStatus, snapshot),
                              style: aboutCardSubtitleStyle.copyWith(
                                color: Theme.of(context)
                                    .extension<RPColors>()!
                                    .grey900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String getStatusText(
    RPLocalizations locale,
    StudyDeploymentStatusTypes deploymentStatusType,
    AsyncSnapshot<StudyDeploymentStatus?> snapshot,
  ) {
    if (deploymentStatusType == StudyDeploymentStatusTypes.DeployingDevices) {
      return locale.translate('pages.about.status.deploying_devices.message') +
          snapshot.data!.deviceStatusList.first
              .remainingDevicesToRegisterBeforeDeployment!
              .join(' | ');
    } else {
      return locale.translate(studyStatusText[deploymentStatusType]!);
    }
  }

  static Map<StudyDeploymentStatusTypes, Color> studyStatusColors = {
    StudyDeploymentStatusTypes.Invited: CACHET.DEPLOYMENT_INVITED,
    StudyDeploymentStatusTypes.DeployingDevices: CACHET.DEPLOYMENT_DEPLOYING,
    StudyDeploymentStatusTypes.Running: CACHET.DEPLOYMENT_RUNNING,
    StudyDeploymentStatusTypes.Stopped: CACHET.DEPLOYMENT_STOPPED,
  };

  static Map<StudyDeploymentStatusTypes, String> studyStatusText = {
    StudyDeploymentStatusTypes.Invited: 'pages.about.status.invited.message',
    StudyDeploymentStatusTypes.DeployingDevices:
        'pages.about.status.deploying_devices.message',
    StudyDeploymentStatusTypes.Running: 'pages.about.status.running.message',
    StudyDeploymentStatusTypes.Stopped: 'pages.about.status.stopped.message',
  };

  Widget _announcementCard(
    BuildContext context,
    Message message, {
    Function? onTap,
  }) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    // Initialization the language of the timeago package
    timeago.setLocaleMessages('da', timeago.DaMessages());
    timeago.setLocaleMessages('es', timeago.EsMessages());

    return Container(
      child: StudiesMaterial(
        backgroundColor: Theme.of(context).extension<RPColors>()!.grey50!,
        hasBox: true,
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap();
            } else {
              context.push('${MessageDetailsPage.route}/${message.id}');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 8.0, bottom: 8, right: 8),
                        child: Text(
                          locale.translate(message.title!),
                          overflow: TextOverflow.ellipsis,
                          style: aboutCardTitleStyle.copyWith(
                            color: Theme.of(context)
                                .extension<RPColors>()!
                                .grey900,
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: CACHET.DEPLOYMENT_DEPLOYING,
                      borderRadius: BorderRadius.circular(100.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            locale.translate(message.type
                                .toString()
                                .split('.')
                                .last
                                .toLowerCase()),
                            style: aboutCardSubtitleStyle.copyWith(
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      if (message.subTitle != null &&
                          message.subTitle!.isNotEmpty)
                        Expanded(
                          child: Text(
                            locale.translate(message.subTitle!),
                            style: aboutCardContentStyle.copyWith(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                      Spacer(),
                      Text(
                        timeago.format(message.timestamp.toLocal()),
                        style: aboutCardTimeAgoStyle.copyWith(
                          color:
                              Theme.of(context).extension<RPColors>()!.grey600,
                        ),
                      )
                    ],
                  ),
                ),
                if (message.message != null && message.message!.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                          child: Text(
                        locale.translate(message.message!).length > 150
                            ? '${locale.translate(message.message!).substring(0, 150)}...'
                            : locale.translate(message.message!),
                        style: aboutCardContentStyle,
                        textAlign: TextAlign.start,
                      )),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension CopyWithAdditional on DateTime {
  DateTime copyWithAdditional({
    int years = 0,
    int months = 0,
    int days = 0,
    int hours = 0,
    int minutes = 0,
    int seconds = 0,
    int milliseconds = 0,
    int microseconds = 0,
  }) {
    return DateTime(
      year + years,
      month + months,
      day + days,
      hour + hours,
      minute + minutes,
      second + seconds,
      millisecond + milliseconds,
      microsecond + microseconds,
    );
  }
}
