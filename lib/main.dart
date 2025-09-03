import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:temperature_upload/loading_provider.dart';
import 'package:temperature_upload/pages/main/pages/find_device/device_register.dart';
import 'package:temperature_upload/pages/main/pages/home/home_page.dart';
import 'package:temperature_upload/pages/main/pages/write_journal/write_journal.dart';
import 'package:temperature_upload/pages/main/providers/ble_provider.dart';
import 'package:temperature_upload/pages/login/login_page.dart';
import 'package:temperature_upload/splash_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LoadingProvider>(create: (_) => LoadingProvider(),),
        ChangeNotifierProvider<BLEProvider>(create: (_) => BLEProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<LoadingProvider>().isLoading;

    return MaterialApp(
      title: '온도계 정보',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/home/device-register': (_) => const DeviceRegister(),
        '/home/write-journal': (_) => const WriteJournal()
      },
      builder: (context, child) => Stack(
        children: [
          child!,
          if (isLoading)
            Container(
              color: Colors.black45,
              child: Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }
}
