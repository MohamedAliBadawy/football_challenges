import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:football_challenges/core/db_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlayersSearchWidget extends StatelessWidget {
  PlayersSearchWidget({
    super.key,
    required this.callback,
    required this.leagueId,
  });
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final Function(Map<String, dynamic>) callback;
  final List<int> leagueId;

  final TextEditingController _typeAheadController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return TypeAheadField(
      controller: _typeAheadController,
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            labelText: AppLocalizations.of(context)!.player,
          ),
        );
      },
      debounceDuration: const Duration(milliseconds: 500),
      direction: VerticalDirection.up,
      suggestionsCallback: (pattern) async {
        return await _databaseHelper.searchPlayers(pattern, leagueId);
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion['name']),
          leading: Image.memory(suggestion['image']),
        );
      },
      emptyBuilder: (context) {
        if (_typeAheadController.text.length < 3) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              AppLocalizations.of(context)!.characters3,
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(AppLocalizations.of(context)!.noItems),
          );
        }
      },
      onSelected: callback,
    );
  }
}
