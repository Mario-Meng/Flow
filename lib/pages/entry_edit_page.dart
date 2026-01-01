import 'package:flutter/material.dart';
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

  Mood? _selectedMood;
  bool _isSaving = false;

  bool get isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _locationController.text = widget.entry!.locationName ?? '';
      _selectedMood = widget.entry!.mood;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entry = Entry(
        id: isEditing ? widget.entry!.id : const Uuid().v4(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        mood: _selectedMood,
        locationName: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        createdAt: isEditing ? widget.entry!.createdAt : now,
        updatedAt: now,
      );

      if (isEditing) {
        await _dbService.updateEntry(entry);
      } else {
        await _dbService.insertEntry(entry);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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

