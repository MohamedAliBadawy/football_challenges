import 'package:flutter/material.dart';

import 'package:football_challenges/core/db_helper.dart';
import 'package:football_challenges/core/style/snack_bar.dart';
import 'package:football_challenges/core/style/theme_provider.dart';

import 'package:football_challenges/features/offline_modes/same_phone/selection_provider.dart';
import 'package:football_challenges/models/league_model.dart';
import 'package:football_challenges/widgets/brightness_adjusted_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  _LeaguesScreenState createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  late Future<List<League>> _leaguesFuture;
  List<League> _allLeagues = [];
  List<League> _filteredLeagues = [];
  final Set<int> _selectedLeagues = {};
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  bool enabled = false;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    enabled = false;
    _leaguesFuture = _databaseHelper.getLeagues();
    _leaguesFuture.then((leagues) {
      _allLeagues = leagues;

      _filteredLeagues = leagues;
      _sortAndFilterLeagues();
    });
    _searchController.addListener(_sortAndFilterLeagues);
    enabled = true;
  }

  void _sortAndFilterLeagues() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLeagues = _allLeagues
          .where((league) => league.name.toLowerCase().contains(query))
          .toList()
        ..sort((a, b) => b.isActive.compareTo(a.isActive));
    });
  }

  void _toggleSelection(int id, int isActive) {
    if (isActive == 1) {
      setState(() {
        if (_selectedLeagues.contains(id)) {
          _selectedLeagues.remove(id);
        } else {
          _selectedLeagues.add(id);
        }
      });
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedLeagues.clear();
      } else {
        _selectedLeagues.addAll(_filteredLeagues
            .where((league) => league.isActive == 1)
            .map((league) => league.id));
      }
      _selectAll = !_selectAll;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectLeagues),
        actions: [
          Row(
            children: [
              Text(AppLocalizations.of(context)!.selectAll),
              Checkbox(
                value: _selectAll,
                onChanged: (value) {
                  _toggleSelectAll();
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              enabled: enabled,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.search,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<League>>(
              future: _leaguesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          '${AppLocalizations.of(context)!.error}: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text(AppLocalizations.of(context)!.noLeagues));
                }
                return LayoutBuilder(builder: (context, constraints) {
                  final crossAxisCount = (constraints.maxWidth / 200).ceil();
                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 0.6),
                    itemCount: _filteredLeagues.length,
                    itemBuilder: (context, index) {
                      final league = _filteredLeagues[index];
                      final isSelected = _selectedLeagues.contains(league.id);
                      return GestureDetector(
                        onTap: () =>
                            _toggleSelection(league.id, league.isActive),
                        child: GridTile(
                          footer: league.isActive == 1
                              ? null
                              : GridTileBar(
                                  title: Text(
                                    AppLocalizations.of(context)!.comingSoon,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  backgroundColor: Colors.black54,
                                ),
                          header: GridTileBar(
                            title: Text(
                              league.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor:
                                isSelected ? Colors.green[300] : Colors.black54,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.read<ThemeProvider>().themeMode ==
                                      ThemeMode.dark
                                  ? Colors.grey[400]
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.transparent,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child:
                                Theme.of(context).brightness == Brightness.light
                                    ? Image.memory(league.logo)
                                    : BrightnessAdjustedImage(
                                        image: league.logo,
                                        brightness: 0.0,
                                      ),
                          ),
                        ),
                      );
                    },
                  );
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedLeagues.isEmpty) {
            showSnackBar(AppLocalizations.of(context)!.noLeaguesSelected);
            return;
          } else {
            Provider.of<SelectionProvider>(context, listen: false)
                .setLeagues(_selectedLeagues.toList());
            GoRouter.of(context).pop();
          }
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
