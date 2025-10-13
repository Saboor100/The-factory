// lib/models/user_registration_model.dart
class UserRegistration {
  final String id;
  final EventBasicInfo event;
  final String confirmationNumber;
  final String ticketType;
  final String registrationStatus;
  final String paymentStatus;
  final double paidAmount;
  final String? paymentMethod;
  final DateTime registrationDate;
  final String athleteName;

  UserRegistration({
    required this.id,
    required this.event,
    required this.confirmationNumber,
    required this.ticketType,
    required this.registrationStatus,
    required this.paymentStatus,
    required this.paidAmount,
    this.paymentMethod,
    required this.registrationDate,
    required this.athleteName,
  });

  factory UserRegistration.fromJson(Map<String, dynamic> json) {
    return UserRegistration(
      id: json['_id'] ?? json['id'] ?? '',
      event: EventBasicInfo.fromJson(json['event'] ?? {}),
      confirmationNumber: json['confirmationNumber'] ?? '',
      ticketType: json['ticketType'] ?? '',
      registrationStatus: json['registrationStatus'] ?? 'active',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'],
      registrationDate: DateTime.parse(
        json['registrationDate'] ?? DateTime.now().toIso8601String(),
      ),
      athleteName:
          '${json['athleteFirstName'] ?? ''} ${json['athleteLastName'] ?? ''}'
              .trim(),
    );
  }
}

class EventBasicInfo {
  final String id;
  final String title;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;

  EventBasicInfo({
    required this.id,
    required this.title,
    required this.location,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
  });

  String get formattedDateRange {
    final start = '${startDate.day}/${startDate.month}/${startDate.year}';
    final end = '${endDate.day}/${endDate.month}/${endDate.year}';
    return start == end ? start : '$start - $end';
  }

  factory EventBasicInfo.fromJson(Map<String, dynamic> json) {
    return EventBasicInfo(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      imageUrl: json['imageUrl'],
    );
  }
}
