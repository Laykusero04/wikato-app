import 'package:flutter/widgets.dart';

import 'app.dart';
import 'data/content_repository.dart';
import 'data/dialects.dart';
import 'data/notification_service.dart';
import 'data/progress_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressStore.init();
  await ContentRepository.preload(
    ProgressStore.languageCode.value ?? defaultDialectCode,
  );
  await NotificationService.init();
  // Refresh the scheduled message with the current streak count whenever
  // the app launches.
  if (ProgressStore.reminderEnabled.value) {
    await NotificationService.scheduleDaily(ProgressStore.reminderHour.value);
  }
  runApp(const WikatoApp());
}
