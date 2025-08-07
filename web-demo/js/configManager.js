/**
 * 配置管理模块
 * 负责机械臂配置的增删改查和验证
 */

// 默认配置常量（避免 CORS 问题，不再从 config.json 加载）
const DEFAULT_CONFIG = {
  "version": "1.0.0",
  "robots": [
    {
      "id": "1",
      "name": "乐白机械臂-1",
      "ip": "192.168.4.69",
      "port": 3031,
      "type": "real",
      "buttons": [
        {
          "id": "scene_001",
          "name": "张庆风调用jsonrpc",
          "scene": "10279"
        }
      ]
    }
  ],
  "settings": {
    "timeout": 5000,
    "retryCount": 3,
    "checkInterval": 10000
  }
};

class ConfigManager {
  constructor(stateManager) {
    this.stateManager = stateManager;
    this.appState = stateManager.getAppState();
  }

  /**
   * 初始化配置（从默认配置文件或localStorage）
   */
  async initializeConfig() {
    // 首先尝试从localStorage加载
    const savedConfig = this.appState.get('robotsConfig');

    if (savedConfig && savedConfig.length > 0) {
      console.log('[ConfigManager] 使用已保存的配置');
      return savedConfig;
    }

    // 如果没有保存的配置，尝试加载默认配置
    try {
      const defaultConfig = await this.loadDefaultConfig();
      this.appState.updateRobotsConfig(defaultConfig.robots || []);

      // 更新设置
      if (defaultConfig.settings) {
        this.appState.setState({ settings: defaultConfig.settings });
      }

      console.log('[ConfigManager] 加载默认配置成功');
      return defaultConfig.robots || [];
    } catch (error) {
      console.warn('[ConfigManager] 加载默认配置失败:', error);
      return [];
    }
  }

  /**
   * 加载默认配置（从内置配置常量）
   */
  async loadDefaultConfig() {
    // 返回内置的默认配置，避免 CORS 问题
    return Promise.resolve(DEFAULT_CONFIG);
  }

  /**
   * 获取所有机械臂配置
   */
  getAllRobots() {
    return this.appState.get('robotsConfig') || [];
  }

  /**
   * 根据ID获取机械臂配置
   */
  getRobotById(robotId) {
    const robots = this.getAllRobots();
    return robots.find(robot => robot.id === robotId);
  }

  /**
   * 添加新的机械臂配置
   */
  addRobot(robotConfig) {
    // 验证配置
    const validationResult = this.validateRobotConfig(robotConfig);
    if (!validationResult.isValid) {
      throw new Error(`配置验证失败: ${validationResult.errors.join(', ')}`);
    }

    // 生成唯一ID
    if (!robotConfig.id) {
      robotConfig.id = this.generateRobotId();
    }

    // 检查ID是否已存在
    if (this.getRobotById(robotConfig.id)) {
      throw new Error(`机械臂ID "${robotConfig.id}" 已存在`);
    }

    const robots = this.getAllRobots();
    const newRobots = [...robots, robotConfig];

    this.appState.updateRobotsConfig(newRobots);

    console.log('[ConfigManager] 添加机械臂配置:', robotConfig);
    return robotConfig;
  }

  /**
   * 更新机械臂配置
   */
  updateRobot(robotId, updates) {
    const robots = this.getAllRobots();
    const robotIndex = robots.findIndex(robot => robot.id === robotId);

    if (robotIndex === -1) {
      throw new Error(`机械臂 "${robotId}" 不存在`);
    }

    // 合并更新
    const updatedRobot = { ...robots[robotIndex], ...updates };

    // 验证更新后的配置
    const validationResult = this.validateRobotConfig(updatedRobot);
    if (!validationResult.isValid) {
      throw new Error(`配置验证失败: ${validationResult.errors.join(', ')}`);
    }

    const newRobots = [...robots];
    newRobots[robotIndex] = updatedRobot;

    this.appState.updateRobotsConfig(newRobots);

    console.log('[ConfigManager] 更新机械臂配置:', updatedRobot);
    return updatedRobot;
  }

  /**
   * 删除机械臂配置
   */
  deleteRobot(robotId) {
    const robots = this.getAllRobots();
    const newRobots = robots.filter(robot => robot.id !== robotId);

    if (newRobots.length === robots.length) {
      throw new Error(`机械臂 "${robotId}" 不存在`);
    }

    this.appState.updateRobotsConfig(newRobots);

    console.log('[ConfigManager] 删除机械臂配置:', robotId);
    return true;
  }

  /**
   * 添加场景按钮
   */
  addSceneButton(robotId, buttonConfig) {
    const robot = this.getRobotById(robotId);
    if (!robot) {
      throw new Error(`机械臂 "${robotId}" 不存在`);
    }

    // 验证按钮配置
    const validationResult = this.validateButtonConfig(buttonConfig);
    if (!validationResult.isValid) {
      throw new Error(`按钮配置验证失败: ${validationResult.errors.join(', ')}`);
    }

    // 生成唯一按钮ID
    if (!buttonConfig.id) {
      buttonConfig.id = this.generateButtonId(robotId);
    }

    // 检查场景ID是否重复
    const existingButton = robot.buttons.find(btn => btn.scene === buttonConfig.scene);
    if (existingButton) {
      throw new Error(`场景 "${buttonConfig.scene}" 已存在`);
    }

    const updatedButtons = [...robot.buttons, buttonConfig];
    return this.updateRobot(robotId, { buttons: updatedButtons });
  }

