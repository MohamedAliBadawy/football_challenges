// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'preloaded_banner_ad.dart';

/// Allows showing ads. A facade for `package:google_mobile_ads`.
class AdsController {
  final MobileAds _instance;

  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 5;

  PreloadedBannerAd? _preloadedAd;

  /// Creates an [AdsController] that wraps around a [MobileAds] [instance].
  ///
  /// Example usage:
  ///
  ///     var controller = AdsController(MobileAds.instance);
  AdsController(MobileAds instance) : _instance = instance;

  void dispose() {
    _preloadedAd?.dispose();
    _interstitialAd?.dispose();
  }

  /// Initializes the injected [MobileAds.instance].
  Future<void> initialize() async {
    loadInterstitialAd();
    await _instance.initialize();
  }

  /// Starts preloading an ad to be used later.
  ///
  /// The work doesn't start immediately so that calling this doesn't have
  /// adverse effects (jank) during start of a new screen.
  void preloadAd() {
    // TODO: When ready, change this to the Ad Unit IDs provided by AdMob.
    //       The current values are AdMob's sample IDs.
    final adUnitId = defaultTargetPlatform == TargetPlatform.android
        ? 'ca-app-pub-1357441394398917/6668784198'
        // iOS
        : 'ca-app-pub-3940256099942544/2934735716';
    _preloadedAd =
        PreloadedBannerAd(size: AdSize.mediumRectangle, adUnitId: adUnitId);

    // Wait a bit so that calling at start of a new screen doesn't have
    // adverse effects on performance.
    Future<void>.delayed(const Duration(seconds: 1)).then((_) {
      return _preloadedAd!.load();
    });
  }

  void loadInterstitialAd() {
    final adUnitId = defaultTargetPlatform == TargetPlatform.android
        ? 'ca-app-pub-1357441394398917/9637760130'
        : 'ca-app-pub-1357441394398917/9637760130';
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_numInterstitialLoadAttempts <= maxFailedLoadAttempts) {
            loadInterstitialAd();
          }
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd == null) {
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) => print('Ad showed.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('Ad dismissed.');
        ad.dispose();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('Ad failed to show.');
        ad.dispose();
        loadInterstitialAd();
      },
      onAdImpression: (InterstitialAd ad) => print('Ad impression.'),
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  /// Allows caller to take ownership of a [PreloadedBannerAd].
  ///
  /// If this method returns a non-null value, then the caller is responsible
  /// for disposing of the loaded ad.
  PreloadedBannerAd? takePreloadedAd() {
    final ad = _preloadedAd;
    _preloadedAd = null;
    return ad;
  }
}
