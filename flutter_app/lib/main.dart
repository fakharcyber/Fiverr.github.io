import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const FakharFiverrApp());

class FakharFiverrApp extends StatelessWidget {
  const FakharFiverrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fakhar Fiverr AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class ChatItem {
  final bool isUser;
  final String text;
  ChatItem({required this.isUser, required this.text});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String apiBaseUrl = 'http://127.0.0.1:8000';

  int selectedTab = 0;
  final chatController = TextEditingController();
  final clientController = TextEditingController();
  final extraController = TextEditingController();

  final List<ChatItem> chat = [
    ChatItem(isUser: false, text: 'Assalam-o-Alaikum! 👋 Main Fakhar hoon. Tum mujhse baat kar sakte ho. Fiverr client ka message samajhna ho ya reply banana ho, main help karunga.'),
  ];
  String replyType = 'general';
  String generatedReply = '';
  bool chatLoading = false;
  bool replyLoading = false;

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['detail'] ?? 'Server error');
    }
    return data;
  }

  Future<void> sendChat() async {
    final text = chatController.text.trim();
    if (text.isEmpty || chatLoading) return;

    setState(() {
      chat.add(ChatItem(isUser: true, text: text));
      chatController.clear();
      chatLoading = true;
    });

    try {
      final history = chat
          .skip(1)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();
      final data = await post('/chat', {
        'message': text,
        'history': history,
      });
      if (!mounted) return;
      setState(() {
        chat.add(ChatItem(isUser: false, text: (data['reply'] ?? '').toString()));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => chat.add(ChatItem(isUser: false, text: 'Error: $e')));
    } finally {
      if (mounted) setState(() => chatLoading = false);
    }
  }

  Future<void> generateReply() async {
    final message = clientController.text.trim();
    if (message.isEmpty || replyLoading) {
      if (message.isEmpty) setState(() => generatedReply = 'Pehle client ka message paste karo.');
      return;
    }
    setState(() {
      replyLoading = true;
      generatedReply = 'Generating...';
    });
    try {
      final data = await post('/generate-reply', {
        'client_message': message,
        'reply_type': replyType,
        'extra_context': extraController.text.trim(),
      });
      if (!mounted) return;
      setState(() => generatedReply = (data['reply'] ?? '').toString());
    } catch (e) {
      if (!mounted) return;
      setState(() => generatedReply = 'Error: $e');
    } finally {
      if (mounted) setState(() => replyLoading = false);
    }
  }

  Future<void> copyText(String value) async {
    if (value.trim().isEmpty || value == 'Generating...') return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
  }

  @override
  void dispose() {
    chatController.dispose();
    clientController.dispose();
    extraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🤖', style: TextStyle(fontSize: 27)),
            SizedBox(width: 8),
            Text('Fakhar Fiverr AI'),
          ],
        ),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedTab,
            onDestinationSelected: (i) => setState(() => selectedTab = i),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.smart_toy), label: Text('Chat')),
              NavigationRailDestination(icon: Icon(Icons.work_outline), label: Text('Fiverr')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: selectedTab == 0 ? buildChat() : buildFiverr()),
        ],
      ),
    );
  }

  Widget buildChat() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          child: const Text(
            'Fakhar se Urdu, Roman Urdu ya English mein baat karo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: chat.length,
            itemBuilder: (context, index) {
              final item = chat[index];
              return Align(
                alignment: item.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 680),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: item.isUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SelectableText(item.text),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: chatController,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => sendChat(),
                    decoration: const InputDecoration(
                      hintText: 'Urdu, Roman Urdu ya English mein likho...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: chatLoading ? null : sendChat,
                  child: chatLoading ? const CircularProgressIndicator() : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildFiverr() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Fiverr Reply Assistant',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Flutter • Dart • Supabase • API • HTML/CSS/JS • Microsoft Documentation'),
              const SizedBox(height: 18),
              TextField(
                controller: clientController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Client message',
                  hintText: 'Fiverr client ka message yahan paste karo...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: replyType,
                decoration: const InputDecoration(labelText: 'Reply type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'new_client', child: Text('New Client')),
                  DropdownMenuItem(value: 'price', child: Text('Price')),
                  DropdownMenuItem(value: 'requirements', child: Text('Requirements')),
                  DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
                  DropdownMenuItem(value: 'follow_up', child: Text('Follow-up')),
                  DropdownMenuItem(value: 'technical', child: Text('Technical')),
                ],
                onChanged: (v) => setState(() => replyType = v ?? 'general'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: extraController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Extra context (optional)',
                  hintText: 'Example: Ask for Figma and API requirements.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: replyLoading ? null : generateReply,
                icon: const Icon(Icons.auto_awesome),
                label: Text(replyLoading ? 'Generating...' : 'Generate Reply'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('AI Reply', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  OutlinedButton.icon(
                    onPressed: () => copyText(generatedReply),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  generatedReply.isEmpty ? 'Reply yahan show hogi.' : generatedReply,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
