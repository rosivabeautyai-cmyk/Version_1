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
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            constraints: BoxConstraints(maxWidth: 0.78.sw),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.r),
                topRight: Radius.circular(18.r),
                bottomLeft: Radius.circular(isUser ? 18.r : 4.r),
                bottomRight: Radius.circular(isUser ? 4.r : 18.r),
              ),
              border: isUser || message.isError
                  ? null
                  : Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
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

/// Small "ROSIVA is typing..." indicator shown while a reply is
/// pending.
class TypingIndicatorBubble extends StatelessWidget {
  const TypingIndicatorBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
            bottomRight: Radius.circular(18.r),
            bottomLeft: Radius.circular(4.r),
          ),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: SizedBox(
          width: 16.w,
          height: 16.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
