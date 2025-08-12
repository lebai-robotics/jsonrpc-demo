import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/robot_config.dart';
import '../models/scene_button.dart';
import '../providers/robot_provider.dart';
import '../services/config_service.dart';
import '../widgets/robot_status.dart';

/// 配置页面
/// 用于配置机器人信息和管理场景列表
class ConfigScreen extends StatefulWidget {
  final String? initialSceneId;

  const ConfigScreen({super.key, this.initialSceneId});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 机器人配置表单
  final _robotFormKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ipController;
  late TextEditingController _portController;

  // 场景配置表单
  final _sceneFormKey = GlobalKey<FormState>();
  late TextEditingController _sceneNameController;
  late TextEditingController _sceneIdController;
  late TextEditingController _sceneParamsController;

  String? _editingSceneId; // 正在编辑的场景ID
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 初始化控制器
    _nameController = TextEditingController();
    _ipController = TextEditingController();
    _portController = TextEditingController();
    _sceneNameController = TextEditingController();
    _sceneIdController = TextEditingController();
    _sceneParamsController = TextEditingController();

    // 如果有初始场景ID，切换到场景配置标签页
    if (widget.initialSceneId != null) {
      _tabController.index = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editScene(widget.initialSceneId!);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _sceneNameController.dispose();
    _sceneIdController.dispose();
    _sceneParamsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('机器人配置'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.settings, size: 32), text: '基本设置'),
            Tab(icon: Icon(Icons.apps, size: 32), text: '场景管理'),
          ],
        ),
      ),
      body: Consumer<RobotProvider>(
        builder: (context, robotProvider, child) {
          // 初始化表单数据
          _loadRobotConfig(robotProvider.robotConfig);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                ],
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRobotConfigTab(context, robotProvider),
                _buildSceneManagementTab(context, robotProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 加载机器人配置到表单
  void _loadRobotConfig(RobotConfig? config) {
    if (config != null && _nameController.text.isEmpty) {
      _nameController.text = config.name;
      _ipController.text = config.ip;
      _portController.text = config.port.toString();
    }
  }

  /// 构建机器人配置标签页
  Widget _buildRobotConfigTab(
    BuildContext context,
    RobotProvider robotProvider,
  ) {
    const double _inputGap = 20;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当前状态卡片
          if (robotProvider.hasConfig)
            RobotStatus(
              robotName: robotProvider.robotConfig?.name,
              robotIp: robotProvider.robotConfig?.ip,
              robotPort: robotProvider.robotConfig?.port,
              robotState: robotProvider.robotState,
              lastCheck: robotProvider.lastStateCheck,
              onRefresh: () => robotProvider.checkRobotState(),
            ),

          if (robotProvider.hasConfig) const SizedBox(height: 24),

          // 配置表单
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _robotFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '机器人配置',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 机器人名称
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '机器人名称',
                        hintText: '请输入机器人名称',
                        prefixIcon: Icon(Icons.label),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入机器人名称';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: _inputGap),

                    // IP地址
                    TextFormField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP地址',
                        hintText: '192.168.1.100',
                        prefixIcon: Icon(Icons.wifi),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {},
                      // inputFormatters: [
                      //   FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      // ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入IP地址';
                        }
                        // if (!RobotConfig.isValidIP(value.trim())) {
                        //   return 'IP地址格式无效';
                        // }
                        return null;
                      },
                    ),

                    const SizedBox(height: _inputGap),

                    // 端口号
                    TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: '端口号',
                        hintText: '3031（真机环境）',
                        prefixIcon: Icon(Icons.router),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入端口号';
                        }
                        final port = int.tryParse(value.trim());
                        if (port == null || !RobotConfig.isValidPort(port)) {
                          return '端口号无效（应为1-65535）';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // 保存按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _saveRobotConfig(robotProvider),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save, size: 24),
                        label: Text(
                          _isLoading ? '保存中...' : '保存配置',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontSize: 24),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 预设配置
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '快速配置',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _setPresetConfig('3031'),
                          child: const Text('真机环境 (3031)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _setPresetConfig('3030'),
                          child: const Text('仿真环境 (3030)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建场景管理标签页
  Widget _buildSceneManagementTab(
    BuildContext context,
    RobotProvider robotProvider,
  ) {
    final scenes = robotProvider.scenes;

    return Column(
      children: [
        // 添加场景按钮
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            onPressed: () => _showSceneDialog(context, robotProvider),
            icon: const Icon(Icons.add),
            label: const Text('添加场景', style: TextStyle(fontSize: 24)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        // 场景列表
        Expanded(
          child: scenes.isEmpty
              ? _buildEmptyScenesList()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: scenes.length,
                  itemBuilder: (context, index) {
                    final scene = scenes[index];
                    return _buildSceneListItem(context, scene, robotProvider);
                  },
                ),
        ),
      ],
    );
  }

  /// 构建空场景列表
  Widget _buildEmptyScenesList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text('暂无场景', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '点击上方按钮添加第一个场景',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建场景列表项
  Widget _buildSceneListItem(
    BuildContext context,
    SceneButton scene,
    RobotProvider robotProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        // leading: Container(
        //   padding: const EdgeInsets.all(8),
        //   decoration: BoxDecoration(
        //     color: Theme.of(context).colorScheme.primaryContainer,
        //     borderRadius: BorderRadius.circular(8),
        //   ),
        //   child: Icon(
        //     Icons.smart_toy_outlined,
        //     color: Theme.of(context).colorScheme.onPrimaryContainer,
        //   ),
        // ),
        title: Text(
          scene.name,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('场景 ${scene.sceneId}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 上传图片
            IconButton(
              onPressed: () => _uploadImage(context, scene, robotProvider),
              icon: const Icon(Icons.upload),
              tooltip: '上传图片',
            ),
            // 编辑场景
            IconButton(
              onPressed: () => _editScene(scene.id),
              icon: const Icon(Icons.edit),
              tooltip: '编辑',
            ),
            // IconButton(
            //   icon: SvgPicture.asset(
            //     'assets/icons/params.svg',
            //     width: 24,
            //     height: 24,
            //   ),
            //   onPressed: () => _editParams(context, scene, robotProvider),
            // ),
            IconButton(
              onPressed: () => _deleteScene(context, scene, robotProvider),
              icon: const Icon(Icons.delete),
              color: Theme.of(context).colorScheme.error,
              tooltip: '删除',
            ),
          ],
        ),
      ),
    );
  }

  /// 保存机器人配置
  Future<void> _saveRobotConfig(RobotProvider robotProvider) async {
    if (!_robotFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await robotProvider.updateRobotInfo(
        name: _nameController.text.trim(),
        ip: _ipController.text.trim(),
        port: int.parse(_portController.text.trim()),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('配置保存成功'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('保存失败');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 设置预设配置
  void _setPresetConfig(String port) {
    _portController.text = port;
    if (_nameController.text.isEmpty) {
      _nameController.text = '乐白机械臂-1';
    }
    if (_ipController.text.isEmpty) {
      _ipController.text = '192.168.1.100';
    }
  }

  /// 显示场景配置对话框
  Future<void> _showSceneDialog(
    BuildContext context,
    RobotProvider robotProvider,
  ) async {
    _sceneNameController.clear();
    _sceneIdController.clear();
    _sceneParamsController.clear();
    _editingSceneId = null;

    return showDialog<void>(
      context: context,
      builder: (context) => _buildSceneDialog(context, robotProvider),
    );
  }

  /// 编辑场景
  void _editScene(String sceneId) {
    final robotProvider = Provider.of<RobotProvider>(context, listen: false);
    final scene = robotProvider.scenes.firstWhere((s) => s.id == sceneId);

    _sceneNameController.text = scene.name;
    _sceneIdController.text = scene.sceneId;
    _sceneParamsController.text = scene.params ?? '';
    _editingSceneId = sceneId;

    showDialog<void>(
      context: context,
      builder: (context) => _buildSceneDialog(context, robotProvider),
    );
  }

  /// 构建场景配置对话框
  Widget _buildSceneDialog(BuildContext context, RobotProvider robotProvider) {
    final isEditing = _editingSceneId != null;

    return AlertDialog(
      title: Text(
        isEditing ? '编辑场景' : '添加场景',
        style: const TextStyle(fontSize: 24),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _sceneFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _sceneNameController,
                decoration: const InputDecoration(
                  labelText: '场景名称',
                  hintText: '请输入场景名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入场景名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sceneIdController,
                decoration: const InputDecoration(
                  labelText: '场景ID',
                  hintText: '请输入场景ID（数字）',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入场景ID';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return '场景ID必须是数字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                maxLines: 1,
                controller: _sceneParamsController,
                decoration: const InputDecoration(
                  labelText: '场景参数（目前只支持输入一个字符串参数）',
                  hintText: '请输入场景参数',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消', style: TextStyle(fontSize: 16)),
        ),
        ElevatedButton(
          onPressed: () => _saveScene(context, robotProvider),
          child: Text(
            isEditing ? '保存' : '添加',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  /// 保存场景
  Future<void> _saveScene(
    BuildContext context,
    RobotProvider robotProvider,
  ) async {
    if (!_sceneFormKey.currentState!.validate()) return;

    try {
      final name = _sceneNameController.text.trim();
      final sceneId = _sceneIdController.text.trim();
      final params = _sceneParamsController.text.trim();

      if (_editingSceneId != null) {
        // 编辑场景
        await robotProvider.updateScene(
          _editingSceneId!,
          name: name,
          newSceneId: sceneId,
          params: params,
        );
      } else {
        // 添加场景
        await robotProvider.addScene(name, sceneId);
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingSceneId != null ? '场景更新成功' : '场景添加成功'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
        content: Text('确定要删除场景 "${scene.name}" 吗？'),
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

  /// 上传场景图片
  Future<void> _uploadImage(
    BuildContext context,
    SceneButton scene,
    RobotProvider robotProvider,
  ) async {
    try {
      // 选择图片源
      final imageSource = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择图片来源'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (imageSource == null) return;

      // 选择图片
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: imageSource,
        maxWidth: 800, // 限制图片宽度，减少存储空间
        maxHeight: 600, // 限制图片高度
        imageQuality: 85, // 压缩质量
      );

      if (pickedFile == null) return;

      print('pickedImageFile: ${pickedFile.path}');

      if (!context.mounted) return;

      // 显示加载状态
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // 获取ConfigService实例
        final configService = ConfigService();
        await configService.initialize();

        // 如果场景已有图片，先删除旧图片
        if (scene.imagePath != null) {
          await configService.deleteSceneImage(scene.imagePath!);
        }

        // 保存新图片
        final newImagePath = await configService.saveSceneImage(
          scene.id,
          pickedFile.path,
        );

        // 更新场景配置
        await robotProvider.updateScene(scene.id, imagePath: newImagePath);

        if (context.mounted) {
          Navigator.of(context).pop(); // 关闭加载对话框
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('场景 "${scene.name}" 图片上传成功'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (error) {
        if (context.mounted) {
          Navigator.of(context).pop(); // 关闭加载对话框
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('图片上传失败: ${error.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择图片失败: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
