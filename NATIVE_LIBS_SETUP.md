# Native Libraries Setup for macOS & Android

## 🐛 遇到的问题

### macOS 错误
```
Exception: Failed to load chunker library: Invalid argument(s): 
Failed to load dynamic library '/Users/mario/Library/Containers/...
/lib/native/libchunker.dylib': dlopen(...) no such file
```

### 根本原因

1. **路径解析问题**
   - Flutter 应用运行在沙盒中
   - `_getPackageRoot()` 无法正确找到包的路径
   - 库文件在包中，但应用找不到

2. **FFI 库加载机制**
   - macOS: 需要从应用 bundle 或系统路径加载
   - Android: 需要打包到 APK 的 lib/{abi}/ 目录
   - 不能直接从包的 `lib/native/` 加载

## ✅ 解决方案

### 方案概述

将native库文件复制到正确的位置：

```
主项目:
├── lib/native/
│   └── libchunker.dylib           ← macOS 加载这个

包项目:
└── packages/dart_cdc_sync/
    ├── lib/native/                 ← 源文件
    │   ├── libchunker.dylib
    │   ├── libchunker_android_arm64.so
    │   └── libchunker_android_amd64.so
    ├── macos/Frameworks/           ← macOS 插件
    │   └── libchunker.dylib
    └── android/src/main/jniLibs/   ← Android 插件
        ├── arm64-v8a/
        │   └── libchunker.so
        └── x86_64/
            └── libchunker.so
```

### 自动化脚本

创建了 `setup_native_libs.sh` 脚本来自动复制库文件：

```bash
#!/bin/bash
./setup_native_libs.sh

# 输出:
# ✓ macOS: libchunker.dylib
# ✓ Android ARM64: libchunker.so
# ✓ Android x86_64: libchunker.so
```

### FFI 加载代码优化

修改了 `chunker_ffi.dart` 的 macOS 加载逻辑：

```dart
if (Platform.isMacOS) {
  // Try to load from bundled framework first
  try {
    _dylib = ffi.DynamicLibrary.open('libchunker.dylib');
  } catch (e) {
    // Fallback to package path (for development)
    final libPath = '$packageRoot/lib/native/libchunker.dylib';
    _dylib = ffi.DynamicLibrary.open(libPath);
  }
}
```

**优先级**：
1. 首先尝试从系统路径加载（应用bundle中）
2. 失败则回退到包路径（开发环境）

## 📝 使用步骤

### 编译原生库

```bash
# 1. 编译 macOS 库
cd packages/dart_cdc_sync/chunker-ffi
./build.sh

# 2. 编译 Android 库  
./build_android.sh

# 3. 复制到正确位置
cd ../../..
./setup_native_libs.sh
```

### 运行应用

```bash
# 清理缓存
flutter clean

# macOS
flutter run -d macos

# Android
flutter run -d android
```

## 🔍 验证库文件

### 检查库文件存在

```bash
# 主项目 (macOS 运行时使用)
ls -lh lib/native/libchunker.dylib

# macOS 插件
ls -lh packages/dart_cdc_sync/macos/Frameworks/libchunker.dylib

# Android 插件  
ls -lh packages/dart_cdc_sync/android/src/main/jniLibs/*/libchunker.so
```

### 验证 Universal Binary

```bash
file lib/native/libchunker.dylib

# 应该输出:
# Mach-O universal binary with 2 architectures: [x86_64] [arm64]
```

### 验证 Android 库

```bash
file packages/dart_cdc_sync/android/src/main/jniLibs/arm64-v8a/libchunker.so

# 应该输出:
# ELF 64-bit LSB shared object, ARM aarch64
```

## 📦 .gitignore 配置

已添加到主项目 `.gitignore`：

```gitignore
# Native libraries (copied from packages, not committed)
lib/native/
```

**原因**：
- 这些是编译产物
- 从包中复制而来
- 不同开发者需要自己编译/复制
- 避免提交大型二进制文件

## 🔧 故障排查

### 错误：Library not loaded

```
dyld: Library not loaded: libchunker_darwin_arm64.dylib
```

**解决**：
1. 运行 `./setup_native_libs.sh`
2. 确保 `lib/native/libchunker.dylib` 存在
3. `flutter clean && flutter run`

### 错误：dlopen failed (Android)

```
dlopen failed: library "libchunker.so" not found
```

**解决**：
1. 检查 `android/src/main/jniLibs/*/libchunker.so` 存在
2. 运行 `./setup_native_libs.sh`
3. `flutter clean && flutter build apk`

### 错误：Failed to load dynamic library (macOS)

```
Failed to load dynamic library '.../lib/native/libchunker.dylib'
```

**解决**：
1. 确认库文件存在
2. 检查库文件权限 `chmod +x lib/native/libchunker.dylib`
3. 验证是 Universal Binary: `file lib/native/libchunker.dylib`

## 📋 开发流程

### 新环境设置

```bash
# 1. Clone 仓库
git clone <repo-url>
cd flow

# 2. 初始化 submodule
git submodule update --init --recursive

# 3. 编译原生库
cd packages/dart_cdc_sync/chunker-ffi
./build.sh
./build_android.sh

# 4. 设置库文件
cd ../../..
./setup_native_libs.sh

# 5. 运行应用
flutter pub get
flutter run
```

### 更新原生库

```bash
# 1. 重新编译
cd packages/dart_cdc_sync/chunker-ffi
./build.sh
./build_android.sh

# 2. 重新复制
cd ../../..
./setup_native_libs.sh

# 3. 清理并重新运行
flutter clean
flutter run
```

## ✅ 完成清单

在运行应用前，确认：

- [ ] macOS 库已编译: `packages/dart_cdc_sync/lib/native/libchunker.dylib`
- [ ] Android 库已编译: `packages/dart_cdc_sync/lib/native/libchunker_android_*.so`
- [ ] 主项目库已复制: `lib/native/libchunker.dylib`
- [ ] macOS 插件库已复制: `packages/dart_cdc_sync/macos/Frameworks/libchunker.dylib`
- [ ] Android 插件库已复制: `packages/dart_cdc_sync/android/src/main/jniLibs/*/libchunker.so`
- [ ] 运行了 `flutter clean`
- [ ] 库文件有执行权限

---

**最后更新**: 2026-01-04

