import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/src/either.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/glass_toast.dart';
import '../../../context/domain/entities/geo_location.dart';
import '../../../context/domain/repositories/i_geocoding_repository.dart';
import '../../../context/presentation/providers/geocoding_provider.dart';
import '../../../dashboard/presentation/widgets/nebula_background.dart';
import '../../domain/entities/saved_location.dart';
import '../providers/saved_locations_provider.dart';

class AddLocationScreen extends ConsumerStatefulWidget {

  const AddLocationScreen({
    super.key,
    this.locationToEdit,
  });
  final SavedLocation? locationToEdit;

  @override
  ConsumerState<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends ConsumerState<AddLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  List<dynamic> _searchResults = <dynamic>[];
  bool _isSearching = false;
  Timer? _debounce;
  bool _showManualEntry = false;
  bool _isNorth = true;
  bool _isEast = true;
  String? _placeName;

  @override
  void initState() {
    super.initState();
    if (widget.locationToEdit != null) {
      final SavedLocation loc = widget.locationToEdit!;
      _nameController.text = loc.name;
      _latController.text = loc.latitude.abs().toString();
      _lngController.text = loc.longitude.abs().toString();
      _isNorth = loc.latitude >= 0;
      _isEast = loc.longitude >= 0;
      _placeName = loc.placeName;
      _showManualEntry = true;
    }
  }

  Widget _buildDirectionButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _nameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchOSM(query);
      } else {
        setState(() {
          _searchResults = <dynamic>[];
        });
      }
    });
  }

  Future<void> _searchOSM(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final IGeocodingRepository repository = ref.read(geocodingRepositoryProvider);
      final Either<Failure, List<GeoLocation>> result = await repository.searchLocations(query);

      result.fold(
        (Failure failure) {
          debugPrint('Error searching locations: ${failure.message}');
          setState(() {
            _searchResults = <dynamic>[];
          });
        },
        (List<GeoLocation> locations) {
          setState(() {
            _searchResults = locations.map((GeoLocation loc) => <String, Object?>{
              'display_name': loc.name,
              'lat': loc.latitude.toString(),
              'lon': loc.longitude.toString(),
              'address': <dynamic, dynamic>{}, // Open-Meteo doesn't return detailed address structure like OSM
            }).toList();
          });
        },
      );
    } catch (e) {
      debugPrint('Error searching locations: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectLocation(dynamic location) {
    final double lat = double.parse(location['lat']);
    final double lng = double.parse(location['lon']);

    _isNorth = lat >= 0;
    _isEast = lng >= 0;

    _latController.text = lat.abs().toString();
    _lngController.text = lng.abs().toString();
    
    // Try to get a good name
    final String name = location['display_name'];
    // Open-Meteo returns a clean name already, so we can use it directly or split if needed.
    // The previous logic was specific to OSM Nominatim's structure.
    
    _nameController.text = name;

    setState(() {
      _showManualEntry = true;
      _searchResults = <dynamic>[]; // Clear results
      _placeName = location['display_name'];
    });
  }

  void _saveLocation() {
    if (_nameController.text.isEmpty || _latController.text.isEmpty || _lngController.text.isEmpty) {
      showGlassToast(context, 'Please fill in all fields');
      return;
    }

    try {
      double lat = double.parse(_latController.text);
      double lng = double.parse(_lngController.text);

      if (!_isNorth) lat = -lat;
      if (!_isEast) lng = -lng;

      // Check for duplicates (exclude current location if editing)
      final List<SavedLocation> currentLocations = ref.read(savedLocationsNotifierProvider).value ?? <SavedLocation>[];
      final bool isDuplicate = currentLocations.any((SavedLocation loc) {
        if (widget.locationToEdit != null && loc.id == widget.locationToEdit!.id) return false;
        return (loc.latitude - lat).abs() < 0.0001 && (loc.longitude - lng).abs() < 0.0001;
      });

      if (_nameController.text.isEmpty) {
        showGlassToast(context, 'Please enter a name');
        return;
      }

      if (isDuplicate) {
        showGlassToast(context, 'This location is already saved');
        return;
      }

      final SavedLocation newLocation = SavedLocation(
        id: widget.locationToEdit?.id ?? const Uuid().v4(),
        name: _nameController.text,
        latitude: lat,
        longitude: lng,
        createdAt: widget.locationToEdit?.createdAt ?? DateTime.now(),
        placeName: _placeName,
      );

      ref.read(savedLocationsNotifierProvider.notifier).addLocation(newLocation);
      context.pop();
      showGlassToast(context, widget.locationToEdit != null ? 'Location updated' : 'Location added successfully');
    } catch (e) {
      showGlassToast(context, 'Invalid coordinates');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020204),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.locationToEdit != null ? 'Edit Location' : 'Add Location', style: const TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: <Widget>[
          const NebulaBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Search Bar
                  GlassPanel(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search city, town, or place...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        border: InputBorder.none,
                        icon: const Icon(Ionicons.search, color: Colors.white70),
                        suffixIcon: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  
                  // Search Results
                  if (_searchResults.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141419),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: _searchResults.map((result) {
                          return ListTile(
                            title: Text(
                              result['display_name'].split(',')[0],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              result['display_name'],
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectLocation(result),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  
                  if (!_showManualEntry && _searchResults.isEmpty)
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showManualEntry = true;
                          });
                        },
                        icon: const Icon(Ionicons.create_outline, color: Colors.blueAccent),
                        label: const Text('Enter Coordinates Manually'),
                      ),
                    ),

                  // Manual Entry Form
                  if (_showManualEntry) ...<Widget>[
                    const Text(
                      'Location Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Name Field
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Location Name (e.g. Home, Park)',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          border: InputBorder.none,
                          labelStyle: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Latitude Row
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: GlassPanel(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextField(
                              controller: _latController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'Latitude',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: <Widget>[
                              _buildDirectionButton('N', _isNorth, () => setState(() => _isNorth = true)),
                              _buildDirectionButton('S', !_isNorth, () => setState(() => _isNorth = false)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Longitude Row
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: GlassPanel(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextField(
                              controller: _lngController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'Longitude',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: <Widget>[
                              _buildDirectionButton('E', _isEast, () => setState(() => _isEast = true)),
                              _buildDirectionButton('W', !_isEast, () => setState(() => _isEast = false)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
