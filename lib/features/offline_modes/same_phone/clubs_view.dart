import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:football_challenges/core/db_helper.dart';
import 'package:football_challenges/core/style/theme_provider.dart';
import 'package:football_challenges/features/offline_modes/same_phone/selection_provider.dart';
import 'package:football_challenges/models/club_model.dart';
import 'package:football_challenges/widgets/brightness_adjusted_image.dart';
import 'package:gif/gif.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClubsScreen extends StatefulWidget {
  final List<int> clubsIds;

  const ClubsScreen({super.key, required this.clubsIds});
  @override
  _ClubsScreenState createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen>
    with TickerProviderStateMixin {
  late GifController _controller;

  late Future<List<Club>> _clubsFuture;
  List<Club> _allClubs = [
    Club(id: 0, name: "Random", logo: Uint8List.fromList([1, 2]), leagueId: 0)
  ];
  List<Club> _filteredClubs = [];
  int _selectedClub = 0;
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  bool enabled = false;
  @override
  void initState() {
    enabled = false;
    _controller = GifController(vsync: this);

    super.initState();
    _clubsFuture = _databaseHelper.getClubsByLeagueIds(widget.clubsIds);
    _clubsFuture.then((clubs) {
      setState(() {
        _allClubs.addAll(clubs);

        _filteredClubs = clubs;
        _sortAndFilterLeagues();
      });
    });
    _searchController.addListener(_sortAndFilterLeagues);
    enabled = true;
  }

  void _sortAndFilterLeagues() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClubs = _allClubs
          .where((league) => league.name.toLowerCase().contains(query))
          .toList();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      _selectedClub = id;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.selectClub)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              enabled: enabled,
              controller: _searchController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.search,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Club>>(
              future: _clubsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          '${AppLocalizations.of(context)!.error}: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text(AppLocalizations.of(context)!.noClubs));
                }
                return LayoutBuilder(builder: (context, constraints) {
                  final crossAxisCount = (constraints.maxWidth / 200).ceil();

                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount < 1 ? 1 : crossAxisCount,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 0.6),
                    itemCount: _filteredClubs.length,
                    itemBuilder: (context, index) {
                      final club = _filteredClubs[index];
                      final isSelected =
                          _selectedClub == club.id ? true : false;
                      return GestureDetector(
                        onTap: () => _toggleSelection(
                          club.id,
                        ),
                        child: GridTile(
                          header: GridTileBar(
                            title: Text(
                              club.name,
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
                                    ? (club.id == 0
                                        ? Gif(
                                            color: Colors.black,
                                            image: const AssetImage(
                                                "assets/Untitled-design-1--unscreen.gif"),
                                            controller:
                                                _controller, // if duration and fps is null, original gif fps will be used.

                                            autostart: Autostart.loop,
                                            placeholder: (context) => Text(
                                                AppLocalizations.of(context)!
                                                    .loading),
                                            onFetchCompleted: () {
                                              _controller.reset();
                                              _controller.forward();
                                            },
                                            repeat: ImageRepeat.noRepeat,
                                          )
                                        : Image.memory(club.logo!))
                                    : club.id == 0
                                        ? Gif(
                                            image: const AssetImage(
                                                "assets/Untitled-design-1--unscreen.gif"),
                                            controller:
                                                _controller, // if duration and fps is null, original gif fps will be used.

                                            autostart: Autostart.no,
                                            placeholder: (context) => Text(
                                                AppLocalizations.of(context)!
                                                    .loading),
                                            onFetchCompleted: () {
                                              _controller.reset();
                                              _controller.forward();
                                            },
                                            repeat: ImageRepeat.noRepeat,
                                          )
                                        : BrightnessAdjustedImage(
                                            image: club.logo!,
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
          if (_selectedClub == 0) {
            Random random = Random();
            _selectedClub = random.nextInt(_allClubs.length - 1) + 1;
            Provider.of<SelectionProvider>(context, listen: false)
                .setClub(_allClubs[_selectedClub].id);
          } else {
            Provider.of<SelectionProvider>(context, listen: false)
                .setClub(_selectedClub);
          }

          GoRouter.of(context).pop();
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
