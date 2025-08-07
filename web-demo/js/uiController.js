/**
 * 界面控制模块
 * 负责页面渲染、用户交互和界面状态管理
 */

class UIController {
  constructor(stateManager, configManager, rpcClient) {
    this.stateManager = stateManager;
    this.configManager = configManager;
    this.rpcClient = rpcClient;
    this.appState = stateManager.getAppState();

    // DOM 元素引用
    this.elements = {};

    // 绑定事件监听器
    this.bindStateEvents();
  }

  /**
   * 初始化界面
   */
  async initialize() {
    console.log('[UIController] 初始化界面');

    // 缓存DOM元素
    this.cacheElements();

    // 显示加载状态
    this.showLoading('正在加载配置...');

    try {
      // 初始化配置
      await this.configManager.initializeConfig();

      // 渲染界面
      this.renderMainInterface();

      // 绑定事件
      this.bindUIEvents();

      // 开始连接检查
      this.startConnectionCheck();

      this.hideLoading();

    } catch (error) {
      console.error('[UIController] 初始化失败:', error);
      this.showError('初始化失败', error.message);
    }
  }

  /**
   * 缓存DOM元素
   */
  cacheElements() {
    this.elements = {
      container: document.getElementById('main-container'),
      robotsContainer: document.getElementById('robots-container'),
      configButton: document.getElementById('config-button'),
      statusBar: document.getElementById('status-bar'),
      loadingOverlay: document.getElementById('loading-overlay'),
      errorModal: document.getElementById('error-modal'),
      successToast: document.getElementById('success-toast')
    };
  }

  /**
   * 绑定状态变化事件
   */
  bindStateEvents() {
    this.appState.on('robotsConfigChange', () => {
      this.renderRobotCards();
    });

    this.appState.on('connectionStatusChange', (robotId, isOnline) => {
      this.updateRobotConnectionStatus(robotId, isOnline);
    });

    this.appState.on('robotStateChange', (robotId, robotState) => {
      this.updateRobotStatus(robotId, robotState);
    });
  }

  /**
   * 绑定UI事件
   */
  bindUIEvents() {
    // 配置按钮
    if (this.elements.configButton) {
      this.elements.configButton.addEventListener('click', () => {
        this.openConfigPage();
      });
    }

    // Modal相关事件
    this.bindModalEvents();

    // 窗口大小变化
    window.addEventListener('resize', () => {
      this.handleResize();
    });
  }

