import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scene_button.dart';

/// 场景卡片组件
/// 显示场景信息并支持执行操作，采用3:2的宽高比
class SceneCard extends StatelessWidget {
  final SceneButton scene;
  final bool isEnabled;
  final bool isExecuting;
  final VoidCallback? onExecute;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SceneCard({
    super.key,
    required this.scene,
    this.isEnabled = true,
    this.isExecuting = false,
    this.onExecute,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 8,
      shadowColor: colorScheme.shadow.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 3 / 5, // 3:2 比例
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainerHighest,
                colorScheme.surfaceContainer,
              ],
            ),
          ),
          child: Stack(
            children: [
              // 背景图片（如果有）
              if (scene.imagePath != null)
                Positioned.fill(
                  child: _buildSceneImage(scene.imagePath!, colorScheme),
                ),

              // 渐变遮罩
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        colorScheme.surface.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),

              // 内容区域
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 顶部工具栏
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 场景图标
                          // Container(
                          //   padding: const EdgeInsets.all(8),
                          //   decoration: BoxDecoration(
                          //     color: colorScheme.primaryContainer,
                          //     borderRadius: BorderRadius.circular(12),
                          //   ),
                          //   child: Icon(
                          //     Icons.smart_toy_outlined,
                          //     color: colorScheme.onPrimaryContainer,
                          //     size: 24,
                          //   ),
                          // ),

                          // 操作按钮
                          // if (onEdit != null || onDelete != null)
                          //   PopupMenuButton<String>(
                          //     icon: Icon(
                          //       Icons.more_vert,
                          //       color: colorScheme.onSurface,
                          //     ),
                          //     onSelected: (value) {
                          //       switch (value) {
                          //         case 'edit':
                          //           onEdit?.call();
                          //           break;
                          //         case 'delete':
                          //           onDelete?.call();
                          //           break;
                          //       }
                          //     },
                          //     itemBuilder: (context) => [
                          //       if (onEdit != null)
                          //         const PopupMenuItem(
                          //           value: 'edit',
                          //           child: Row(
                          //             children: [
                          //               Icon(Icons.edit),
                          //               SizedBox(width: 8),
                          //               Text('编辑'),
                          //             ],
                          //           ),
                          //         ),
                          //       if (onDelete != null)
                          //         const PopupMenuItem(
                          //           value: 'delete',
                          //           child: Row(
                          //             children: [
                          //               Icon(Icons.delete),
                          //               SizedBox(width: 8),
                          //               Text('删除'),
                          //             ],
                          //           ),
                          //         ),
                          //     ],
                          //   ),
                        ],
                      ),

                      const Spacer(),

                      // 场景信息
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scene.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '场景 ${scene.sceneId}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 执行按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isEnabled && !isExecuting
                              ? onExecute
                              : null,
                          icon: isExecuting
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Icon(
                                  Icons.play_arrow,
                                  color: colorScheme.onPrimary,
                                ),
                          label: Text(
                            // isExecuting ? '执行中...' : '执行场景',
                            "点单",
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEnabled
                                ? Colors.red
                                : colorScheme.outline,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: isEnabled ? 4 : 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 禁用状态遮罩
              if (!isEnabled)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.block,
                        size: 48,
                        color: colorScheme.outline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建场景图片组件
  Widget _buildSceneImage(String imagePath, ColorScheme colorScheme) {
    // 检查是否为本地文件路径
    final isLocalFile =
        !imagePath.startsWith('assets/') && File(imagePath).existsSync();

    if (isLocalFile) {
      // 使用本地文件
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(imagePath)),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              colorScheme.surface.withOpacity(0.7),
              BlendMode.overlay,
            ),
            onError: (exception, stackTrace) {
              print('加载场景图片失败: $imagePath, $exception');
            },
          ),
        ),
      );
    } else {
      // 使用资源文件（兼容旧版本）
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              colorScheme.surface.withOpacity(0.7),
              BlendMode.overlay,
            ),
            onError: (exception, stackTrace) {
              print('加载场景资源图片失败: $imagePath, $exception');
            },
          ),
        ),
      );
    }
  }
}

/// 添加场景卡片
/// 用于显示添加新场景的按钮
class AddSceneCard extends StatelessWidget {
  final VoidCallback? onAdd;

  const AddSceneCard({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shadowColor: colorScheme.shadow.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.5), width: 2),
      ),
      child: AspectRatio(
        aspectRatio: 3 / 2, // 保持相同比例
        child: InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  colorScheme.surfaceContainer.withOpacity(0.3),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 32,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '添加场景',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '点击添加新的机器人场景',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
