import 'package:hive/hive.dart';

part 'jog_record.g.dart';

@HiveType(typeId: 0)
class JogRecord extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double distanceKm;

  @HiveField(2)
  final int durationSeconds; // ⏱ 이게 꼭 있어야 함!

  @HiveField(3)
  final double speedKmph;

  JogRecord({
    required this.date,
    required this.distanceKm,
    required this.durationSeconds,
    required this.speedKmph,
  });

  // ✅ 여기서 durationSeconds 없으면 에러 발생!
  Duration get duration => Duration(seconds: durationSeconds);
}
extension JogRecordShare on JogRecord {
  String toShareText() {
    return '''
📊 내가 달린 조깅 기록!

📅 날짜: ${date.toLocal().toString().split('.')[0]}
⏱ 시간: ${durationSeconds ~/ 60}분 ${durationSeconds % 60}초
📏 거리: ${distanceKm.toStringAsFixed(2)} km
🚀 평균 속도: ${speedKmph.toStringAsFixed(2)} km/h

#조깅 #운동기록 #건강한습관
''';
  }
}


