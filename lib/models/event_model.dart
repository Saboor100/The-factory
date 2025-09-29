// lib/models/event_model.dart
class Event {
  static String _cleanField(dynamic value) {
    if (value == null || value == 'null') return '';
    return value.toString().trim();
  }

  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationDeadline;
  final List<TicketType> ticketTypes;
  final String? imageUrl;
  final String organizerName;
  final String organizerEmail;
  final String? organizerPhone;
  final String category;
  final List<String> tags;
  final bool isPublished;
  final bool isFeatured;
  final bool requiresApproval;
  final int totalRegistrations;
  final bool isRegistrationOpen;
  final bool hasAvailableSpots;
  final List<TicketType> availableTicketTypes;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.registrationDeadline,
    required this.ticketTypes,
    this.imageUrl,
    required this.organizerName,
    required this.organizerEmail,
    this.organizerPhone,
    required this.category,
    required this.tags,
    required this.isPublished,
    required this.isFeatured,
    required this.requiresApproval,
    required this.totalRegistrations,
    required this.isRegistrationOpen,
    required this.hasAvailableSpots,
    required this.availableTicketTypes,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      registrationDeadline: DateTime.parse(json['registrationDeadline']),
      ticketTypes:
          (json['ticketTypes'] as List<dynamic>?)
              ?.map((ticket) => TicketType.fromJson(ticket))
              .toList() ??
          [],
      imageUrl: json['imageUrl'],
      organizerName: _cleanField(json['organizerName']),
      organizerEmail: _cleanField(json['organizerEmail']),
      organizerPhone: _cleanField(json['organizerPhone']),
      category: json['category'] ?? 'other',
      tags: List<String>.from(json['tags'] ?? []),
      isPublished: json['isPublished'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      requiresApproval: json['requiresApproval'] ?? false,
      totalRegistrations: json['totalRegistrations'] ?? 0,
      isRegistrationOpen: json['isRegistrationOpen'] ?? false,
      hasAvailableSpots: json['hasAvailableSpots'] ?? false,
      availableTicketTypes:
          (json['availableTicketTypes'] as List<dynamic>?)
              ?.map((ticket) => TicketType.fromJson(ticket))
              .toList() ??
          [],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'registrationDeadline': registrationDeadline.toIso8601String(),
      'ticketTypes': ticketTypes.map((ticket) => ticket.toJson()).toList(),
      'imageUrl': imageUrl,
      'organizerName': organizerName,
      'organizerEmail': organizerEmail,
      'organizerPhone': organizerPhone,
      'category': category,
      'tags': tags,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'requiresApproval': requiresApproval,
      'totalRegistrations': totalRegistrations,
      'isRegistrationOpen': isRegistrationOpen,
      'hasAvailableSpots': hasAvailableSpots,
      'availableTicketTypes':
          availableTicketTypes.map((ticket) => ticket.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper methods
  String get formattedDateRange {
    final start = '${startDate.day}/${startDate.month}/${startDate.year}';
    final end = '${endDate.day}/${endDate.month}/${endDate.year}';
    return start == end ? start : '$start - $end';
  }

  String get categoryDisplayName {
    switch (category) {
      case 'lacrosse_camp':
        return 'Lacrosse Camp';
      case 'tournament':
        return 'Tournament';
      case 'clinic':
        return 'Clinic';
      case 'workshop':
        return 'Workshop';
      case 'training':
        return 'Training';
      case 'social':
        return 'Social';
      case 'fundraiser':
        return 'Fundraiser';
      default:
        return 'Other';
    }
  }

  double get lowestPrice {
    if (availableTicketTypes.isEmpty) return 0.0;
    return availableTicketTypes
        .map((t) => t.price)
        .reduce((a, b) => a < b ? a : b);
  }

  double get highestPrice {
    if (availableTicketTypes.isEmpty) return 0.0;
    return availableTicketTypes
        .map((t) => t.price)
        .reduce((a, b) => a > b ? a : b);
  }
}

class TicketType {
  final String name;
  final String description;
  final double price;
  final int maxCapacity;
  final int currentRegistrations;
  final bool isActive;

  TicketType({
    required this.name,
    required this.description,
    required this.price,
    required this.maxCapacity,
    required this.currentRegistrations,
    required this.isActive,
  });

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      maxCapacity: json['maxCapacity'] ?? 0,
      currentRegistrations: json['currentRegistrations'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'maxCapacity': maxCapacity,
      'currentRegistrations': currentRegistrations,
      'isActive': isActive,
    };
  }

  bool get hasAvailableSpots => isActive && currentRegistrations < maxCapacity;
  int get availableSpots => maxCapacity - currentRegistrations;
  double get occupancyPercentage => (currentRegistrations / maxCapacity) * 100;
}

// Registration Data for API requests
class RegistrationData {
  final String athleteFirstName;
  final String athleteLastName;
  final String parentLastName;
  final String email;
  final String phone;
  final Address address;
  final String usaLaxNumber;
  final int graduationYear;
  final String ticketType;
  final String? discountCode;
  final EmergencyContact? emergencyContact;
  final MedicalInfo? medicalInfo;

