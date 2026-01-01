# 配置说明

## API Key 配置

本项目使用配置文件来管理敏感信息（如 API Key），不会将这些信息提交到版本控制。

### 首次设置步骤

1. 复制配置示例文件：
   ```bash
   cp lib/config.example.dart lib/config.dart
   ```

2. 编辑 `lib/config.dart`，填入你的实际 API Key：
   ```dart
   class AppConfig {
     // 高德地图 API Key
     static const String amapApiKey = 'YOUR_ACTUAL_API_KEY';
   }
   ```

3. 获取高德地图 API Key：
   - 访问 [高德开放平台](https://lbs.amap.com/)
   - 注册账号并创建应用
   - 获取 Web 服务 API Key
   - 将 Key 填入 `config.dart`

### 注意事项

- `lib/config.dart` 已添加到 `.gitignore`，不会被提交
- `lib/config.example.dart` 是示例文件，会被提交到仓库
- 团队成员需要各自创建自己的 `config.dart` 文件
- 生产环境部署时，需要在 CI/CD 中配置实际的 API Key

### 其他配置项

如需添加其他配置（如数据库连接、第三方服务密钥等），请在 `AppConfig` 类中添加相应的常量。


