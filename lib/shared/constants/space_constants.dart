import 'package:flutter/cupertino.dart';

const Color kSpaceColor = Color(0xFFEDEAE4);

const Map<String, List<String>> kSpaceIconsByType = {
  'personal': [
    'person_fill',
    'wallet',
    'coins',
    'star_fill',
    'sun_max_fill',
    'airplane',
  ],
  'family': [
    'house_fill',
    'user_group',
    'heart_fill',
    'baby',
    'sofa',
    'cart_fill',
  ],
  'organization': [
    'briefcase_fill',
    'building_2_fill',
    'store',
    'school',
    'church',
    'chart_bar_fill',
  ],
};

List<String> spaceIconsFor(String type) =>
    kSpaceIconsByType[type] ?? kSpaceIconsByType['personal']!;

String defaultSpaceIcon(String type) => spaceIconsFor(type).first;
