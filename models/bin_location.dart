class BinLocation {
  final double latitude;
  final double longitude;
  final String address;

  BinLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory BinLocation.fromJson(Map<String, dynamic> json) {
    final lat = double.parse(json['geometry']['coordinates'][1].toString());
    final lng = double.parse(json['geometry']['coordinates'][0].toString());
    final address = json['fields']['address'] ?? "Unknown Location";

    return BinLocation(
      latitude: lat,
      longitude: lng,
      address: address,
    );
  }
}
