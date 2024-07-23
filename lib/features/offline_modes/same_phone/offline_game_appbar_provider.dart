import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:football_challenges/core/ads/ads_controller.dart';
import 'package:football_challenges/models/message_model.dart';
import 'package:football_challenges/features/offline_modes/same_phone/user_player_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OfflineGameAppbarProvider with ChangeNotifier {
  int teamAScore = 0;
  int teamBScore = 0;
  List<UserPlayer> turns = [];
  List<Message> messages = [];
  int turn = 0;
  int winScore = 1;
  Timer? timer;
  int remainingTime = 0; //initial time in seconds
  late BuildContext context;

  void initialize(int initialClub, List<UserPlayer> teamA,
      List<UserPlayer> teamB, int playerTime, int win, BuildContext con) {
    remainingTime = playerTime;
    winScore = win;
    context = con;
    if (teamA.length == 1) {
      turns.add(teamA[0]);
      turns.add(teamB[0]);
    } else if (teamA.length == 2) {
      turns.add(teamA[0]);
      turns.add(teamB[0]);
      turns.add(teamA[1]);
      turns.add(teamB[1]);
    }
    startTimer(playerTime);
  }

  void teamAScored() {
    teamAScore++;
    evaluate();
    notifyListeners();
  }

  void teamBScored() {
    teamBScore++;
    evaluate();
    notifyListeners();
  }

  void nextTurn(int playerTime) {
    remainingTime = playerTime;
    turn++;
    if (turns.length == 2) {
      turn = turn % 2;
    } else {
      turn = turn % 4;
    }
    notifyListeners();
  }

  int lastTurn() {
    int res;
    if (turns.length == 2) {
      if (turn == 0) {
        res = 1;
      } else {
        res = turn - 1;
      }
    } else {
      if (turn == 0) {
        res = 1;
      } else {
        res = turn - 1;
      }
    }
    return res;
  }

  void evaluate() async {
    if (teamAScore == winScore) {
      final adsController = context.read<AdsController>();
      // Let the player see the game just after winning for a bit.
      await Future<void>.delayed(const Duration(seconds: 1));
      adsController.showInterstitialAd();

      GoRouter.of(context).go('/won', extra: {
        'players': turns.map((player) => player.toMap()).toList(),
        'won': 'A',
        'lost': 'B'
      });
    } else if (teamBScore == winScore) {
      final adsController = context.read<AdsController>();

      // Let the player see the game just after winning for a bit.
      await Future<void>.delayed(const Duration(seconds: 1));
      adsController.showInterstitialAd();

      GoRouter.of(context).go('/won', extra: {
        'players': turns.map((player) => player.toMap()).toList(),
        'won': 'B',
        'lost': 'A'
      });
    }

    notifyListeners();
  }

  void startTimer(int playerTime) {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        remainingTime--;
      } else {
        final progress = ProgressHUD.of(context);
        progress!.show();

        if (turns[turn].team == 'A') {
          teamBScore++;
          messages.add(Message(
              sender: AppLocalizations.of(context)!.gameMaster,
              first: true,
              uid: "xxx",
              text:
                  "${turns[turn].name} ${AppLocalizations.of(context)!.didntAnswerFastEnough}!\n${AppLocalizations.of(context)!.aPointGoesForTeam} B"));
        } else if (turns[turn].team == 'B') {
          teamAScore++;
          messages.add(Message(
              sender: AppLocalizations.of(context)!.gameMaster,
              first: true,
              uid: "xxx",
              text:
                  "${turns[turn].name} ${AppLocalizations.of(context)!.didntAnswerFastEnough}!\n${AppLocalizations.of(context)!.aPointGoesForTeam} A"));
        }
        messages[messages.length - 2].cheating = true;
        evaluate();
        nextTurn(playerTime);
        if (messages[messages.length - 1].player != null) {
          messages.add(Message(
              sender: AppLocalizations.of(context)!.gameMaster,
              first: true,
              uid: "xxx",
              text:
                  "${turns[turn].name} ${AppLocalizations.of(context)!.turn}!\n${AppLocalizations.of(context)!.findAPlayerThatPlayedFor} ${messages[messages.length - 1].club!.name}"));
        } else if (messages[messages.length - 1].club != null) {
          messages.add(Message(
              sender: AppLocalizations.of(context)!.gameMaster,
              uid: "xxx",
              first: true,
              text:
                  "${turns[turn].name} ${AppLocalizations.of(context)!.turn}!\n${AppLocalizations.of(context)!.findAClubThat} ${messages[messages.length - 1].player!.name} ${AppLocalizations.of(context)!.playedFor}"));
        }

        startTimer(playerTime);
        progress.dismiss();
      }

      notifyListeners();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
