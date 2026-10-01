import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tag_filter_state.dart';
import '../models/catalog_model.dart';

class TagMatrixProvider extends ChangeNotifier {
  final Map<String, TagFilterState> _tagStates = {};
  final Set<String> _globalBlacklist = {
    'Gore',
    'Scat',
    'Ugly Bastard',
    'Guff',
  };

  // Parametric Filter Equalizer States
  RangeValues _durationRange = const RangeValues(0, 60); // In minutes
  RangeValues _yearRange = const RangeValues(2010, 2026);
  String _selectedQuality = "All"; // "All", "1080p", "4K Ultra"
  String _selectedCensorship = "All"; // "All", "Uncensored", "Decensored"
  bool _blacklistShieldEnabled = true;

  late final List<TagModel> _allTags = CatalogRepository.getAllItems()
      .map((item) => TagModel(
            name: item.name,
            slug: item.slug,
            count: item.count,
            category: item.categoryGroup ?? item.type.name.toUpperCase(),
          ))
      .toList();

  Map<String, TagFilterState> get tagStates => _tagStates;
  Set<String> get globalBlacklist => _globalBlacklist;
  bool get blacklistShieldEnabled => _blacklistShieldEnabled;
  List<TagModel> get allTags => _allTags;

  RangeValues get durationRange => _durationRange;
  RangeValues get yearRange => _yearRange;
  String get selectedQuality => _selectedQuality;
  String get selectedCensorship => _selectedCensorship;

  List<String> get whitelistedTags => _tagStates.entries
      .where((e) => e.value == TagFilterState.included)
      .map((e) => e.key)
      .toList();

  List<String> get blacklistedTags {
    final list = _tagStates.entries
        .where((e) => e.value == TagFilterState.excluded)
        .map((e) => e.key)
        .toSet();
    if (_blacklistShieldEnabled) {
      list.addAll(_globalBlacklist);
    }
    return list.toList();
  }

  TagMatrixProvider() {
    _loadPreferences();
  }

  TagFilterState getTagState(String tagName) {
    return _tagStates[tagName] ?? TagFilterState.neutral;
  }

  // 3-State Cycle: Neutral -> Included (+) -> Excluded (-) -> Neutral
  void cycleTagState(String tagName) {
    final current = getTagState(tagName);
    if (current == TagFilterState.neutral) {
      _tagStates[tagName] = TagFilterState.included;
    } else if (current == TagFilterState.included) {
      _tagStates[tagName] = TagFilterState.excluded;
    } else {
      _tagStates.remove(tagName);
    }
    notifyListeners();
  }

  void toggleBlacklistShield() {
    _blacklistShieldEnabled = !_blacklistShieldEnabled;
    notifyListeners();
    _savePreferences();
  }

  void addGlobalBlacklist(String tag) {
    _globalBlacklist.add(tag);
    notifyListeners();
    _savePreferences();
  }

  void removeGlobalBlacklist(String tag) {
    _globalBlacklist.remove(tag);
    notifyListeners();
    _savePreferences();
  }

  void setDurationRange(RangeValues values) {
    _durationRange = values;
    notifyListeners();
  }

  void setYearRange(RangeValues values) {
    _yearRange = values;
    notifyListeners();
  }

  void setQuality(String quality) {
    _selectedQuality = quality;
    notifyListeners();
  }

  void setCensorship(String censorship) {
    _selectedCensorship = censorship;
    notifyListeners();
  }

  void resetAllFilters() {
    _tagStates.clear();
    _durationRange = const RangeValues(0, 60);
    _yearRange = const RangeValues(2010, 2026);
    _selectedQuality = "All";
    _selectedCensorship = "All";
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('global_blacklist');
    if (list != null) {
      _globalBlacklist.clear();
      _globalBlacklist.addAll(list);
    }
    _blacklistShieldEnabled = prefs.getBool('blacklist_shield_enabled') ?? true;
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('global_blacklist', _globalBlacklist.toList());
    await prefs.setBool('blacklist_shield_enabled', _blacklistShieldEnabled);
  }
}
