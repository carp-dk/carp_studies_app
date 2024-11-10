part of carp_study_app;

class InvitationListPage extends StatelessWidget {
  static const String route = '/invitations';
  final InvitationsViewModel model;
  const InvitationListPage({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Scaffold(
      backgroundColor:
          Theme.of(context).extension<CarpColors>()!.backgroundGray,
      body: FutureBuilder<List<ActiveParticipationInvitation>>(
        future: bloc.backend.getInvitations(),
        builder: (context, snapshot) {
          Widget child;

          if (snapshot.hasData) {
            child = SliverFixedExtentList(
              itemExtent: 150,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Container(
                    child: InvitationMaterial(
                      invitation: snapshot.data![index],
                    ),
                  );
                },
                childCount: snapshot.data!.length,
              ),
            );
          } else {
            child = const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor:
                    Theme.of(context).extension<CarpColors>()!.backgroundGray,
                title: const CarpAppBar(),
                centerTitle: true,
                pinned: true,
                stretch: true,
                stretchTriggerOffset: 20,
                scrolledUnderElevation: 0,
                onStretchTrigger: () async => bloc.backend.getInvitations(),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: IntrinsicHeight(
                    child: Stack(
                      children: [
                        Positioned(
                          left: 8,
                          top: 0,
                          bottom: 0,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(LoginPage.route);
                              }
                            },
                          ),
                        ),
                        Center(
                          child: Text(
                            locale.translate('invitation.invitations'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                      bottom: 8.0, left: 16.0, right: 16.0),
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      locale.translate('invitation.subtitle'),
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ),
              ),
              child,
            ],
          );
        },
      ),
    );
  }
}

class InvitationMaterial extends StatelessWidget {
  final ActiveParticipationInvitation invitation;

  const InvitationMaterial({
    super.key,
    required this.invitation,
  });

  @override
  Widget build(BuildContext context) {
    return StudiesMaterial(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.white!,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          context.push(
              '${InvitationDetailsPage.route}/${invitation.participation.participantId}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                invitation.invitation.name,
                maxLines: 1,
                style: studyTitleStyle.copyWith(
                    color: CACHET.TASK_COMPLETED_BLUE,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(
                invitation.invitation.description ?? '',
                maxLines: 2,
                style: studyDetailsInfoTitle.copyWith(
                  color: Theme.of(context).extension<CarpColors>()!.grey900,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
