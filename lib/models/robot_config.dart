import 'scene_button.dart';

/// 机械臂配置数据模型
/// 包含机械臂的基本信息和场景列表
class RobotConfig {
  final String id;
  final String name;
  final String ip;
  final int port;
  final List<SceneButton> scenes;

  const RobotConfig({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.scenes,
  });

  /// 从JSON创建RobotConfig实例
  factory RobotConfig.fromJson(Map<String, dynamic> json) {
    final scenesData = json['buttons'] as List<dynamic>? ?? [];
    final scenes = scenesData
        .map(
          (sceneJson) =>
              SceneButton.fromJson(sceneJson as Map<String, dynamic>),
        )
        .toList();

    return RobotConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      ip: json['ip'] as String,
      port: json['port'] as int,
      scenes: scenes,
    );
  }

  /// 将RobotConfig转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip': ip,
      'port': port,
      'buttons': scenes.map((scene) => scene.toJson()).toList(),
    };
  }

  /// 创建默认配置
  factory RobotConfig.defaultConfig() {
    return const RobotConfig(
      id: 'robot_1',
      name: '乐白机械臂-1',
      ip: '192.168.4.69',
      port: 3031,
      scenes: [],
    );
  }

  /// 创建副本，可选择性更新字段
  RobotConfig copyWith({
    String? id,
    String? name,
    String? ip,
    int? port,
    List<SceneButton>? scenes,
  }) {
    return RobotConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      scenes: scenes ?? this.scenes,
    );
  }

  /// 添加场景
  RobotConfig addScene(SceneButton scene) {
    final newScenes = List<SceneButton>.from(scenes)..add(scene);
    return copyWith(scenes: newScenes);
  }

  /// 更新场景
  RobotConfig updateScene(String sceneId, SceneButton updatedScene) {
    final newScenes = scenes
        .map((scene) => scene.id == sceneId ? updatedScene : scene)
        .toList();
    return copyWith(scenes: newScenes);
  }

  /// 删除场景
  RobotConfig removeScene(String sceneId) {
    final newScenes = scenes.where((scene) => scene.id != sceneId).toList();
    return copyWith(scenes: newScenes);
  }

  /// 验证IP地址格式
  static bool isValidIP(String ip) {
    final ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return ipRegex.hasMatch(ip);
  }

  /// 验证端口号
  static bool isValidPort(int port) {
    return port >= 1 && port <= 65535;
  }

  /// 验证配置
  bool get isValid {
    return name.isNotEmpty && isValidIP(ip) && isValidPort(port);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RobotConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          ip == other.ip &&
          port == other.port &&
          scenes.length == other.scenes.length &&
          _listEquals(scenes, other.scenes);

  bool _listEquals(List<SceneButton> a, List<SceneButton> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      ip.hashCode ^
      port.hashCode ^
      scenes.hashCode;

  @override
  String toString() {
    return 'RobotConfig{id: $id, name: $name, ip: $ip, port: $port, scenes: ${scenes.length}}';
  }
}
