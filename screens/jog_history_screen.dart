import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/jog_record.dart';
import 'package:share_plus/share_plus.dart';

class JogHistoryScreen extends StatelessWidget {
  const JogHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jogBox = Hive.box<JogRecord>('jog_records');

    return Scaffold(
      appBar: AppBar(title: const Text("📋 조깅 기록")),
      body: ValueListenableBuilder(
        valueListenable: jogBox.listenable(),
        builder: (context, Box<JogRecord> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text("기록이 없습니다."));
          }

          final records = box.values.toList().reversed.toList();

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return ListTile(
                title: Text(
                  "${record.date.toLocal()}".split(' ')[0],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "거리: ${record.distanceKm.toStringAsFixed(2)} km | 시간: ${record.durationSeconds ~/ 60}분",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    Share.share(record.toShareText());
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
