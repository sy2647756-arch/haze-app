import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 「Share to」底部面板（Figma Invition 系列）。
/// v1 只有「Copy link」真能用（复制到剪贴板）；社交按钮与联系人列表点了 coming soon。
Future<void> showShareSheet(BuildContext context, {required String link}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShareSheet(link: link),
  );
}

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({required this.link});
  final String link;

  void _soon(BuildContext c, String what) {
    Navigator.of(c).pop();
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(
        content: Text('$what — coming soon'),
        duration: const Duration(seconds: 1)));
  }

  Future<void> _copy(BuildContext c) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!c.mounted) return;
    Navigator.of(c).pop();
    ScaffoldMessenger.of(c).showSnackBar(const SnackBar(
        content: Text('Shared successfully · link copied'),
        duration: Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Center(
                  child: Text('Share to',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, size: 20, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Recent Share',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final n in ['Melody', 'Jiaxing', 'Maddy', 'Ella'])
                _person(context, n),
              _more(context),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(height: 1),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _channel(context, 'WeChat', const Color(0xFF2DC100), Icons.chat,
                  () => _soon(context, 'WeChat')),
              _channel(context, 'Facebook', const Color(0xFF1877F2), Icons.facebook,
                  () => _soon(context, 'Facebook')),
              _channel(context, 'Twitter', const Color(0xFF1DA1F2), Icons.close,
                  () => _soon(context, 'Twitter')),
              _channel(context, 'Instagram', const Color(0xFFE1306C),
                  Icons.camera_alt, () => _soon(context, 'Instagram')),
              _channel(context, 'Copy link', const Color(0xFFC640A3), Icons.link,
                  () => _copy(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _person(BuildContext c, String name) {
    return GestureDetector(
      onTap: () => _soon(c, 'Direct share'),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFFEDEAF6)),
            alignment: Alignment.center,
            child: Text(name.characters.first,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B7EE5))),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 52,
            child: Text(name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _more(BuildContext c) {
    return GestureDetector(
      onTap: () => _soon(c, 'More contacts'),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12)),
            child: const Icon(Icons.more_horiz, color: Colors.black45),
          ),
          const SizedBox(height: 6),
          const Text('More',
              style: TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _channel(BuildContext c, String label, Color color, IconData icon,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 56,
            child: Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
