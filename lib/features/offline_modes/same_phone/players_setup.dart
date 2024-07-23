import 'package:flutter/material.dart';
import 'package:football_challenges/features/offline_modes/same_phone/team_provider.dart';
import 'package:football_challenges/features/offline_modes/same_phone/user_player_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlayerInputScreen extends StatefulWidget {
  const PlayerInputScreen({super.key});

  @override
  _PlayerInputScreenState createState() => _PlayerInputScreenState();
}

class _PlayerInputScreenState extends State<PlayerInputScreen> {
  final _formKey = GlobalKey<FormState>();
  List<TextEditingController> _playerNameControllers = [];

  int _numPlayers = 2; // Default to 2 players

  void _addPlayerFields(int count) {
    _playerNameControllers.clear();
    for (int i = 0; i < count; i++) {
      _playerNameControllers.add(TextEditingController());
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _addPlayerFields(_numPlayers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.playerSetup)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: _numPlayers,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.numberOfPlayers),
                  items: [2, 4].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _numPlayers = value!;
                    _addPlayerFields(_numPlayers);
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _playerNameControllers.length,
                    itemBuilder: (context, index) {
                      return TextFormField(
                        controller: _playerNameControllers[index],
                        decoration: InputDecoration(
                            labelText:
                                '${AppLocalizations.of(context)!.playerName} ${index + 1}'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)!
                                .pleaseEnterAName;
                          } else {
                            for (var i = 0;
                                i < _playerNameControllers.length;
                                i++) {
                              if (value.trim() ==
                                      _playerNameControllers[i].text.trim() &&
                                  i != index) {
                                return AppLocalizations.of(context)!
                                    .theNameIsAlreadyInTheGame;
                              }
                            }
                          }
                          return null;
                        },
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() == true) {
                      List<UserPlayer> players = _playerNameControllers
                          .map((controller) =>
                              UserPlayer(name: controller.text.trim()))
                          .toList();

                      Provider.of<TeamProvider>(context, listen: false)
                          .emptyTeams();
                      Provider.of<TeamProvider>(context, listen: false)
                          .addPlayers(players);
                      GoRouter.of(context)
                          .push('/offline/playerInput/team_management');
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.submit),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
