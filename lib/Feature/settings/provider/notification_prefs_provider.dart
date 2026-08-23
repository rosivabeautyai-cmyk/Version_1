import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's notification toggle preferences on-device.
/// These are UI preferences only — actually delivering push
/// notifications requires a backend/FCM integration that isn't part
/// of this screen's scope.
class NotificationPrefsProvider extends ChangeNotifier {
  static const _aiRecsKey = 'notif_ai_recommendations';
  static const _priceDropsKey = 'notif_price_drops';
  static const _newDiscoveriesKey = 'notif_new_discoveries';

  bool _aiRecommendations = true;
  bool _priceDrops = true;
  bool _newDiscoveries = false;

  bool get aiRecommendations => _aiRecommendations;
  bool get priceDrops => _priceDrops;
  bool get newDiscoveries => _newDiscoveries;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _aiRecommendations = prefs.getBool(_aiRecsKey) ?? true;
    _priceDrops = prefs.getBool(_priceDropsKey) ?? true;
    _newDiscoveries = prefs.getBool(_newDiscoveriesKey) ?? false;
    notifyListeners();
  }

  Future<void> setAiRecommendations(bool value) async {
    _aiRecommendations = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiRecsKey, value);
  }

  Future<void> setPriceDrops(bool value) async {
    _priceDrops = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_priceDropsKey, value);
  }

  Future<void> setNewDiscoveries(bool value) async {
    _newDiscoveries = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_newDiscoveriesKey, value);
  }
}
