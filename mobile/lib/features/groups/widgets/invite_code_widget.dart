import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class InviteCodeWidget extends StatelessWidget {
  final String inviteCode;
  final String groupName;

  const InviteCodeWidget({
    super.key,
    required this.inviteCode,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CÓDIGO DE INVITACIÓN (MÁX 5 PRO)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                inviteCode,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  fontFamily: 'monospace',
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20),
                tooltip: 'Copiar código',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado al portapapeles')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 20),
                tooltip: 'Compartir enlace con amigos',
                onPressed: () {
                  Share.share(
                    '¡Únete a mi grupo de viaje "$groupName" en Waylo! Usa el código: $inviteCode o descarga la app en https://waylo.app/join/$inviteCode',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
