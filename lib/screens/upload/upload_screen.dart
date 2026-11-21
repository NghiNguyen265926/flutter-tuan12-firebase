import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../utils/app_logger.dart';
import '../../utils/format.dart';
import '../../utils/ui.dart';

class UploadItem {
  UploadItem({
    required this.name,
    required this.size,
    required this.ref,
    this.task,
    this.state = TaskState.running,
    this.progress = 0,
  });

  final String name;
  final int size;
  final Reference ref;
  UploadTask? task;
  TaskState state;
  double progress;
  String? url;
  StreamSubscription<TaskSnapshot>? sub;
}

/// Bài tập 5.2 - Upload file lên Firebase Storage
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  static const Color _blue = Color(0xFF4FC3F7);

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final List<UploadItem> _items = [];
  bool _editMode = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.sub?.cancel();
    }
    super.dispose();
  }

  /// File đã upload trước đó của user (thư mục uploads/<uid>)
  Future<void> _loadExisting() async {
    try {
      final result = await _storage.ref('uploads/$_uid').listAll();
      final loaded = <UploadItem>[];
      for (final ref in result.items) {
        final meta = await ref.getMetadata();
        loaded.add(UploadItem(
          name: _displayName(ref.name),
          size: meta.size ?? 0,
          ref: ref,
          state: TaskState.success,
          progress: 1,
        ));
      }
      loaded.sort((a, b) => b.ref.name.compareTo(a.ref.name));
      if (!mounted) return;
      setState(() => _items.addAll(loaded));
    } catch (e) {
      logger.e('Load existing files error: $e');
    }
  }

  // File lưu trên Storage có dạng <timestamp>_<tên gốc>
  String _displayName(String stored) {
    final i = stored.indexOf('_');
    return i > 0 ? stored.substring(i + 1) : stored;
  }

    
  Future<void> _pickFiles() async {
    try {
      // Mở trình chọn file
      final files = await FilePicker.pickFiles();

      // Người dùng không chọn file hoặc đã đóng màn hình
      if (files.isEmpty || !mounted) return;

      for (final f in files) {
        // Lấy đường dẫn file
        final path = f.path;

        if (path == null) {
          showMsg(
            context,
            'Không thể truy cập đường dẫn file: ${f.name}',
            error: true,
          );
          continue;
        }

        // Lấy dung lượng file theo API mới
        final size = f.lengthSync() ?? await f.length() ?? 0;

        if (!mounted) return;

        // Bắt đầu upload lên Firebase Storage
        _startUpload(File(path), f.name, size);
      }
    } catch (e) {
      logger.e('File picker error: $e');

      if (mounted) {
        showMsg(
          context,
          'Không thể chọn file: $e',
          error: true,
        );
      }
    }
  }


  void _startUpload(File file, String name, int size) {
    final ref = _storage
        .ref()
        .child('uploads/$_uid/${DateTime.now().millisecondsSinceEpoch}_$name');
    final task = ref.putFile(file);
    final item = UploadItem(name: name, size: size, ref: ref, task: task);
    setState(() => _items.insert(0, item));

    // EventListener: lắng nghe tiến trình upload
    item.sub = task.snapshotEvents.listen(
      (TaskSnapshot snap) {
        if (!mounted) return;
        setState(() {
          item.state = snap.state;
          item.progress =
              snap.totalBytes == 0 ? 0 : snap.bytesTransferred / snap.totalBytes;
        });
      },
      onError: (Object e) {
        logger.w('Upload event error: $e');
        if (!mounted) return;
        setState(() {
          item.state = (e is FirebaseException && e.code == 'canceled')
              ? TaskState.canceled
              : TaskState.error;
        });
      },
    );

    task.then((snap) async {
      try {
        item.url = await snap.ref.getDownloadURL();
        logger.i('File uploaded, download URL: ${item.url}');
      } catch (e) {
        logger.w('getDownloadURL error: $e');
      }
    }, onError: (Object e) {
      logger.w('Upload stopped: $e');
    });
  }

  Future<void> _pause(UploadItem item) async {
    await item.task?.pause();
  }

  Future<void> _resume(UploadItem item) async {
    await item.task?.resume();
  }

  Future<void> _stop(UploadItem item) async {
    await item.task?.cancel();
    if (mounted) setState(() => item.state = TaskState.canceled);
  }

  Future<void> _remove(UploadItem item) async {
    try {
      if (item.state == TaskState.success) {
        await item.ref.delete(); // xóa trên Storage
      }
      item.sub?.cancel();
      if (mounted) setState(() => _items.remove(item));
    } catch (e) {
      logger.e('Delete error: $e');
      if (mounted) showMsg(context, 'Không xóa được: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _blue),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Upload', style: TextStyle(color: Colors.black38)),
        actions: [
          TextButton(
            onPressed: () => setState(() => _editMode = !_editMode),
            child: Text(_editMode ? 'Done' : 'Edit',
                style: const TextStyle(color: _blue)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _items.isEmpty
                ? _emptyView()
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) => _tile(_items[i]),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _pickFiles,
                child: const Text('Choose File',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return const Center(
      child: Icon(Icons.cloud_upload, size: 110, color: _blue),
    );
  }

  Color _barColor(TaskState s) {
    switch (s) {
      case TaskState.success:
        return const Color(0xFF3DD16F);
      case TaskState.paused:
        return const Color(0xFFFFC107);
      case TaskState.running:
        return _blue;
      default:
        return Colors.redAccent;
    }
  }

  Color _badgeColor(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'pdf':
        return Colors.redAccent;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  String _badgeText(String name) {
    final ext = name.contains('.') ? name.split('.').last : '';
    if (ext.isEmpty) return 'FI';
    return ext.length <= 2 ? ext.toUpperCase() : ext.substring(0, 2).toUpperCase();
  }

  String _statusText(UploadItem item) {
    final pct = '${(item.progress * 100).toStringAsFixed(0)}%';
    switch (item.state) {
      case TaskState.success:
        return formatSize(item.size);
      case TaskState.running:
        return pct;
      case TaskState.paused:
        return 'Tạm dừng • $pct';
      case TaskState.canceled:
        return 'Đã hủy';
      case TaskState.error:
        return 'Lỗi';
    }
  }

  Widget _tile(UploadItem item) {
    final color = _barColor(item.state);
    final active =
        item.state == TaskState.running || item.state == TaskState.paused;

    Widget trailing;
    if (_editMode) {
      trailing = IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        onPressed: () => _remove(item),
      );
    } else if (item.state == TaskState.success) {
      trailing = const Icon(Icons.check, color: Color(0xFF3DD16F));
    } else if (active) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item.state == TaskState.running
              ? IconButton(
                  tooltip: 'Pause',
                  icon: const Icon(Icons.pause, color: _blue),
                  onPressed: () => _pause(item),
                )
              : IconButton(
                  tooltip: 'Resume',
                  icon: const Icon(Icons.play_arrow, color: Color(0xFFFFB300)),
                  onPressed: () => _resume(item),
                ),
          IconButton(
            tooltip: 'Stop',
            icon: const Icon(Icons.stop, color: Colors.redAccent),
            onPressed: () => _stop(item),
          ),
        ],
      );
    } else {
      trailing = IconButton(
        tooltip: 'Remove',
        icon: const Icon(Icons.close, color: Colors.redAccent),
        onPressed: () => _remove(item),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _badgeColor(item.name).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_badgeText(item.name),
                  style: TextStyle(
                      color: _badgeColor(item.name),
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13)),
                      ),
                      Text(_statusText(item),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 4,
                    color: color,
                    backgroundColor: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
