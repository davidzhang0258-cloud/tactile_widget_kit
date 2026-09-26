import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

/// OPPO 桌面小卡片联动测试页。
/// 用于验证 App → 桌面卡片的数据推送，以及卡片按钮 → 唤醒 App。
class WidgetTestPage extends StatelessWidget {
  const WidgetTestPage({super.key});

  static const _wonderChannel = MethodChannel('com.tactile.widgetkit/wonder_channel');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('卡片联动测试')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // 1. 生成一个测试数据
                final testMessage = '随机动态码: ${Random().nextInt(9999)}';

                // 2. 把数据存入共享的 SharedPreferences 中
                // 这里的键名 'test_data' 必须和 Kotlin 里读的键名一模一样
                await HomeWidget.saveWidgetData<String>('test_data', testMessage);

                // 3. Notify the native layer to refresh all three widget sizes.
                await HomeWidget.updateWidget(
                  qualifiedAndroidName: 'com.tactile.widgetkit.TestWidgetProvider',
                );
                await HomeWidget.updateWidget(
                  qualifiedAndroidName: 'com.tactile.widgetkit.TestWidgetProviderMedium',
                );
                await HomeWidget.updateWidget(
                  qualifiedAndroidName: 'com.tactile.widgetkit.TestWidgetProviderLarge',
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已发送数据到卡片: $testMessage')),
                  );
                }
              },
              child: const Text('发送数据更新桌面卡片'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _wonderChannel.invokeMethod('refresh');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已刷新 Wonder Calendar 卡片')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('刷新失败: $e')),
                    );
                  }
                }
              },
              child: const Text('刷新 Wonder Calendar 卡片'),
            ),
          ],
        ),
      ),
    );
  }
}
