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
      width: 360,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xF5121215),
        border: Border(left: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'PLAYLIST',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
              ),
              IconButton(
                tooltip: 'Add media files',
                onPressed: onAddFiles,
                icon: const Icon(Icons.add),
              ),
              IconButton(
                tooltip: 'Clear playlist',
                onPressed: playlist.medias.isEmpty ? null : notifier.clearQueue,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const Divider(color: Colors.white12),
          Expanded(
            child: playlist.medias.isEmpty
                ? const Center(
                    child: Text(
                      'Open multiple files or add media to build a playlist.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
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
                      return ListTile(
                        key: ValueKey('${media.uri}-$index'),
                        dense: true,
                        selected: isCurrent,
                        selectedTileColor: const Color(0x22F59E0B),
                        leading: Icon(
                          isCurrent ? Icons.equalizer : Icons.movie_outlined,
                          color: isCurrent
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white54,
                        ),
                        title: Text(
                          p.basename(media.uri),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          media.uri,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white38),
                        ),
                        onTap: () => notifier.jumpTo(index),
                        trailing: IconButton(
                          tooltip: 'Remove from playlist',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => notifier.removeFromQueue(index),
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
