import 'dart:convert';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:signal_scope/src/features/sos/domain/emergency_models.dart';

class EmergencySettingsStore {
  static const _settingsKey = 'emergency_settings_v1';

  Future<EmergencySettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return _defaultSettings();
    }

    final settings = EmergencySettings.fromJson(
      jsonDecode(raw) as Map<String, Object?>,
    );

    // Migra el contacto demostrativo que venía precargado en versiones anteriores.
    final contacts = settings.contacts
        .where(
          (contact) => !(contact.name == 'Familiar de confianza' &&
              contact.phone == '123' &&
              contact.email.isEmpty),
        )
        .toList();

    if (contacts.length != settings.contacts.length) {
      final migrated = settings.copyWith(contacts: contacts);
      await save(migrated);
      return migrated;
    }

    return settings;
  }

  Future<void> save(EmergencySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  EmergencySettings _defaultSettings() {
    final countryCode = PlatformDispatcher.instance.locale.countryCode ?? 'CO';
    return EmergencySettings(
      contacts: const <EmergencyContact>[],
      quickMessages: const <QuickEmergencyMessage>[
        QuickEmergencyMessage(
          title: 'Necesito ayuda',
          text: 'Necesito ayuda urgente. Por favor comunícate conmigo.',
        ),
        QuickEmergencyMessage(
          title: 'Estoy atrapado',
          text: 'Estoy atrapado y necesito rescate.',
        ),
        QuickEmergencyMessage(
          title: 'Estoy herido',
          text: 'Estoy herido y necesito asistencia médica.',
        ),
        QuickEmergencyMessage(
          title: 'No puedo respirar',
          text: 'No puedo respirar bien. Necesito ayuda urgente.',
        ),
        QuickEmergencyMessage(
          title: 'Estoy a salvo',
          text: 'Estoy a salvo por ahora. Me comunicaré cuando pueda.',
        ),
      ],
      additionalNote: 'Mensaje enviado desde la aplicación Emergencias.',
      countryCode: countryCode.toUpperCase(),
    );
  }
}

class EmergencyDirectory {
  static Map<String, List<EmergencyNumber>> directory = <String, List<EmergencyNumber>>{
    'CO': const <EmergencyNumber>[
      EmergencyNumber(
        label: 'Emergencias generales',
        number: '123',
        description: 'Número único de emergencias en Colombia.',
      ),
      EmergencyNumber(
        label: 'Policía',
        number: '112',
        description: 'Apoyo policial inmediato donde esta línea local aplica.',
      ),
      EmergencyNumber(
        label: 'Bomberos',
        number: '119',
        description: 'Incendios, humo, explosiones o rescate.',
      ),
      EmergencyNumber(
        label: 'Ambulancia',
        number: '125',
        description: 'Urgencias médicas donde esta línea local aplica.',
      ),
      EmergencyNumber(
        label: 'Cruz Roja',
        number: '132',
        description: 'Apoyo humanitario y primeros auxilios.',
      ),
    ],
    'US': const <EmergencyNumber>[
      EmergencyNumber(
        label: 'Emergencias generales',
        number: '911',
        description: 'Policía, bomberos y ambulancia en peligro inmediato.',
      ),
      EmergencyNumber(
        label: 'Crisis emocional',
        number: '988',
        description: 'Línea de crisis y prevención del suicidio.',
      ),
    ],
    'ES': const <EmergencyNumber>[
      EmergencyNumber(
        label: 'Emergencias generales',
        number: '112',
        description: 'Número único de urgencias en España.',
      ),
    ],
  };

  static List<EmergencyNumber> numbersFor(String countryCode) {
    return directory[countryCode.toUpperCase()] ??
        const <EmergencyNumber>[
          EmergencyNumber(
            label: 'Número local',
            number: 'Consulta localmente',
            description: 'Verifica el número oficial del país antes de una emergencia.',
          ),
        ];
  }
}
