// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:football_challenges/core/style/locale_provider.dart';
import 'package:football_challenges/core/style/theme_provider.dart';
import 'package:football_challenges/features/auth/auth_service.dart';
import 'package:football_challenges/widgets/google_sign_in_button.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/in_app_purchase/in_app_purchase.dart';
import '../../core/style/responsive_screen.dart';
import 'custom_name_dialog.dart';
import 'settings.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  static const _gap = SizedBox(height: 60);
  final List<String> items = [
    'English',
    'العربية',
  ];
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final authService = Provider.of<AuthService>(context, listen: true);

    Future<String> uploadImageToStorage(File file) async {
      authService.isLoading = true;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${authService.myUser!.uid}');
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => null);
      return await snapshot.ref.getDownloadURL();
    }

    Future<void> _pickImage(BuildContext context) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        // Upload the file to a storage service and get the URL
        final photoURL = await uploadImageToStorage(
            file); // You need to implement this function
        authService.updatePhotoURL(photoURL);
      }
    }

    return Scaffold(
      body: ResponsiveScreen(
        squarishMainArea: ListView(
          children: [
            Text(
              AppLocalizations.of(context)!.settings,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Permanent Marker',
                fontSize: 55,
                height: 1,
              ),
            ),
            _gap,
            if (authService.myUser != null)
              Consumer<AuthService>(
                builder: (context, value, child) {
                  if (value.isLoading) return const CircularProgressIndicator();
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: value.myUser!.photoURL == null
                            ? Image.asset("assets/FoOtBall challenges2.png")
                                .image
                            : NetworkImage(value.myUser!.photoURL!),
                      ),
                      ElevatedButton(
                        onPressed: () => _pickImage(context),
                        child: Text(
                            AppLocalizations.of(context)!.changeProfilePicture),
                      ),
                    ],
                  );
                },
              ),
            _gap,
            _NameChangeLine(
              AppLocalizations.of(context)!.name,
              authService,
            ),
            ValueListenableBuilder<bool>(
              valueListenable: settings.soundsOn,
              builder: (context, soundsOn, child) => _SettingsLine(
                AppLocalizations.of(context)!.soundFX,
                Icon(soundsOn ? Icons.graphic_eq : Icons.volume_off),
                onSelected: () => settings.toggleSoundsOn(),
              ),
            ),
            _SettingsLine(
              AppLocalizations.of(context)!.theme,
              Icon(
                Provider.of<ThemeProvider>(context).themeMode == ThemeMode.light
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              onSelected: () =>
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme(),
            ),
            _SettingsLine(
              AppLocalizations.of(context)!.language,
              DropdownButtonHideUnderline(
                child: DropdownButton(
                  // Down Arrow Icon
                  value: Localizations.localeOf(context).languageCode == 'ar'
                      ? "العربية"
                      : "English",
                  items: items.map((String items) {
                    return DropdownMenuItem(
                      value: items,
                      child: Text(items),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue == 'English') {
                      Provider.of<LocaleProvider>(context, listen: false)
                          .toggleLocale(const Locale('en'));
                    } else if (newValue == 'العربية') {
                      Provider.of<LocaleProvider>(context, listen: false)
                          .toggleLocale(const Locale('ar'));
                    }
                  },
                ),
              ),
            ),
            Consumer<InAppPurchaseController?>(
                builder: (context, inAppPurchase, child) {
              if (inAppPurchase == null) {
                // In-app purchases are not supported yet.
                // Go to lib/main.dart and uncomment the lines that create
                // the InAppPurchaseController.
                return const SizedBox.shrink();
              }

              Widget icon;
              VoidCallback? callback;
              if (inAppPurchase.adRemoval.active) {
                icon = const Icon(Icons.check);
              } else if (inAppPurchase.adRemoval.pending) {
                icon = const CircularProgressIndicator();
              } else {
                icon = const Icon(Icons.ad_units);
                callback = () {
                  inAppPurchase.buy();
                };
              }
              return _SettingsLine(
                AppLocalizations.of(context)!.removeAds,
                icon,
                onSelected: callback,
              );
            }),
            _gap,
            if (authService.myUser != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(70, 0, 70, 0),
                child: ElevatedButton(
                  onPressed: () => authService.signOut(),
                  child: Text(AppLocalizations.of(context)!.signOut),
                ),
              ),
            if (authService.myUser == null)
              GoogleSignInButton(
                onPressed: () => authService.signInWithGoogle(),
              )
          ],
        ),
        rectangularMenuArea: FilledButton(
          onPressed: () {
            GoRouter.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.back),
        ),
      ),
    );
  }
}

class _NameChangeLine extends StatelessWidget {
  final String title;
  final AuthService authService;
  _NameChangeLine(this.title, this.authService);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return InkResponse(
      highlightShape: BoxShape.rectangle,
      onTap: () => showCustomNameDialog(context, authService),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(title,
                  style: const TextStyle(
                    fontFamily: 'Permanent Marker',
                    fontSize: 30,
                  )),
            ),
            ValueListenableBuilder(
              valueListenable: settings.playerName,
              builder: (context, name, child) => Flexible(
                child: Text(
                  authService.myUser == null
                      ? '‘$name’'
                      : '${authService.myUser!.displayName}',
                  style: const TextStyle(
                    fontFamily: 'Permanent Marker',
                    fontSize: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsLine extends StatelessWidget {
  final String title;

  final Widget icon;

  final VoidCallback? onSelected;

  const _SettingsLine(this.title, this.icon, {this.onSelected});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      highlightShape: BoxShape.rectangle,
      onTap: onSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Permanent Marker',
                  fontSize: 30,
                ),
              ),
            ),
            icon,
          ],
        ),
      ),
    );
  }
}
