import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'entry_edit_page.dart';

/// Flow 主页
class FlowHomePage extends StatefulWidget {
  const FlowHomePage({super.key});

  @override
  State<FlowHomePage> createState() => _FlowHomePageState();
}

class _FlowHomePageState extends State<FlowHomePage> {
  final _dbService = DatabaseService();
  final _mediaService = MediaService();
  List<Entry> _entries = [];
  bool _isLoading = true;
  bool _showOnlyFavorites = false; // 是否只显示收藏
  
  // 全局唯一的视频控制器
  VideoPlayerController? _globalVideoController;
  String? _currentVideoAssetId;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _disposeGlobalVideoController();
    super.dispose();
  }

  void _disposeGlobalVideoController() {
    if (_globalVideoController != null) {
      try {
        if (_globalVideoController!.value.isInitialized) {
          _globalVideoController!.pause();
        }
        _globalVideoController!.dispose();
      } catch (e) {
        debugPrint('释放视频控制器失败: $e');
      }
      _globalVideoController = null;
      _currentVideoAssetId = null;
    }
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    
    // 清理旧的视频控制器
    _disposeGlobalVideoController();
    
    try {
      final entries = _showOnlyFavorites 
          ? await _dbService.getFavoriteEntries()
          : await _dbService.getEntries();
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite(Entry entry) async {
    await _dbService.toggleFavorite(entry.id);
    _loadEntries();
  }

  /// 显示/隐藏收藏列表
  void _toggleFavoriteView() {
    setState(() {
      _showOnlyFavorites = !_showOnlyFavorites;
    });
    _loadEntries();
  }

  Future<void> _openEditPage([Entry? entry]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EntryEditPage(entry: entry),
      ),
    );

    if (result == true) {
      _loadEntries();
    }
  }

  Future<void> _deleteEntry(Entry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日记'),
        content: const Text('确定要删除这条日记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.deleteEntry(entry.id);
      _loadEntries();
    }
  }

  Future<void> _switchVideo(String assetId, String videoPath) async {
    // 如果是要播放的视频已经是当前播放的，不切换
    if (_currentVideoAssetId == assetId && _globalVideoController != null) {
      return;
    }

    // 暂停并释放当前视频
    _disposeGlobalVideoController();

    // 初始化新视频
    try {
      _globalVideoController = VideoPlayerController.file(File(videoPath));
      await _globalVideoController!.initialize();
      _globalVideoController!.setLooping(true);
      _globalVideoController!.setVolume(0.0); // 静音播放
      
      if (mounted) {
        setState(() {
          _currentVideoAssetId = assetId;
        });
        _globalVideoController!.play();
      }
    } catch (e) {
      debugPrint('切换视频失败: $e');
      _disposeGlobalVideoController();
    }
  }

  void _pauseCurrentVideo() {
    if (_globalVideoController != null && 
        _globalVideoController!.value.isInitialized &&
        _globalVideoController!.value.isPlaying) {
      try {
        _globalVideoController!.pause();
      } catch (e) {
        debugPrint('暂停视频失败: $e');
      }
    }
  }

  VideoPlayerController? _getVideoController(String assetId) {
    if (_currentVideoAssetId == assetId && _globalVideoController != null) {
      return _globalVideoController;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // 标题栏
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // 菜单图标
                            Builder(
                              builder: (context) => GestureDetector(
                                onTap: () {
                                  Scaffold.of(context).openDrawer();
                                },
                                child: Container(
                                width: 32,
                                height: 32,
                                margin: const EdgeInsets.only(right: 0),
                                
                                child: const Icon(
                                  Icons.menu_rounded,
                                  size: 20,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                            ),
                            const Text(
                              'Flow',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.filter_list_rounded,
                            size: 20,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 日记列表
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_entries.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Slidable(
                              key: ValueKey(_entries[index].id),
                              endActionPane: ActionPane(
                                motion: const StretchMotion(),
                                extentRatio: 0.25,
                                children: [
                                  CustomSlidableAction(
                                    onPressed: (_) => _toggleFavorite(_entries[index]),
                                    backgroundColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildCircleActionButton(
                                          icon: _entries[index].isFavorite 
                                              ? Icons.star_rounded 
                                              : Icons.star_border_rounded,
                                          color: const Color(0xFFFFCC00),
                                        ),
                                        _buildCircleActionButton(
                                          icon: Icons.edit_rounded,
                                          color: const Color(0xFF007AFF),
                                          onTap: () => _openEditPage(_entries[index]),
                                        ),
                                        _buildCircleActionButton(
                                          icon: Icons.delete_rounded,
                                          color: const Color(0xFFFF3B30),
                                          onTap: () => _deleteEntry(_entries[index]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              child: FlowCard(
                                entry: _entries[index],
                                mediaService: _mediaService,
                                currentVideoAssetId: _currentVideoAssetId,
                                getVideoController: _getVideoController,
                                onVideoVisibilityChanged: _switchVideo,
                                onVideoVisibilityLost: _pauseCurrentVideo,
                                onTap: () => _openEditPage(_entries[index]),
                              ),
                            ),
                          );
                        },
                        childCount: _entries.length,
                      ),
                    ),
                  ),
              ],
            ),
            // 浮动添加按钮
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _openEditPage(),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建侧边栏
  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.layers_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Flow',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '记录生活的每一刻',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 菜单项
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: const Text('所有内容'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_entries.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF007AFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      _showOnlyFavorites 
                          ? Icons.favorite 
                          : Icons.favorite_outline,
                      color: _showOnlyFavorites ? Colors.red : null,
                    ),
                    title: Text(
                      _showOnlyFavorites ? '所有内容' : '收藏',
                      style: TextStyle(
                        color: _showOnlyFavorites ? Colors.red : null,
                      ),
                    ),
                    trailing: _showOnlyFavorites
                        ? null
                        : FutureBuilder<List<Entry>>(
                            future: _dbService.getFavoriteEntries(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${snapshot.data!.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                    onTap: () {
                      Navigator.pop(context);
                      _toggleFavoriteView();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('日历视图'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: 跳转到日历视图
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('设置'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: 跳转到设置页面
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('关于'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: 显示关于信息
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建圆形操作按钮
  Widget _buildCircleActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.book_outlined,
              size: 40,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '还没有日记',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击下方按钮开始记录',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flow 卡片组件
class FlowCard extends StatefulWidget {
  final Entry entry;
  final MediaService mediaService;
  final String? currentVideoAssetId;
  final VideoPlayerController? Function(String assetId) getVideoController;
  final Function(String assetId, String videoPath) onVideoVisibilityChanged;
  final VoidCallback onVideoVisibilityLost;
  final VoidCallback? onTap;

  const FlowCard({
    super.key,
    required this.entry,
    required this.mediaService,
    required this.currentVideoAssetId,
    required this.getVideoController,
    required this.onVideoVisibilityChanged,
    required this.onVideoVisibilityLost,
    this.onTap,
  });

  @override
  State<FlowCard> createState() => _FlowCardState();
}

class _FlowCardState extends State<FlowCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 媒体区域（如果有图片或视频资源）
            if (widget.entry.mediaAssets.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: _buildMediaLayout(),
              ),
            // 内容区域（可点击进入编辑页面）
            GestureDetector(
              onTap: widget.onTap,
              child: Padding(
                // 如果没有标题和内容，使用较小的 padding
                padding: EdgeInsets.all(
                  (widget.entry.title.trim().isEmpty &&
                   widget.entry.contentSummary.trim().isNotEmpty) ? 8 : 16
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题或内容摘要
                    if (widget.entry.title.trim().isNotEmpty) ...[
                      // 有标题时显示标题
                      Text(
                        widget.entry.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          height: 1.3,
                        ),
                      ),
                      // 如果有内容，显示内容摘要
                      if (widget.entry.contentSummary.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.entry.contentSummary,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black.withOpacity(0.85),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ] else if (widget.entry.contentSummary.trim().isNotEmpty)
                      // 无标题但有内容时直接显示内容
                      Text(
                        widget.entry.contentSummary,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    // 分隔线（仅在有标题或内容时显示）
                    if (widget.entry.title.trim().isNotEmpty || 
                        widget.entry.contentSummary.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 0.5,
                        color: const Color(0xFFE5E5EA),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // 日期和更多按钮（始终显示）
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(widget.entry.createdDateTime),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8E8E93),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showMoreOptions(context),
                          child: const Icon(
                            Icons.more_horiz,
                            color: Color(0xFF8E8E93),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildMediaLayout() {
    final media = widget.entry.mediaAssets;
    if (media.isEmpty) return const SizedBox.shrink();

    // 找到第一个视频的索引
    int? firstVideoIndex;
    for (int i = 0; i < media.length; i++) {
      if (media[i].isVideo) {
        firstVideoIndex = i;
        break;
      }
    }

    final count = media.length;
    
    if (count == 1) {
      // 单媒体模式
      return SizedBox(
        height: 200,
        width: double.infinity,
        child: _buildMediaTile(media[0], 0, firstVideoIndex),
      );
    } else if (count == 2) {
      // 双媒体模式：左右并列
      return SizedBox(
        height: 160,
        child: Row(
          children: [
            Expanded(child: _buildMediaTile(media[0], 0, firstVideoIndex)),
            const SizedBox(width: 2),
            Expanded(child: _buildMediaTile(media[1], 1, firstVideoIndex)),
          ],
        ),
      );
    } else if (count == 3) {
      // 三媒体模式：左边大图，右边两小图
      return SizedBox(
        height: 180,
        child: Row(
          children: [
            Expanded(flex: 2, child: _buildMediaTile(media[0], 0, firstVideoIndex)),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _buildMediaTile(media[1], 1, firstVideoIndex)),
                  const SizedBox(height: 2),
                  Expanded(child: _buildMediaTile(media[2], 2, firstVideoIndex)),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // 四媒体及以上：2x2 网格，显示数量
      return SizedBox(
        height: 180,
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _buildMediaTile(media[0], 0, firstVideoIndex)),
                  const SizedBox(height: 2),
                  Expanded(child: _buildMediaTile(media[2], 2, firstVideoIndex)),
                ],
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _buildMediaTile(media[1], 1, firstVideoIndex)),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaTile(media[3], 3, firstVideoIndex),
                        if (count > 4)
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: Text(
                                '+${count - 4}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMediaTile(Asset asset, int index, int? firstVideoIndex) {
    // 如果是视频
    if (asset.isVideo) {
      // 只有第一个视频使用 VideoTile 播放，其他显示缩略图
      if (index == firstVideoIndex) {
        return GestureDetector(
          onTap: () => _playVideo(asset),
          child: VideoTile(
            asset: asset,
            mediaService: widget.mediaService,
            currentVideoAssetId: widget.currentVideoAssetId,
            getVideoController: widget.getVideoController,
            onVisibilityChanged: widget.onVideoVisibilityChanged,
            onVisibilityLost: widget.onVideoVisibilityLost,
          ),
        );
      } else {
        // 其他视频显示缩略图，点击跳转到播放页面
        return GestureDetector(
          onTap: () => _playVideo(asset),
          child: _buildVideoThumbnail(asset),
        );
      }
    }
    
    // 图片使用缩略图
    return FutureBuilder<String>(
      future: widget.mediaService.getThumbnailPath(asset),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final file = File(snapshot.data!);
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _buildPlaceholder(false),
          );
        }
        return _buildPlaceholder(false);
      },
    );
  }

  Future<void> _playVideo(Asset asset) async {
    final videoPath = await widget.mediaService.getOriginalPath(asset);
    if (!mounted) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(videoPath: videoPath),
      ),
    );
  }

  Widget _buildVideoThumbnail(Asset asset) {
    return FutureBuilder<String>(
      future: widget.mediaService.getThumbnailPath(asset),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final file = File(snapshot.data!);
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => _buildPlaceholder(true),
              ),
              // 时长显示在右下角
              if (asset.duration != null)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatVideoDuration(asset.duration!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
        return _buildPlaceholder(true);
      },
    );
  }

  String _formatVideoDuration(int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    
    if (minutes > 0) {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '0:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildPlaceholder(bool isVideo) {
    return Container(
      color: isVideo ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
      child: Center(
        child: Icon(
          isVideo ? Icons.videocam : Icons.image_outlined,
          color: isVideo ? Colors.white54 : const Color(0xFF8E8E93),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildMoodTag(Mood mood) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color(mood.colorValue).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mood.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            mood.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(mood.colorValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTag(String location) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4ECDC4).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            size: 14,
            color: Color(0xFF4ECDC4),
          ),
          const SizedBox(width: 4),
          Text(
            location,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4ECDC4),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    
    // 将日期归零到当天0点，只比较日期不比较时间
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(targetDate).inDays;

    if (diff == 0) {
      return '今天';
    } else if (diff == 1) {
      return '昨天';
    } else if (diff < 7) {
      return DateFormat('EEEE', 'zh_CN').format(date);
    } else {
      return DateFormat('M月d日, yyyy').format(date);
    }
  }

  void _showMoreOptions(BuildContext context) {
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
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑'),
              onTap: () {
                Navigator.of(context).pop();
                widget.onTap?.call();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// 视频播放组件（自动播放，全局唯一实例）
class VideoTile extends StatefulWidget {
  final Asset asset;
  final MediaService mediaService;
  final String? currentVideoAssetId;
  final VideoPlayerController? Function(String assetId) getVideoController;
  final Function(String assetId, String videoPath) onVisibilityChanged;
  final VoidCallback onVisibilityLost;

  const VideoTile({
    super.key,
    required this.asset,
    required this.mediaService,
    required this.currentVideoAssetId,
    required this.getVideoController,
    required this.onVisibilityChanged,
    required this.onVisibilityLost,
  });

  @override
  State<VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<VideoTile> {
  bool _isVisible = false;
  String? _videoPath;

  @override
  void initState() {
    super.initState();
    _loadVideoPath();
  }

  Future<void> _loadVideoPath() async {
    try {
      _videoPath = await widget.mediaService.getOriginalPath(widget.asset);
    } catch (e) {
      debugPrint('获取视频路径失败: $e');
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final isVisible = info.visibleFraction > 0.5; // 超过50%可见时播放
    
    if (_isVisible != isVisible && _videoPath != null) {
      _isVisible = isVisible;
      
      if (isVisible) {
        widget.onVisibilityChanged(widget.asset.id, _videoPath!);
      } else {
        widget.onVisibilityLost();
      }
    }
  }

  Future<void> _playVideo() async {
    if (_videoPath == null) {
      _videoPath = await widget.mediaService.getOriginalPath(widget.asset);
    }
    if (!mounted || _videoPath == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(videoPath: _videoPath!),
      ),
    );
  }

  String _formatVideoDuration(int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    
    if (minutes > 0) {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '0:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.getVideoController(widget.asset.id);
    final isCurrentVideo = widget.currentVideoAssetId == widget.asset.id;
    
    return GestureDetector(
      onTap: _playVideo,
      child: VisibilityDetector(
        key: Key('video_${widget.asset.id}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              isCurrentVideo && 
              controller != null && 
              controller.value.isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    )
                  : FutureBuilder<String>(
                      future: widget.mediaService.getThumbnailPath(widget.asset),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final file = File(snapshot.data!);
                          return Image.file(
                            file,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white54,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white54,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    ),
              // 时长显示在右下角
              if (widget.asset.duration != null)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatVideoDuration(widget.asset.duration!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 视频播放页面（全屏）
class VideoPlayerPage extends StatefulWidget {
  final String videoPath;

  const VideoPlayerPage({super.key, required this.videoPath});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(File(widget.videoPath));
      await _controller.initialize();
      _controller.addListener(_videoListener);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      }
    } catch (e) {
      debugPrint('全屏视频初始化失败: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('视频加载失败')),
        );
      }
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 视频播放器
            GestureDetector(
              onTap: _toggleControls,
              child: Center(
                child: _isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : const CircularProgressIndicator(
                        color: Colors.white,
                      ),
              ),
            ),
            // 控制层
            if (_showControls) ...[
              // 顶部栏
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              // 中间播放按钮
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black87,
                      size: 40,
                    ),
                  ),
                ),
              ),
              // 底部进度条
              if (_isInitialized)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFF007AFF),
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_controller.value.position),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(_controller.value.duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
