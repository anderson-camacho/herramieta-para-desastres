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
    return EmergencySettings.fromJson(
      jsonDecode(raw) as Map<String, Object?>,
    );
  }

  Future<void> save(EmergencySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  EmergencySettings _defaultSettings() {
    final countryCode = PlatformDispatcher.instance.locale.countryCode ?? 'CO';
    return EmergencySettings(
      contacts: const <EmergencyContact>[
        EmergencyContact(
          name: 'Familiar de confianza',
          phone: '123',
          email: '',
        ),
      ],
      quickMessages: const <QuickEmergencyMessage>[
        QuickEmergencyMessage(
          title: 'No puedo respirar',
          text: 'No puedo respirar bien. Necesito ayuda urgente.',
        ),
        QuickEmergencyMessage(
          title: 'No puedo ver nada',
          text: 'No puedo ver nada por humo, polvo u oscuridad. Necesito apoyo.',
        ),
        QuickEmergencyMessage(
          title: 'Estoy atrapado',
          text: 'Estoy atrapado y necesito rescate.',
        ),
        QuickEmergencyMessage(
          title: 'Estoy herido',
          text: 'Estoy herido y necesito asistencia medica.',
        ),
        QuickEmergencyMessage(
          title: 'Estoy a salvo',
          text: 'Sigo con vida y estoy a salvo por ahora.',
        ),
      ],
      additionalNote: 'Estoy usando Rescue Signal para pedir ayuda.',
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
        description: 'Numero unico de emergencias en Colombia. Atiende policia, salud y bomberos segun el caso.',
      ),
      EmergencyNumber(
        label: 'Policia',
        number: '112',
        description: 'Apoyo policial inmediato donde esta linea local aplica.',
      ),
      EmergencyNumber(
        label: 'Bomberos',
        number: '119',
        description: 'Incendios, humo, explosiones o rescate.',
      ),
      EmergencyNumber(
        label: 'Ambulancia',
        number: '125',
        description: 'Orientado a urgencias medicas donde esta linea local aplica.',
      ),
      EmergencyNumber(
        label: 'Cruz Roja',
        number: '132',
        description: 'Apoyo humanitario y primeros auxilios donde esta linea local aplica.',
      ),
    ],
    'US': const <EmergencyNumber>[
      EmergencyNumber(
        label: 'Emergencias generales',
        number: '911',
        description: 'Policia, bomberos y ambulancia en peligro inmediato.',
      ),
      EmergencyNumber(
        label: 'Crisis emocional',
        number: '988',
        description: 'Linea de crisis y prevencion del suicidio.',
      ),
      EmergencyNumber(
        label: 'Apoyo social',
        number: '211',
        description: 'Orientacion a servicios sociales y refugio en muchas areas.',
      ),
    ],
    'ES': const <EmergencyNumber>[
      EmergencyNumber(
        label: 'Emergencias generales',
        number: '112',
        description: 'Numero unico de urgencias en todo el territorio nacional.',
      ),
    ],
  };

  static List<EmergencyNumber> numbersFor(String countryCode) {
    return directory[countryCode.toUpperCase()] ??
        const <EmergencyNumber>[
          EmergencyNumber(
            label: 'Numero local',
            number: 'Consulta localmente',
            description: 'No hay una guia integrada para este pais. Verifica el numero oficial local antes de depender de el.',
          ),
        ];
  }
}

