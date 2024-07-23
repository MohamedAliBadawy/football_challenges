// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List<String> soundTypeToFilename(SfxType type) {
  switch (type) {
    case SfxType.refereeWhistleBlow:
      return const [
        'referee_whistle_blow.mp3',
      ];

    case SfxType.buttonTap:
      return const [
        'soccer_kick.mp3',
        'soccer_ball_kick.mp3',
      ];
  }
}

/// Allows control over loudness of different SFX types.
double soundTypeToVolume(SfxType type) {
  switch (type) {
    case SfxType.refereeWhistleBlow:
      return 0.4;

    case SfxType.buttonTap:
      return 1.0;
  }
}

enum SfxType {
  refereeWhistleBlow,
  buttonTap,
}
