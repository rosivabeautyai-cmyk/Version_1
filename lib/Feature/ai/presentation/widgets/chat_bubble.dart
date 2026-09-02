import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/core/functions/navigations.dart';

import '../../../favorites/provider/favorites_provider.dart';
import '../../../products/presentation/screens/product_details_screen.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../../data/models/chat_message_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.isUser;

    final bubbleColor = message.isError
        ? colorScheme.error.withValues(alpha: 0.08)
        : isUser
        ? colorScheme.primary
        : theme.cardColor;

    final textColor = message.isError
        ? colorScheme.error
        : isUser
        ? Colors.white
        : theme.textTheme.bodyMedium?.color;

    final products = message.products;

    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            constraints: BoxConstraints(maxWidth: 0.78.sw),
            decoration: BoxDecoration(
              color: bubbleColor,
              // Directional (start/end) rather than physical
              // (left/right) so the bubble's "tail" corner mirrors
              // correctly in Arabic RTL instead of staying pinned to
              // a physical side.
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(18.r),
                topEnd: Radius.circular(18.r),
                bottomStart: Radius.circular(isUser ? 18.r : 4.r),
                bottomEnd: Radius.circular(isUser ? 4.r : 18.r),
              ),
              border: isUser || message.isError
                  ? null
                  : Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.12),
                    ),
            ),
            child: Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          ),
          if (products != null && products.isNotEmpty)
            SizedBox(
              height: 230.h,
              width: 0.9.sw,
              child: Builder(
                builder: (context) {
                  final favorites = context.watch<FavoritesProvider?>();
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    separatorBuilder: (_, _) => SizedBox(width: 12.w),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        width: 150,
                        isFavorite: favorites?.isFavorite(product.id) ?? false,
                        onFavoriteTap: favorites == null
                            ? null
                            : () => favorites.toggle(product.id),
                        onTap: () => pushTo(
                          context,
                          ProductDetailsScreen(productId: product.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Small "ROSIVA is typing…" indicator shown while a reply is pending:
/// three dots that rise and fade in sequence — the calm, familiar
/// "assistant is thinking" cue. Direction-agnostic so it sits on the
/// start edge in both LTR and RTL.
class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key});

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final dotColor = theme.colorScheme.primary;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(18.r),
            topEnd: Radius.circular(18.r),
            bottomEnd: Radius.circular(18.r),
            bottomStart: Radius.circular(4.r),
          ),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: SizedBox(
          height: 8.w,
          child: reduceMotion
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) SizedBox(width: 5.w),
                      _Dot(color: dotColor, opacity: 0.6, offsetY: 0),
                    ],
                  ],
                )
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) SizedBox(width: 5.w),
                          _dot(i, dotColor),
                        ],
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _dot(int index, Color color) {
    // Each dot runs the same 0→1 curve, staggered by a third of the
    // cycle, mapped to a small rise + fade.
    final phase = (_controller.value - index * 0.18) % 1.0;
    final t = Curves.easeInOut.transform(
      phase < 0.5 ? phase * 2 : (1 - phase) * 2,
    );
    return _Dot(color: color, opacity: 0.35 + 0.65 * t, offsetY: -3.0 * t);
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double opacity;
  final double offsetY;

  const _Dot({
    required this.color,
    required this.opacity,
    required this.offsetY,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Container(
        width: 8.w,
        height: 8.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity.clamp(0.0, 1.0)),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
