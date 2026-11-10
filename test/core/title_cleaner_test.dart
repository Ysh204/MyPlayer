import 'package:flutter_test/flutter_test.dart';
import 'package:my_player/core/title_cleaner.dart';

void main() {
  group('cleanMediaTitle', () {
    test('cleans scene release with TV show and episode name', () {
      const raw =
          "War.S01E01.It's.Done.1080p.WEB-DLEnglish.MSubs.MoviesMod.aLin.mkv";
      expect(cleanMediaTitle(raw), "War S01E01 - It's Done");
    });

    test('cleans movie with release year and scene tags', () {
      const raw =
          'Oppenheimer.2023.2160p.UHD.BluRay.x265.10bit.TrueHD.7.1.Atmos-SWTYBLZ.mkv';
      expect(cleanMediaTitle(raw), 'Oppenheimer (2023)');
    });

    test('cleans standard movie with dot separated title', () {
      const raw = 'Inception.2010.1080p.BrRip.x264.YIFY.mp4';
      expect(cleanMediaTitle(raw), 'Inception (2010)');
    });

    test('handles simple filenames without scene tags', () {
      expect(cleanMediaTitle('Vacation_Video_2024.mp4'), 'Vacation Video (2024)');
      expect(cleanMediaTitle('sample_video.mov'), 'sample video');
    });

    test('handles empty and whitespace gracefully', () {
      expect(cleanMediaTitle(''), '');
      expect(cleanMediaTitle('   '), '');
    });
  });
}
