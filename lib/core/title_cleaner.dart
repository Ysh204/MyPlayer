import 'package:path/path.dart' as p;

/// Cleans raw video filenames by stripping scene tags, hashes, and codec labels
/// into a clean, human-readable title.
String cleanMediaTitle(String raw) {
  if (raw.trim().isEmpty) return '';

  var base = p.basename(raw);

  // Strip extension
  final ext = p.extension(base);
  if (ext.isNotEmpty && ext.length <= 5) {
    base = base.substring(0, base.length - ext.length);
  }

  // Common scene cutoff tags
  final cutoffRegex = RegExp(
    r'[\.\s_\-\[(]+(?:1080p|720p|480p|2160p|4k|uhd|web-?dl|webrip|bluray|bdrip|brrip|dvdrip|h\.?264|h\.?265|hevc|x264|x265|aac|dts|ddp5\.1|ac3|atmos|hdr\b|10bit|remux|proper|repack)',
    caseSensitive: false,
  );

  final cutoffMatch = cutoffRegex.firstMatch(base);
  String cleanPart = cutoffMatch != null ? base.substring(0, cutoffMatch.start) : base;

  // Replace dots, underscores, and multiple hyphens with spaces
  cleanPart = cleanPart
      .replaceAll(RegExp(r'[\._]+'), ' ')
      .replaceAll(RegExp(r'\s+-\s+'), ' - ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // If title has a 4-digit release year at the end, format as (YYYY)
  final yearTrailing = RegExp(r'^(.*?)\s+(19\d\d|20\d\d)$');
  final yearMatch = yearTrailing.firstMatch(cleanPart);
  if (yearMatch != null) {
    cleanPart = '${yearMatch.group(1)} (${yearMatch.group(2)})';
  }

  // Format S01E01 nicely if followed by episode title: e.g. "War S01E01 It's Done" -> "War S01E01 - It's Done"
  final seWithEpTitle = RegExp(r'^(.*?)\s+([sS]\d{1,2}[eE]\d{1,2})\s+(.+)$');
  final seMatch = seWithEpTitle.firstMatch(cleanPart);
  if (seMatch != null && !seMatch.group(3)!.startsWith('-')) {
    cleanPart = '${seMatch.group(1)} ${seMatch.group(2)!.toUpperCase()} - ${seMatch.group(3)}';
  }

  // Strip leading/trailing hyphens or brackets
  cleanPart = cleanPart.replaceAll(RegExp(r'^[\s\-–—]+|[\s\-–—]+$'), '').trim();

  return cleanPart.isNotEmpty ? cleanPart : p.basenameWithoutExtension(raw);
}
