import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/help.dart';
import '../models/scene_button.dart';
import '../providers/app_state.dart';
import '../providers/robot_provider.dart';
import '../widgets/robot_status.dart';
import '../widgets/scene_card.dart';
import '../widgets/loading_overlay.dart';
import 'config_screen.dart';

/// 首页界面
/// 显示机器人状态和场景卡片列表
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<AppState, RobotProvider>(
        builder: (context, appState, robotProvider, child) {
          return LoadingOverlay(
            isLoading: appState.isLoading,
            message: appState.loadingMessage,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // 顶部标题栏
                    _buildAppBar(context, robotProvider),

                    // 主要内容区域
                    Expanded(
                      child: _buildMainContent(
                        context,
                        appState,
                        robotProvider,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建应用栏
  Widget _buildAppBar(BuildContext context, RobotProvider robotProvider) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // 应用图标和标题
          // Container(
          //   padding: const EdgeInsets.all(12),
          //   decoration: BoxDecoration(
          //     color: theme.colorScheme.primaryContainer,
          //     borderRadius: BorderRadius.circular(16),
          //   ),
          //   child: Icon(
          //     Icons.smart_toy,
          //     color: theme.colorScheme.onPrimaryContainer,
          //     size: 28,
          //   ),
          // ),
          // const SizedBox(width: 16),
          // Expanded(
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         '乐白机械臂控制',
          //         style: theme.textTheme.headlineSmall?.copyWith(
          //           color: theme.colorScheme.onSurface,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //       Text(
          //         '机器人场景控制中心',
          //         style: theme.textTheme.bodyMedium?.copyWith(
          //           color: theme.colorScheme.onSurfaceVariant,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // 配置按钮
          // IconButton(
          //   onPressed: () => _navigateToConfig(context),
          //   icon: Icon(
          //     Icons.settings,
          //     color: theme.colorScheme.primary,
          //     size: 28,
          //   ),
          //   tooltip: '配置',
          //   style: IconButton.styleFrom(
          //     backgroundColor: theme.colorScheme.surfaceContainer,
          //     padding: const EdgeInsets.all(12),
          //   ),
          // ),
        ],
      ),
    );
  }

  /// 构建主要内容
  Widget _buildMainContent(
    BuildContext context,
    AppState appState,
    RobotProvider robotProvider,
  ) {
    if (!robotProvider.isConfigLoaded) {
      // 配置加载中
      return const Center(child: SimpleLoading(message: '正在加载配置...', size: 32));
    }

    if (!robotProvider.hasConfig) {
      // 未配置状态
      return _buildWelcomeScreen(context);
    }

    // 正常内容
    return RefreshIndicator(
      onRefresh: () => robotProvider.checkRobotState(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 机器人状态区域
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RobotStatus(
                robotName: robotProvider.robotConfig?.name,
                robotIp: robotProvider.robotConfig?.ip,
                robotPort: robotProvider.robotConfig?.port,
                robotState: robotProvider.robotState,
                lastCheck: robotProvider.lastStateCheck,
                onRefresh: () => robotProvider.checkRobotState(),
                onConfig: () => _navigateToConfig(context),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // 场景列表标题
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.apps,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '场景列表',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${robotProvider.scenes.length} 个场景',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 场景卡片网格
          _buildSceneGrid(context, appState, robotProvider),
        ],
      ),
    );
  }

  /// 构建场景网格
  Widget _buildSceneGrid(
    BuildContext context,
    AppState appState,
    RobotProvider robotProvider,
  ) {
    final scenes = robotProvider.scenes;
    final isTaskRunning = appState.isTaskRunning;
    final isRobotOnline = robotProvider.isOnline;

    if (scenes.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyScenes(context));
    }

    // 计算列数（响应式设计）
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _calculateCrossAxisCount(screenWidth);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 3 / 2, // 保持3:2比例
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final scene = scenes[index];
          final isExecuting =
              appState.isTaskRunning &&
              appState.currentRobotId == robotProvider.robotConfig?.id;

          return SceneCard(
            scene: scene,
            isEnabled: !isTaskRunning && isRobotOnline,
            isExecuting: isExecuting,
            onExecute: () =>
                _executeScene(context, scene, appState, robotProvider),
            onEdit: () => _editScene(context, scene),
            onDelete: () => _deleteScene(context, scene, robotProvider),
          );
        }, childCount: scenes.length),
      ),
    );
  }

  /// 计算网格列数
  int _calculateCrossAxisCount(double screenWidth) {
    print('screenWidth: $screenWidth');
    if (screenWidth > 1200) {
      return 3; // 大屏幕显示3列
    } else if (screenWidth >= 800) {
      return 2; // 平板显示2列
    } else {
      return 1; // 手机显示1列
    }
  }

  /// 构建欢迎界面
  Widget _buildWelcomeScreen(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 欢迎图标
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 80,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),

            const SizedBox(height: 32),

            // 欢迎标题
            Text(
              '欢迎使用乐白机械臂控制中心',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // 提示文本
            Text(
              '请确保机器人和您的设备在同一个网络中\n首次使用需要先配置机械臂设备',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // 配置按钮
            ElevatedButton.icon(
              onPressed: () => _navigateToConfig(context),
              icon: const Icon(Icons.settings, size: 28),
              label: const Text('开始配置'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空场景界面
  Widget _buildEmptyScenes(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apps,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无配置场景',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请前往配置页面添加机器人场景',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToConfig(context),
              icon: const Icon(Icons.add),
              label: const Text('添加场景'),
            ),
          ],
        ),
      ),
    );
  }

  /// 执行场景
  Future<void> _executeScene(
    BuildContext context,
    SceneButton scene,
    AppState appState,
    RobotProvider robotProvider,
  ) async {
    try {
      appState.setTaskRunning(
        true,
        taskId: scene.id,
        robotId: robotProvider.robotConfig?.id,
      );
      appState.setLoading(true, '正在执行场景 ${scene.name}...');
      print('执行场景 ${scene.sceneId}...');

      await robotProvider.executeScene(scene.sceneId);
      await sleep(1500);
      appState.setLoading(false);
      appState.setTaskRunning(false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '场景 "${scene.name}" 执行成功',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF1BAE70),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      appState.setLoading(false);
      appState.setTaskRunning(false);
      appState.setError(error.toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('执行失败: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 编辑场景
  void _editScene(BuildContext context, SceneButton scene) {
    _navigateToConfig(context, selectedSceneId: scene.id);
  }

  /// 删除场景
  Future<void> _deleteScene(
    BuildContext context,
    SceneButton scene,
    RobotProvider robotProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除场景 "${scene.name}" 吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await robotProvider.removeScene(scene.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('场景 "${scene.name}" 已删除'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败: ${error.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// 导航到配置页面
  void _navigateToConfig(BuildContext context, {String? selectedSceneId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConfigScreen(initialSceneId: selectedSceneId),
      ),
    );
  }
}
