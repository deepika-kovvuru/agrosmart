// ai_assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'app_theme.dart';
import 'offline_api_service.dart';
import 'translation_provider.dart';

class AIAssistantScreen extends StatefulWidget {
  final String? initialCrop;
  const AIAssistantScreen({super.key, this.initialCrop});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final List<_ChatMessage> _messages = [];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isTyping = false;
  String? _playingMessageId;

  @override
  void initState() {
    super.initState();
    // Add default greeting message
    _messages.add(_ChatMessage(
      id: 'greet',
      text: 'Hello! I am your Agrosmart AI Assistant. How can I help you with your crop health, fertilizer scheduling, irrigation, or pest protection today?'.tr,
      isSender: false,
    ));

    // If opened with an initial crop context, trigger auto question
    if (widget.initialCrop != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendPrompt('Tell me about the best irrigation and pest control for ${widget.initialCrop} crop.'.tr);
      });
    }
  }

  void _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    _inputCtrl.clear();
    _sendPrompt(text);
  }

  void _sendPrompt(String text) async {
    setState(() {
      _messages.add(_ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isSender: true,
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    // Query backend Ask AI API
    final result = await OfflineApiService.askAI(text);

    if (mounted) {
      setState(() {
        _isTyping = false;
        if (result['success'] == true) {
          _messages.add(_ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: result['response'],
            isSender: false,
          ));
        } else {
          _messages.add(_ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: 'I\'m sorry, I was unable to connect. Please check your internet connection and try again.'.tr,
            isSender: false,
          ));
        }
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _triggerVoiceInput() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _VoiceListeningDialog(
        onListeningComplete: (query) {
          Navigator.pop(context);
          setState(() {
            _inputCtrl.text = query;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  radius: 18,
                  child: const Icon(Icons.support_agent_rounded, color: AppTheme.primary, size: 20),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF69F0AE),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agrosmart AI'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'Online'.tr,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF69F0AE),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildChatBubble(message);
              },
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(_ChatMessage message) {
    final isMe = message.isSender;
    final isPlaying = _playingMessageId == message.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              radius: 16,
              child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF2D6A4F) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5,
                      color: isMe ? Colors.white : AppTheme.textPrimary,
                      height: 1.45,
                    ),
                  ),
                  if (!isMe && message.id != 'greet') ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isPlaying) {
                                _playingMessageId = null;
                              } else {
                                _playingMessageId = message.id;
                                // Automatically stop speaking after 4 seconds for simulation
                                Future.delayed(const Duration(seconds: 4), () {
                                  if (mounted && _playingMessageId == message.id) {
                                    setState(() {
                                      _playingMessageId = null;
                                    });
                                  }
                                });
                              }
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                                size: 16,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPlaying ? 'Speaking...'.tr : 'Listen'.tr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isPlaying) ...[
                          const SizedBox(width: 8),
                          _buildAudioWaveVisual(),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildAudioWaveVisual() {
    return SizedBox(
      height: 12,
      child: Row(
        children: List.generate(4, (index) {
          return Container(
            width: 2.5,
            height: (index % 2 == 0) ? 8.0 : 12.0,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(52, 0, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: List.generate(3, (index) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 0.8)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _triggerVoiceInput,
            child: CircleAvatar(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              radius: 20,
              child: const Icon(Icons.mic_rounded, color: AppTheme.primary, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _inputCtrl,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask your farming question...'.tr,
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Poppins'),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
                style: const TextStyle(fontSize: 13.5, fontFamily: 'Poppins'),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: CircleAvatar(
              backgroundColor: AppTheme.primary,
              radius: 19,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String id;
  final String text;
  final bool isSender;

  const _ChatMessage({
    required this.id,
    required this.text,
    required this.isSender,
  });
}

class _VoiceListeningDialog extends StatefulWidget {
  final Function(String) onListeningComplete;
  const _VoiceListeningDialog({required this.onListeningComplete});

  @override
  State<_VoiceListeningDialog> createState() => _VoiceListeningDialogState();
}

class _VoiceListeningDialogState extends State<_VoiceListeningDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _isAvailable = false;
  bool _notAvailable = false;
  String _transcript = '';
  String _statusText = 'Initializing microphone...';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            _stopAndReturn();
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _statusText = 'Error: ${error.errorMsg}. Try again.';
            _isListening = false;
          });
        },
      );

      if (_isAvailable && mounted) {
        _startListening();
      } else if (mounted) {
        setState(() {
          _notAvailable = true;
          _statusText = 'Microphone not available on this device.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notAvailable = true;
          _statusText = 'Could not access microphone. Grant permission and retry.';
        });
      }
    }
  }

  void _startListening() async {
    if (!_isAvailable) return;
    setState(() {
      _transcript = '';
      _isListening = true;
      _statusText = 'Listening... Speak now';
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _transcript = result.recognizedWords;
          if (result.finalResult && _transcript.isNotEmpty) {
            _statusText = 'Got it!';
          }
        });
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_IN',
      cancelOnError: false,
    );
  }

  void _stopAndReturn() {
    if (!mounted) return;
    _speech.stop();
    setState(() {
      _isListening = false;
      _statusText = _transcript.isNotEmpty ? 'Transcribed!' : 'No speech detected.';
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        final result = _transcript.isNotEmpty ? _transcript : '';
        widget.onListeningComplete(result);
      }
    });
  }

  void _stopManually() {
    _speech.stop();
    _stopAndReturn();
  }

  @override
  void dispose() {
    _speech.stop();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32),
                Text(
                  'Agrosmart Voice Input',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _speech.stop();
                    widget.onListeningComplete('');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Animated pulsing mic
            AnimatedBuilder(
              animation: _animCtrl,
              builder: (context, child) {
                final pulse = _isListening ? _animCtrl.value * 10 : 0.0;
                return Container(
                  padding: EdgeInsets.all(14 + pulse),
                  decoration: BoxDecoration(
                    color: (_isListening ? AppTheme.primary : Colors.grey)
                        .withValues(alpha: 0.12 + _animCtrl.value * 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: GestureDetector(
                    onTap: _isListening ? _stopManually : _startListening,
                    child: CircleAvatar(
                      backgroundColor: _isListening ? AppTheme.primary : Colors.grey.shade400,
                      radius: 30,
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            // Status text
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isListening ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
            // Live transcript preview
            if (_transcript.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '"$_transcript"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Try saying: "Fertilizer for Paddy" or "Chilli pests"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (_isListening)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE63946),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: const Text('Stop & Send', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                  onPressed: _stopManually,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
