import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/core/widgets/state_views.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../data/models/chat_message_model.dart';
import '../../provider/ai_chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/legal_expandable_card.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AiChatProvider(),
      child: const _AiView(),
    );
  }
}

class _AiView extends StatefulWidget {
  const _AiView();

  @override
  State<_AiView> createState() => _AiViewState();
}

class _AiViewState extends State<_AiView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send(AiChatProvider provider, AppLocalizations lang) {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    _inputController.clear();
    provider.sendMessage(
      text,
      errorFallback: lang.somethingWentWrongDesc,
      noResultsFallback: lang.aiNoProductsFound,
      recommendationsIntroFallback: lang.aiRecommendationsIntro,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final provider = context.watch<AiChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16.r,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 16.sp,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                lang.rosivaAiTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: provider.isConfigured
                  ? _buildChat(context, provider, lang)
                  : _buildNotConfigured(context, lang),
            ),
            _buildInputBar(context, provider, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildChat(
    BuildContext context,
    AiChatProvider provider,
    AppLocalizations lang,
  ) {
    final theme = Theme.of(context);
    final showWelcome = provider.messages.isEmpty;

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      children: [
        LegalExpandableCard(
          icon: Icons.verified_user_outlined,
          title: lang.aiAccuracyTitle,
          body: lang.aiAccuracyDesc,
        ),
        LegalExpandableCard(
          icon: Icons.health_and_safety_outlined,
          title: lang.medicalAdviceDisclaimerTitle,
          body: lang.medicalAdviceDisclaimerDesc,
          accentColor: theme.colorScheme.error,
        ),
        SizedBox(height: 8.h),
        if (showWelcome)
          ChatBubble(message: _welcomeMessage(lang))
        else
          ...provider.messages.map((m) => ChatBubble(message: m)),
        if (provider.isSending) const TypingIndicatorBubble(),
      ],
    );
  }

  ChatMessageModel _welcomeMessage(AppLocalizations lang) => ChatMessageModel(
        id: 'welcome',
        role: ChatRole.assistant,
        text: lang.aiWelcomeMessage,
        timestamp: DateTime.now(),
      );

  Widget _buildNotConfigured(BuildContext context, AppLocalizations lang) {
    return AppEmptyView(
      icon: Icons.auto_awesome_rounded,
      title: lang.rosivaAiTitle,
      description: lang.aiNotConfigured,
    );
  }

  Widget _buildInputBar(
    BuildContext context,
    AiChatProvider provider,
    AppLocalizations lang,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: provider.isConfigured && !provider.isSending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(provider, lang),
              decoration: InputDecoration(
                hintText: lang.aiInputHint,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Material(
            color: theme.colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: provider.isConfigured && !provider.isSending
                  ? () => _send(provider, lang)
                  : null,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
