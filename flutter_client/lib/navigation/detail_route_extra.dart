import 'package:flutter/widgets.dart';

import '../models/media.dart';

class DetailRouteExtra {
  const DetailRouteExtra({required this.item, this.returnFocusNode});

  final MediaItem item;
  final FocusNode? returnFocusNode;
}
