class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.email,
  });

  final String name;
  final String phone;
  final String email;

  EmergencyContact copyWith({
    String? name,
    String? phone,
    String? email,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name,
        'phone': phone,
        'email': email,
      };

  factory EmergencyContact.fromJson(Map<String, Object?> json) {
    return EmergencyContact(
      name: '${json['name'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      email: '${json['email'] ?? ''}',
    );
  }
}

class QuickEmergencyMessage {
  const QuickEmergencyMessage({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  QuickEmergencyMessage copyWith({
    String? title,
    String? text,
  }) {
    return QuickEmergencyMessage(
      title: title ?? this.title,
      text: text ?? this.text,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'title': title,
        'text': text,
      };

  factory QuickEmergencyMessage.fromJson(Map<String, Object?> json) {
    return QuickEmergencyMessage(
      title: '${json['title'] ?? ''}',
      text: '${json['text'] ?? ''}',
    );
  }
}

class EmergencySettings {
  const EmergencySettings({
    required this.contacts,
    required this.quickMessages,
    required this.additionalNote,
    required this.countryCode,
  });

  final List<EmergencyContact> contacts;
  final List<QuickEmergencyMessage> quickMessages;
  final String additionalNote;
  final String countryCode;

  EmergencySettings copyWith({
    List<EmergencyContact>? contacts,
    List<QuickEmergencyMessage>? quickMessages,
    String? additionalNote,
    String? countryCode,
  }) {
    return EmergencySettings(
      contacts: contacts ?? this.contacts,
      quickMessages: quickMessages ?? this.quickMessages,
      additionalNote: additionalNote ?? this.additionalNote,
      countryCode: countryCode ?? this.countryCode,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'contacts': contacts.map((item) => item.toJson()).toList(),
        'quickMessages': quickMessages.map((item) => item.toJson()).toList(),
        'additionalNote': additionalNote,
        'countryCode': countryCode,
      };

  factory EmergencySettings.fromJson(Map<String, Object?> json) {
    return EmergencySettings(
      contacts: ((json['contacts'] as List<Object?>?) ?? <Object?>[])
          .map((item) => EmergencyContact.fromJson((item as Map<Object?, Object?>).cast<String, Object?>()))
          .toList(),
      quickMessages: ((json['quickMessages'] as List<Object?>?) ?? <Object?>[])
          .map((item) => QuickEmergencyMessage.fromJson((item as Map<Object?, Object?>).cast<String, Object?>()))
          .toList(),
      additionalNote: '${json['additionalNote'] ?? ''}',
      countryCode: '${json['countryCode'] ?? 'CO'}',
    );
  }
}

class EmergencyNumber {
  const EmergencyNumber({
    required this.label,
    required this.number,
    required this.description,
  });

  final String label;
  final String number;
  final String description;
}

