## 前言
本项目是关于json-rpc与机器人通信的demo示例，采用flutter编写，根目录下web-demo文件夹为web端示例。

关于json-rpc的介绍，可以参考[这里](https://help.lebai.ltd/dev/jsonrpc.html)

json-rpc主要是通过http或者websocket与机器人通信，获取机器人状态，发送指令等。本项目会有flutter和js的相关示例, 看项目代码即可理解是如何调用并且完成整个项目的，目前都是通过http方式调用。

## 示例

### flutter端示例
> /lib/services/jsonrpc_client.dart 可供参考
```dart
/// 发送JSON-RPC请求
  Future<dynamic> sendRequest(
    String ip,
    int port,
    String method, [
    dynamic params,
  ]) async {
    final url = Uri.parse('http://$ip:$port');
    final requestData = {
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
      'id': _requestId++,
    };

    Exception? lastError;

    // 重试机制
    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        print(
          '[JsonRPC] 尝试 ${attempt + 1}/${retryCount + 1}: $method -> $ip:$port',
        );

        final response = await _makeRequest(url, requestData);

        if (response['error'] != null) {
          final error = response['error'] as Map<String, dynamic>;
          throw JsonRpcError(
            error['code'] as int,
            error['message'] as String,
            error['data'],
          );
        }

        print('[JsonRPC] 成功: $method');
        return response['result'];
      } catch (error) {
        lastError = error is Exception ? error : Exception(error.toString());
        print('[JsonRPC] 尝试 ${attempt + 1} 失败: ${error.toString()}');

        // 如果是最后一次尝试，不需要等待
        if (attempt < retryCount) {
          final delayMs = retryDelay.inMilliseconds * (1 << attempt); // 指数退避
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }
    }

    // 所有重试都失败
    throw lastError ?? const JsonRpcError(-32603, '未知错误');
  }

  /// 执行HTTP请求
  Future<Map<String, dynamic>> _makeRequest(
    Uri url,
    Map<String, dynamic> requestData,
  ) async {
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestData),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw JsonRpcError(
          -32603,
          'HTTP错误: ${response.statusCode} ${response.reasonPhrase}',
        );
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // 验证JSON-RPC响应格式
      if (responseData['jsonrpc'] != '2.0') {
        throw const JsonRpcError(-32700, '无效的JSON-RPC响应格式');
      }

      return responseData;
    } on TimeoutException {
      throw JsonRpcError(-32603, '请求超时 (${timeout.inMilliseconds}ms)');
    } on SocketException catch (e) {
      throw JsonRpcError(-32603, '网络连接失败: ${e.message}');
    } on FormatException {
      throw const JsonRpcError(-32700, '响应数据格式错误');
    }
  }
```

### js调用示例
> /web-demo/js/communication.js 可供参考
```js
/**
 * 乐白机械臂 JSON-RPC 通信模块
 * 实现 JSON-RPC 2.0 协议，支持自动重试和错误处理
 */

class JsonRpcClient {
  constructor(config = {}) {
    this.timeout = config.timeout || 5000;
    this.retryCount = config.retryCount || 3;
    this.retryDelay = config.retryDelay || 1000;
    this.requestId = 1;
  }

  /**
   * 发送 JSON-RPC 请求
   * @param {string} ip - 机械臂IP地址
   * @param {number} port - 端口号
   * @param {string} method - RPC方法名
   * @param {*} params - 方法参数
   * @returns {Promise} 返回响应结果
   */
  async sendRequest(ip, port, method, params = null) {
    const url = `http://${ip}:${port}`;
    // const url = '/api'
    const requestData = {
      jsonrpc: "2.0",
      method: method,
      params: params,
      id: this.requestId++
    };

    let lastError = null;

    // 重试机制
    for (let attempt = 0; attempt <= this.retryCount; attempt++) {
      try {
        console.log(`[JsonRPC] 尝试 ${attempt + 1}/${this.retryCount + 1}: ${method} -> ${ip}:${port}`);

        const response = await this._makeRequest(url, requestData);

        if (response.error) {
          throw new JsonRpcError(response.error.code, response.error.message, response.error.data);
        }

        console.log(`[JsonRPC] 成功: ${method}`, response.result);
        return response.result;

      } catch (error) {
        lastError = error;
        console.warn(`[JsonRPC] 尝试 ${attempt + 1} 失败:`, error.message);

        // 如果是最后一次尝试，不需要等待
        if (attempt < this.retryCount) {
          await this._sleep(this.retryDelay * Math.pow(2, attempt)); // 指数退避
        }
      }
    }

    // 所有重试都失败
    throw lastError || new Error('未知错误');
  }

  /**
   * 执行HTTP请求
   * @private
   */
  async _makeRequest(url, requestData) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeout);

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestData),
        signal: controller.signal
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        throw new Error(`HTTP错误: ${response.status} ${response.statusText}`);
      }

      const responseData = await response.json();

      // 验证JSON-RPC响应格式
      if (responseData.jsonrpc !== "2.0") {
        throw new Error('无效的JSON-RPC响应格式');
      }

      return responseData;

    } catch (error) {
      clearTimeout(timeoutId);

      if (error.name === 'AbortError') {
        throw new Error(`请求超时 (${this.timeout}ms)`);
      }

      throw error;
    }
  }

  /**
   * 延时函数
   * @private
   */
  _sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * 启动场景任务
   */
  async startTask(ip, port, taskName) {
    const taskParams = {
      name: taskName,
      is_parallel: false,
      loop_to: 1,
      dir: "",
      // kind: "LUA",
      // params: params.params || []
    };

    return await this.sendRequest(ip, port, 'start_task', [taskParams]);
  }

  /**
   * 获取机器人状态
   */
  async getRobotState(ip, port) {
    try {
      // 调用乐白机器人的GetRobotState接口
      const result = await this.sendRequest(ip, port, 'get_robot_state', []);
      return result;
    } catch (error) {
      console.warn(`[JsonRPC] 获取机器人状态失败: ${ip}:${port}`, error);
      throw error;
    }
  }

  /**
   * 检查设备连接状态（已废弃，使用getRobotState替代）
   */
  async checkConnection(ip, port) {
    try {
      // 通过获取机器人状态来检查连接
      await this.getRobotState(ip, port);
      return true;
    } catch (error) {
      return false;
    }
  }


}

/**
 * JSON-RPC 错误类
 */
class JsonRpcError extends Error {
  constructor(code, message, data = null) {
    super(message);
    this.name = 'JsonRpcError';
    this.code = code;
    this.data = data;
  }

  /**
   * 获取友好的错误消息
   */
  getFriendlyMessage() {
    switch (this.code) {
      case -32700:
        return '数据解析错误，请检查网络连接';
      case -32600:
        return '请求格式无效';
      case -32601:
        return '方法不存在，请检查场景配置';
      case -32602:
        return '参数无效，请检查场景参数';
      case -32603:
        return '内部错误，请重试';
      default:
        return this.message || '未知错误';
    }
  }
}

// 导出类供其他模块使用
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { JsonRpcClient, JsonRpcError };
} else {
  window.JsonRpcClient = JsonRpcClient;
  window.JsonRpcError = JsonRpcError;
} 

```
