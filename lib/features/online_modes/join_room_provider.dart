import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:football_challenges/core/ads/ads_controller.dart';
import 'package:football_challenges/core/style/snack_bar.dart';
import 'package:football_challenges/features/auth/auth_service.dart';
import 'package:football_challenges/models/club_model.dart';
import 'package:football_challenges/models/message_model.dart';
import 'package:football_challenges/models/player_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class JoinRoomProvider with ChangeNotifier {
  late BuildContext context;
}
