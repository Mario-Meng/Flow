import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'entry_edit_page.dart';

/// 日记查看页面
class EntryViewPage extends StatefulWidget {
  final Entry entry;

  const EntryViewPage({super.key, required this.entry});

  @override
  State<EntryViewPage> createState() => _EntryViewPageState();
}

class _EntryViewPageState extends State<EntryViewPage> {
  final _mediaService = MediaService();

  /// 进入编辑模式
  Future<void> _enterEditMode() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EntryEditPage(entry: widget.entry),
      ),
    );

    if (result == true && mounted) {
      // 编辑完成，返回主页刷新
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '查看日记',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _enterEditMode,
            child: const Text(
              '编辑',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 媒体区域
          if (widget.entry.mediaAssets.isNotEmpty) ...[
            _buildMediaSection(),
            const SizedBox(height: 16),
          ],

          // 内容卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                if (widget.entry.title.trim().isNotEmpty) ...[
                  Text(
                    widget.entry.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: const Color(0xFFE5E5EA),
                  ),
                  const SizedBox(height: 16),
                ],

                // Markdown 内容
                if (widget.entry.content.trim().isNotEmpty)
                  MarkdownWidget(
                    data: widget.entry.content,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    config: MarkdownConfig(
                      configs: [
                        H1Config(
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        H2Config(
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        H3Config(
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        PConfig(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                        CodeConfig(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 心情和位置信息
          if (widget.entry.mood != null || widget.entry.locationName != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.entry.mood != null) _buildMoodTag(widget.entry.mood!),
                  if (widget.entry.locationName != null)
                    _buildLocationTag(widget.entry.locationName!),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // 时间信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(
                  '创建: ${_formatDateTime(widget.entry.createdDateTime)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '更新: ${_formatDateTime(widget.entry.updatedDateTime)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
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

  /// 媒体区域
  Widget _buildMediaSection() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: widget.entry.mediaAssets.length,
        itemBuilder: (context, index) {
          final asset = widget.entry.mediaAssets[index];
          return Padding(
            padding: EdgeInsets.only(right: index < widget.entry.mediaAssets.length - 1 ? 8 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<String>(
                future: _mediaService.getThumbnailPath(asset),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.file(
                      File(snapshot.data!),
                      fit: BoxFit.cover,
                      width: 160,
                    );
                  }
                  return Container(
                    width: 160,
                    color: const Color(0xFFE5E5EA),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodTag(Mood mood) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(mood.colorValue).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mood.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            mood.displayName,
            style: TextStyle(
              fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            size: 16,
            color: Color(0xFF007AFF),
          ),
          const SizedBox(width: 4),
          Text(
            location,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF007AFF),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy年M月d日 HH:mm', 'zh_CN').format(dateTime);
  }
}

