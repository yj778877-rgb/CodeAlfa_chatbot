import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String _fallbackFaqAnswer = '''Sorry, I couldn't find an answer to that question. 😔

Please ask something related to our café.

☕ Coffee Menu
• Espresso
• Americano
• Cappuccino
• Latte
• Mocha
• Flat White
• Macchiato
• Cold Coffee
• Iced Americano
• Iced Latte

🍕 Food Menu
• Pizza
• Burgers
• Pasta
• Sandwiches
• Fries
• Desserts
• Beverages

📍 You can also ask about:
• Menu
• Prices
• Offers
• Timings
• Location
• Reservations
• Home Delivery
• Takeaway
• Contact Number
• Parking
• Wi-Fi
• Payment Methods

I'm always happy to help! 😊''';

String _normalizeFaqTextForIsolate(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\u0000-\u007F\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _containsWholePatternForIsolate(String input, String pattern) {
  final words = pattern.split(' ').where((word) => word.isNotEmpty).toList();
  if (words.length < 2) {
    return false;
  }
  final escapedPattern = RegExp.escape(pattern);
  final phraseRegex = RegExp(r'(^|\s)' + escapedPattern + r'($|\s)');
  return phraseRegex.hasMatch(input);
}

String _findFaqAnswerIsolate(Map<String, dynamic> payload) {
  final query = payload['query'] as String;
  final faqData = payload['faqData'] as List<dynamic>;
  final normalizedInput = _normalizeFaqTextForIsolate(query);
  for (final faq in faqData) {
    final patterns = (faq['patterns'] as List<dynamic>).cast<String>();
    for (final normalizedPattern in patterns) {
      if (normalizedInput == normalizedPattern) {
        return faq['answer'] as String;
      }
      if (_containsWholePatternForIsolate(normalizedInput, normalizedPattern)) {
        return faq['answer'] as String;
      }
    }
  }
  return _fallbackFaqAnswer;
}

// ---------- COLOR PALETTE ----------
class AppColors {
  static const primaryCoffee = Color(0xFF4B2E1E);
  static const warmMocha = Color(0xFF6F4E37);
  static const latteBeige = Color(0xFFD9C3A5);
  static const backgroundCream = Color(0xFFF7EFE5);
  static const botBubble = Color(0xFFFFFFFF);
  static const userBubble = Color(0xFF4B2E1E);
  static const textPrimary = Color(0xFF2A1B14);
  static const textSecondary = Color(0xFF6B584C);
  static const timestampColor = Color(0xFF9A8575);
  static const onlineGreen = Color(0xFF6B8E23);
  static const inputFill = Color(0xFFFFFBF7);
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _sendPressed = false;
  bool _typingIndicatorActive = false;
  bool _isInputEnabled = false;
  int _typingDotIndex = 0;
  double _inputBarHeight = 54.0;
  String _welcomeTitleText = '';
  String _welcomeBodyText = '';
  String _welcomeTimestamp = '';
  Timer? _typingIndicatorTimer;
  Timer? _welcomeTypewriterTimer;
  late final List<Map<String, dynamic>> _normalizedFaqData;

  final List<Map<String, dynamic>> _faqData = [
  {
    'patterns': ['Do you have pizza?'],
    'answer': "We serve pizzas. Would you like to see our pizza menu? We have Margherita, Farmhouse, Pepperoni and Cheese Burst Pizzas. I'll also recommend having some coffee with it."
  },
  {
    'patterns': ['hello', 'hi', 'hey', 'good morning', 'good evening','hii'],
    'answer': 'Hello! Welcome to Cafe Solstice. How can I help you today?'
  },
  {
    'patterns': ['who are you', 'introduce yourself', 'what are you', 'tell me about yourself', 'your name'],
    'answer': "I'm the virtual assistant of Cafe Solstice. I'm here to help you with our menu, timings, reservations and more."
  },
  {
    'patterns': ['Ok tell me the price of margherita pizza, and suggest me a coffee also'],
    'answer': 'The Margherita Pizza is priced at ₹250. I would recommend pairing it with our Cappuccino for a delightful experience, which is priced at ₹150.'
  },
  {
    'patterns': ['Where are you located?'],
    'answer': 'Cafe Solstice is located at Plot No. 22, Sadar Bazar, Ramkrishna Colony, Powai Naka, Satara, Maharashtra 415001.'
  },
  {
    'patterns': ['Can I call to book a table?'],
    'answer': 'Yes! Feel free to call us on 9876543210.'
  },
  {
    'patterns': ['Do you have customer support?'],
    'answer': 'Our support team is available on 9876543210.'
  },
  {
    'patterns': ['Can I book a table via phone?'],
    'answer': 'Yes! You can reserve your table by calling 9876543210.'
  },
  {
    'patterns': ['Can I order by phone?'],
    'answer': 'Yes! You can place your order by calling 9876543210.'
  },
  {
    'patterns': ['Can I hangout with friends here?'],
    'answer': 'Of course! Large pizzas and combo meals are perfect for groups hanging out together.'
  },
  {
    'patterns': ['Do you have a washroom?'],
    'answer': 'Yes, clean washroom facilities are available for customers.'
  },
  {
    'patterns': ['Is there AC'],
    'answer': 'Yes! Our indoor seating is fully air-conditioned.'
  },
  {
    'patterns': ['what time do you open?'],
    'answer': 'We are open daily from 9:00 AM to 10:00 PM \n We look forward to serving you!'
  },
  {
    'patterns': ['Can you share the menu?'],
    'answer': "☕ Coffee Menu\n"
              "• Espresso\n"
              "• Americano\n"
              "• Cappuccino\n"
              "• Latte\n"
              "• Mocha\n"
              "• Flat White\n"
              "• Macchiato\n"
              "• Cold Coffee\n"
              "• Iced Americano\n"
              "• Iced Latte\n\n"
              "🍕 Food Menu\n" 
              "• Pizza\n"
              "• Burgers\n"
              "• Pasta\n"
              "• Sandwiches\n"
              "• Fries\n"
              "• Desserts\n"
              "• Beverages\n\n"
              "I'm always happy to help! 😊"
  },
];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
    _textController.addListener(_updateInputHeight);
    _updateInputHeight();
    _welcomeTimestamp = _formatTimestamp(DateTime.now());
    _startWelcomeTypewriter();
    _normalizedFaqData = _faqData.map((faq) {
      final patterns = (faq['patterns'] as List<dynamic>).cast<String>();
      final normalizedPatterns = patterns.map(_normalizeFaqText).toList();
      return {
        'patterns': normalizedPatterns,
        'answer': faq['answer'] as String,
      };
    }).toList();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _typingIndicatorTimer?.cancel();
    _focusNode.dispose();
    _scrollController.dispose();
    _textController.removeListener(_updateInputHeight);
    _textController.dispose();
    _welcomeTypewriterTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _normalizeFaqText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^ -\u007F\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }


  void _updateInputHeight() {
    if (!mounted) return;
    final lineCount = _textController.text.isEmpty
        ? 1
        : _textController.text.split('\n').length;
    final nextHeight = (54.0 + ((lineCount - 1) * 18.0)).clamp(54.0, 152.0);
    if ((_inputBarHeight - nextHeight).abs() > 0.01) {
      setState(() {
        _inputBarHeight = nextHeight;
      });
    }
  }

  void _showMessageMenu(BuildContext context, String messageText, LongPressStartDetails details) {
    final overlay = Overlay.of(context);
    final renderObject = overlay.context.findRenderObject();
    if (renderObject is! RenderBox) {
      return;
    }

    final position = RelativeRect.fromRect(
      Rect.fromLTWH(details.globalPosition.dx, details.globalPosition.dy, 1, 1),
      Offset.zero & renderObject.size,
    );

    final currentContext = context;
    showMenu<String>(
      context: currentContext,
      position: position,
      items: const [
        PopupMenuItem<String>(
          value: 'copy',
          child: Text('Copy'),
        ),
      ],
    );
  }

  void _showBotReply(String userMessage) async {
    setState(() {
      _typingIndicatorActive = true;
    });
    _startTypingBubbleAnimation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToBottom();
    });
    _welcomeTypewriterTimer?.cancel();
    String answer = "";
    final stopwatch = Stopwatch()..start();

    try {
      answer = await compute(_findFaqAnswerIsolate, {
        'faqData': _normalizedFaqData,
        'query': userMessage,
      });
    } catch (_) {
      answer = _fallbackFaqAnswer;
    }

    if (!mounted) return;

    const minimumTypingDuration = Duration(milliseconds: 1400);
    final elapsed = stopwatch.elapsed;
    if (elapsed < minimumTypingDuration) {
      await Future.delayed(minimumTypingDuration - elapsed);
    }

    if (!mounted) return;
    _stopTypingBubbleAnimation();
    setState(() {
      _typingIndicatorActive = false;
    });
    _addBotReply(answer);
  }

  void _startTypingBubbleAnimation() {
    _typingIndicatorTimer?.cancel();
    _typingDotIndex = 0;
    _typingIndicatorTimer = Timer.periodic(const Duration(milliseconds: 240), (_) {
      if (!mounted) return;
      setState(() {
        _typingDotIndex = (_typingDotIndex + 1) % 5;
      });
    });
  }

  void _stopTypingBubbleAnimation() {
    _typingIndicatorTimer?.cancel();
    _typingIndicatorTimer = null;
    _typingDotIndex = 0;
  }

  void _addBotReply(String answer) {
    final timestamp = _formatTimestamp(DateTime.now());
    setState(() {
      _messages.add(ChatMessage(text: answer, isUser: false, timestamp: timestamp));
    });
    _scrollToBottom();
  }

  void _startWelcomeTypewriter() {
    _welcomeTypewriterTimer?.cancel();
    setState(() {
      _isInputEnabled = false;
      _welcomeTitleText = '';
      _welcomeBodyText = '';
    });

    const typingDelay = Duration(milliseconds: 35);
    final fullTitle = 'Welcome to Cafe Solstice! 👋';
    final fullBody = "Hi! I'm your AI assistant. Ask me anything about our menu, timings, offers and more.";
    var titleIndex = 0;
    var bodyIndex = 0;
    var titleComplete = false;
    var bodyComplete = false;

    _welcomeTypewriterTimer = Timer.periodic(typingDelay, (timer) {
      if (!mounted) return;

      if (!titleComplete) {
        titleIndex += 1;
        if (titleIndex >= fullTitle.length) {
          titleComplete = true;
        }
        setState(() {
          _welcomeTitleText = fullTitle.substring(0, titleIndex);
        });
        return;
      }

      if (!bodyComplete) {
        bodyIndex += 1;
        if (bodyIndex >= fullBody.length) {
          bodyComplete = true;
        }
        setState(() {
          _welcomeBodyText = fullBody.substring(0, bodyIndex);
        });
        return;
      }

      timer.cancel();
      _welcomeTypewriterTimer = null;
      if (!mounted) return;
      setState(() {
        _isInputEnabled = true;
        _welcomeTitleText = fullTitle;
        _welcomeBodyText = fullBody;
      });
    });
  }

  String _formatTimestamp(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: _formatTimestamp(DateTime.now()),
      ));
      _textController.clear();
    });
    _scrollToBottom();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBotReply(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    const inputBarHeight = 74.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // ---------- BACKGROUND IMAGE ----------
            Positioned.fill(
              child: Image.asset(
                'assets/images/chat_background.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // Warm translucent overlay for readability over future bg image
            Positioned.fill(
              child: Container(
                color: AppColors.backgroundCream.withValues(alpha: 0.55),
              ),
            ),

            SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildChatArea(context, keyboardInset, inputBarHeight),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildFloatingAppBar(context),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: keyboardInset,
                    child: _buildInputArea(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- FLOATING APP BAR ----------
  Widget _buildFloatingAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryCoffee.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.latteBeige.withValues(alpha: 0.6),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCoffee.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 19,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage('assets/images/bot_avatar.jpg'),
              ),
            ),
            const SizedBox(width: 12),

            // Title + subtitle + status pill
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cafe Solstice',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Bezoria',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 0),
                  Text(
                    'FAQ Assistant',
                    style: const TextStyle(
                      fontFamily: 'Orvelia',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _buildOnlinePill(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlinePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.onlineGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.onlineGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Online',
            style: const TextStyle(
              fontFamily: 'Orvelia',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.onlineGreen,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- CHAT AREA ----------
  Widget _buildChatArea(BuildContext context, double bottomInset, double inputBarHeight) {
    final children = <Widget>[_buildBotWelcomeMessage(context)];
    for (final message in _messages) {
      children.add(_buildChatMessage(context, message));
    }
    if (_typingIndicatorActive) {
      children.add(_buildTypingIndicator());
    }

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, 100, 16, _inputBarHeight + 24 + bottomInset + 16),
      physics: const BouncingScrollPhysics(),
      children: children,
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.latteBeige.withValues(alpha: 0.7),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: const CircleAvatar(
        radius: 14,
        backgroundColor: Colors.transparent,
        backgroundImage: AssetImage('assets/images/bot_avatar.jpg'),
      ),
    );
  }

  Widget _buildBotWelcomeMessage(BuildContext context) {
    final messageText = '$_welcomeTitleText\n$_welcomeBodyText';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onLongPressStart: (details) {
          _showMessageMenu(context, messageText, details);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildBotAvatar(),
            Flexible(
              child: _buildBubble(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _welcomeTitleText,
                      style: const TextStyle(
                        fontFamily: 'Orvelia',
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _welcomeBodyText,
                      style: const TextStyle(
                        fontFamily: 'Orvelia',
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color.fromARGB(255, 0, 0, 0),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _welcomeTimestamp,
                      style: const TextStyle(
                        fontFamily: 'Orvelia',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessage(BuildContext context, ChatMessage message) {
    final alignment = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = message.isUser ? AppColors.primaryCoffee : AppColors.botBubble;
    final textColor = message.isUser ? const Color.fromARGB(255, 246, 244, 244) : AppColors.textPrimary;
    final borderRadius = message.isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(22),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          );

    final bubble = _buildBubble(
      backgroundColor: bubbleColor,
      borderRadius: borderRadius,
      child: Column(
        crossAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.text,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 14,
              color: textColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message.timestamp,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: message.isUser ? const Color.fromARGB(179, 244, 242, 242) : AppColors.timestampColor,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onLongPressStart: (details) {
          _showMessageMenu(context, message.text, details);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: message.isUser
              ? [Flexible(child: bubble)]
              : [_buildBotAvatar(), Flexible(child: bubble)],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    const dotPatterns = [
      [1.0, 0.0, 0.0],
      [1.0, 1.0, 0.0],
      [1.0, 1.0, 1.0],
      [0.0, 1.0, 1.0],
      [0.0, 0.0, 1.0],
    ];
    final currentPattern = dotPatterns[_typingDotIndex % dotPatterns.length];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: _typingIndicatorActive ? 1.0 : 0.0,
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                decoration: BoxDecoration(
                  color: AppColors.botBubble,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(22),
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCoffee.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Typing...',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        final opacity = currentPattern[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary.withValues(alpha: 0.35 + 0.65 * opacity),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble({
    required Widget child,
    required BorderRadius borderRadius,
    Color? backgroundColor,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(18, 16, 18, 12),
    BoxConstraints? constraints,
  }) {
    return Container(
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.botBubble,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCoffee.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  // ---------- INPUT AREA ----------
  Widget _buildInputArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Floating rounded text input
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCoffee.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: AppColors.latteBeige.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                enabled: _isInputEnabled,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                maxLines: 6,
                minLines: 1,
                onSubmitted: _isInputEnabled ? (_) => _sendMessage() : null,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'Type your question...',
                  hintStyle: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ).copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send button
          GestureDetector(
            onTapDown: _isInputEnabled
                ? (_) {
                    setState(() => _sendPressed = true);
                    HapticFeedback.lightImpact();
                  }
                : null,
            onTapUp: _isInputEnabled ? (_) => setState(() => _sendPressed = false) : null,
            onTapCancel: _isInputEnabled ? () => setState(() => _sendPressed = false) : null,
            onTap: _isInputEnabled ? _sendMessage : null,
            child: AnimatedScale(
              scale: _sendPressed ? 0.90 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primaryCoffee,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCoffee.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
