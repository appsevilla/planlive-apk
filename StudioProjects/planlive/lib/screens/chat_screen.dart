import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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

  Future<void> _sendReport(String messageId, String senderName, String messageText, String motivo) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('reportes_chat').add({
      'messageId': messageId,
      'mensaje': messageText,
      'senderName': senderName,
      'reporterId': user.uid,
      'motivo': motivo.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'resuelto': false,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte enviado, gracias por ayudarnos.')),
    );
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

    final motivo = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reportar mensaje'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: motivos.map((motivo) {
                  return RadioListTile<String>(
                    title: Text(motivo),
                    value: motivo,
                    groupValue: motivoSeleccionado,
                    onChanged: (value) => setState(() => motivoSeleccionado = value),
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: motivoSeleccionado == null
                  ? null
                  : () => Navigator.of(context).pop(motivoSeleccionado),
              child: const Text('Enviar reporte'),
            ),
          ],
        );
      },
    );

    if (motivo != null) {
      await _sendReport(messageId, senderName, messageText, motivo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Global'),
        backgroundColor: Colors.deepPurple, // cabecera morada
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo_planlive.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          SafeArea(
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
                        return const Center(
                          child: Text('No hay mensajes aún', style: TextStyle(color: Colors.white70)),
                        );
                      }

                      return ListView.builder(
                        reverse: true,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data()! as Map<String, dynamic>;
                          final isMe = data['senderId'] == _auth.currentUser?.uid;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Container(
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
                                  if (!isMe)
                                    TextButton.icon(
                                      icon: const Icon(Icons.report, color: Colors.redAccent),
                                      label: const Text('Reportar', style: TextStyle(color: Colors.redAccent)),
                                      onPressed: () => _reportMessage(
                                        doc.id,
                                        data['senderName'] ?? 'Anon',
                                        data['message'] ?? '',
                                      ),
                                    ),
                                ],
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
        ],
      ),
    );
  }
}
