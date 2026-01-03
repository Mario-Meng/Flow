/// 应用配置示例文件
/// 使用方法：
/// 1. 复制此文件为 config.dart
/// 2. 在 config.dart 中填入你的实际 API Key
/// 3. config.dart 不会被提交到 Git（已添加到 .gitignore）
class AppConfig {
  // 高德地图 API Key
  // 获取地址: https://lbs.amap.com/
  static const String amapApiKey = 'YOUR_AMAP_API_KEY_HERE';

  // S3 Cloud Storage Configuration (for data sync)
  // Supports AWS S3, Qiniu Cloud, Alibaba Cloud OSS, etc.
  static const String s3Endpoint = 'https://s3.amazonaws.com';
  static const String s3Region = 'us-east-1';
  static const String s3Bucket = 'your-bucket-name';
  static const String awsAccessKeyId = 'YOUR_AWS_ACCESS_KEY_ID';
  static const String awsSecretAccessKey = 'YOUR_AWS_SECRET_ACCESS_KEY';
  
  // AES Encryption Key (for data sync)
  // Must be exactly 32 characters (256-bit)
  static const String aesKey = '12345678901234567890123456789012';
}



