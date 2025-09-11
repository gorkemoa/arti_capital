import 'package:flutter/material.dart';

class MessageDetailView extends StatefulWidget {
  const MessageDetailView({super.key, required this.peerName});
  final String peerName;

  @override
  State<MessageDetailView> createState() => _MessageDetailViewState();
}

class _MessageDetailViewState extends State<MessageDetailView> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(text: 'Merhaba! Size nasıl yardımcı olabilirim?', isMe: false, time: '12:28'),
    const _ChatMessage(text: 'Merhaba, başvurumun durumu nedir?', isMe: true, time: '12:29'),
    const _ChatMessage(text: 'İnceleyip hemen dönüş yapacağım.', isMe: false, time: '12:30'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.onPrimary.withOpacity(0.15),
              child: Text(
                _initials(widget.peerName),
                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.peerName, style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w700)),
           ],
            ),
          ],
        ),
        centerTitle: false,
        foregroundColor: colorScheme.onPrimary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              reverse: false,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (index == 0) {
                  return Column(
                    children: [
                      _DateChip(label: 'Bugün'),
                      const SizedBox(height: 8),
                      _Bubble(message: msg, peerName: widget.peerName),
                    ],
                  );
                }
                return _Bubble(message: msg, peerName: widget.peerName);
              },
            ),
          ),
          _Composer(
            controller: _controller,
            onSend: _handleSend,
          ),
        ],
      ),
    );
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isMe: true, time: _nowLabel()));
    });
    _controller.clear();
  }

  String _nowLabel() {
    final now = TimeOfDay.now();
    final String hh = now.hour.toString().padLeft(2, '0');
    final String mm = now.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.peerName});
  final _ChatMessage message;
  final String peerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bubbleColor = message.isMe ? colorScheme.primary : colorScheme.surface;
    final textColor = message.isMe ? colorScheme.onPrimary : colorScheme.onSurface;
    final subtleBorder = theme.colorScheme.outline.withOpacity(message.isMe ? 0.0 : 0.12);

    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: message.isMe
          ? colorScheme.primary.withOpacity(0.15)
          : colorScheme.secondary.withOpacity(0.15),
      child: Text(
        message.isMe ? _initials('Ben') : _initials(peerName),
        style: theme.textTheme.labelSmall?.copyWith(
          color: message.isMe ? colorScheme.primary : colorScheme.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final bubble = Flexible(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Stack(
          children: [
            // Bubble body (tail removed)
            Container(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(message.isMe ? 14 : 4),
                  topRight: Radius.circular(message.isMe ? 4 : 14),
                  bottomLeft: const Radius.circular(14),
                  bottomRight: const Radius.circular(14),
                ),
                border: Border.all(color: subtleBorder),
                boxShadow: [
                  BoxShadow(color: theme.shadowColor.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(color: textColor, height: 1.25),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.time,
                        style: theme.textTheme.labelSmall?.copyWith(color: textColor.withOpacity(0.8)),
                      ),
                      if (message.isMe) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.done_all_rounded, size: 16, color: textColor.withOpacity(0.9)),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            // Tail removed per design
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: message.isMe
            ? [
                // Right aligned: bubble then avatar
                bubble,
                const SizedBox(width: 8),
                avatar,
              ]
            : [
                // Left aligned: avatar then bubble
                avatar,
                const SizedBox(width: 8),
                bubble,
              ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

// Tail painter removed

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleBorder = theme.colorScheme.outline.withOpacity(0.12);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(color: theme.colorScheme.surface, border: Border(top: BorderSide(color: subtleBorder))),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: theme.shadowColor.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      tooltip: 'Emoji',
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Mesaj yazın...',
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.attach_file_rounded),
                      tooltip: 'Ek Ekle',
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.camera_alt_outlined),
                      tooltip: 'Kamera',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSend,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.send_rounded, color: theme.colorScheme.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isMe, required this.time});
  final String text;
  final bool isMe;
  final String time;
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.8), fontWeight: FontWeight.w700)),
    );
  }
}


