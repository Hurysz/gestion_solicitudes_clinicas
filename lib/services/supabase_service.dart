import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://ofjjlenwhxsqdtwnjemw.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9mampsZW53aHhzcWR0d25qZW13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4OTYzODcsImV4cCI6MjA2NjQ3MjM4N30.o1r6JcNEyWoWxrq3HyaRfQR7EFJgBOOK3FzICicazPI',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Insertar solicitud
  static Future<void> enviarSolicitud({
    required String ruc,
    required String descripcion,
    required String prioridad,
  }) async {
    final response = await client.from('solicitudes').insert({
      'ruc_clinica': ruc,
      'descripcion': descripcion,
      'prioridad': prioridad,
      'estado': 'pendiente',
      'fecha_creacion': DateTime.now().toUtc(),
    });

    if (response.error != null) {
      throw Exception('Error al enviar solicitud: ${response.error!.message}');
    }
  }

  // Obtener solicitudes por RUC
  static Future<List<Map<String, dynamic>>> obtenerSolicitudesPorRuc(String ruc) async {
    final response = await client
        .from('solicitudes')
        .select()
        .eq('ruc_clinica', ruc)
        .order('fecha_creacion', ascending: false);

    if (response.error != null) {
      throw Exception('Error al obtener solicitudes: ${response.error!.message}');
    }

    return List<Map<String, dynamic>>.from(response.data);
  }

  // ✅ Escuchar cambios usando RealtimeChannel (versión flutter)
  static RealtimeChannel suscribirseSolicitudes(void Function(Map<String, dynamic>) onChange) {
    final channel = client.channel('public:solicitudes');

    channel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: '*', schema: 'public', table: 'solicitudes'),
      (payload, [ref]) {
        if (payload is Map<String, dynamic>) {
          onChange(payload);
        }
      },
    );

    channel.subscribe();
    return channel;
  }

  // Actualizar estado
  static Future<void> actualizarEstado({
    required int id,
    required String nuevoEstado,
  }) async {
    final response = await client
        .from('solicitudes')
        .update({'estado': nuevoEstado})
        .eq('id', id);

    if (response.error != null) {
      throw Exception('Error al actualizar estado: ${response.error!.message}');
    }
  }
}
