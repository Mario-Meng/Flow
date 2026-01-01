import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const FlowApp());
}

class FlowApp extends StatelessWidget {
  const FlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const JournalHomePage(),
    );
  }
}

class JournalHomePage extends StatelessWidget {
  const JournalHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
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
                        const Text(
                          'Journal',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: -0.5,
                          ),
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
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      _buildJournalEntries(),
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
          ],
        ),
      ),
    );
  }

  List<Widget> _buildJournalEntries() {
    return [
      // 条目1: 海滩日记 - 多图网格布局
      JournalCard(
        entry: JournalEntry(
          title: 'Morning outing to Ocean Beach',
          content:
              'I dreamed about surfing last night. Whenever that happens, I know I\'m going to have a great day on the water. Sarah',
          date: 'Tuesday, Sep 12',
          imageLayout: ImageLayoutType.gridComplex,
          images: [
            ImageData(color: const Color(0xFF87CEEB), aspectRatio: 1.0), // 冲浪者
            ImageData(color: const Color(0xFFFF6B6B), aspectRatio: 1.0), // 播客封面
            ImageData(color: const Color(0xFF98D8C8), aspectRatio: 1.0), // 贝壳
            ImageData(color: const Color(0xFF4ECDC4), aspectRatio: 1.0), // 地点标签
            ImageData(color: const Color(0xFFE8D5B7), aspectRatio: 1.0), // 海岸
          ],
          tags: [
            JournalTag(
              icon: Icons.location_on,
              label: 'Ocean Beach',
              color: const Color(0xFF4ECDC4),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // 条目2: 山间徒步
      JournalCard(
        entry: JournalEntry(
          title: 'Afternoon hike, Mount Diablo',
          content:
              'What a day! Sheila and Jaro are in town visiting from LA. We decided to head out to Mount Diablo to see the poppies in bloom. The',
          date: 'Monday, Sep 11',
          imageLayout: ImageLayoutType.sideStack,
          images: [
            ImageData(color: const Color(0xFF7CB342), aspectRatio: 1.5), // 山景
          ],
          tags: [
            JournalTag(
              icon: Icons.directions_walk,
              label: '9560 steps',
              title: 'Walk',
              color: const Color(0xFFFFE4E1),
              iconColor: const Color(0xFFFF6B6B),
            ),
            JournalTag(
              icon: Icons.park,
              label: 'Mt. Diablo State Park',
              color: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF4CAF50),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // 条目3: 咖啡馆阅读
      JournalCard(
        entry: JournalEntry(
          title: 'Quiet afternoon at Blue Bottle',
          content:
              'Finally finished reading "The Midnight Library". Such a beautiful story about choices and parallel lives. The lavender latte was perfect.',
          date: 'Sunday, Sep 10',
          imageLayout: ImageLayoutType.single,
          images: [
            ImageData(color: const Color(0xFFD4A574), aspectRatio: 1.8),
          ],
          tags: [
            JournalTag(
              icon: Icons.menu_book,
              label: 'The Midnight Library',
              color: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFFF9800),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // 条目4: 音乐会
      JournalCard(
        entry: JournalEntry(
          title: 'Live at The Fillmore',
          content:
              'Incredible show tonight! The energy was absolutely electric. Met some amazing people in the crowd. Can\'t wait for the next one.',
          date: 'Saturday, Sep 9',
          imageLayout: ImageLayoutType.gridSimple,
          images: [
            ImageData(color: const Color(0xFF9C27B0), aspectRatio: 1.0),
            ImageData(color: const Color(0xFFE91E63), aspectRatio: 1.0),
            ImageData(color: const Color(0xFF673AB7), aspectRatio: 1.0),
          ],
          tags: [
            JournalTag(
              icon: Icons.music_note,
              label: 'Concert',
              color: const Color(0xFFF3E5F5),
              iconColor: const Color(0xFF9C27B0),
            ),
            JournalTag(
              icon: Icons.location_on,
              label: 'The Fillmore',
              color: const Color(0xFFE8EAF6),
              iconColor: const Color(0xFF3F51B5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // 条目5: 烹饪日记
      JournalCard(
        entry: JournalEntry(
          title: 'Homemade pasta night',
          content:
              'First attempt at making fresh pasta from scratch. It was messy, took forever, but absolutely worth it. Mom would be proud.',
          date: 'Friday, Sep 8',
          imageLayout: ImageLayoutType.dual,
          images: [
            ImageData(color: const Color(0xFFFFEB3B), aspectRatio: 1.0),
            ImageData(color: const Color(0xFFFF5722), aspectRatio: 1.0),
          ],
          tags: [
            JournalTag(
              icon: Icons.restaurant,
              label: 'Cooking',
              color: const Color(0xFFFFF8E1),
              iconColor: const Color(0xFFFF9800),
            ),
          ],
        ),
      ),
    ];
  }
}

// 数据模型
enum ImageLayoutType { single, dual, gridSimple, gridComplex, sideStack }

class ImageData {
  final Color color;
  final double aspectRatio;

  ImageData({required this.color, this.aspectRatio = 1.0});
}

class JournalTag {
  final IconData icon;
  final String label;
  final String? title;
  final Color color;
  final Color? iconColor;

  JournalTag({
    required this.icon,
    required this.label,
    this.title,
    required this.color,
    this.iconColor,
  });
}

class JournalEntry {
  final String title;
  final String content;
  final String date;
  final ImageLayoutType imageLayout;
  final List<ImageData> images;
  final List<JournalTag> tags;

  JournalEntry({
    required this.title,
    required this.content,
    required this.date,
    required this.imageLayout,
    required this.images,
    this.tags = const [],
  });
}

// 日记卡片组件
class JournalCard extends StatelessWidget {
  final JournalEntry entry;

  const JournalCard({super.key, required this.entry});

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
          // 图片区域
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildImageLayout(),
          ),
          // 内容区域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.content,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black.withOpacity(0.85),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // 分隔线
                Container(
                  height: 0.5,
                  color: const Color(0xFFE5E5EA),
                ),
                const SizedBox(height: 12),
                // 日期和更多按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.date,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Icon(
                      Icons.more_horiz,
                      color: Color(0xFF8E8E93),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageLayout() {
    switch (entry.imageLayout) {
      case ImageLayoutType.gridComplex:
        return _buildComplexGrid();
      case ImageLayoutType.sideStack:
        return _buildSideStackLayout();
      case ImageLayoutType.single:
        return _buildSingleImage();
      case ImageLayoutType.gridSimple:
        return _buildSimpleGrid();
      case ImageLayoutType.dual:
        return _buildDualImages();
    }
  }

  // 复杂网格布局 (第一个条目样式)
  Widget _buildComplexGrid() {
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          // 左侧大图
          Expanded(
            flex: 5,
            child: _buildPlaceholderImage(entry.images[0].color),
          ),
          const SizedBox(width: 2),
          // 右侧小图网格
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPlaceholderImage(
                          entry.images[1].color,
                          child: _buildPodcastOverlay(),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: _buildPlaceholderImage(entry.images[2].color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPlaceholderImage(
                          entry.images[3].color,
                          child: _buildLocationBadge(entry.tags.first),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: _buildPlaceholderImage(entry.images[4].color),
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

  // 侧边堆叠布局 (第二个条目样式)
  Widget _buildSideStackLayout() {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          // 左侧大图
          Expanded(
            flex: 5,
            child: _buildPlaceholderImage(
              entry.images[0].color,
              child: _buildMountainScene(),
            ),
          ),
          const SizedBox(width: 2),
          // 右侧标签堆叠
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: _buildWalkTag(entry.tags[0]),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: _buildMapTag(entry.tags[1]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 单图布局
  Widget _buildSingleImage() {
    return SizedBox(
      height: 160,
      child: Stack(
        children: [
          _buildPlaceholderImage(entry.images[0].color),
          if (entry.tags.isNotEmpty)
            Positioned(
              right: 12,
              bottom: 12,
              child: _buildFloatingTag(entry.tags[0]),
            ),
        ],
      ),
    );
  }

  // 简单网格布局
  Widget _buildSimpleGrid() {
    return SizedBox(
      height: 140,
      child: Row(
        children: entry.images.map((img) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: _buildPlaceholderImage(img.color),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 双图布局
  Widget _buildDualImages() {
    return SizedBox(
      height: 160,
      child: Row(
        children: [
          Expanded(
            child: _buildPlaceholderImage(entry.images[0].color),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _buildPlaceholderImage(entry.images[1].color),
          ),
        ],
      ),
    );
  }

  // 占位符图片
  Widget _buildPlaceholderImage(Color color, {Widget? child}) {
    return Container(
      color: color,
      child: child,
    );
  }

  // 播客覆盖层
  Widget _buildPodcastOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B6B),
            const Color(0xFFFFE66D),
            const Color(0xFF4ECDC4),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'DECODER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'RING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'SLATE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 7,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 地点徽章
  Widget _buildLocationBadge(JournalTag tag) {
    return Container(
      color: tag.color,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                tag.icon,
                color: tag.iconColor ?? tag.color,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tag.label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 山景场景占位
  Widget _buildMountainScene() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF87CEEB),
            const Color(0xFF98D8C8),
            const Color(0xFF7CB342),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF8BC34A),
                    Color(0xFF689F38),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 步行标签
  Widget _buildWalkTag(JournalTag tag) {
    return Container(
      color: tag.color,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_walk,
            color: tag.iconColor,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            tag.title ?? '',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
          Text(
            tag.label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // 地图标签
  Widget _buildMapTag(JournalTag tag) {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: Stack(
        children: [
          // 模拟地图背景
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF5F5DC).withOpacity(0.5),
                    const Color(0xFFE8F5E9),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.park,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tag.label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 浮动标签
  Widget _buildFloatingTag(JournalTag tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tag.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tag.icon,
            size: 14,
            color: tag.iconColor,
          ),
          const SizedBox(width: 4),
          Text(
            tag.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tag.iconColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
