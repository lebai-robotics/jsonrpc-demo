import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'providers/robot_provider.dart';
import 'services/config_service.dart';
import 'services/jsonrpc_client.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const LebaiRobotControlApp());
}

class LebaiRobotControlApp extends StatelessWidget {
  const LebaiRobotControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 应用状态Provider
        ChangeNotifierProvider(create: (_) => AppState()),

        // 机器人Provider
        ChangeNotifierProvider(
          create: (_) => RobotProvider(ConfigService(), JsonRpcClient()),
        ),
      ],
      child: MaterialApp(
        title: '乐白机械臂控制',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3), // 科技蓝色
            brightness: Brightness.light,
          ),
          useMaterial3: true,

          // 卡片主题
          cardTheme: const CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),

          // 按钮主题
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // 输入框主题
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),

          // 应用栏主题
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,

          // 深色模式下的卡片主题
          cardTheme: const CardThemeData(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),

          // 深色模式下的按钮主题
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // 深色模式下的输入框主题
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),

          // 深色模式下的应用栏主题
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        ),
        themeMode: ThemeMode.system, // 跟随系统主题
        home: const HomeScreen(),
      ),
    );
  }
}
