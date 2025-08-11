import 'package:flutter/material.dart';
import '../services/jsonrpc_client.dart';

/// 机器人状态显示组件
/// 显示机器人的在线状态、IP地址等信息
class RobotStatus extends StatelessWidget {
  final String? robotName;
  final String? robotIp;
  final int? robotPort;
  final RobotState robotState;
  final DateTime? lastCheck;
  final VoidCallback? onRefresh;
  final VoidCallback? onConfig;

  const RobotStatus({
    super.key,
    this.robotName,
    this.robotIp,
    this.robotPort,
    required this.robotState,
    this.lastCheck,
    this.onRefresh,
    this.onConfig,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 6,
      shadowColor: colorScheme.shadow.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surfaceContainerHighest,
              colorScheme.surfaceContainer,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                Icon(
                  Icons.precision_manufacturing,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        robotName ?? '未配置机器人',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (robotIp != null && robotPort != null)
                        Text(
                          '$robotIp:$robotPort',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                // 配置按钮
                IconButton(
                  onPressed: onConfig,
                  icon: Icon(
                    Icons.settings,
                    color: colorScheme.primary,
                    size: 40,
                  ),
                  tooltip: '配置机器人',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 状态信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusBackgroundColor(colorScheme),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(colorScheme),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // 状态指示器
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(colorScheme),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(colorScheme).withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 状态文本
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusText(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (lastCheck != null)
                          Text(
                            '更新时间: ${_formatTime(lastCheck!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 刷新按钮
                  IconButton(
                    onPressed: onRefresh,
                    icon: Icon(Icons.refresh, color: colorScheme.primary),
                    tooltip: '刷新状态',
                  ),
                ],
              ),
            ),

            // 网络提示
            if (robotState == RobotState.unknown && robotIp != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      color: colorScheme.onErrorContainer,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '请确保机器人和您的设备在同一个网络中',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 获取状态文本
  String _getStatusText() {
    switch (robotState) {
      case RobotState.booting:
        return '启动中 - 机器人正在启动';
      case RobotState.starting:
        return '启动中 - 机器人正在启动';
      case RobotState.stopping:
        return '停止中 - 机器人正在停止';
      case RobotState.updating:
        return '更新中 - 机器人正在更新';
      case RobotState.robotOn:
        return '初始化完成';
      case RobotState.idle:
        return '空闲 - 准备就绪';
      case RobotState.running:
        return '运行中 - 正在执行任务';
      case RobotState.paused:
        return '暂停 - 任务已暂停';
      case RobotState.stopped:
        return '已停止 - 任务已停止';
      case RobotState.error:
        return '错误 - 请检查机器人状态';
      case RobotState.disabled:
        return '未启用 - 机器人未启用';
      case RobotState.unknown:
        return '未知情况';
      case RobotState.teaching:
        return '示教中 - 机器人正在示教';
      case RobotState.disconnected:
        return '离线 - 无法连接到机器人';
    }
  }

  /// 获取状态颜色
  Color _getStatusColor(ColorScheme colorScheme) {
    switch (robotState) {
      case RobotState.booting:
        return Colors.yellowAccent;
      case RobotState.starting:
        return Colors.deepOrangeAccent;
      case RobotState.stopping:
        return Colors.blueGrey;
      case RobotState.updating:
        return Colors.deepPurpleAccent;
      case RobotState.robotOn:
        return Colors.yellowAccent;
      case RobotState.idle:
        return Colors.green;
      case RobotState.running:
        return Colors.blue;
      case RobotState.paused:
        return Colors.orange;
      case RobotState.stopped:
        return colorScheme.outline;
      case RobotState.error:
        return Colors.red;
      case RobotState.disabled:
        return colorScheme.outline;
      case RobotState.unknown:
        return colorScheme.outline;
      case RobotState.teaching:
        return Colors.purple;
      case RobotState.disconnected:
        return colorScheme.outline;
    }
  }

  /// 获取状态背景颜色
  Color _getStatusBackgroundColor(ColorScheme colorScheme) {
    switch (robotState) {
      case RobotState.booting:
        return Colors.yellowAccent.withOpacity(0.1);
      case RobotState.starting:
        return Colors.deepOrangeAccent.withOpacity(0.1);
      case RobotState.stopping:
        return Colors.blueGrey.withOpacity(0.1);
      case RobotState.updating:
        return Colors.deepPurpleAccent.withOpacity(0.1);
      case RobotState.robotOn:
        return Colors.yellowAccent.withOpacity(0.1);
      case RobotState.idle:
        return Colors.green.withOpacity(0.1);
      case RobotState.running:
        return Colors.blue.withOpacity(0.1);
      case RobotState.paused:
        return Colors.orange.withOpacity(0.1);
      case RobotState.stopped:
        return colorScheme.surfaceContainerHighest;
      case RobotState.error:
        return Colors.red.withOpacity(0.1);
      case RobotState.disabled:
        return colorScheme.surfaceContainerHighest;
      case RobotState.unknown:
        return colorScheme.surfaceContainerHighest;
      case RobotState.teaching:
        return Colors.purple.withOpacity(0.1);
      case RobotState.disconnected:
        return colorScheme.surfaceContainerHighest;
    }
  }

  /// 格式化时间
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// 简化版机器人状态卡片（用于配置页面等）
class RobotStatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final RobotState state;
  final Widget? trailing;

  const RobotStatusCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.state,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: _getStatusColor(colorScheme),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing,
    );
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    switch (state) {
      case RobotState.booting:
        return Colors.yellowAccent;
      case RobotState.starting:
        return Colors.deepOrangeAccent;
      case RobotState.stopping:
        return Colors.blueGrey;
      case RobotState.updating:
        return Colors.deepPurpleAccent;
      case RobotState.robotOn:
        return Colors.yellowAccent;
      case RobotState.idle:
        return Colors.green;
      case RobotState.running:
        return Colors.blue;
      case RobotState.paused:
        return Colors.orange;
      case RobotState.stopped:
        return colorScheme.outline;
      case RobotState.error:
        return Colors.red;
      case RobotState.disabled:
        return colorScheme.outline;
      case RobotState.teaching:
        return Colors.deepPurpleAccent;
      case RobotState.unknown:
        return colorScheme.outline;
      case RobotState.disconnected:
        return colorScheme.outline;
    }
  }
}
