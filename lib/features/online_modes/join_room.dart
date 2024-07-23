import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:football_challenges/core/style/snack_bar.dart';
import 'package:football_challenges/features/auth/auth_service.dart';
import 'package:football_challenges/features/online_modes/join_room_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class JoinRoomScreen extends StatefulWidget {
  final String roomId;
  JoinRoomScreen({super.key, required this.roomId});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  TextEditingController controller = TextEditingController();
  late JoinRoomProvider provider;

  @override
  void initState() {
    super.initState();
    if (widget.roomId.isEmpty) return;
    // Adding post frame callback to ensure the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final progress = ProgressHUD.of(provider.context);
      progress!.show();
      if (context.read<AuthService>().myUser == null) {
        await context.read<AuthService>().signInWithGoogle();
      }
      context
          .read<AuthService>()
          .updateRoomList(await context.read<AuthService>().roomsStream.first);
      controller.text = widget.roomId;
      context.read<AuthService>().searchRooms(controller.text);

      if (context.read<AuthService>().searchResults.length == 1) {
        final room = context.read<AuthService>().searchResults[0].data()!
            as Map<String, dynamic>;
        if (room['currentPlayersNum'] < room['playersNum']) {
          if (room['isPrivate']) {
            String? password = await showPasswordDialog(provider.context);
            bool isValid = password == room['password'];
            if (isValid) {
              await joinRoom(room['roomId'], room['currentPlayersNum']);
              GoRouter.of(context).push('/online_team_management',
                  extra: {'roomId': room['roomId'], 'isOwner': false});
            } else {
              showSnackBar(AppLocalizations.of(context)!.incorrectPassword);
            }
          } else {
            await joinRoom(room['roomId'], room['currentPlayersNum']);
            GoRouter.of(context).push('/online_team_management',
                extra: {'roomId': room['roomId'], 'isOwner': false});
          }
        } else {
          showSnackBar(AppLocalizations.of(context)!.roomIsFull);
        }
      }
      progress.dismiss();
    });
  }

  Future<void> joinRoom(String roomId, int playersNum) async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    final User? myUser =
        Provider.of<AuthService>(context, listen: false).myUser;
    await roomRef.update({
      'currentPlayersNum': playersNum + 1,
    });
    await roomRef.collection('players').doc(myUser!.uid).set({
      'uid': myUser.uid,
      'name': myUser.displayName.toString(),
      'image': myUser.photoURL.toString(),
      'team': '',
    });
  }

  Future<String?> showPasswordDialog(BuildContext context) async {
    TextEditingController _passwordController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.enterPassword),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.password),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.ok),
              onPressed: () {
                Navigator.of(context).pop(_passwordController.text);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    provider = context.read<JoinRoomProvider>();
    return ProgressHUD(
        child: Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.joinRoom)),
      body: Consumer<AuthService>(builder: (context, authService, child) {
        provider.context = context;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.searchRooms,
                  border: OutlineInputBorder(),
                ),
                onChanged: (query) {
                  if (controller.text.isNotEmpty) {
                    authService.searchRooms(query);
                  } else {
                    authService.notify();
                  }
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: authService.roomsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            '${AppLocalizations.of(context)!.error}: ${snapshot.error}'));
                  }

                  if (snapshot.hasData) {
                    authService.updateRoomList(snapshot.data!);
                    authService.slientSearchRooms(controller.text);

                    return ListView.builder(
                      itemCount: controller.text.isEmpty
                          ? snapshot.data!.size
                          : authService.searchResults.length,
                      itemBuilder: (context, index) {
                        final room = controller.text.isEmpty
                            ? snapshot.data!.docs[index]
                            : authService.searchResults[index];
                        return ListTile(
                          title: Text(room['roomName']),
                          subtitle: Text(
                              '${AppLocalizations.of(context)!.id}: ${room.id}'),
                          leading: Text(
                              "${room['currentPlayersNum']}/${room['playersNum']}"),
                          trailing: Icon(
                              room['isPrivate']
                                  ? Icons.lock_outline
                                  : Icons.lock_open_outlined,
                              color: room['isPrivate']
                                  ? Colors.red
                                  : Colors.green),
                          onTap: () async {
                            if (room['currentPlayersNum'] <
                                room['playersNum']) {
                              final progress = ProgressHUD.of(context);
                              progress!.show();
                              if (room['isPrivate']) {
                                String? password =
                                    await showPasswordDialog(context);
                                bool isValid = password == room['password'];
                                if (isValid) {
                                  await joinRoom(room['roomId'],
                                      room['currentPlayersNum']);
                                  GoRouter.of(context)
                                      .push('/online_team_management', extra: {
                                    'roomId': room['roomId'],
                                    'isOwner': false
                                  });
                                } else {
                                  showSnackBar(AppLocalizations.of(context)!
                                      .incorrectPassword);
                                }
                              } else {
                                await joinRoom(
                                    room['roomId'], room['currentPlayersNum']);
                                GoRouter.of(context)
                                    .push('/online_team_management', extra: {
                                  'roomId': room['roomId'],
                                  'isOwner': room['currentPlayersNum'] == 0,
                                });
                              }
                              progress.dismiss();
                            } else {
                              showSnackBar(AppLocalizations.of(context)!
                                  .thisRoomIsFullOfPlayers);
                            }
                          },
                        );
                      },
                    );
                  }

                  return Center(
                      child: Text(AppLocalizations.of(context)!.noRoomsFound));
                },
              ),
            ),
          ],
        );
      }),
    ));
  }
}
