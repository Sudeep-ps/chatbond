import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple navigation state for home feature
final homeSelectedUserProvider = StateProvider<String?>((ref) => null);

// We can reuse chat providers for home feature as well
// This file is mainly for home-specific providers
