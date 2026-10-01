import 'package:flutter/material.dart';

enum ViewLayoutType {
  widescreen16x9, // For full series (Hanime, HStream)
  staggeredMasonry3x4, // For 3D & Clips (Rule34, HMV Mania)
  compactList, // For fast indexing
}

enum FilterType {
  dropdown,
  multiSelect,
  rangeSlider,
  booleanToggle,
}

class FilterOption {
  final String label;
  final String value;

  FilterOption({required this.label, required this.value});
}

class FilterGroup {
  final String key;
  final String title;
  final FilterType type;
  final List<FilterOption> options;
  final dynamic defaultValue;
  final double? min;
  final double? max;

  FilterGroup({
    required this.key,
    required this.title,
    required this.type,
    this.options = const [],
    this.defaultValue,
    this.min,
    this.max,
  });
}

class ExtensionTab {
  final String id;
  final String title;
  final IconData? icon;
  final String? feedQuery;

  ExtensionTab({
    required this.id,
    required this.title,
    this.icon,
    this.feedQuery,
  });
}

class NavButton {
  final String id;
  final String label;
  final IconData icon;

  NavButton({
    required this.id,
    required this.label,
    required this.icon,
  });
}
