import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/services.dart';

/// 日记编辑页面
class EntryEditPage extends StatefulWidget {
  final Entry? entry; // 如果为 null，则为新建模式

  const EntryEditPage({super.key, this.entry});

  @override
  State<EntryEditPage> createState() => _EntryEditPageState();
}

class _EntryEditPageState extends State<EntryEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _dbService = DatabaseService();
  final _mediaService = MediaService();
  final _scrollController = ScrollController();

  Mood? _selectedMood;
  bool _isSaving = false;
  
  // 已选择的图片
  List<XFile> _selectedImages = [];
  // 已选择的视频
  List<XFile> _selectedVideos = [];
  // 已有的媒体资源（编辑模式）
  List<Asset> _existingAssets = [];

  bool get isEditing => widget.entry != null;
  
  /// 是否有媒体资源（已有的或新选择的）
  bool get _hasMedia => 
      _existingAssets.isNotEmpty || 
      _selectedImages.isNotEmpty || 
      _selectedVideos.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _locationController.text = widget.entry!.locationName ?? '';
      _selectedMood = widget.entry!.mood;
      _existingAssets = List.from(widget.entry!.mediaAssets);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 选择图片
  Future<void> _pickImages() async {
    final images = await _mediaService.pickMultipleImages();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  /// 拍照
  Future<void> _takePhoto() async {
    final image = await _mediaService.takePhoto();
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  /// 选择视频
  Future<void> _pickVideo() async {
    final video = await _mediaService.pickVideo();
    if (video != null) {
      setState(() {
        _selectedVideos.add(video);
      });
    }
  }

  /// 录制视频
  Future<void> _recordVideo() async {
    final video = await _mediaService.recordVideo();
    if (video != null) {
      setState(() {
        _selectedVideos.add(video);
      });
    }
  }

  /// 移除新选择的图片
  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// 移除新选择的视频
  void _removeSelectedVideo(int index) {
    setState(() {
      _selectedVideos.removeAt(index);
    });
  }

  /// 移除已有的资源
  void _removeExistingAsset(int index) {
    setState(() {
      _existingAssets.removeAt(index);
    });
  }

  /// 显示添加媒体的选项
  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '添加媒体',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择图片'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('从相册选择视频'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('录制视频'),
              onTap: () {
                Navigator.pop(context);
                _recordVideo();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entryId = isEditing ? widget.entry!.id : const Uuid().v4();
      
      List<Asset> newAssets = [];
      int sortOrder = _existingAssets.length;
      
      // 处理新选择的图片
      if (_selectedImages.isNotEmpty) {
        final imageAssets = await _mediaService.processAndSaveImages(
          images: _selectedImages,
          entryId: entryId,
          startIndex: sortOrder,
        );
        newAssets.addAll(imageAssets);
        sortOrder += imageAssets.length;
      }
      
      // 处理新选择的视频
      for (final video in _selectedVideos) {
        final videoAsset = await _mediaService.processAndSaveVideo(
          video: video,
          entryId: entryId,
          sortOrder: sortOrder,
        );
        if (videoAsset != null) {
          newAssets.add(videoAsset);
          sortOrder++;
        }
      }
      
      // 合并已有的和新的资源
      final allAssets = [..._existingAssets, ...newAssets];
      
      final entry = Entry(
        id: entryId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        mood: _selectedMood,
        locationName: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        createdAt: isEditing ? widget.entry!.createdAt : now,
        updatedAt: now,
        assets: allAssets,
      );

      if (isEditing) {
        await _dbService.updateEntry(entry);
        
        // 删除移除的资源
        final removedAssets = widget.entry!.mediaAssets
            .where((a) => !_existingAssets.any((e) => e.id == a.id))
            .toList();
        for (final asset in removedAssets) {
          await _dbService.deleteAsset(asset.id);
          await _mediaService.deleteMediaFiles(asset);
        }
      } else {
        await _dbService.insertEntry(entry);
      }
      
      // 保存新的资源到数据库
      if (newAssets.isNotEmpty) {
        await _dbService.insertAssets(newAssets);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // 返回 true 表示有更新
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取键盘高度
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    // 底部安全区高度
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    // 工具栏高度
    const toolbarHeight = 56.0;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      resizeToAvoidBottomInset: false, // 禁用自动调整，我们手动处理
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditing ? '编辑日记' : '新建日记',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveEntry,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 主内容区域
          Form(
            key: _formKey,
            child: ListView(
              controller: _scrollController,
              // 底部留出工具栏 + 安全区的空间
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: toolbarHeight + bottomSafeArea + 16 + keyboardHeight,
              ),
              children: [
                // 媒体区域（仅在有媒体时显示）
                if (_hasMedia) ...[
                  _buildMediaSection(),
                  const SizedBox(height: 16),
                ],
                
                // 标题输入
                _buildSectionCard(
                  child: TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: '标题',
                      hintStyle: TextStyle(
                        color: Color(0xFFC7C7CC),
                        fontSize: 17,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入标题';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 内容输入
                _buildSectionCard(
                  child: TextFormField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: '写下你的想法...',
                      hintStyle: TextStyle(
                        color: Color(0xFFC7C7CC),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    maxLines: null,
                    minLines: 8,
                    keyboardType: TextInputType.multiline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入内容';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 心情选择
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '心情',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMoodSelector(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 地点输入
                _buildSectionCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF8E8E93),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            hintText: '添加地点',
                            hintStyle: TextStyle(
                              color: Color(0xFFC7C7CC),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 提示文字
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '支持 Markdown 格式编写内容',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          // 底部浮动工具栏
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyToolbar(
              keyboardHeight: keyboardHeight,
              bottomSafeArea: bottomSafeArea,
              toolbarHeight: toolbarHeight,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部浮动工具栏
  Widget _buildStickyToolbar({
    required double keyboardHeight,
    required double bottomSafeArea,
    required double toolbarHeight,
  }) {
    final hasKeyboard = keyboardHeight > 0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      // 键盘弹起时跟随键盘上移
      transform: Matrix4.translationValues(0, -keyboardHeight, 0),
      child: ClipRect(
        child: BackdropFilter(
          // 高斯模糊效果
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              // 半透明背景 + 模糊效果
              color: const Color(0xFFF2F2F7).withOpacity(0.9),
              border: const Border(
                top: BorderSide(
                  color: Color(0xFFE5E5EA),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              // 键盘弹起时不需要底部安全区
              bottom: !hasKeyboard,
              child: Container(
                height: toolbarHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 图片按钮
                    _buildToolbarButton(
                      icon: Icons.image_outlined,
                      label: '图片',
                      onTap: _showMediaOptions,
                    ),
                    const SizedBox(width: 8),
                    // 位置按钮
                    _buildToolbarButton(
                      icon: Icons.location_on_outlined,
                      label: '位置',
                      onTap: () {
                        // TODO: 实现位置功能
                      },
                    ),
                    const SizedBox(width: 8),
                    // 心情按钮
                    _buildToolbarButton(
                      icon: Icons.mood_outlined,
                      label: '心情',
                      onTap: () {
                        // TODO: 实现心情快捷选择功能
                      },
                    ),
                    const Spacer(),
                    // 收起键盘按钮（仅在键盘弹起时显示）
                    if (hasKeyboard)
                      _buildToolbarButton(
                        icon: Icons.keyboard_hide_outlined,
                        label: '收起',
                        onTap: () {
                          FocusScope.of(context).unfocus();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建工具栏按钮
  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF007AFF),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 媒体区域（仅在有媒体时显示）
  Widget _buildMediaSection() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          // 已有的媒体资源
          ..._existingAssets.asMap().entries.map((entry) {
            final index = entry.key;
            final asset = entry.value;
            return _buildExistingAssetTile(asset, index);
          }),
          // 新选择的图片
          ..._selectedImages.asMap().entries.map((entry) {
            final index = entry.key;
            final xFile = entry.value;
            return _buildSelectedImageTile(xFile, index);
          }),
          // 新选择的视频
          ..._selectedVideos.asMap().entries.map((entry) {
            final index = entry.key;
            final xFile = entry.value;
            return _buildSelectedVideoTile(xFile, index);
          }),
        ],
      ),
    );
  }

  /// 已有资源缩略图
  Widget _buildExistingAssetTile(Asset asset, int index) {
    return FutureBuilder<String>(
      future: _mediaService.getThumbnailPath(asset),
      builder: (context, snapshot) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 100,
                  height: 100,
                  color: const Color(0xFFE5E5EA),
                  child: snapshot.hasData
                      ? Image.file(
                          File(snapshot.data!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF8E8E93),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                ),
              ),
              // 视频标识
              if (asset.isVideo)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam,
                          size: 12,
                          color: Colors.white,
                        ),
                        SizedBox(width: 2),
                        Text(
                          '视频',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeExistingAsset(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 新选择的图片缩略图
  Widget _buildSelectedImageTile(XFile xFile, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 100,
              height: 100,
              color: const Color(0xFFE5E5EA),
              child: Image.file(
                File(xFile.path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeSelectedImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // 新图片标识
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '新',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 新选择的视频缩略图
  Widget _buildSelectedVideoTile(XFile xFile, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 100,
              height: 100,
              color: const Color(0xFF2C2C2E),
              child: const Center(
                child: Icon(
                  Icons.videocam,
                  size: 32,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeSelectedVideo(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // 新视频标识
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam,
                    size: 10,
                    color: Colors.white,
                  ),
                  SizedBox(width: 2),
                  Text(
                    '新',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildMoodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: Mood.values.map((mood) {
          final isSelected = _selectedMood == mood;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMood = isSelected ? null : mood;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(mood.colorValue).withOpacity(0.2)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Color(mood.colorValue)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Text(
                        mood.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(mood.colorValue),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