  /**
   * 绑定Modal相关事件
   */
  bindModalEvents() {
    // 场景Modal
    const sceneModal = document.getElementById('scene-modal');
    const sceneForm = document.getElementById('scene-form');
    const closeSceneModalBtn = document.getElementById('close-scene-modal');
    const cancelSceneBtn = document.getElementById('cancel-scene-btn');

    if (sceneForm) {
      sceneForm.addEventListener('submit', (event) => {
        this.handleSceneSubmit(event);
      });
    }

    if (closeSceneModalBtn) {
      closeSceneModalBtn.addEventListener('click', () => {
        this.hideSceneModal();
      });
    }

    if (cancelSceneBtn) {
      cancelSceneBtn.addEventListener('click', () => {
        this.hideSceneModal();
      });
    }

    // 点击Modal背景关闭Modal
    if (sceneModal) {
      sceneModal.addEventListener('click', (event) => {
        if (event.target === sceneModal) {
          this.hideSceneModal();
        }
      });
    }

    // ESC键关闭Modal
    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape') {
        if (sceneModal && sceneModal.style.display === 'flex') {
          this.hideSceneModal();
        }
      }
    });
  }

  /**
   * 渲染主界面
   */
  renderMainInterface() {
    const robots = this.configManager.getAllRobots();

    // 如果没有配置，显示初始引导
    if (robots.length === 0) {
      this.renderWelcomeScreen();
    } else {
      this.renderRobotCards();
    }

    this.updateStatusBar();
  }

  /**
   * 渲染欢迎界面
   */
  renderWelcomeScreen() {
    if (!this.elements.robotsContainer) return;

    this.elements.robotsContainer.innerHTML = `
            <div class="welcome-screen">
                <div class="welcome-content">
                    <h2>🤖 乐白机械臂控制中心</h2>
                    <p class="welcome-subtitle">请确保机器人和您的设备在同一个网络中</p>
                    <div class="welcome-instructions">
                        <p>🔧 首次使用需要先配置机械臂设备</p>
                        <p>📡 系统会自动检测设备连接状态</p>
                        <p>🎯 配置完成后即可执行场景任务</p>
                    </div>
                    <button class="ui-button primary large" onclick="window.uiController.openConfigPage()">
                        <span class="ui-icon">⚙️</span>
                        开始配置
                    </button>
                </div>
            </div>
        `;
  }

  /**
   * 渲染机械臂卡片
   */
  renderRobotCards() {
    if (!this.elements.robotsContainer) return;

    const robots = this.configManager.getAllRobots();
    const isTaskRunning = this.appState.get('isTaskRunning');

    if (robots.length === 0) {
      this.renderWelcomeScreen();
      return;
    }

    let cardsHTML = '';

    robots.forEach(robot => {
      const robotState = this.appState.getRobotState(robot.id);
      const stateClass = this.getRobotStateClass(robotState);
      const stateText = this.getRobotStateText(robotState);
      const isOnline = robotState !== 'unknown' && robotState !== 'offline';

      cardsHTML += `
                <div class="robot-card ${stateClass}" data-robot-id="${robot.id}">
                    <div class="robot-header">
                        <div class="robot-info">
                            <div class="robot-details">
                                <span class="robot-ip">📡 ${robot.ip}:${robot.port}</span>
                            </div>
                        </div>
                        <div class="robot-status ${stateClass}">
                            <span class="status-indicator"></span>
                            <span class="status-text">${stateText}</span>
                        </div>
                    </div>
                    
                    <div class="robot-scenes">
                        ${this.renderSceneButtons(robot, isTaskRunning, isOnline)}
                    </div>
                </div>
            `;
    });

    this.elements.robotsContainer.innerHTML = cardsHTML;

    // 绑定按钮事件
    this.bindSceneButtons();
  }

  /**
   * 渲染场景按钮
   */
  renderSceneButtons(robot, isTaskRunning, isOnline) {
    if (!robot.buttons || robot.buttons.length === 0) {
      return `
        <div class="no-scenes">
          <p>暂无配置场景</p>
          <small>请前往设备配置添加场景</small>
        </div>
      `;
    }

    return robot.buttons.map(button => {
      const disabled = isTaskRunning || isOnline;
      const disabledClass = disabled ? 'disabled' : '';
      const disabledAttr = disabled ? 'disabled' : '';

      return `
        <button class="scene-execute-btn ${disabledClass}" 
                data-robot-id="${robot.id}" 
                data-scene="${button.scene}"
                ${disabledAttr}>
          <div class="scene-icon">🎯</div>
          <div class="scene-info">
            <span class="scene-name">${this.escapeHtml(button.name)}</span>
            <span class="scene-id">场景 ${button.scene}</span>
          </div>
          <div class="execute-arrow">▶</div>
        </button>
      `;
    }).join('');
  }

  /**
   * 绑定场景按钮事件
   */
  bindSceneButtons() {
    const sceneButtons = document.querySelectorAll('.scene-execute-btn');

    sceneButtons.forEach(button => {
      button.addEventListener('click', async (e) => {
        const robotId = e.currentTarget.dataset.robotId;
        const sceneId = e.currentTarget.dataset.scene;

        await this.executeScene(robotId, sceneId);
      });
    });
  }

  /**
   * 获取机器人状态对应的CSS类
   */
  getRobotStateClass(state) {
    // 根据乐白机器人API文档的ERobotState枚举
    switch (state) {
      case 'IDLE':           // 空闲
      case 'STANDBY':        // 待机
      case 0:
        return 'idle';
      case 'RUNNING':        // 运行中
      case 'MOVING':         // 运动中
      case 'BUSY':           // 忙碌
      case 1:
        return 'running';
      case 'PAUSED':         // 暂停
      case 'PAUSE':          // 暂停
      case 2:
        return 'paused';
      case 'STOPPED':        // 停止
      case 'STOP':           // 停止
      case 3:
        return 'stopped';
      case 'ERROR':          // 错误
      case 'FAULT':          // 故障
      case 'EMERGENCY':      // 急停
      case 4:
        return 'error';
      case 'DISABLED':       // 禁用
      case 'POWEROFF':       // 断电
      case 5:
        return 'disabled';
      case 'unknown':
      case null:
      case undefined:
      default:
        return 'offline';
    }
  }

  /**
   * 获取机器人状态对应的显示文本
   */
  getRobotStateText(state) {
    // 根据乐白机器人API文档的ERobotState枚举
    switch (state) {
      case 'IDLE':
      case 'STANDBY':
      case 0:
        return '空闲';
      case 'RUNNING':
      case 'MOVING':
      case 'BUSY':
      case 1:
        return '运行中';
      case 'PAUSED':
      case 'PAUSE':
      case 2:
        return '暂停';
      case 'STOPPED':
      case 'STOP':
      case 3:
        return '已停止';
      case 'ERROR':
      case 'FAULT':
      case 'EMERGENCY':
      case 4:
        return '错误';
      case 'DISABLED':
      case 'POWEROFF':
      case 5:
        return '未启用';
      case 'unknown':
      case null:
      case undefined:
      default:
        return '离线';
    }
  }

  /**
   * 执行场景
   */
  async executeScene(robotId, sceneId) {
    try {
      const robot = this.configManager.getRobotById(robotId);
      if (!robot) {
        throw new Error('机械臂配置不存在');
      }

      // 设置任务运行状态
      this.appState.setTaskRunning(true, null, robotId);

      this.showLoading(`正在执行场景${sceneId}...`);

      // 执行RPC调用
      const result = await this.rpcClient.startTask(robot.ip, robot.port, sceneId);

      console.log('[UIController] 场景执行成功:', result);

      // 场景启动成功，立即重置任务状态
      this.appState.setTaskRunning(false);

      this.hideLoading();
      this.showSuccess(`场景${sceneId}启动成功`);

    } catch (error) {
      console.error('[UIController] 场景执行失败:', error);

      // 重置运行状态
      this.appState.setTaskRunning(false);

      this.hideLoading();

      let errorMessage = '场景执行失败';
      if (error instanceof JsonRpcError) {
        errorMessage = error.getFriendlyMessage();
      } else {
        errorMessage = error.message || errorMessage;
      }

      this.showError('执行失败', errorMessage);
    }
  }





  /**
   * 更新机械臂连接状态
   */
  updateRobotConnectionStatus(robotId, isOnline) {
    const robotCard = document.querySelector(`[data-robot-id="${robotId}"]`);
    if (!robotCard) return;

    const statusIndicator = robotCard.querySelector('.status-indicator');
    const statusText = robotCard.querySelector('.status-text');

    if (statusIndicator) {
      statusIndicator.className = `status-indicator ${isOnline ? 'online' : 'offline'}`;
    }

    if (statusText) {
      statusText.textContent = isOnline ? '在线' : '离线';
    }

    robotCard.className = `robot-card ${isOnline ? 'online' : 'offline'}`;

    // 更新按钮状态
    const buttons = robotCard.querySelectorAll('.scene-button');
    const isTaskRunning = this.appState.get('isTaskRunning');

    buttons.forEach(button => {
      const shouldDisable = !isOnline;
      button.disabled = shouldDisable;
      button.className = `scene-button ui-button ${shouldDisable ? 'disabled' : ''}`;
    });
  }

  /**
   * 更新机器人状态显示
   */
  updateRobotStatus(robotId, robotState) {
    const robotCard = document.querySelector(`[data-robot-id="${robotId}"]`);
    if (!robotCard) return;

    const stateClass = this.getRobotStateClass(robotState);
    const stateText = this.getRobotStateText(robotState);
    const isOnline = robotState !== 'unknown' && robotState !== 'offline';

    // 更新卡片状态类
    robotCard.className = `robot-card ${stateClass}`;

    // 更新状态显示
    const robotStatus = robotCard.querySelector('.robot-status');
    if (robotStatus) {
      robotStatus.className = `robot-status ${stateClass}`;
    }

    const statusText = robotCard.querySelector('.status-text');
    if (statusText) {
      statusText.textContent = stateText;
    }

    // 更新按钮状态
    const buttons = robotCard.querySelectorAll('.scene-execute-btn');
    const isTaskRunning = this.appState.get('isTaskRunning');

    buttons.forEach(button => {
      const shouldDisable = !isOnline || isTaskRunning;
      button.disabled = shouldDisable;
      button.className = `scene-execute-btn ${shouldDisable ? 'disabled' : ''}`;
    });

    // 更新状态栏
    this.updateStatusBar();
  }

  /**
   * 开始机器人状态检查
   */
  startConnectionCheck() {
    const checkInterval = this.appState.get('settings').checkInterval || 10000;

    // 立即检查一次
    this.checkAllRobotStates();

    // 定期检查
    setInterval(() => {
      this.checkAllRobotStates();
    }, checkInterval);
  }

  /**
   * 检查所有机器人状态
   */
  async checkAllRobotStates() {
    const robots = this.configManager.getAllRobots();

    const checkPromises = robots.map(async (robot) => {
      try {
        const response = await this.rpcClient.getRobotState(robot.ip, robot.port);
        // API返回格式：{state: 'IDLE'} 或 {state: 0}
        const robotState = response && response.state !== undefined ? response.state : response;
        this.appState.updateRobotState(robot.id, robotState);
        console.log(`[UIController] 机器人 ${robot.name} 状态:`, robotState);
      } catch (error) {
        console.warn(`[UIController] 获取 ${robot.name} 状态失败:`, error);
        this.appState.updateRobotState(robot.id, 'unknown');
      }
    });

    await Promise.all(checkPromises);
  }

  /**
   * 更新状态栏
   */
  updateStatusBar() {
    if (!this.elements.statusBar) return;

    const robots = this.configManager.getAllRobots();
    const idleCount = robots.filter(robot => {
      const state = this.appState.getRobotState(robot.id);
      return state === 'IDLE' || state === 'STANDBY' || state === 0;
    }).length;
    const runningCount = robots.filter(robot => {
      const state = this.appState.getRobotState(robot.id);
      return state === 'RUNNING' || state === 'MOVING' || state === 'BUSY' || state === 1;
    }).length;
    const errorCount = robots.filter(robot => {
      const state = this.appState.getRobotState(robot.id);
      return state === 'ERROR' || state === 'FAULT' || state === 'EMERGENCY' || state === 4;
    }).length;
    const isTaskRunning = this.appState.get('isTaskRunning');

    let statusText = '';
    if (robots.length === 0) {
      statusText = '暂无配置设备';
    } else {
      const statusParts = [];
      if (idleCount > 0) statusParts.push(`${idleCount} 空闲`);
      if (runningCount > 0) statusParts.push(`${runningCount} 运行中`);
      if (errorCount > 0) statusParts.push(`${errorCount} 异常`);

      statusText = `设备状态: ${statusParts.join(', ') || '0 在线'}`;
      if (isTaskRunning) {
        statusText += ' | 🔄 任务执行中...';
      }
    }

    this.elements.statusBar.textContent = statusText;
  }

  /**
   * 打开配置页面
   */
  openConfigPage() {
    window.location.href = './config.html';
  }

  /**
   * 显示加载状态
   */
  showLoading(message = '加载中...') {
    if (this.elements.loadingOverlay) {
      this.elements.loadingOverlay.innerHTML = `
                <div class="loading-content">
                    <div class="loading-spinner"></div>
                    <p>${message}</p>
                </div>
            `;
      this.elements.loadingOverlay.style.display = 'flex';
    }
  }

  /**
   * 隐藏加载状态
   */
  hideLoading() {
    if (this.elements.loadingOverlay) {
      this.elements.loadingOverlay.style.display = 'none';
    }
  }

  /**
   * 显示成功消息
   */
  showSuccess(message) {
    this.showToast(message, 'success');
  }

  /**
   * 显示警告消息
   */
  showWarning(message) {
    this.showToast(message, 'warning');
  }

  /**
   * 显示错误消息
   */
  showError(title, message) {
    console.error(`[UIController] ${title}: ${message}`);
    this.showToast(`${title}: ${message}`, 'error');
  }

  /**
   * 显示Toast消息
   */
  showToast(message, type = 'info') {
    // 创建toast元素
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `
            <span class="toast-message">${this.escapeHtml(message)}</span>
            <button class="toast-close" onclick="this.parentElement.remove()">×</button>
        `;

    // 添加到页面
    document.body.appendChild(toast);

    // 自动移除
    setTimeout(() => {
      if (toast.parentNode) {
        toast.parentNode.removeChild(toast);
      }
    }, 4000);
  }

  /**
   * 处理窗口大小变化
   */
  handleResize() {
    // 可以在这里添加响应式布局调整逻辑
    console.log('[UIController] 窗口大小变化');
  }

  /**
   * 显示场景编辑Modal
   */
  showSceneModal(robotId, sceneData = null) {
    const modal = document.getElementById('scene-modal');
    const modalTitle = document.getElementById('scene-modal-title');
    const sceneNameInput = document.getElementById('scene-name');
    const sceneIdInput = document.getElementById('scene-id');

    // 设置modal标题和表单数据
    if (sceneData) {
      modalTitle.textContent = '编辑场景';
      sceneNameInput.value = sceneData.name || '';
      sceneIdInput.value = sceneData.scene || '';
    } else {
      modalTitle.textContent = '添加场景';
      sceneNameInput.value = '';
      sceneIdInput.value = '';
    }

    // 保存当前操作的机器人ID和场景数据到modal数据属性
    modal.dataset.robotId = robotId;
    modal.dataset.isEdit = sceneData ? 'true' : 'false';
    if (sceneData) {
      modal.dataset.sceneId = sceneData.id;
    } else {
      delete modal.dataset.sceneId;
    }

    // 显示modal
    modal.style.display = 'flex';

    // 聚焦到第一个输入框
    setTimeout(() => sceneNameInput.focus(), 100);
  }

  /**
   * 隐藏场景编辑Modal
   */
  hideSceneModal() {
    const modal = document.getElementById('scene-modal');
    modal.style.display = 'none';

    // 清理数据属性
    delete modal.dataset.robotId;
    delete modal.dataset.isEdit;
    delete modal.dataset.sceneId;

    // 重置表单
    document.getElementById('scene-form').reset();
  }

  /**
   * 处理场景表单提交
   */
  async handleSceneSubmit(event) {
    event.preventDefault();

    const modal = document.getElementById('scene-modal');
    const robotId = modal.dataset.robotId;
    const isEdit = modal.dataset.isEdit === 'true';
    const sceneId = modal.dataset.sceneId;

    const formData = new FormData(event.target);
    const sceneData = {
      name: formData.get('name').trim(),
      scene: formData.get('scene').trim()
    };

    // 基本验证
    if (!sceneData.name || !sceneData.scene) {
      this.showToast('请填写完整的场景信息', 'error');
      return;
    }

    try {
      if (isEdit && sceneId) {
        // 编辑场景
        await this.configManager.updateSceneButton(robotId, sceneId, sceneData);
        this.showToast('场景更新成功', 'success');
      } else {
        // 添加场景
        await this.configManager.addSceneButton(robotId, sceneData);
        this.showToast('场景添加成功', 'success');
      }

      // 重新渲染界面
      this.renderMainInterface();

      // 关闭modal
      this.hideSceneModal();

    } catch (error) {
      console.error('[UIController] 场景操作失败:', error);
      this.showToast(error.message || '操作失败', 'error');
    }
  }

  /**
   * 删除场景
   */
  async deleteScene(robotId, sceneId) {
    if (!confirm('确定要删除这个场景吗？')) {
      return;
    }

    try {
      await this.configManager.deleteSceneButton(robotId, sceneId);
      this.showToast('场景删除成功', 'success');

      // 重新渲染界面
      this.renderMainInterface();

    } catch (error) {
      console.error('[UIController] 删除场景失败:', error);
      this.showToast(error.message || '删除失败', 'error');
    }
  }

  /**
   * 显示Toast提示
   */
  showToast(message, type = 'info') {
    // 创建toast元素
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.textContent = message;

    // 添加样式
    Object.assign(toast.style, {
      position: 'fixed',
      top: '20px',
      right: '20px',
      padding: '12px 20px',
      borderRadius: '6px',
      color: 'white',
      fontWeight: '500',
      zIndex: '1001',
      transform: 'translateX(100%)',
      transition: 'transform 0.3s ease',
      maxWidth: '300px',
      wordWrap: 'break-word'
    });

    // 设置颜色
    switch (type) {
      case 'success':
        toast.style.backgroundColor = '#28a745';
        break;
      case 'error':
        toast.style.backgroundColor = '#dc3545';
        break;
      case 'warning':
        toast.style.backgroundColor = '#ffc107';
        toast.style.color = '#212529';
        break;
      default:
        toast.style.backgroundColor = '#17a2b8';
    }

    // 添加到页面
    document.body.appendChild(toast);

    // 显示动画
    setTimeout(() => {
      toast.style.transform = 'translateX(0)';
    }, 10);

    // 自动隐藏
    setTimeout(() => {
      toast.style.transform = 'translateX(100%)';
      setTimeout(() => {
        if (toast.parentNode) {
          document.body.removeChild(toast);
        }
      }, 300);
    }, 3000);
  }

  /**
   * HTML转义
   */
  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}

// 导出类供其他模块使用
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { UIController };
} else {
  window.UIController = UIController;
} 
