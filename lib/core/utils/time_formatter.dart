String formatDuration(Duration duration) {
  final safeDuration = duration.isNegative ? Duration.zero : duration;
  final hours = safeDuration.inHours;
  final minutes =
      safeDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds =
      safeDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
