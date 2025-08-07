import 'package:flutter/foundation.dart';

/// 应用全局状态管理
/// 管理任务执行状态、连接状态等全局信息
class AppState extends ChangeNotifier {
  // 任务执行状态
  bool _isTaskRunning = false;
  String? _currentTaskId;
  String? _currentRobotId;

  // 加载状态
  bool _isLoading = false;
  String _loadingMessage = '';

  // 错误状态
  String? _lastError;

  // 应用设置
  Map<String, dynamic> _settings = {
    'timeout': 5000,
    'retryCount': 3,
    'checkInterval': 10000,
    'theme': 'dark',
  };

  // Getters
  bool get isTaskRunning => _isTaskRunning;
  String? get currentTaskId => _currentTaskId;
  String? get currentRobotId => _currentRobotId;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  String? get lastError => _lastError;
  Map<String, dynamic> get settings => Map.unmodifiable(_settings);

  /// 设置任务运行状态
  void setTaskRunning(bool isRunning, {String? taskId, String? robotId}) {
    _isTaskRunning = isRunning;
    _currentTaskId = isRunning ? taskId : null;
    _currentRobotId = isRunning ? robotId : null;

    print('[AppState] 任务状态更新: $isRunning, 任务ID: $taskId, 机器人ID: $robotId');
    notifyListeners();
  }

  /// 设置加载状态
  void setLoading(bool isLoading, [String message = '加载中...']) {
    _isLoading = isLoading;
    _loadingMessage = message;

    if (!isLoading) {
      _loadingMessage = '';
    }

    notifyListeners();
  }

  /// 设置错误信息
  void setError(String? error) {
    _lastError = error;

    if (error != null) {
      print('[AppState] 错误信息: $error');
    }

    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// 更新设置
  void updateSettings(Map<String, dynamic> newSettings) {
    _settings = {..._settings, ...newSettings};
    print('[AppState] 设置已更新: $newSettings');
    notifyListeners();
  }

  /// 获取设置值
  T getSetting<T>(String key, T defaultValue) {
    return _settings[key] as T? ?? defaultValue;
  }

  /// 重置所有状态
  void reset() {
    _isTaskRunning = false;
    _currentTaskId = null;
    _currentRobotId = null;
    _isLoading = false;
    _loadingMessage = '';
    _lastError = null;

    print('[AppState] 状态已重置');
    notifyListeners();
  }

  @override
  void dispose() {
    print('[AppState] AppState disposed');
    super.dispose();
  }
}
