import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance =
  RemoteConfigService._internal();

  factory RemoteConfigService() => _instance;

  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  Future<void> init() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero, // PROD → 12 hours
      ),
    );

    await _remoteConfig.fetchAndActivate();
  }

  String getString(String key) => _remoteConfig.getString(key);
  bool getBool(String key) => _remoteConfig.getBool(key);
  int getInt(String key) => _remoteConfig.getInt(key);
}
