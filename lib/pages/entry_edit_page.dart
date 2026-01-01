import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';
import '../services/services.dart';

/// 底部面板类型
enum BottomPanelType {
  none,   // 无面板
  mood,   // 心情选择
  location, // 位置输入
}

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
  
  // 当前显示的底部面板
  BottomPanelType _activePanel = BottomPanelType.none;
  // 位置输入焦点
  final _locationFocusNode = FocusNode();
  
  // 位置相关状态
  bool _isLoadingLocation = false;
  List<BusinessArea> _nearbyPlaces = [];
  bool _hasLocationPermission = false;
  
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
    _locationFocusNode.dispose();
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
                left: 12,
                right: 12,
                top: 12,
                bottom: toolbarHeight + bottomSafeArea + 12 + keyboardHeight,
              ),
              children: [
                // 媒体区域（仅在有媒体时显示）
                if (_hasMedia) ...[
                  _buildMediaSection(),
                  const SizedBox(height: 16),
                ],
                
                // 标题和内容合并到一个卡片
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题输入
                      TextFormField(
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
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 0.5,
                        color: const Color(0xFFE5E5EA),
                      ),
                      const SizedBox(height: 12),
                      // 内容输入
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          hintText: '开始记录...',
                          hintStyle: TextStyle(
                            color: Color(0xFFC7C7CC),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        maxLines: null,
                        minLines: 10,
                        keyboardType: TextInputType.multiline,
                        validator: (value) {
                          // 如果有媒体资源或标题，内容可以为空
                          if (_hasMedia || _titleController.text.trim().isNotEmpty) {
                            return null;
                          }
                          // 没有媒体资源且没有标题时，内容必填
                          if (value == null || value.trim().isEmpty) {
                            return '请至少添加图片/视频、标题或内容';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // 已选择的心情和位置显示
                if (_selectedMood != null || _locationController.text.isNotEmpty)
                  _buildSelectedInfoCard(),

                const SizedBox(height: 16),

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

  /// 请求位置权限并获取附近地点
  Future<void> _fetchNearbyLocations() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // 检查位置服务是否启用
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请先打开位置服务')),
          );
        }
        setState(() {
          _isLoadingLocation = false;
          _hasLocationPermission = false;
        });
        return;
      }

      // 检查位置权限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _hasLocationPermission = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('位置权限被永久拒绝，请在设置中允许'),
              action: SnackBarAction(
                label: '打开设置',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
          _hasLocationPermission = false;
        });
        return;
      }

      // 获取当前位置
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 调用高德API获取附近地点
      final places = await AmapService.getNearbyBusinessAreas(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _nearbyPlaces = places;
        _hasLocationPermission = true;
        _isLoadingLocation = false;
      });
    } catch (e) {
      print('获取位置失败: $e');
      setState(() {
        _isLoadingLocation = false;
        _hasLocationPermission = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取位置失败: $e')),
        );
      }
    }
  }

  /// 切换底部面板
  void _togglePanel(BottomPanelType panel) {
    // 先收起键盘
    FocusScope.of(context).unfocus();
    
    // 等待键盘收起后再显示面板
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() {
        if (_activePanel == panel) {
          // 如果点击当前激活的面板，则关闭
          _activePanel = BottomPanelType.none;
        } else {
          _activePanel = panel;
          // 如果打开位置面板，尝试获取附近地点
          if (panel == BottomPanelType.location) {
            _fetchNearbyLocations();
          }
        }
      });
    });
  }
  
  /// 关闭底部面板
  void _closePanel() {
    setState(() {
      _activePanel = BottomPanelType.none;
    });
  }

  /// 构建底部浮动工具栏
  Widget _buildStickyToolbar({
    required double keyboardHeight,
    required double bottomSafeArea,
    required double toolbarHeight,
  }) {
    final hasPanel = _activePanel != BottomPanelType.none;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      // 整个工具栏+面板一起跟随键盘上移
      transform: Matrix4.translationValues(0, -keyboardHeight, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 工具栏
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7).withOpacity(0.9),
                  border: const Border(
                    top: BorderSide(
                      color: Color(0xFFE5E5EA),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Container(
                  height: toolbarHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // 图片按钮
                      _buildToolbarButton(
                        icon: Icons.image_outlined,
                        label: '图片',
                        isActive: false,
                        hasValue: _hasMedia,
                        onTap: () {
                          _closePanel();
                          _showMediaOptions();
                        },
                      ),
                      const SizedBox(width: 8),
                      // 位置按钮（使用 Flexible 防止溢出）
                      Flexible(
                        child: _buildToolbarButton(
                          icon: Icons.location_on_outlined,
                          label: _locationController.text.isEmpty ? '位置' : _locationController.text,
                          isActive: _activePanel == BottomPanelType.location,
                          hasValue: _locationController.text.isNotEmpty,
                          onTap: () => _togglePanel(BottomPanelType.location),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 心情按钮
                      _buildToolbarButton(
                        icon: _selectedMood != null ? null : Icons.mood_outlined,
                        emoji: _selectedMood?.emoji,
                        label: _selectedMood?.displayName ?? '心情',
                        isActive: _activePanel == BottomPanelType.mood,
                        hasValue: _selectedMood != null,
                        onTap: () => _togglePanel(BottomPanelType.mood),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 底部面板（心情/位置选择）
          if (hasPanel)
            _buildBottomPanel(bottomSafeArea),
        ],
      ),
    );
  }

  /// 构建工具栏按钮
  Widget _buildToolbarButton({
    IconData? icon,
    String? emoji,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool hasValue = false,
  }) {
    final color = isActive ? const Color(0xFF007AFF) : 
                  hasValue ? const Color(0xFF34C759) : 
                  const Color(0xFF007AFF);
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFF007AFF).withOpacity(0.15)
              : Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: isActive 
              ? Border.all(color: const Color(0xFF007AFF), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null)
              Text(emoji, style: const TextStyle(fontSize: 16))
            else if (icon != null)
              Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 60),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建底部面板
  Widget _buildBottomPanel(double bottomSafeArea) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _activePanel == BottomPanelType.mood
              ? _buildMoodPanel()
              : _buildLocationPanel(),
        ),
      ),
    );
  }
  
  /// 构建心情选择面板
  Widget _buildMoodPanel() {
    return Container(
      key: const ValueKey('mood_panel'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '选择心情',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              if (_selectedMood != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMood = null;
                    });
                  },
                  child: const Text(
                    '清除',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: Mood.values.map((mood) {
              final isSelected = _selectedMood == mood;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMood = mood;
                  });
                  // 选择后关闭面板
                  Future.delayed(const Duration(milliseconds: 150), () {
                    _closePanel();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(mood.colorValue).withOpacity(0.2)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? Color(mood.colorValue) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mood.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        mood.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Color(mood.colorValue) : const Color(0xFF1C1C1E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  /// 构建位置输入面板
  Widget _buildLocationPanel() {
    return Container(
      key: const ValueKey('location_panel'),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxHeight: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '选择位置',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              if (_locationController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _locationController.clear();
                    });
                  },
                  child: const Text(
                    '清除',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 手动输入框
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_location_outlined,
                  color: Color(0xFF8E8E93),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: '手动输入位置',
                      hintStyle: TextStyle(
                        color: Color(0xFFC7C7CC),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) => setState(() {}),
                    onSubmitted: (value) => _closePanel(),
                  ),
                ),
              ],
            ),
          ),
          
          // 加载中或地点列表
          if (_isLoadingLocation)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      '正在获取附近地点...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_hasLocationPermission && _nearbyPlaces.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              '附近地点',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _nearbyPlaces.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final place = _nearbyPlaces[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        size: 20,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    title: Text(
                      place.name,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      setState(() {
                        _locationController.text = place.name;
                      });
                      _closePanel();
                    },
                  );
                },
              ),
            ),
          ] else if (!_hasLocationPermission && !_isLoadingLocation) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.location_off_outlined,
                    size: 48,
                    color: Color(0xFF8E8E93),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '需要位置权限才能获取附近地点',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _fetchNearbyLocations,
                    child: const Text('授权位置权限'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// 构建已选择信息卡片（显示在内容区域）
  Widget _buildSelectedInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (_selectedMood != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Color(_selectedMood!.colorValue).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedMood!.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    _selectedMood!.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(_selectedMood!.colorValue),
                    ),
                  ),
                ],
              ),
            ),
            if (_locationController.text.isNotEmpty) const SizedBox(width: 8),
          ],
          if (_locationController.text.isNotEmpty)
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _locationController.text,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1C1C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.all(12),
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
