import 'package:flutter/material.dart';
import 'package:d2l_plus/constants/colors.dart';
import 'package:d2l_plus/tools/backender.dart';
import 'package:d2l_plus/tools/storage.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({Key? key}) : super(key: key);

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final _backender = Backender();
  final _storage = SecureStorage();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();

    // Добавляем приветственное сообщение от ассистента
    _messages.add(
      ChatMessage(
        text:
            'Hi, I am D2L Plus assistant. How can I help you? You can ask me about your courses, assignments, deadlines or other information.',
        sender: MessageSender.assistant,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    try {
      final userId = await _storage.getUserId();
      if (userId != null && userId.isNotEmpty) {
        setState(() {
          _userId = userId;
        });
      }
    } catch (e) {
      debugPrint('Error loading user ID: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          sender: MessageSender.user,
        ),
      );
      _isLoading = true;
      _textController.clear();
    });

    // Прокручиваем список к последнему сообщению
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      if (_userId == null) {
        throw Exception('User ID not found');
      }

      // Отправляем запрос к API ассистента
      final response = await _backender.sendAssistantMessage(
        userId: _userId!,
        prompt: text,
      );

      // Обрабатываем ответ
      setState(() {
        _messages.add(
          ChatMessage(
            text: response['message'] ?? 'Sorry, I couldn\'t get the answer.',
            sender: MessageSender.assistant,
          ),
        );
        _isLoading = false;
      });

      // Прокручиваем список к последнему сообщению
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'An error occurred while sending the message: ${e.toString()}',
            sender: MessageSender.assistant,
            isError: true,
          ),
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('D2L Plus Assistant'),
        backgroundColor: UAColors.blue,
      ),
      body: Column(
        children: [
          // Область сообщений
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text('No messages'),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageItem(_messages[index]);
                    },
                  ),
          ),

          // Индикатор загрузки (если ожидается ответ)
          if (_isLoading)
            const LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(UAColors.blue),
              backgroundColor: Colors.transparent,
            ),

          // Поле ввода сообщения
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                      filled: true,
                      fillColor: UAColors.coolGray.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  backgroundColor: UAColors.red,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: UAColors.blue,
              radius: 16,
              child: const Icon(
                Icons.assistant,
                color: Colors.white,
                size: 18,
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? UAColors.red
                    : message.isError
                        ? Colors.red.shade100
                        : UAColors.coolGray.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : message.isError
                          ? Colors.red.shade800
                          : Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser)
            CircleAvatar(
              backgroundColor: UAColors.red.withOpacity(0.8),
              radius: 16,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

/// Перечисление для отправителей сообщений
enum MessageSender {
  user,
  assistant,
}

/// Класс, представляющий сообщение в чате
class ChatMessage {
  final String text;
  final MessageSender sender;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.sender,
    this.isError = false,
  });
}
