import 'package:flutter/material.dart';
import 'package:football_challenges/core/style/snack_bar.dart';
import 'package:football_challenges/features/offline_modes/same_phone/selection_provider.dart';
import 'package:football_challenges/features/offline_modes/same_phone/user_player_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'team_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TeamManagementScreen extends StatelessWidget {
  const TeamManagementScreen({
    super.key,
  });

  void _showPlayerSelectionDialog(BuildContext context, String team) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectAPlayer),
          content: Consumer<TeamProvider>(
            builder: (context, teamProvider, child) {
              List<UserPlayer> availablePlayers =
                  (team == 'A' ? teamProvider.teamB : teamProvider.teamA);

              return SingleChildScrollView(
                child: ListBody(
                  children: availablePlayers.map((player) {
                    return ListTile(
                      title: Text(player.name),
                      onTap: () {
                        teamProvider.movePlayerToTeam(player, team);
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.teamManagement)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Consumer<TeamProvider>(
                builder: (context, teamProvider, child) {
                  return Column(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${AppLocalizations.of(context)!.team} A',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: ListView.builder(
                                itemCount: teamProvider.teamA.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                        backgroundColor: Colors.grey,
                                        radius: 20,
                                        child: ClipOval(
                                            child: Image.asset(
                                                'assets/FoOtBall challenges2.png'))),
                                    title: Text(teamProvider.teamA[index].name),
                                  );
                                },
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  _showPlayerSelectionDialog(context, 'A'),
                              child: Text(
                                  '${AppLocalizations.of(context)!.addToTeam} A'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${AppLocalizations.of(context)!.team} B',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: ListView.builder(
                                itemCount: teamProvider.teamB.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                        backgroundColor: Colors.grey,
                                        child: ClipOval(
                                            child: Image.asset(
                                                'assets/FoOtBall challenges2.png')),
                                        radius: 20),
                                    title: Text(teamProvider.teamB[index].name),
                                  );
                                },
                              ),
                            ),
                            Flexible(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _showPlayerSelectionDialog(context, 'B'),
                                child: Text(
                                    '${AppLocalizations.of(context)!.addToTeam} B'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (Provider.of<TeamProvider>(context, listen: false).teamA.length !=
              Provider.of<TeamProvider>(context, listen: false).teamB.length) {
            showSnackBar(AppLocalizations.of(context)!.teamsMustBeEven);
            return;
          }

          GoRouter.of(context).push('/offline/offline_chat_game', extra: {
            'teamA': Provider.of<TeamProvider>(context, listen: false).teamA,
            'teamB': Provider.of<TeamProvider>(context, listen: false).teamB,
            'winScore': Provider.of<SelectionProvider>(context, listen: false)
                .selectedScore,
            'playerTime': Provider.of<SelectionProvider>(context, listen: false)
                .selectedTime,
            'leagueIds':
                Provider.of<SelectionProvider>(context, listen: false).leagues,
            'initialClub':
                Provider.of<SelectionProvider>(context, listen: false).club,
          });
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
