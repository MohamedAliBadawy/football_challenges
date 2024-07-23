import 'package:football_challenges/models/club_model.dart';
import 'package:football_challenges/models/player_model.dart';

class Message {
  final String sender;
  final String? text;
  final String? arabicText;
  final String? reason;
  final String? arabicReason;
  final Club? club;
  final Player? player;
  final bool? correct;
  bool? cheating;
  bool? first;
  String? image;
  final String uid;

  Message(
      {required this.sender,
      this.text,
      this.club,
      this.player,
      this.correct,
      this.cheating = false,
      this.first = false,
      this.reason,
      this.image,
      required this.uid,
      this.arabicText,
      this.arabicReason});

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'text': text,
      'arabicText': arabicText,
      'reason': reason,
      'arabicReason': arabicReason,
      'club': club?.id,
      'player': player?.id,
      'correct': correct,
      'cheating': cheating,
      'first': first,
      'image': image,
    };
  }

  static Message fromMap(Map<String, dynamic> map) {
    return Message(
      sender: map['sender'],
      text: map['text'],
      arabicText: map['arabicText'],
      reason: map['reason'],
      arabicReason: map['arabicReason'],
      club: map['club'] == null ? null : Club.fromMap(map['club']),
      player: map['player'] == null ? null : Player.fromMap(map['player']),
      correct: map['correct'],
      cheating: map['cheating'],
      first: map['first'],
      image: map['image'],
      uid: map['uid'],
    );
  }
}
