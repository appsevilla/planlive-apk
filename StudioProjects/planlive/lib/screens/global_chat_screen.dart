import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:planlive/widgets/background_scaffold.dart';

class GlobalChatScreen extends StatefulWidget {
  const GlobalChatScreen({super.key});

  @override
  State<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends State<GlobalChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _palabrasOfensivas = [
    'baboso', 'idiota', 'tarado', 'cabrón', 'imbécil', 'gilipollas',
    'bobo', 'mentiroso', 'huevón', 'pendejo', 'zopenco', 'pendeja',
    'burro', 'cretino', 'bastardo', 'mamón', 'maricón', 'tonto',
    'hijo de puta', 'malparido', 'marica', 'subnormal', 'zorra',
    'puta', 'puto', 'polla', 'verga', 'culo', 'coño', 'chingada',
    'jodido', 'joder', 'mierda', 'pedorro', 'caca', 'culo roto',
    'güey', 'chingón', 'pajero', 'pajear', 'maldito', 'estúpido',
    'retardado', 'mongol', 'culero', 'joto', 'pinche', 'chingar',
    'cabronazo', 'troll', 'estúpida', 'tonta', 'mariconazo',
    // Añade más si quieres
  ];

  bool _contienePalabraOfensiva(String texto) {
    final textoMinus = texto.toLowerCase();
    for (final palabra in _palabrasOfensivas) {
      if (textoMinus.contains(palabra)) return true;
    }
    return false;
  }

  Future<void> _sendMessage() async {
    final user = _auth.currentUser;
    final texto = _controller.text.trim();

    if (user == null || texto.isEmpty) return;

    if (_contienePalabraOfensiva(texto)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pueden enviar mensajes ofensivos.')),
      );
      return;
    }

    final displayName = user.displayName;
    if (displayName == null || displayName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor configura un nombre en tu perfil antes de chatear.')),
      );
      return;
    }

    await _firestore.collection('global_chat').add({
      'senderId': user.uid,
      'senderName': displayName,
      'message': texto,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  Future<void> _reportMessage(String messageId, String senderName, String messageText) async {
    final motivos = [
      'Mensaje ofensivo',
      'Spam',
      'Acoso',
      'Contenido inapropiado',
      'Otro',
    ];

    String? motivoSeleccionado;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reportar mensaje'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: motivos
                    .map(
                      (motivo) => RadioListTile<String>(
                    title: Text(motivo),
                    value: motivo,
                    groupValue: motivoSeleccionado,
                    onChanged: (value) => setState(() => motivoSeleccionado = value),
                  ),
                )
                    .toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: motivoSeleccionado == null
                  ? null
                  : () {
                Navigator.of(context).pop(motivoSeleccionado);
              },
              child: const Text('Enviar reporte'),
            ),
          ],
        );
      },
    ).then((motivo) async {
      if (motivo != null) {
        final user = _auth.currentUser;
        if (user == null) return;

        await _firestore.collection('reportes_chat').add({
          'messageId': messageId,
          'mensaje': messageText,
          'senderName': senderName,
          'reporterId': user.uid,
          'motivo': motivo,
          'timestamp': FieldValue.serverTimestamp(),
          'resuelto': false,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reporte enviado, gracias por ayudarnos.')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      appBar: AppBar(
        title: const Text('Chat Global'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('global_chat')
                    .orderBy('timestamp', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text('No hay mensajes aún', style: TextStyle(color: Colors.white70)));
                  }

                  return ListView.builder(
                    reverse: true,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data()! as Map<String, dynamic>;
                      final isMe = data['senderId'] == _auth.currentUser?.uid;

                      return GestureDetector(
                        onLongPress: () => _reportMessage(
                          doc.id,
                          data['senderName'] ?? 'Anon',
                          data['message'] ?? '',
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.deepPurpleAccent : Colors.grey[700],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['senderName'] ?? 'Anon',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['message'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF111328),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.deepPurpleAccent,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
