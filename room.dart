import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id, ownerId, title, city, area, roomType, description;
  final int rent, deposit;
  final List<String> photos;
  final bool furnished, bathroom, kitchen, parking, wifi, featured, verified;
  final double? latitude, longitude;
  final String status;
  final DateTime? availableFrom;

  const Room({required this.id, required this.ownerId, required this.title, required this.city, required this.area,
    required this.rent, required this.deposit, required this.roomType, required this.description, required this.photos,
    required this.furnished, required this.bathroom, required this.kitchen, required this.parking, required this.wifi,
    required this.featured, required this.verified, required this.latitude, required this.longitude, required this.status, required this.availableFrom});

  factory Room.fromDoc(DocumentSnapshot<Map<String,dynamic>> d) {
    final m=d.data()??{}; final geo=m['location'];
    return Room(id:d.id, ownerId:m['ownerId']??'', title:m['title']??'', city:m['city']??'', area:m['area']??'',
      rent:(m['rent'] as num? ?? 0).toInt(), deposit:(m['deposit'] as num? ?? 0).toInt(), roomType:m['roomType']??'Single',
      description:m['description']??'', photos:List<String>.from(m['photos']??const []), furnished:m['furnished']==true,
      bathroom:m['bathroom']==true, kitchen:m['kitchen']==true, parking:m['parking']==true, wifi:m['wifi']==true,
      featured:m['featured']==true, verified:m['verified']==true, latitude:(geo?['latitude'] as num?)?.toDouble(),
      longitude:(geo?['longitude'] as num?)?.toDouble(), status:m['status']??'pending',
      availableFrom:(m['availableFrom'] as Timestamp?)?.toDate());
  }
}
