import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:football_challenges/core/db_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClubsSearchWidget extends StatelessWidget {
  ClubsSearchWidget(
      {super.key,
      required this.callback,
      required this.leagueId,
      this.readOnly = false});
  final Function(Map<String, dynamic>) callback;
  final List<int> leagueId;
  bool readOnly;

  final TextEditingController typeAheadController = TextEditingController();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  @override
  Widget build(BuildContext context) {
    return TypeAheadField(
      direction: VerticalDirection.up,
      controller: typeAheadController,
      builder: (context, typeAheadController, focusNode) {
        return TextField(
            readOnly: readOnly,
            controller: typeAheadController,
            focusNode: focusNode,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: AppLocalizations.of(context)!.club,
            ));
      },
      transitionBuilder: (context, animation, child) {
        return FadeTransition(
          opacity:
              CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn),
          child: child,
        );
      },
      suggestionsCallback: (pattern) async {
        return await _databaseHelper.fuzzySearchClubs(pattern, leagueId);
      },
      emptyBuilder: (context) {
        if (typeAheadController.text.length < 3) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              AppLocalizations.of(context)!.characters3,
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              AppLocalizations.of(context)!.noItems,
            ),
          );
        }
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion['name']),
          leading: Image.memory(suggestion['logo']),
        );
      },
      onSelected: callback,
    );
  }
}
