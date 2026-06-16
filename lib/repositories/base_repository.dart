import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_config.dart';

class BaseRepository {
  SupabaseClient get client => SupabaseConfig.client;

  @protected
  PostgrestQueryBuilder get table => client.from(_table);
  final String _table;

  BaseRepository(this._table);

  @protected
  String logPrefix() => '[$runtimeType]';

  @protected
  void log(String message) {
    debugPrint('${logPrefix()} $message');
  }
}
