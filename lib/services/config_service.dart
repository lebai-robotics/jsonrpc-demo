import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/robot_config.dart';
import '../models/scene_button.dart';

/// 配置服务类
/// 负责机械臂配置的本地存储、加载和验证
class ConfigService {
  static const String _configKey = 'robot_config';
  static const String _settingsKey = 'app_settings';

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// 初始化配置服务
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    return Future.value();
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('ConfigService must be initialized before use');
    }
  }

  /// 保存机器人配置
  Future<bool> saveRobotConfig(RobotConfig config) async {
    _ensureInitialized();

    try {
      final configJson = jsonEncode(config.toJson());
      final success = await _prefs.setString(_configKey, configJson);

      if (success) {
        print('[ConfigService] 配置保存成功: ${config.name}');
      } else {
        print('[ConfigService] 配置保存失败');
      }

      return success;
    } catch (error) {
      print('[ConfigService] 保存配置时发生错误: $error');
      return false;
    }
  }

  /// 加载机器人配置
  Future<RobotConfig?> loadRobotConfig() async {
    _ensureInitialized();

    try {
      final configJson = _prefs.getString(_configKey);

      if (configJson == null || configJson.isEmpty || configJson == '') {
        return null;
      }

      final configData = jsonDecode(configJson) as Map<String, dynamic>;
      final config = RobotConfig.fromJson(configData);
      return config;
    } catch (error) {
      return null;
    }
  }

  /// 删除配置
  Future<bool> deleteRobotConfig() async {
    _ensureInitialized();

    try {
      final success = await _prefs.remove(_configKey);

      if (success) {
        print('[ConfigService] 配置删除成功');
      }

      return success;
    } catch (error) {
      print('[ConfigService] 删除配置时发生错误: $error');
      return false;
    }
  }

  /// 检查是否有保存的配置
  Future<bool> hasRobotConfig() async {
    _ensureInitialized();
    return _prefs.containsKey(_configKey);
  }

  /// 验证机器人配置
  ValidationResult validateRobotConfig(RobotConfig config) {
    final errors = <String>[];

    // 验证基本字段
    if (config.name.trim().isEmpty) {
      errors.add('机器人名称不能为空');
    }

    if (!RobotConfig.isValidIP(config.ip)) {
      errors.add('IP地址格式无效');
    }

    if (!RobotConfig.isValidPort(config.port)) {
      errors.add('端口号无效（应为1-65535）');
    }

    // 验证场景配置
    for (int i = 0; i < config.scenes.length; i++) {
      final scene = config.scenes[i];
      final sceneErrors = validateSceneButton(scene);
      if (!sceneErrors.isValid) {
        errors.add('场景${i + 1}: ${sceneErrors.errors.join(', ')}');
      }
    }

    // 检查场景ID重复
    final sceneIds = config.scenes.map((s) => s.sceneId).toList();
    final duplicateIds = <String>[];
    for (int i = 0; i < sceneIds.length; i++) {
      final id = sceneIds[i];
      if (sceneIds.indexOf(id) != i && !duplicateIds.contains(id)) {
        duplicateIds.add(id);
      }
    }
    if (duplicateIds.isNotEmpty) {
      errors.add('场景ID重复: ${duplicateIds.join(', ')}');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// 验证场景按钮配置
  ValidationResult validateSceneButton(SceneButton scene) {
    final errors = <String>[];

    if (scene.name.trim().isEmpty) {
      errors.add('场景名称不能为空');
    }

    if (scene.sceneId.trim().isEmpty) {
      errors.add('场景ID不能为空');
    }

    // 验证场景ID格式（应为数字字符串）
    if (scene.sceneId.isNotEmpty && int.tryParse(scene.sceneId) == null) {
      errors.add('场景ID应为有效的数字');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// 生成唯一的场景ID
  String generateSceneId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000).toString().padLeft(3, '0');
    return 'scene_$timestamp$random';
  }

  /// 保存应用设置
  Future<bool> saveSettings(Map<String, dynamic> settings) async {
    _ensureInitialized();

    try {
      final settingsJson = jsonEncode(settings);
      return await _prefs.setString(_settingsKey, settingsJson);
    } catch (error) {
      print('[ConfigService] 保存设置时发生错误: $error');
      return false;
    }
  }

  /// 加载应用设置
  Future<Map<String, dynamic>> loadSettings() async {
    _ensureInitialized();

    try {
      final settingsJson = _prefs.getString(_settingsKey);

      if (settingsJson == null || settingsJson.isEmpty) {
        return _getDefaultSettings();
      }

      final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
      return {..._getDefaultSettings(), ...settings};
    } catch (error) {
      print('[ConfigService] 加载设置时发生错误: $error');
      return _getDefaultSettings();
    }
  }

  /// 获取默认设置
  Map<String, dynamic> _getDefaultSettings() {
    return {
      'timeout': 5000,
      'retryCount': 3,
      'checkInterval': 10000,
      'theme': 'dark',
    };
  }

  /// 获取场景图片存储目录
  Future<Directory> getSceneImagesDirectory() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final sceneImagesDir = Directory(
      path.join(appSupportDir.path, 'scene_images'),
    );

    if (!await sceneImagesDir.exists()) {
      await sceneImagesDir.create(recursive: true);
    }

    return sceneImagesDir;
  }

  /// 保存场景图片
  /// 将选中的图片复制到应用目录，返回新的文件路径
  Future<String> saveSceneImage(String sceneId, String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('源图片文件不存在');
      }

      final sceneImagesDir = await getSceneImagesDirectory();
      final fileName =
          '${sceneId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(sourcePath)}';
      final destinationPath = path.join(sceneImagesDir.path, fileName);

      // 复制图片文件
      await sourceFile.copy(destinationPath);

      print('[ConfigService] 场景图片保存成功: $destinationPath');
      return destinationPath;
    } catch (error) {
      print('[ConfigService] 保存场景图片失败: $error');
      rethrow;
    }
  }

  /// 删除场景图片
  Future<void> deleteSceneImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        print('[ConfigService] 场景图片删除成功: $imagePath');
      }
    } catch (error) {
      print('[ConfigService] 删除场景图片失败: $error');
      // 删除失败不抛出异常，避免影响其他操作
    }
  }

  /// 清理未使用的场景图片
  /// 删除不在当前配置中的图片文件
  Future<void> cleanupUnusedImages(List<SceneButton> scenes) async {
    try {
      final sceneImagesDir = await getSceneImagesDirectory();
      if (!await sceneImagesDir.exists()) return;

      final usedImagePaths = scenes
          .where((scene) => scene.imagePath != null)
          .map((scene) => scene.imagePath!)
          .toSet();

      await for (final entity in sceneImagesDir.list()) {
        if (entity is File && !usedImagePaths.contains(entity.path)) {
          await entity.delete();
          print('[ConfigService] 清理未使用的图片: ${entity.path}');
        }
      }
    } catch (error) {
      print('[ConfigService] 清理未使用图片失败: $error');
    }
  }
}

/// 验证结果类
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({required this.isValid, required this.errors});

  @override
  String toString() {
    return 'ValidationResult{isValid: $isValid, errors: $errors}';
  }
}
