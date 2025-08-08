import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/robot_config.dart';
import '../models/scene_button.dart';
import '../services/config_service.dart';
import '../services/jsonrpc_client.dart';

/// 机器人状态管理Provider
/// 管理机器人配置、连接状态和场景执行
class RobotProvider extends ChangeNotifier {
  final ConfigService _configService;
  final JsonRpcClient _rpcClient;

  // 机器人配置
  RobotConfig? _robotConfig;

  // 机器人状态
  RobotState _robotState = RobotState.unknown;
  DateTime? _lastStateCheck;

  // 状态检查定时器
  Timer? _statusCheckTimer;

  // 配置加载状态
  bool _isConfigLoaded = false;

  RobotProvider(this._configService, this._rpcClient) {
    _initialize();
  }

  // Getters
  RobotConfig? get robotConfig => _robotConfig;
  RobotState get robotState => _robotState;
  DateTime? get lastStateCheck => _lastStateCheck;
  bool get isConfigLoaded => _isConfigLoaded;
  bool get hasConfig => _robotConfig != null;
  bool get isOnline => _robotState != RobotState.unknown;

  List<SceneButton> get scenes => _robotConfig?.scenes ?? [];

  /// 初始化
  Future<void> _initialize() async {
    try {
      await _configService.initialize();
      await loadConfig();
      _startStatusCheck();
    } catch (error) {
      print('[RobotProvider] 初始化失败: $error');
    }
  }

  /// 加载配置
  Future<void> loadConfig() async {
    try {
      final config = await _configService.loadRobotConfig();
      _robotConfig = config;
      _isConfigLoaded = true;

      if (config != null) {
        // 立即检查一次状态
        await checkRobotState();
      } else {}

      notifyListeners();
    } catch (error) {
      print('[RobotProvider] 加载配置失败: $error');
      _isConfigLoaded = true;
      notifyListeners();
    }
  }

  /// 保存配置
  Future<bool> saveConfig(RobotConfig config) async {
    try {
      // 验证配置
      final validation = _configService.validateRobotConfig(config);
      if (!validation.isValid) {
        throw Exception('配置验证失败: ${validation.errors.join(', ')}');
      }

      final success = await _configService.saveRobotConfig(config);
      if (success) {
        _robotConfig = config;
        print('[RobotProvider] 配置保存成功');
        notifyListeners();

        // 配置更新后立即检查状态
        await checkRobotState();
      }

      return success;
    } catch (error) {
      print('[RobotProvider] 保存配置失败: $error');
      return false;
    }
  }

  /// 更新机器人基本信息
  Future<bool> updateRobotInfo({String? name, String? ip, int? port}) async {
    if (_robotConfig == null) {
      // 如果没有配置，创建新的
      _robotConfig = RobotConfig.defaultConfig();
    }

    final updatedConfig = _robotConfig!.copyWith(
      name: name,
      ip: ip,
      port: port,
    );

    return await saveConfig(updatedConfig);
  }

  /// 添加场景
  Future<bool> addScene(
    String name,
    String sceneId, {
    String? imagePath,
  }) async {
    if (_robotConfig == null) return false;

    // 检查场景ID是否已存在
    if (_robotConfig!.scenes.any((s) => s.sceneId == sceneId)) {
      throw Exception('场景ID "$sceneId" 已存在');
    }

    final scene = SceneButton(
      id: _configService.generateSceneId(),
      name: name,
      sceneId: sceneId,
      imagePath: imagePath,
    );

    final updatedConfig = _robotConfig!.addScene(scene);
    return await saveConfig(updatedConfig);
  }

  /// 更新场景
  Future<bool> updateScene(
    String sceneId, {
    String? name,
    String? newSceneId,
    String? imagePath,
    bool clearImagePath = false,
  }) async {
    if (_robotConfig == null) return false;

    final scene = _robotConfig!.scenes.firstWhere(
      (s) => s.id == sceneId,
      orElse: () => throw Exception('场景不存在'),
    );

    // 如果要更新场景ID，检查新ID是否重复
    if (newSceneId != null && newSceneId != scene.sceneId) {
      if (_robotConfig!.scenes.any(
        (s) => s.sceneId == newSceneId && s.id != sceneId,
      )) {
        throw Exception('场景ID "$newSceneId" 已存在');
      }
    }

    final updatedScene = scene.copyWith(
      name: name,
      sceneId: newSceneId,
      imagePath: imagePath,
      clearImagePath: clearImagePath,
    );

    final updatedConfig = _robotConfig!.updateScene(sceneId, updatedScene);
    return await saveConfig(updatedConfig);
  }

