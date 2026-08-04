import 'settings_models.dart';

abstract interface class BusinessSettingsRepository {
  Future<BusinessPolicySettings> loadBusinessPolicies();

  Future<void> saveBusinessPolicies(BusinessPolicySettings settings);

  Future<OperationalDefaults> loadOperationalDefaults();

  Future<void> saveOperationalDefaults(OperationalDefaults settings);
}

abstract interface class DeviceSettingsRepository {
  Future<DeviceSettings> loadDeviceSettings(String deviceId);

  Future<void> saveDeviceSettings(DeviceSettings settings);
}
