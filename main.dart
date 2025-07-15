import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/jog_record.dart';
import 'screens/jog_history_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/bin_location.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(JogRecordAdapter());
  await Hive.openBox<JogRecord>('jog_records');

  runApp(MaterialApp(home: JoggingApp()));
}

class JoggingApp extends StatefulWidget {
  @override
  State<JoggingApp> createState() => _JoggingAppState();
}

class _JoggingAppState extends State<JoggingApp> {
  Position? _lastPosition;
  Timer? _timer;
  double _totalDistance = 0.0;
  final Stopwatch _stopwatch = Stopwatch();
  late final Stream<Position> _positionStream;
  late StreamSubscription<Position> _positionSubscription;

  GoogleMapController? _mapController;
  List<LatLng> _routePoints = [];
  Set<Marker> _markers = {}; //  시작/도착 마커 저장

  @override
  void initState() {
    super.initState();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
    // 쓰레기통 마커 불러오기
    fetchBinLocations().then((bins) {
      setState(() {
        for (var bin in bins) {
          _markers.add(Marker(
            markerId: MarkerId("bin_${bin.latitude}_${bin.longitude}"),
            position: LatLng(bin.latitude, bin.longitude),
            infoWindow: InfoWindow(title: "쓰레기통", snippet: bin.address),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ));
        }
      });
    }).catchError((e) {
      print("쓰레기통 데이터 불러오기 실패: $e");
    });
  }

  void _startJogging() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });

    _positionSubscription = _positionStream.listen((Position pos) {
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          pos.latitude,
          pos.longitude,
        );
        setState(() {
          _totalDistance += distance;
        });
      }

      setState(() {
        final currentLatLng = LatLng(pos.latitude, pos.longitude);
        _routePoints.add(currentLatLng);

        //  시작 마커
        if (_routePoints.length == 1) {
          _markers.add(Marker(
            markerId: const MarkerId("start"),
            position: currentLatLng,
            infoWindow: const InfoWindow(title: "출발 지점"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ));
        }
      });

      _lastPosition = pos;

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(pos.latitude, pos.longitude),
        ),
      );
    });
  }

  void _stopJogging() {
    _stopwatch.stop();
    _positionSubscription.cancel();
    _timer?.cancel();
    _saveJogRecord();

    //  종료 마커 추가
    if (_lastPosition != null) {
      final endLatLng = LatLng(_lastPosition!.latitude, _lastPosition!.longitude);
      setState(() {
        _markers.add(Marker(
          markerId: const MarkerId("end"),
          position: endLatLng,
          infoWindow: const InfoWindow(title: "도착 지점"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      });
    }

    setState(() {
      _stopwatch.reset();
      _totalDistance = 0.0;
      _lastPosition = null;
      // 경로와 마커는 유지 → 지도에서 확인 가능
    });
  }

  void _saveJogRecord() {
    final record = JogRecord(
      date: DateTime.now(),
      distanceKm: _totalDistance / 1000,
      durationSeconds: _stopwatch.elapsed.inSeconds,
      speedKmph: _calculateSpeed(),
    );
    Hive.box<JogRecord>('jog_records').add(record);
  }
  void _shareJogRecord() {
    final duration = _formatDuration(_stopwatch.elapsed);
    final speed = _calculateSpeed().toStringAsFixed(2);
    final distanceKm = (_totalDistance / 1000).toStringAsFixed(2);

    final text = '''
📊 내 조깅 기록 공유합니다!

⏱ 시간: $duration
📏 거리: $distanceKm km
🚀 평균 속도: $speed km/h

#조깅기록 #FlutterApp #건강한습관
''';

    Share.share(text);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  double _calculateSpeed() {
    if (_stopwatch.elapsed.inSeconds == 0) return 0.0;
    final seconds = _stopwatch.elapsed.inSeconds;
    final mps = _totalDistance / seconds;
    return mps * 3.6;
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _positionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _formatDuration(_stopwatch.elapsed);
    final speed = _calculateSpeed().toStringAsFixed(2);
    final distanceKm = (_totalDistance / 1000).toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(title: const Text('조깅 트래커')),
      body: Column(
        children: [
          // 🗺️ 지도 영역
          Expanded(
            flex: 1,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(37.5665, 126.9780),
                zoom: 16,
              ),
              myLocationEnabled: true,
              polylines: {
                Polyline(
                  polylineId: const PolylineId("route"),
                  color: Colors.blue,
                  width: 5,
                  points: _routePoints,
                ),
              },
              markers: _markers, //  마커 추가
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
          //  조깅 정보
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("⏱ 시간: $duration", style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 16),
                Text("📏 거리: $distanceKm km", style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 16),
                Text("🚀 평균 속도: $speed km/h", style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startJogging,
                  child: const Text("▶ 조깅 시작"),
                ),
                ElevatedButton(
                  onPressed: _stopJogging,
                  child: const Text("⏸ 조깅 정지"),
                ),
                //ElevatedButton(
                  //onPressed: _shareJogRecord,
                  //child: const Text("📤 기록 공유"),
                //),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JogHistoryScreen()),
                    );
                  },
                  child: const Text("📋 기록 보기"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
Future<List<BinLocation>> fetchBinLocations() async {
  final url = Uri.parse(
      "https://data.melbourne.vic.gov.au/api/explore/v2.1/catalog/datasets/syringe-bin-locations/records?limit=20"
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final records = data['results'] as List;
    return records.map((e) => BinLocation.fromJson(e)).toList();
  } else {
    throw Exception("데이터 불러오기 실패: ${response.statusCode}");
  }
}