  RegistrationData({
    required this.athleteFirstName,
    required this.athleteLastName,
    required this.parentLastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.usaLaxNumber,
    required this.graduationYear,
    required this.ticketType,
    this.discountCode,
    this.emergencyContact,
    this.medicalInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'athleteFirstName': athleteFirstName,
      'athleteLastName': athleteLastName,
      'parentLastName': parentLastName,
      'email': email,
      'phone': phone,
      'address': address.toJson(),
      'usaLaxNumber': usaLaxNumber,
      'graduationYear': graduationYear,
      'ticketType': ticketType,
      if (discountCode != null) 'discountCode': discountCode,
      if (emergencyContact != null)
        'emergencyContact': emergencyContact!.toJson(),
      if (medicalInfo != null) 'medicalInfo': medicalInfo!.toJson(),
    };
  }
}

class Address {
  final String street;
  final String city;
  final String state;
  final String zipCode;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  Map<String, dynamic> toJson() {
    return {'street': street, 'city': city, 'state': state, 'zipCode': zipCode};
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
    );
  }
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relationship;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'phone': phone, 'relationship': relationship};
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relationship: json['relationship'] ?? '',
    );
  }
}

class MedicalInfo {
  final String? allergies;
  final String? medications;
  final String? specialNeeds;

  MedicalInfo({this.allergies, this.medications, this.specialNeeds});

  Map<String, dynamic> toJson() {
    return {
      if (allergies != null) 'allergies': allergies,
      if (medications != null) 'medications': medications,
      if (specialNeeds != null) 'specialNeeds': specialNeeds,
    };
  }

  factory MedicalInfo.fromJson(Map<String, dynamic> json) {
    return MedicalInfo(
      allergies: json['allergies'],
      medications: json['medications'],
      specialNeeds: json['specialNeeds'],
    );
  }
}

// Registration Response from API
class RegistrationResponse {
  final String registrationId;
  final String confirmationNumber;
  final EventSummary event;
  final ParticipantSummary participant;
  final PricingSummary pricing;
  final bool paymentRequired;
  final String? ticketUrl;

  RegistrationResponse({
    required this.registrationId,
    required this.confirmationNumber,
    required this.event,
    required this.participant,
    required this.pricing,
    required this.paymentRequired,
    this.ticketUrl,
  });

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationResponse(
      registrationId: json['registrationId'] ?? '',
      confirmationNumber: json['confirmationNumber'] ?? '',
      event: EventSummary.fromJson(json['event'] ?? {}),
      participant: ParticipantSummary.fromJson(json['participant'] ?? {}),
      pricing: PricingSummary.fromJson(json['pricing'] ?? {}),
      paymentRequired: json['paymentRequired'] ?? false,
      ticketUrl: json['ticketUrl'],
    );
  }
}

class EventSummary {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String location;

  EventSummary({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.location,
  });

  factory EventSummary.fromJson(Map<String, dynamic> json) {
    return EventSummary(
      title: json['title'] ?? '',
      startDate: DateTime.parse(
        json['startDate'] ?? DateTime.now().toIso8601String(),
      ),
      endDate: DateTime.parse(
        json['endDate'] ?? DateTime.now().toIso8601String(),
      ),
      location: json['location'] ?? '',
    );
  }
}

class ParticipantSummary {
  final String name;
  final String ticketType;

  ParticipantSummary({required this.name, required this.ticketType});

  factory ParticipantSummary.fromJson(Map<String, dynamic> json) {
    return ParticipantSummary(
      name: json['name'] ?? '',
      ticketType: json['ticketType'] ?? '',
    );
  }
}

class PricingSummary {
  final double basePrice;
  final double discountAmount;
  final double finalPrice;
  final String? discountCode;

  PricingSummary({
    required this.basePrice,
    required this.discountAmount,
    required this.finalPrice,
    this.discountCode,
  });

  factory PricingSummary.fromJson(Map<String, dynamic> json) {
    return PricingSummary(
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      finalPrice: (json['finalPrice'] ?? 0).toDouble(),
      discountCode: json['discountCode'],
    );
  }
}

// Discount Validation Response
class DiscountValidation {
  final String code;
  final String description;
  final String discountType;
  final double discountAmount;
  final bool valid;
  final String message;

  DiscountValidation({
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountAmount,
    required this.valid,
    required this.message,
  });

  factory DiscountValidation.fromJson(Map<String, dynamic> json) {
    return DiscountValidation(
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? 'fixed',
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      valid: json['valid'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