  /// 删除场景
  Future<bool> removeScene(String sceneId) async {
    if (_robotConfig == null) return false;

    final updatedConfig = _robotConfig!.removeScene(sceneId);
    return await saveConfig(updatedConfig);
  }

  /// 执行场景
  Future<void> executeScene(String sceneId) async {
    if (_robotConfig == null) {
      throw Exception('未配置机器人');
    }

    if (_robotState == RobotState.unknown) {
      throw Exception('机器人离线');
    }

    final scene = _robotConfig!.scenes.firstWhere(
      (s) => s.sceneId == sceneId,
      orElse: () => throw Exception('场景不存在'),
    );

    try {
      print('[RobotProvider] 开始执行场景: ${scene.name}');

      await _rpcClient.startTask(
        _robotConfig!.ip,
        _robotConfig!.port,
        scene.sceneId,
      );

      print('[RobotProvider] 场景执行成功: ${scene.name}');

      // 场景启动后立即检查状态
      await checkRobotState();
    } catch (error) {
      print('[RobotProvider] 场景执行失败: $error');
      rethrow;
    }
  }

  /// 检查机器人状态
  Future<void> checkRobotState() async {
    if (_robotConfig == null) {
      _updateRobotState(RobotState.unknown);
      return;
    }

    try {
      final state = await _rpcClient.getRobotState(
        _robotConfig!.ip,
        _robotConfig!.port,
      );

      _updateRobotState(state);
    } catch (error) {
      print('[RobotProvider] 检查机器人状态失败: $error');
      _updateRobotState(RobotState.unknown);
    }
  }

  /// 更新机器人状态
  void _updateRobotState(RobotState newState) {
    if (_robotState != newState) {
      _robotState = newState;
      _lastStateCheck = DateTime.now();

      print('[RobotProvider] 机器人状态更新: $_robotState');
      notifyListeners();
    }
  }

  /// 开始定时状态检查
  void _startStatusCheck() {
    _statusCheckTimer?.cancel();

    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => checkRobotState(),
    );

    print('[RobotProvider] 定时状态检查已启动');
  }

  /// 停止定时状态检查
  void stopStatusCheck() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
    print('[RobotProvider] 定时状态检查已停止');
  }

  /// 重置配置
  Future<void> resetConfig() async {
    try {
      await _configService.deleteRobotConfig();
      _robotConfig = null;
      _robotState = RobotState.unknown;
      _lastStateCheck = null;

      print('[RobotProvider] 配置已重置');
      notifyListeners();
    } catch (error) {
      print('[RobotProvider] 重置配置失败: $error');
    }
  }

  /// 获取状态显示文本
  String getStateText() {
    switch (_robotState) {
      case RobotState.idle:
        return '空闲';
      case RobotState.running:
        return '运行中';
      case RobotState.paused:
        return '暂停';
      case RobotState.stopped:
        return '已停止';
      case RobotState.error:
        return '错误';
      case RobotState.disabled:
        return '未启用';
      case RobotState.unknown:
        return '离线';
    }
  }

  /// 获取状态颜色
  String getStateColor() {
    switch (_robotState) {
      case RobotState.idle:
        return 'green';
      case RobotState.running:
        return 'blue';
      case RobotState.paused:
        return 'orange';
      case RobotState.stopped:
        return 'gray';
      case RobotState.error:
        return 'red';
      case RobotState.disabled:
        return 'gray';
      case RobotState.unknown:
        return 'gray';
    }
  }

  @override
  void dispose() {
    stopStatusCheck();
    print('[RobotProvider] RobotProvider disposed');
    super.dispose();
  }
}
