import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;

import '../../player/providers/player_provider.dart';

class PlaylistPanel extends ConsumerWidget {
  final VoidCallback onAddFiles;

  const PlaylistPanel({super.key, required this.onAddFiles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playerPlaylistProvider).valueOrNull ??
        const Playlist(<Media>[]);
    final notifier = ref.read(playbackProvider.notifier);

    return Container(
      width: 380,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xF214141A),
        border: Border(left: BorderSide(color: Color(0xFF2E2E3C))),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.queue_music_rounded,
                  size: 20, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PLAYLIST (${playlist.medias.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Add media files',
                iconSize: 20,
                onPressed: onAddFiles,
                icon: const Icon(Icons.add_rounded),
              ),
              IconButton(
                tooltip: 'Clear playlist',
                iconSize: 20,
                onPressed: playlist.medias.isEmpty ? null : notifier.clearQueue,
                icon: const Icon(Icons.delete_sweep_rounded),
              ),
              IconButton(
                tooltip: 'Close panel',
                iconSize: 20,
                onPressed: () => ref.read(activeDrawerProvider.notifier).state =
                    ActiveDrawerPanel.none,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const Divider(color: Color(0xFF2E2E3C), height: 16),
          Expanded(
            child: playlist.medias.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.queue_music_outlined,
                          size: 40,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Playlist is empty',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Add multiple files or drag them into the player.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.white38),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: onAddFiles,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add files'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF3B3B4A)),
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: playlist.medias.length,
                    onReorderItem: (oldIndex, newIndex) {
                      notifier.moveInQueue(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final media = playlist.medias[index];
                      final isCurrent = index == playlist.index;
                      return Container(
                        key: ValueKey('${media.uri}-$index'),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0x28F59E0B)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: isCurrent
                              ? Border.all(color: const Color(0x55F59E0B))
                              : null,
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isCurrent
                                      ? const Color(0xFFF59E0B)
                                      : Colors.white38,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isCurrent
                                    ? Icons.play_circle_fill_rounded
                                    : Icons.movie_outlined,
                                size: 18,
                                color: isCurrent
                                    ? const Color(0xFFF59E0B)
                                    : Colors.white54,
                              ),
                            ],
                          ),
                          title: Text(
                            p.basename(media.uri),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isCurrent
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isCurrent
                                  ? Colors.white
                                  : const Color(0xFFD4D4D8),
                            ),
                          ),
                          subtitle: Text(
                            media.uri,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                          ),
                          onTap: () => notifier.jumpTo(index),
                          trailing: IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () => notifier.removeFromQueue(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
