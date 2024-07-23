import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:football_challenges/core/db_helper.dart';
import 'package:football_challenges/core/style/theme_provider.dart';
import 'package:football_challenges/features/auth/auth_service.dart';
import 'package:football_challenges/models/message_model.dart';
import 'package:football_challenges/widgets/wave_button.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Widget rightMessageWidget(
    BuildContext context, Message message, VoidCallback callback) {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final User? myUser = Provider.of<AuthService>(context, listen: false).myUser;
  Color? _colorWeak = message.cheating == true
      ? (message.correct.toString() == "true"
          ? Colors.green[300]
          : Colors.red[300])
      : Colors.grey;
  Color _colorStrong = message.cheating == true
      ? (message.correct.toString() == "true" ? Colors.green : Colors.red)
      : Colors.grey;
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      (message.cheating!
          ? const SizedBox()
          : ((myUser == null || message.uid != myUser.uid)
              ? PrettyWaveButton(
                  onPressed: callback,
                  child: Text(
                    AppLocalizations.of(context)!.cheating,
                    style: const TextStyle(color: Colors.white),
                  ))
              : const SizedBox())),
      Container(
        width: MediaQuery.of(context).size.width * 0.5,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: Border.all(
                style: BorderStyle.solid, color: Colors.grey, width: 0.5)),
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  message.sender,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                message.text!.isNotEmpty
                    ? Text(
                        message.text.toString(),
                        softWrap: true,
                      )
                    : const SizedBox(),
                SizedBox(
                  height: message.text!.isNotEmpty ? 15 : 0,
                ),
                message.club == null && message.player == null
                    ? const SizedBox()
                    : Container(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: GridTile(
                          header: Container(
                            color: _colorWeak,
                            child: GridTileBar(
                              title: Text(
                                message.club != null
                                    ? message.club!.name
                                    : message.player!.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          footer: message.player != null &&
                                  (message.player!.nameInHomeCountry != null ||
                                      message.player!.fullName != null)
                              ? Container(
                                  color: _colorWeak,
                                  child: GridTileBar(
                                    title: Text(
                                      message.player!.nameInHomeCountry ??
                                          message.player!.fullName ??
                                          "",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                          child: message.club == null && message.player == null
                              ? const SizedBox()
                              : Container(
                                  decoration: BoxDecoration(
                                    color: context
                                                .read<ThemeProvider>()
                                                .themeMode ==
                                            ThemeMode.dark
                                        ? Colors.grey[400]
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _colorStrong,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: message.club != null
                                      ? (message.club!.logo != null
                                          ? Image.memory(message.club!.logo!,
                                              width: 50, height: 50)
                                          : FutureBuilder(
                                              future: _dbHelper.getClubsById(
                                                  message.club!.id),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData) {
                                                  // while data is loading:
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  );
                                                } else {
                                                  // data loaded:

                                                  return Image.memory(
                                                      snapshot.data!.logo!,
                                                      width: 50,
                                                      height: 50);
                                                }
                                              },
                                            ))
                                      : (message.player!.image != null
                                          ? Image.memory(message.player!.image!,
                                              width: 50, height: 50)
                                          : FutureBuilder(
                                              future: _dbHelper.getPlayerById(
                                                  message.player!.id),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData) {
                                                  // while data is loading:
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  );
                                                } else {
                                                  // data loaded:

                                                  return Image.memory(
                                                      snapshot.data!.image!,
                                                      width: 50,
                                                      height: 50);
                                                }
                                              },
                                            )),
                                ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 20),
      CircleAvatar(
          backgroundColor: Colors.grey,
          radius: 20,
          child: ClipOval(
              child: message.image == null
                  ? Image.asset('assets/FoOtBall challenges2.png')
                  : Image.network(message.image!))),
    ],
  );
}
