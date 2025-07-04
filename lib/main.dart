import 'package:camera/camera.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frames/src/pages/camera_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frames/src/services/notification_service.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await dotenv.load(fileName: ".env");
  final notificationService = NotificationService(navigatorKey);
  await notificationService.initFCM();
  FirebaseMessaging.onBackgroundMessage(handleBackGroundMessage);
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      locale: const Locale('es', 'ES'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: CameraPage(cameras: cameras),
    );
  }
}

Future<void> handleBackGroundMessage(RemoteMessage message) async {
  // Aquí puedes manejar la notificación en segundo plano
  print(
    'Background message: ${message.notification?.title} - ${message.notification?.body}',
  );
  // Por ejemplo, podrías mostrar una notificación local o actualizar el estado de la aplicación
}
