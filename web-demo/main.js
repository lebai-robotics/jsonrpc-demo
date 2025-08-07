// 应用初始化
document.addEventListener('DOMContentLoaded', async function () {
  console.log('[App] 开始初始化应用...');

  try {
    // 创建核心组件实例
    const stateManager = StateManager.getInstance();
    const appState = stateManager.getAppState();
    const settings = appState.get('settings');

    // 创建RPC客户端
    const rpcClient = new JsonRpcClient({
      timeout: settings.timeout,
      retryCount: settings.retryCount
    });

    // 创建配置管理器
    const configManager = new ConfigManager(stateManager);

    // 创建界面控制器
    const uiController = new UIController(stateManager, configManager, rpcClient);

    // 将控制器绑定到全局对象，供其他地方调用
    window.uiController = uiController;
    window.appState = appState;
    window.configManager = configManager;
    window.rpcClient = rpcClient;

    // 初始化界面
    await uiController.initialize();

    console.log('[App] 应用初始化完成');

  } catch (error) {
    console.error('[App] 应用初始化失败:', error);

    // 显示错误信息
    document.body.innerHTML = `
      <div style="
        display: flex; 
        align-items: center; 
        justify-content: center; 
        min-height: 100vh; 
        text-align: center;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      ">
        <div style="
          background: rgba(255, 255, 255, 0.95); 
          padding: 2rem; 
          border-radius: 12px; 
          box-shadow: 0 8px 16px rgba(0,0,0,0.2);
          max-width: 500px;
          width: 90%;
        ">
          <h2 style="color: #dc3545; margin-bottom: 1rem;">⚠️ 初始化失败</h2>
          <p style="color: #6c757d; margin-bottom: 1.5rem;">${error.message}</p>
          <button onclick="window.location.reload()" style="
            background: #007bff; 
            color: white; 
            border: none; 
            padding: 0.75rem 1.5rem; 
            border-radius: 8px; 
            cursor: pointer;
            font-size: 1rem;
            font-weight: 500;
          ">重新加载</button>
        </div>
      </div>
    `;
  }
});

// 错误处理
window.addEventListener('error', function (event) {
  console.error('[App] 全局错误:', event.error);
});

window.addEventListener('unhandledrejection', function (event) {
  console.error('[App] 未处理的Promise拒绝:', event.reason);
});
