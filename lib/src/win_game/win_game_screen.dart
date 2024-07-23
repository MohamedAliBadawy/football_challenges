// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:football_challenges/core/ads/ads_controller.dart';
import 'package:football_challenges/core/ads/banner_ad_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/in_app_purchase/in_app_purchase.dart';
import '../../core/style/responsive_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WinGameScreen extends StatelessWidget {
  final String wonTeam;
  final String lostTeam;
  final List<dynamic> players;

  const WinGameScreen({
    super.key,
    required this.wonTeam,
    required this.lostTeam,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    final adsControllerAvailable = context.watch<AdsController?>() != null;
    final adsRemoved =
        context.watch<InAppPurchaseController?>()?.adRemoval.active ?? false;

    const gap = SizedBox(height: 10);
    List<String> teamA = [];
    List<String> teamB = [];

    for (var i = 0; i < players.length; i++) {
      if (players[i]['team'] == 'A') {
        teamA.add(players[i]['name'].toString());
      } else if (players[i]['team'] == 'B')
        teamB.add(players[i]['name'].toString());
    }
    return Scaffold(
      body: ResponsiveScreen(
        squarishMainArea: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (adsControllerAvailable && !adsRemoved) ...[
              const Expanded(
                child: Center(
                  child: BannerAdWidget(),
                ),
              ),
            ],
            gap,
            const Center(
/*               child: Text(
                'You won!',
                style: TextStyle(fontFamily: 'Permanent Marker', fontSize: 50),
              ), */
                ),
            gap,
            Center(
              child: Text(
                '${AppLocalizations.of(context)!.team} $wonTeam ${AppLocalizations.of(context)!.won}\n'
                '${AppLocalizations.of(context)!.players}: ${wonTeam == 'A' ? teamA : teamB} \n'
                '${AppLocalizations.of(context)!.team} $lostTeam ${AppLocalizations.of(context)!.lost}\n'
                '${AppLocalizations.of(context)!.players}: ${lostTeam == 'A' ? teamA : teamB} \n',
                style: const TextStyle(
                    fontFamily: 'Permanent Marker', fontSize: 40),
              ),
            ),
          ],
        ),
        rectangularMenuArea: FilledButton(
          onPressed: () {
            GoRouter.of(context).go('/');
          },
          child: Text(AppLocalizations.of(context)!.home),
        ),
      ),
    );
  }
}
