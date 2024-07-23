import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:football_challenges/core/ads/ads_controller.dart';
import 'package:football_challenges/core/style/snack_bar.dart';
import 'package:football_challenges/features/auth/auth_service.dart';
import 'package:football_challenges/models/club_model.dart';
import 'package:football_challenges/models/message_model.dart';
import 'package:football_challenges/models/player_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnlineRondoProvider with ChangeNotifier {
  int teamAScore = 0;
  int teamBScore = 0;
  int turn = 0;
  List turns = [];
  int winScore = 1;
  Timer? timer;
  int remainingTime = 0;
  String roomId = "";
  late BuildContext context;
  bool isClub = false;
  Club? currentClub;
  Player? currentPlayer;
  Set<int> usedPlayers = {};

  Future<void> addMessage(Message m) async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);

    try {
      await roomRef.collection('messages').add({
        'sender': m.sender,
        'text': m.text,
        'arabicText': m.arabicText,
        'arabicReason': m.arabicReason,
        'reason': m.reason,
        'club': m.club?.toMap(),
        'player': m.player?.toMap(),
        'correct': m.correct,
        'cheating': m.cheating,
        'first': m.first,
        'image': m.image,
        'uid': m.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      showSnackBar(e.toString());
    }
  }

  Future<void> updateCurrentClub(Club club) async {
    final roomDoc = FirebaseFirestore.instance.collection('rooms').doc(roomId);

    // Update the document in Firestore
    await roomDoc.update({'currentClub': club.toMap()});
  }

  Future<void> updateCheatingForMessage(int diff) async {
    final colRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection("messages");
    final roomDocs = await colRef.orderBy('timestamp', descending: false).get();

    var messagesData = roomDocs.docs;

    var targetMessage = messagesData[messagesData.length - diff];

    // Update the document in Firestore
    await colRef.doc(targetMessage.id).update({'cheating': true});
  }

  void initialize(
      int playerTime, int win, BuildContext con, List turnss, String room) {
    remainingTime = playerTime;
    winScore = win;
    context = con;
    turns = turnss;
    roomId = room;
  }

  void teamAScored() async {
    teamAScore++;
  }

  void teamBScored() async {
    teamBScore++;
  }

  void nextTurn(int playerTime) async {
    turn++;
    if (turns.length == 2) {
      turn = turn % 2;
    } else {
      turn = turn % 4;
    }
    final roomDoc = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    remainingTime = playerTime;

    await roomDoc.update({'turn': turn});

    notifyListeners();
  }

  Future<void> selectClub(int playerTime, Message m) async {
    remainingTime = playerTime;
    final roomDoc = FirebaseFirestore.instance.collection('rooms').doc(roomId);

    turn++;
    if (turns.length == 2) {
      turn = turn % 2;
    } else {
      turn = turn % 4;
    }

    await addMessage(m);
    await updateCheatingForMessage(2);

    // Update the document in Firestore
    await roomDoc.update({
      'turn': turn,
      'isClub': isClub,
      'currentClub': currentClub!.toMap(),
    });
  }

  Future<void> cheating(int playerTime, Message m) async {
    remainingTime = playerTime;
    final roomDoc = FirebaseFirestore.instance.collection('rooms').doc(roomId);

    await addMessage(m);
    await updateCheatingForMessage(2);

    turn++;
    if (turns.length == 2) {
      turn = turn % 2;
    } else {
      turn = turn % 4;
    }

    if (!isClub) {
      await addMessage(Message(
          sender: "Game Master",
          first: true,
          uid: "xxx",
          text:
              "${turns[turn]['name']} Turn!\nFind a player that played for ${currentClub!.name}",
          arabicText:
              "دور ${turns[turn]['name']}!\nابحث عن لاعب لعب لـ ${currentClub!.name}"));
    } else if (isClub) {
      await addMessage(Message(
          sender: "Game Master",
          uid: "xxx",
          first: true,
          text:
              "${turns[turn]['name']} Turn!\nFind a Club that ${currentPlayer!.name} played for",
          arabicText:
              "دور ${turns[turn]['name']}!\nابحث عن نادٍ ${currentPlayer!.name} لعب لـه"));
    }
    // Update the document in Firestore
    await roomDoc.update({
      'turn': turn,
      'teamAScore': teamAScore,
      'teamBScore': teamBScore,
    });
  }

  Future<void> selectPlayer(int playerTime, Message m) async {
    remainingTime = playerTime;
    final roomDoc = FirebaseFirestore.instance.collection('rooms').doc(roomId);

    turn++;
    if (turns.length == 2) {
      turn = turn % 2;
    } else {
      turn = turn % 4;
    }

    await addMessage(m);
    await updateCheatingForMessage(2);

    // Update the document in Firestore
    await roomDoc.update({
      'turn': turn,
      'isClub': isClub,
      'currentPlayer': currentPlayer!.toMap(),
      'usedPlayers': FieldValue.arrayUnion([currentPlayer!.id])
    });
  }

  Future<void> timeOver(int playerTime) async {
    remainingTime = playerTime;

    final User? myUser =
        Provider.of<AuthService>(context, listen: false).myUser;
    if (turns[turn]['uid'] == myUser!.uid) {
      late Message m;
      if (turns[turn]['team'] == 'A') {
        teamBScore++;
        m = Message(
            sender: "Game Master",
            first: true,
            uid: "xxx",
            text:
                "${turns[turn]['name']} didn't answer fast enough!\na point goes for team B",
            arabicText:
                "${turns[turn]['name']} لم يجيب بسرعة كافية!\nنقطة تذهب لفريق B");
      } else if (turns[turn]['team'] == 'B') {
        teamAScore++;
        m = Message(
            sender: "Game Master",
            first: true,
            uid: "xxx",
            text:
                "${turns[turn]['name']} didn't answer fast enough!\na point goes for team A",
            arabicText:
                "${turns[turn]['name']} لم يجيب بسرعة كافية!\nنقطة تذهب لفريق A");
      }
      turn++;
      if (turns.length == 2) {
        turn = turn % 2;
      } else {
        turn = turn % 4;
      }
      final roomDoc =
          FirebaseFirestore.instance.collection('rooms').doc(roomId);

      await addMessage(m);
      await updateCheatingForMessage(2);
      if (!isClub) {
        await addMessage(Message(
            sender: "Game Master",
            first: true,
            uid: "xxx",
            text:
                "${turns[turn]['name']} Turn!\nFind a player from ${currentClub!.name}",
            arabicText:
                "دور ${turns[turn]['name']}!\nابحث عن لاعب لعب لـ ${currentClub!.name}"));
      } else if (isClub) {
        await addMessage(Message(
            sender: "Game Master",
            uid: "xxx",
            first: true,
            text:
                "${turns[turn]['name']} Turn!\nFind a Club that ${currentPlayer!.name} played for",
            arabicText:
                "دور ${turns[turn]['name']}!\nابحث عن نادٍ ${currentPlayer!.name} لعب لـه"));
      }
      await roomDoc.update(
          {'turn': turn, 'teamAScore': teamAScore, 'teamBScore': teamBScore});
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
      final roomDoc =
          FirebaseFirestore.instance.collection('rooms').doc(roomId);

      final adsController = context.read<AdsController>();
      // Let the player see the game just after winning for a bit.

      await Future<void>.delayed(const Duration(seconds: 1));
      adsController.showInterstitialAd();
      await roomDoc.update({
        'gameState': "Finished",
      });
      GoRouter.of(context)
          .go('/won', extra: {'players': turns, 'won': 'A', 'lost': 'B'});
    } else if (teamBScore == winScore) {
      final roomDoc =
          FirebaseFirestore.instance.collection('rooms').doc(roomId);

      final adsController = context.read<AdsController>();
      await roomDoc.update({
        'gameState': "Finished",
      });
      // Let the player see the game just after winning for a bit.
      await Future<void>.delayed(const Duration(seconds: 1));
      adsController.showInterstitialAd();

      GoRouter.of(context)
          .go('/won', extra: {'players': turns, 'won': 'B', 'lost': 'A'});
    }
  }

  void startTimer(int playerTime) {
    remainingTime = playerTime;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (remainingTime > 0) {
        remainingTime--;
      } else {
        final progress = ProgressHUD.of(context);
        progress!.show();

        await timeOver(playerTime);
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
