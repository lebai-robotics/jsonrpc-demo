/**
 * 全局状态管理模块
 * 管理应用状态，提供事件发布订阅机制
 */

class AppState {
  constructor() {
    this.state = {
      // 机械臂配置信息
      robotsConfig: [],
      // 当前是否有任务在运行
      isTaskRunning: false,
      // 当前运行的任务ID
      currentTaskId: null,
      // 运行任务的机械臂ID
      currentRobotId: null,
      // 设备连接状态 { robotId: { online: boolean, lastCheck: timestamp } }
      connectionStatus: {},
      // 机器人状态 { robotId: { state: string, lastCheck: timestamp } }
      robotStates: {},
      // 应用设置
      settings: {
        timeout: 5000,
        retryCount: 3,
        checkInterval: 10000
      }
    };

    // 事件监听器
    this.listeners = {};

    // 初始化状态
    this.loadStateFromStorage();
  }

  /**
   * 获取当前状态
   */
  getState() {
    return { ...this.state };
  }

  /**
   * 获取特定状态属性
   */
  get(key) {
    return this.state[key];
  }

  /**
   * 更新状态
   */
  setState(updates) {
    const oldState = { ...this.state };
    this.state = { ...this.state, ...updates };

    // 保存到本地存储
    this.saveStateToStorage();

    // 触发状态变化事件
    this.emit('stateChange', this.state, oldState);

    console.log('[StateManager] 状态更新:', updates);
  }

  /**
   * 更新机械臂配置
   */
  updateRobotsConfig(robotsConfig) {
    this.setState({ robotsConfig });
    this.emit('robotsConfigChange', robotsConfig);
  }

  /**
   * 设置任务运行状态
   */
  setTaskRunning(isRunning, taskId = null, robotId = null) {
    this.setState({
      isTaskRunning: isRunning,
      currentTaskId: taskId,
      currentRobotId: robotId
    });

    this.emit('taskStatusChange', {
      isRunning,
      taskId,
      robotId
    });
  }

  /**
   * 更新设备连接状态
   */
  updateConnectionStatus(robotId, isOnline) {
    const newConnectionStatus = {
      ...this.state.connectionStatus,
      [robotId]: {
        online: isOnline,
        lastCheck: Date.now()
      }
    };

    this.setState({ connectionStatus: newConnectionStatus });
    this.emit('connectionStatusChange', robotId, isOnline);
  }

  /**
   * 更新机器人状态
   */
  updateRobotState(robotId, robotState) {
    const newRobotStates = {
      ...this.state.robotStates,
      [robotId]: {
        state: robotState,
        lastCheck: Date.now()
      }
    };

    this.setState({ robotStates: newRobotStates });
    this.emit('robotStateChange', robotId, robotState);
  }

  /**
   * 检查设备是否在线
   */
  isRobotOnline(robotId) {
    const status = this.state.connectionStatus[robotId];
    return status ? status.online : false;
  }

  /**
   * 获取机械臂配置
   */
  getRobotConfig(robotId) {
    return this.state.robotsConfig.find(robot => robot.id === robotId);
  }

  /**
   * 获取机器人状态
   */
  getRobotState(robotId) {
    const robotState = this.state.robotStates[robotId];
    return robotState ? robotState.state : 'unknown';
  }

  /**
   * 添加事件监听器
   */
  on(event, listener) {
    if (!this.listeners[event]) {
      this.listeners[event] = [];
    }
    this.listeners[event].push(listener);
  }

  /**
   * 移除事件监听器
   */
  off(event, listener) {
    if (!this.listeners[event]) return;

    const index = this.listeners[event].indexOf(listener);
    if (index > -1) {
      this.listeners[event].splice(index, 1);
    }
  }

  /**
   * 触发事件
   */
  emit(event, ...args) {
    if (!this.listeners[event]) return;

    this.listeners[event].forEach(listener => {
      try {
        listener(...args);
      } catch (error) {
        console.error('[StateManager] 事件监听器错误:', error);
      }
    });
  }

  /**
   * 从本地存储加载状态
   */
  loadStateFromStorage() {
    try {
      const savedState = localStorage.getItem('lebai_app_state');
      if (savedState) {
        const parsedState = JSON.parse(savedState);

        // 合并保存的状态，但保留运行时状态
        this.state = {
          ...this.state,
          ...parsedState,
          // 重置运行时状态
          isTaskRunning: false,
          currentTaskId: null,
          currentRobotId: null,
          connectionStatus: {}
        };

        console.log('[StateManager] 从本地存储加载状态成功');
      }
    } catch (error) {
      console.warn('[StateManager] 加载本地状态失败:', error);
    }
  }

  /**
   * 保存状态到本地存储
   */
  saveStateToStorage() {
    try {
      // 只保存持久化状态，排除运行时状态
      const stateToSave = {
        robotsConfig: this.state.robotsConfig,
        settings: this.state.settings
      };

      localStorage.setItem('lebai_app_state', JSON.stringify(stateToSave));
    } catch (error) {
      console.warn('[StateManager] 保存状态到本地失败:', error);
    }
  }

  /**
   * 重置状态
   */
  reset() {
    this.state = {
      robotsConfig: [],
      isTaskRunning: false,
      currentTaskId: null,
      currentRobotId: null,
      connectionStatus: {},
      settings: {
        timeout: 5000,
        retryCount: 3,
        checkInterval: 10000
      }
    };

    localStorage.removeItem('lebai_app_state');
    this.emit('stateReset');
  }
}

/**
 * 单例状态管理器
 */
class StateManager {
  constructor() {
    if (StateManager.instance) {
      return StateManager.instance;
    }

    this.appState = new AppState();
    StateManager.instance = this;
  }

  /**
   * 获取应用状态实例
   */
  getAppState() {
    return this.appState;
  }

  /**
   * 静态方法获取实例
   */
  static getInstance() {
    if (!StateManager.instance) {
      new StateManager();
    }
    return StateManager.instance;
  }
}

// 导出类供其他模块使用
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { StateManager, AppState };
} else {
  window.StateManager = StateManager;
  window.AppState = AppState;
} 
