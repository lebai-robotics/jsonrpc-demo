/// 场景按钮数据模型
/// 包含场景的ID、名称、场景编号和可选的图片路径
class SceneButton {
  final String id;
  final String name;
  final String sceneId;
  final String? imagePath;

  const SceneButton({
    required this.id,
    required this.name,
    required this.sceneId,
    this.imagePath,
  });

  /// 从JSON创建SceneButton实例
  factory SceneButton.fromJson(Map<String, dynamic> json) {
    return SceneButton(
      id: json['id'] as String,
      name: json['name'] as String,
      sceneId: json['scene'] as String,
      imagePath: json['imagePath'] as String?,
    );
  }

  /// 将SceneButton转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scene': sceneId,
      if (imagePath != null) 'imagePath': imagePath,
    };
  }

  /// 创建副本，可选择性更新字段
  SceneButton copyWith({
    String? id,
    String? name,
    String? sceneId,
    String? imagePath,
    bool clearImagePath = false,
  }) {
    return SceneButton(
      id: id ?? this.id,
      name: name ?? this.name,
      sceneId: sceneId ?? this.sceneId,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneButton &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          sceneId == other.sceneId &&
          imagePath == other.imagePath;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ sceneId.hashCode ^ imagePath.hashCode;

  @override
  String toString() {
    return 'SceneButton{id: $id, name: $name, sceneId: $sceneId, imagePath: $imagePath}';
  }
}
