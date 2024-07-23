import 'package:flutter/material.dart';
import 'package:football_challenges/core/db_helper.dart';
import 'package:football_challenges/core/style/theme_provider.dart';
import 'package:football_challenges/models/message_model.dart';
import 'package:football_challenges/widgets/wave_button.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Widget onlineLeftMessageWidget(
    BuildContext context, Message message, VoidCallback callback) {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      CircleAvatar(
          backgroundColor: Colors.grey,
          radius: 20,
          child: ClipOval(
              child: message.image == null
                  ? Image.asset('assets/FoOtBall challenges2.png')
                  : Image.network(message.image!))),
      const SizedBox(width: 20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  message.sender == "Game Master"
                      ? AppLocalizations.of(context)!.gameMaster
                      : message.sender,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 15,
                ),
                message.text!.isNotEmpty
                    ? Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? message.arabicText.toString()
                            : message.text.toString(),
                        softWrap: true,
                      )
                    : const SizedBox(),
                SizedBox(
                  height: message.text!.isNotEmpty ? 15 : 0,
                ),
                message.club == null && message.player == null
                    ? SizedBox()
                    : Container(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: GridTile(
                          header: Container(
                            color: message.first!
                                ? Colors.green[300]
                                : (message.cheating == true
                                    ? (message.correct.toString() == "true"
                                        ? Colors.green[300]
                                        : Colors.red[300])
                                    : Colors.grey),
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
                                  color: message.first!
                                      ? Colors.green[300]
                                      : (message.cheating == true
                                          ? (message.correct.toString() ==
                                                  "true"
                                              ? Colors.green[300]
                                              : Colors.red[300])
                                          : Colors.grey),
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
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.read<ThemeProvider>().themeMode ==
                                      ThemeMode.dark
                                  ? Colors.grey[400]
                                  : Colors.transparent,
                              border: Border.all(
                                color: message.first!
                                    ? Colors.green
                                    : (message.cheating == true
                                        ? (message.correct.toString() == "true"
                                            ? Colors.green
                                            : Colors.red)
                                        : Colors.grey),
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: message.club != null
                                ? (message.club!.logo != null
                                    ? Image.memory(message.club!.logo!,
                                        width: 50, height: 50)
                                    : FutureBuilder(
                                        future: _dbHelper
                                            .getClubsById(message.club!.id),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            // while data is loading:
                                            return Center(
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
                                        future: _dbHelper
                                            .getPlayerById(message.player!.id),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            // while data is loading:
                                            return Center(
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
      message.first!
          ? const SizedBox()
          : (message.cheating!
              ? const SizedBox()
              : PrettyWaveButton(
                  onPressed: callback,
                  child: Text(
                    AppLocalizations.of(context)!.cheating,
                    style: const TextStyle(color: Colors.white),
                  )))
    ],
  );
}
