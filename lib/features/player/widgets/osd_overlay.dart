import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_provider.dart';

class OsdOverlay extends ConsumerWidget {
  const OsdOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final osd = ref.watch(osdProvider);

    return Positioned(
      top: 48,
      left: 0,
      right: 0,
      child: Center(
        child: IgnorePointer(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: osd.visible ? 1.0 : 0.0,
            curve: Curves.easeOutCubic,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: osd.visible ? 1.0 : 0.92,
              curve: Curves.easeOutBack,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xEE16161D),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x88000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      osd.icon,
                      size: 20,
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          osd.text,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (osd.subtext != null && osd.subtext!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            osd.subtext!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                        if (osd.progress != null) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 120,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: osd.progress!.clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor: const Color(0x33FFFFFF),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

