class Profile {
  final String? id;
  final String? userId;
  final String? fullName;
  final DateTime? dob;
  final Address? address;
  final String? clubTeam;
  final String? school;
  final int? graduationYear;
  final String? position;
  final String? instagramHandle;
  final Avatar? avatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Profile({
    this.id,
    this.userId,
    this.fullName,
    this.dob,
    this.address,
    this.clubTeam,
    this.school,
    this.graduationYear,
    this.position,
    this.instagramHandle,
    this.avatar,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['_id'],
      userId: json['user'],
      fullName: json['fullName'],
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      address:
          json['address'] != null ? Address.fromJson(json['address']) : null,
      clubTeam: json['clubTeam'],
      school: json['school'],
      graduationYear: json['graduationYear'],
      position: json['position'] ?? 'Other',
      instagramHandle: json['instagramHandle'],
      avatar: json['avatar'] != null ? Avatar.fromJson(json['avatar']) : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // FIXED: Proper toJson method that matches backend expectations
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    // Only include non-null and non-empty fields
    if (fullName != null && fullName!.isNotEmpty) {
      data['fullName'] = fullName;
    }

    if (dob != null) {
      data['dob'] = dob!.toIso8601String();
    }

    if (clubTeam != null && clubTeam!.isNotEmpty) {
      data['clubTeam'] = clubTeam;
    }

    if (school != null && school!.isNotEmpty) {
      data['school'] = school;
    }

    if (graduationYear != null) {
      data['graduationYear'] = graduationYear;
    }

    if (position != null && position!.isNotEmpty) {
      data['position'] = position;
    }

    if (instagramHandle != null && instagramHandle!.isNotEmpty) {
      // Remove @ symbol if present
      String handle =
          instagramHandle!.startsWith('@')
              ? instagramHandle!.substring(1)
              : instagramHandle!;
      data['instagramHandle'] = handle;
    }

    // FIXED: Send individual address fields, not nested object
    if (address != null) {
      if (address!.street != null && address!.street!.isNotEmpty) {
        data['street'] = address!.street;
      }
      if (address!.city != null && address!.city!.isNotEmpty) {
        data['city'] = address!.city;
      }
      if (address!.state != null && address!.state!.isNotEmpty) {
        data['state'] = address!.state;
      }
      if (address!.zip != null && address!.zip!.isNotEmpty) {
        data['zip'] = address!.zip;
      }
    }

    return data;
  }

  Profile copyWith({
    String? id,
    String? userId,
    String? fullName,
    DateTime? dob,
    Address? address,
    String? clubTeam,
    String? school,
    int? graduationYear,
    String? position,
    String? instagramHandle,
    Avatar? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      clubTeam: clubTeam ?? this.clubTeam,
      school: school ?? this.school,
      graduationYear: graduationYear ?? this.graduationYear,
      position: position ?? this.position,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Address {
  final String? street;
  final String? city;
  final String? state;
  final String? zip;

  Address({this.street, this.city, this.state, this.zip});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      zip: json['zip'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (street != null && street!.isNotEmpty) data['street'] = street;
    if (city != null && city!.isNotEmpty) data['city'] = city;
    if (state != null && state!.isNotEmpty) data['state'] = state;
    if (zip != null && zip!.isNotEmpty) data['zip'] = zip;

    return data;
  }

  Address copyWith({String? street, String? city, String? state, String? zip}) {
    return Address(
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
    );
  }
}

class Avatar {
  final String? url;
  final String? publicId;

  Avatar({this.url, this.publicId});

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(url: json['url'], publicId: json['publicId']);
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'publicId': publicId};
  }

  Avatar copyWith({String? url, String? publicId}) {
    return Avatar(url: url ?? this.url, publicId: publicId ?? this.publicId);
  }
}
