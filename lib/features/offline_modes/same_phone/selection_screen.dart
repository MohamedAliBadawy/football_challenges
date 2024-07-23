import 'package:flutter/material.dart';
import 'package:football_challenges/core/style/snack_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'selection_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.createGame),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${AppLocalizations.of(context)!.selectLeagues}:"),
            Consumer<SelectionProvider>(
              builder: (context, provider, child) {
                return Wrap(spacing: 8.0, children: [
                  FilterChip(
                    showCheckmark: false,
                    label: provider.leagues.isEmpty
                        ? Text(AppLocalizations.of(context)!.select)
                        : Text(AppLocalizations.of(context)!.edit),
                    selected: provider.leagues.isEmpty ? false : true,
                    onSelected: (bool selected) {
                      GoRouter.of(context).push(
                        '/offline/leagues',
                      );
                    },
                  )
                ]);
              },
            ),
            SizedBox(height: 16),
            Text("${AppLocalizations.of(context)!.selectClub}:"),
            Consumer<SelectionProvider>(
              builder: (context, provider, child) {
                return FilterChip(
                  showCheckmark: false,
                  label: provider.club == null
                      ? Text(AppLocalizations.of(context)!.select)
                      : Text(AppLocalizations.of(context)!.edit),
                  selected: provider.club == null ? false : true,
                  onSelected: (bool selected) {
                    if (provider.leagues.isEmpty) {
                      showSnackBar(
                          AppLocalizations.of(context)!.mustSelectLeaguesFirst);
                      return;
                    } else {
                      GoRouter.of(context).push('/offline/clubs',
                          extra: {'clubsIds': provider.leagues});
                    }
                  },
                );
              },
            ),
            SizedBox(height: 16),
            Text("${AppLocalizations.of(context)!.winningScore}:"),
            Consumer<SelectionProvider>(
              builder: (context, provider, child) {
                return Row(
                  children: [1, 2, 3, 4, 5].map((score) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: FilterChip(
                        showCheckmark: false,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(score.toString()),
                          ],
                        ),
                        selected: provider.selectedScore == score,
                        onSelected: (bool selected) {
                          if (selected) {
                            provider.setScore(score);
                          }
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 16),
            Text("${AppLocalizations.of(context)!.selectTime}:"),
            Consumer<SelectionProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    Slider(
                      value: provider.selectedTime.toDouble(),
                      min: 10,
                      max: 60,
                      divisions: 10,
                      label: provider.selectedTime.toString(),
                      onChanged: (double newValue) {
                        provider.setTime(newValue.toInt());
                      },
                    ),
                    Text(
                      '${provider.selectedTime} ${AppLocalizations.of(context)!.seconds}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (Provider.of<SelectionProvider>(context, listen: false)
                  .leagues
                  .isEmpty ||
              Provider.of<SelectionProvider>(context, listen: false).club ==
                  null) {
            showSnackBar(AppLocalizations.of(context)!.noLeaguesOrClub);
            return;
          }

          GoRouter.of(context).push('/offline/playerInput');
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
