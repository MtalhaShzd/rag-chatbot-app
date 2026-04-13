import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) =>
                setState(() => _search = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search history...',
                prefixIcon: Icon(Icons.search, size: 20),
                contentPadding:
                  EdgeInsets.symmetric(vertical: 8)),
            ),
          ),
        ),
      ),
      // Groups messages and shows them as sessions
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.accent));
          }

          final allDocs = snap.data?.docs ?? [];
          if (allDocs.isEmpty) {
            return _emptyState();
          }

          // Group into conversation pairs
          final sessions = _groupIntoSessions(allDocs);

          // Filter by search
          final filtered = sessions.where((s) {
            if (_search.isEmpty) return true;
            return s.any((msg) =>
              (msg['content'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_search));
          }).toList();

          if (filtered.isEmpty) {
            return _emptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final session = filtered[i];
              // First user message as title
              final firstUser = session.firstWhere(
                (m) => m['role'] == 'user',
                orElse: () => session.first);
              final title = firstUser['content']
                .toString();
              final msgCount = session.length;
              final tsStr =
                session.last['timestamp'] ?? '';
              DateTime ts = DateTime.now();
              try { ts = DateTime.parse(tsStr); }
              catch (_) {}

              return _SessionCard(
                title: title,
                messageCount: msgCount,
                timestamp: ts,
                messages: session,
                onDelete: () async {
                  // Delete all messages in this session
                  for (final msg in session) {
                    final id = msg['id'];
                    if (id != null) {
                      await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('messages')
                        .doc(id)
                        .delete();
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  // Groups flat messages into conversation sessions
  // A new session starts after a gap of 1+ hour
  List<List<Map<String, dynamic>>> _groupIntoSessions(
      List<QueryDocumentSnapshot> docs) {
    final sessions = <List<Map<String, dynamic>>>[];
    List<Map<String, dynamic>> current = [];
    DateTime? lastTs;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final tsStr = data['timestamp'] ?? '';
      DateTime ts = DateTime.now();
      try { ts = DateTime.parse(tsStr); } catch (_) {}

      if (lastTs != null &&
          ts.difference(lastTs!).inMinutes > 60) {
        if (current.isNotEmpty) {
          sessions.add(List.from(current));
          current = [];
        }
      }
      current.add(data);
      lastTs = ts;
    }
    if (current.isNotEmpty) sessions.add(current);

    return sessions.reversed.toList();
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history, size: 64,
          color: AppColors.textSecondary
            .withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        const Text('No conversations yet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        const Text(
          'Your chat history will appear here',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary)),
      ],
    ),
  );
}

// Session card — shows preview, tap to expand full convo
class _SessionCard extends StatefulWidget {
  final String title;
  final int messageCount;
  final DateTime timestamp;
  final List<Map<String, dynamic>> messages;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.title,
    required this.messageCount,
    required this.timestamp,
    required this.messages,
    required this.onDelete,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder)),
      child: Column(children: [
        // Session header — tap to expand
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
            setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Icon
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accent
                    .withValues(alpha: 0.15),
                  borderRadius:
                    BorderRadius.circular(12)),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.accent,
                  size: 20)),
              const SizedBox(width: 12),
              // Title + count
              Expanded(child: Column(
                crossAxisAlignment:
                  CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.messageCount} messages · '
                    '${timeago.format(widget.timestamp)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary)),
                ])),
              // Actions
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error, size: 20),
                onPressed: () => _confirmDelete(context),
                tooltip: 'Delete session',
              ),
              Icon(
                _expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
                color: AppColors.textSecondary),
            ]),
          ),
        ),

        // Expanded full conversation
        if (_expanded) ...[
          const Divider(
            height: 1, color: AppColors.darkBorder),
          ListView.builder(
            shrinkWrap: true,
            physics:
              const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: widget.messages.length,
            itemBuilder: (ctx, i) {
              final msg = widget.messages[i];
              final isUser = msg['role'] == 'user';
              final content = msg['content'] ?? '';
              final tsStr = msg['timestamp'] ?? '';
              DateTime ts = DateTime.now();
              try {
                ts = DateTime.parse(tsStr);
              } catch (_) {}

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 12),
                child: Row(
                  mainAxisAlignment: isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                  crossAxisAlignment:
                    CrossAxisAlignment.end,
                  children: [
                    if (!isUser) ...[
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                          AppColors.accent,
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: Colors.white)),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        padding:
                          const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8),
                        decoration: BoxDecoration(
                          color: isUser
                            ? AppColors.userBubble
                            : AppColors.aiBubble,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius
                              .circular(14),
                            topRight: const Radius
                              .circular(14),
                            bottomLeft: Radius.circular(
                              isUser ? 14 : 4),
                            bottomRight: Radius.circular(
                              isUser ? 4 : 14),
                          )),
                        child: Column(
                          crossAxisAlignment:
                            CrossAxisAlignment.start,
                          children: [
                            Text(content,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.5)),
                            const SizedBox(height: 4),
                            Text(
                              '${ts.hour % 12 == 0 ? 12 : ts.hour % 12}:'
                              '${ts.minute.toString().padLeft(2, '0')} '
                              '${ts.hour >= 12 ? 'PM' : 'AM'}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors
                                  .textSecondary)),
                          ]),
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                          AppColors.darkBorder,
                        child: const Icon(
                          Icons.person,
                          size: 14,
                          color: AppColors
                            .textSecondary)),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ]),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: const Text(
          'This conversation will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            child: const Text('Delete',
              style: TextStyle(
                color: AppColors.error))),
        ],
      ),
    );
  }
}