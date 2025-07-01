import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://ofjjlenwhxsqdtwnjemw.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9mampsZW53aHhzcWR0d25qZW13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4OTYzODcsImV4cCI6MjA2NjQ3MjM4N30.o1r6JcNEyWoWxrq3HyaRfQR7EFJgBOOK3FzICicazPI',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Insertar solicitud
  static Future<void> enviarSolicitud({
    required String ruc,
    required String descripcion,
    required String prioridad,
  }) async {
    try {
      await client.from('solicitudes').insert({
        'ruc_clinica': ruc,
        'descripcion': descripcion,
        'prioridad': prioridad,
        'estado': 'pendiente',
        'fecha_creacion': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al enviar solicitud: $e');
    }
  }

  /// Obtener solicitudes por RUC
  static Future<List<Map<String, dynamic>>> obtenerSolicitudesPorRuc(String ruc) async {
    try {
      final List response = await client
          .from('solicitudes')
          .select()
          .eq('ruc_clinica', ruc)
          .order('fecha_creacion', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener solicitudes: $e');
    }
  }

  /// Suscribirse a cambios
  static RealtimeChannel suscribirseSolicitudes(
      void Function(Map<String, dynamic>) onChange) {
    final channel = client.channel('public:solicitudes');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'solicitudes',
      callback: (payload) {
        onChange(payload.newRecord);
      },
    );

    channel.subscribe();
    return channel;
  }


  /// Actualizar estado
  static Future<void> actualizarEstado({
    required int id,
    required String nuevoEstado,
  }) async {
    try {
      await client
          .from('solicitudes')
          .update({'estado': nuevoEstado})
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }
}
