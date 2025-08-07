import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// JSON-RPC错误类
class JsonRpcError implements Exception {
  final int code;
  final String message;
  final dynamic data;

  const JsonRpcError(this.code, this.message, [this.data]);

  /// 获取友好的错误消息
  String get friendlyMessage {
    switch (code) {
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
        return message.isNotEmpty ? message : '未知错误';
    }
  }

  @override
  String toString() => 'JsonRpcError($code): $message';
}

/// 机器人状态枚举
enum RobotState {
  idle, // 空闲
  running, // 运行中
  paused, // 暂停
  stopped, // 停止
  error, // 错误
  disabled, // 禁用
  unknown, // 未知
}

/// 乐白机械臂JSON-RPC客户端
/// 实现JSON-RPC 2.0协议，支持自动重试和错误处理
class JsonRpcClient {
  final Duration timeout;
  final int retryCount;
  final Duration retryDelay;
  int _requestId = 1;

  JsonRpcClient({
    this.timeout = const Duration(seconds: 5),
    this.retryCount = 3,
    this.retryDelay = const Duration(milliseconds: 1000),
  });

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

  /// 启动场景任务
  Future<dynamic> startTask(String ip, int port, String taskName) async {
    final taskParams = {
      'name': taskName,
      'is_parallel': false,
      'loop_to': 1,
      'dir': '',
    };

    return await sendRequest(ip, port, 'start_task', [taskParams]);
  }

  /// 获取机器人状态
  Future<RobotState> getRobotState(String ip, int port) async {
    try {
      final result = await sendRequest(ip, port, 'get_robot_state', []);

      // 处理返回结果，可能是字符串或数字
      final state = result is Map ? result['state'] : result;
      return _parseRobotState(state);
    } catch (error) {
      print('[JsonRPC] 获取机器人状态失败: $ip:$port - $error');
      return RobotState.unknown;
    }
  }

  /// 解析机器人状态
  RobotState _parseRobotState(dynamic state) {
    if (state is String) {
      switch (state.toUpperCase()) {
        case 'IDLE':
        case 'STANDBY':
          return RobotState.idle;
        case 'RUNNING':
        case 'MOVING':
        case 'BUSY':
          return RobotState.running;
        case 'PAUSED':
        case 'PAUSE':
          return RobotState.paused;
        case 'STOPPED':
        case 'STOP':
          return RobotState.stopped;
        case 'ERROR':
        case 'FAULT':
        case 'EMERGENCY':
          return RobotState.error;
        case 'DISABLED':
        case 'POWEROFF':
          return RobotState.disabled;
        default:
          return RobotState.unknown;
      }
    } else if (state is int) {
      switch (state) {
        case 0:
          return RobotState.idle;
        case 1:
          return RobotState.running;
        case 2:
          return RobotState.paused;
        case 3:
          return RobotState.stopped;
        case 4:
          return RobotState.error;
        case 5:
          return RobotState.disabled;
        default:
          return RobotState.unknown;
      }
    }

    return RobotState.unknown;
  }

  /// 检查设备连接状态
  Future<bool> checkConnection(String ip, int port) async {
    try {
      await getRobotState(ip, port);
      return true;
    } catch (error) {
      return false;
    }
  }
}
