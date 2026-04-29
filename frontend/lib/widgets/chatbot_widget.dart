import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class NoticesChatbot extends StatefulWidget {
  const NoticesChatbot({super.key});

  @override
  State<NoticesChatbot> createState() => _NoticesChatbotState();
}

class _NoticesChatbotState extends State<NoticesChatbot>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  bool _isLoading = false;
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  final List<String> _suggestions = [
    '📋 List all notices',
    '📅 Any upcoming deadlines?',
    '🏆 Any hackathons or competitions?',
    '💼 Any placement drives?',
    '🎓 Any scholarship notices?',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _messages.add(ChatMessage(
      text:
          "👋 Hi! I'm your **Notice Assistant**.\n\nI can answer questions about your notices — deadlines, event details, placements, scholarships, and more. Just ask me anything!",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final query = text.trim();
    _inputController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: query,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    final result = await ApiService.askChatbot(query);

    setState(() {
      _isLoading = false;
      if (result['success']) {
        final answer = result['data']['answer'] as String? ??
            'Sorry, I could not find an answer.';
        _messages.add(ChatMessage(
          text: answer,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      } else {
        _messages.add(ChatMessage(
          text:
              '⚠️ Sorry, I encountered an error: ${result['message']}. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_isOpen)
          FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              alignment: Alignment.bottomRight,
              child: _buildChatPanel(),
            ),
          ),
        _buildFAB(),
      ],
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: _toggleChat,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isOpen ? Icons.close_rounded : Icons.smart_toy_rounded,
            key: ValueKey(_isOpen),
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanel() {
    return Container(
      width: 420,
      height: 560,
      margin: const EdgeInsets.only(bottom: 70),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessagesList()),
            if (_messages.length <= 1) _buildSuggestions(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notice Assistant',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF69F0AE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Powered by Gemini AI',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(
                () => _messages.removeRange(1, _messages.length)),
            child: Tooltip(
              message: 'Clear chat',
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.refresh_rounded,
                    color: Colors.white70, size: 20),
              ),
            ),
          ),
          GestureDetector(
            onTap: _toggleChat,
            child: Container(
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white70, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  size: 17, color: Color(0xFF1565C0)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF1565C0)
                    : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildRichText(msg.text, isUser),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 17, color: Color(0xFF1565C0)),
            ),
          ],
        ],
      ),
    );
  }

  /// Parses markdown-ish text: **bold**, bullet lines starting with • or *, newlines
  Widget _buildRichText(String text, bool isUser) {
    final Color baseColor =
        isUser ? Colors.white : const Color(0xFF1A1A2E);
    final Color boldColor =
        isUser ? Colors.white : const Color(0xFF0D47A1);

    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Detect bullet lines
      final isBullet = line.trimLeft().startsWith('•') ||
          line.trimLeft().startsWith('- ') ||
          line.trimLeft().startsWith('* ');

      if (isBullet) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: boldColor,
                        fontWeight: FontWeight.w700)),
                Expanded(
                  child: _inlineRichText(
                    line.replaceFirst(RegExp(r'^[\s•\-\*]+'), '').trim(),
                    baseColor: baseColor,
                    boldColor: boldColor,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _inlineRichText(line,
                baseColor: baseColor, boldColor: boldColor),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  RichText _inlineRichText(String text,
      {required Color baseColor, required Color boldColor}) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    final baseStyle = GoogleFonts.poppins(
      fontSize: 13,
      color: baseColor,
      height: 1.5,
    );
    final boldStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: boldColor,
    );

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
            text: text.substring(lastEnd, match.start), style: baseStyle));
      }
      spans.add(TextSpan(text: match.group(1), style: boldStyle));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                size: 17, color: Color(0xFF1565C0)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bouncingDot(0),
                const SizedBox(width: 5),
                _bouncingDot(200),
                const SizedBox(width: 5),
                _bouncingDot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bouncingDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMs),
      curve: Curves.easeInOut,
      builder: (_, val, __) => Opacity(
        opacity: val,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF1565C0),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: const Color(0xFFFAFAFF),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _suggestions.map((s) {
          return GestureDetector(
            onTap: () => _sendMessage(s),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1565C0).withOpacity(0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                s,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: const Color(0xFF1565C0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEF5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE0E4EF)),
              ),
              child: TextField(
                controller: _inputController,
                style: GoogleFonts.poppins(fontSize: 13),
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  hintText: 'Ask about notices, deadlines...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_inputController.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
