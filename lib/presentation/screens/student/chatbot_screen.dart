import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// A data class for chat messages
class Message {
  final String text;
  final bool isUser;
  Message(this.text, this.isUser);
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _systemPrompt = 'You are a helpful English learning assistant for the Engademy app. Be friendly and concise.'; // Default prompt
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.env['GEMINI_API_KEY'];
    if (_apiKey == null || _apiKey!.isEmpty || _apiKey == 'PASTE_YOUR_GEMINI_API_KEY_HERE') {
      print('GEMINI_API_KEY not found or not configured');
      _messages.add(Message("AI feature not configured. Please contact support.", false));
      return;
    }
    _loadSystemPromptAndStart();
  }

  Future<void> _loadSystemPromptAndStart() async {
    final promptDoc = await FirebaseFirestore.instance.collection('config').doc('chatbot_prompt').get();
    if (promptDoc.exists && promptDoc.data() != null) {
      _systemPrompt = promptDoc.data()!['systemPrompt'] ?? _systemPrompt;
    }
    _messages.add(Message("Hello! How can I help you with your English learning today? Ask me anything based on the app's lessons!", false));
    setState(() {});
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;
    final userMessage = _textController.text;
    setState(() {
      _messages.add(Message(userMessage, true));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final relevantContent = await _findRelevantLessons(userMessage);
      final finalPrompt = '''
      SYSTEM PROMPT: $_systemPrompt

      USER QUESTION: "$userMessage"

      RELEVANT CONTEXT FROM APP DATABASE:
      ---
      $relevantContent
      ---

      Based *only* on the system prompt and the provided context, answer the user's question. If the context is not relevant, say you cannot answer.
      ''';

      // Switched to a different model to avoid temporary overload
      final model = 'gemini-2.5-flash';
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey');

      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        'contents': [{
          'parts': [{'text': finalPrompt}]
        }]
      });

      // Make the HTTP POST request
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
            final aiResponse = data['candidates'][0]['content']['parts'][0]['text'] ?? 'Sorry, I couldn\'t process that.';
            setState(() {
              _messages.add(Message(aiResponse, false));
            });
        } else {
          final blockReason = data?['promptFeedback']?['blockReason']?.toString() ?? 'No content';
          setState(() {
             _messages.add(Message("Response blocked. Reason: $blockReason", false));
          });
        }
      } else {
        throw Exception('Failed to generate content: ${response.body}');
      }

    } catch (e) {
      setState(() {
        _messages.add(Message("Error: ${e.toString()}", false));
      });
    } finally {
      setState(() { _isLoading = false; });
      _scrollToBottom();
    }
  }
  
  Future<String> _findRelevantLessons(String query) async {
    final queryWords = query.toLowerCase().split(' ').where((w) => w.length > 2).toSet();
    final lessonsSnapshot = await FirebaseFirestore.instance.collectionGroup('lessons').limit(20).get();
    
    List<Map<String, dynamic>> relevantDocs = [];
    for (var doc in lessonsSnapshot.docs) {
      final data = doc.data();
      final title = (data['title'] as String? ?? '').toLowerCase();
      final content = (data['content'] as String? ?? '').toLowerCase();
      
      if (queryWords.any((word) => title.contains(word) || content.contains(word))) {
        relevantDocs.add({'title': data['title'], 'content': data['content']});
      }
    }

    if (relevantDocs.isEmpty) return "No relevant lessons found in the database.";

    return relevantDocs.map((d) => "Lesson: ${d['title']}\nContent: ${d['content']}").join('\n---\n');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: const Text('Engademy AI Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(text: message.text, isUserMessage: message.isUser);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: _isLoading ? null : (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.send_rounded, size: 30),
                  onPressed: _isLoading ? null : _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
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

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;

  const MessageBubble({super.key, required this.text, required this.isUserMessage});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.blue.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(1, 1))],
        ),
        child: SelectableText(
          text,
          style: TextStyle(color: isUserMessage ? Colors.white : Colors.black87, fontSize: 16),
        ),
      ),
    );
  }
}