  /**
   * 更新场景按钮
   */
  updateSceneButton(robotId, buttonId, updates) {
    const robot = this.getRobotById(robotId);
    if (!robot) {
      throw new Error(`机械臂 "${robotId}" 不存在`);
    }

    const buttonIndex = robot.buttons.findIndex(btn => btn.id === buttonId);
    if (buttonIndex === -1) {
      throw new Error(`按钮 "${buttonId}" 不存在`);
    }

    const updatedButton = { ...robot.buttons[buttonIndex], ...updates };

    // 验证更新后的按钮配置
    const validationResult = this.validateButtonConfig(updatedButton);
    if (!validationResult.isValid) {
      throw new Error(`按钮配置验证失败: ${validationResult.errors.join(', ')}`);
    }

    const updatedButtons = [...robot.buttons];
    updatedButtons[buttonIndex] = updatedButton;

    return this.updateRobot(robotId, { buttons: updatedButtons });
  }

  /**
   * 删除场景按钮
   */
  deleteSceneButton(robotId, buttonId) {
    const robot = this.getRobotById(robotId);
    if (!robot) {
      throw new Error(`机械臂 "${robotId}" 不存在`);
    }

    const updatedButtons = robot.buttons.filter(btn => btn.id !== buttonId);

    if (updatedButtons.length === robot.buttons.length) {
      throw new Error(`按钮 "${buttonId}" 不存在`);
    }

    return this.updateRobot(robotId, { buttons: updatedButtons });
  }

  /**
   * 验证机械臂配置
   */
  validateRobotConfig(config) {
    const errors = [];

    // 验证基本字段
    if (!config.name || typeof config.name !== 'string') {
      errors.push('名称不能为空');
    }

    if (!config.ip || !this.isValidIP(config.ip)) {
      errors.push('IP地址格式无效');
    }

    if (!config.port || !this.isValidPort(config.port)) {
      errors.push('端口号无效（应为1-65535）');
    }

    // 验证按钮配置
    if (config.buttons && Array.isArray(config.buttons)) {
      config.buttons.forEach((button, index) => {
        const buttonValidation = this.validateButtonConfig(button);
        if (!buttonValidation.isValid) {
          errors.push(`按钮${index + 1}: ${buttonValidation.errors.join(', ')}`);
        }
      });
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * 验证按钮配置
   */
  validateButtonConfig(config) {
    const errors = [];

    if (!config.name || typeof config.name !== 'string') {
      errors.push('按钮名称不能为空');
    }

    if (!config.scene || typeof config.scene !== 'string') {
      errors.push('场景ID不能为空');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * 验证IP地址格式
   */
  isValidIP(ip) {
    const ipRegex = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
    return ipRegex.test(ip);
  }

  /**
   * 验证端口号
   */
  isValidPort(port) {
    const portNum = parseInt(port);
    return Number.isInteger(portNum) && portNum >= 1 && portNum <= 65535;
  }

  /**
   * 生成机械臂ID
   */
  generateRobotId() {
    return `robot_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;
  }

  /**
   * 生成按钮ID
   */
  generateButtonId(robotId) {
    return `${robotId}_btn_${Date.now()}_${Math.random().toString(36).substr(2, 3)}`;
  }

  /**
   * 导出配置
   */
  exportConfig() {
    const config = {
      version: "1.0.0",
      robots: this.getAllRobots(),
      settings: this.appState.get('settings'),
      exportTime: new Date().toISOString()
    };

    return JSON.stringify(config, null, 2);
  }

  /**
   * 导入配置
   */
  importConfig(configJson) {
    try {
      const config = JSON.parse(configJson);

      if (!config.robots || !Array.isArray(config.robots)) {
        throw new Error('配置格式无效：缺少robots数组');
      }

      // 验证所有机械臂配置
      config.robots.forEach((robot, index) => {
        const validation = this.validateRobotConfig(robot);
        if (!validation.isValid) {
          throw new Error(`机械臂${index + 1}配置无效: ${validation.errors.join(', ')}`);
        }
      });

      // 更新配置
      this.appState.updateRobotsConfig(config.robots);

      if (config.settings) {
        this.appState.setState({ settings: config.settings });
      }

      console.log('[ConfigManager] 导入配置成功');
      return true;

    } catch (error) {
      console.error('[ConfigManager] 导入配置失败:', error);
      throw error;
    }
  }

  /**
   * 重置配置
   */
  resetConfig() {
    this.appState.updateRobotsConfig([]);
    console.log('[ConfigManager] 配置已重置');
  }
}

// 导出类供其他模块使用
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { ConfigManager };
} else {
  window.ConfigManager = ConfigManager;
} 
