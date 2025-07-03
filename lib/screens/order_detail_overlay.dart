// order_detail_overlay.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailOverlay {
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> solicitud,
    required void Function() onClose,
  }) {
    return showGeneralDialog(
      context: context,
      barrierLabel: 'DetalleSolicitud',
      barrierDismissible: true,
      barrierColor: Colors.black54, // Fondo oscuro
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        // No importa; lo hace la transitionBuilder
        return const SizedBox.shrink();
      },
      transitionBuilder: (ctx, anim1, anim2, _) {
        final curved = Curves.easeOut.transform(anim1.value);
        return Opacity(
          opacity: curved,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8 * curved, sigmaY: 8 * curved),
            child: Center(
              child: _DetailCard(
                solicitud: solicitud,
                onClose: onClose,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Map<String, dynamic> solicitud;
  final VoidCallback onClose;
  const _DetailCard({
    Key? key,
    required this.solicitud,
    required this.onClose,
  }) : super(key: key);

  String _formatFecha(String iso) {
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF233550).withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Text(
              'Solicitud #${solicitud['id']}',
              style: const TextStyle(
                color: Color(0xFFee763d),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Campos
            _buildRow('Fecha:', _formatFecha(solicitud['fecha_creacion'])),
            const SizedBox(height: 12),
            _buildSubtitle('Descripción'),
            const SizedBox(height: 4),
            Text(
              solicitud['descripcion'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildRow('Estado:', solicitud['estado']),
            const SizedBox(height: 4),
            _buildRow('Prioridad:', solicitud['prioridad']),
            const SizedBox(height: 16),

            // Botón de cerrar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onClose();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFee763d),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(String text) {
    return Text(
      text,
      style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
    );
  }
}
