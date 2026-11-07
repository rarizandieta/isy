import 'package:flutter/material.dart';

/// Reacciones disponibles para una publicación.
enum ReactionType { like, love, want }

extension ReactionTypeX on ReactionType {
  String get label {
    switch (this) {
      case ReactionType.like:
        return 'Me gusta';
      case ReactionType.love:
        return 'Me encanta';
      case ReactionType.want:
        return 'Lo quiero';
    }
  }

  IconData get filledIcon {
    switch (this) {
      case ReactionType.like:
        return Icons.thumb_up;
      case ReactionType.love:
        return Icons.favorite;
      case ReactionType.want:
        return Icons.shopping_cart;
    }
  }

  IconData get outlinedIcon {
    switch (this) {
      case ReactionType.like:
        return Icons.thumb_up_outlined;
      case ReactionType.love:
        return Icons.favorite_outline;
      case ReactionType.want:
        return Icons.shopping_cart_outlined;
    }
  }
}
