import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:messengerapp/account/signin.dart';
import 'package:messengerapp/account/signup.dart';
import 'package:messengerapp/component/themeprovide.dart';
import 'package:messengerapp/firebase_options.dart';
import 'package:messengerapp/homepage.dart';
import 'package:provider/provider.dart';

late Size mq;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: "basic_channel",
        channelName: "Basic Notification",
        channelDescription: "Test Notification Channel",
        channelGroupKey: "Basic Notification Channel",
      )
    ],
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: "Basic Notification Channel",
        channelGroupName: "Basic Group",
      ),
    ],
  );
  bool isAllowedToSendNotifications =
      await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowedToSendNotifications) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((value) {
    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SignIn(),
      routes: {
        '/homepage': (context) => const Homepage(
              title: Text(''),
            ),
        '/signin': (context) => const SignIn(),
        '/signup': (context) => const Signup(),
      },
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
