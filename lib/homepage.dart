import 'dart:developer';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:messengerapp/account/profile.dart';
import 'package:messengerapp/account/signin.dart';
import 'package:messengerapp/apilists/apis.dart';
import 'package:messengerapp/component/dictionary.dart';
import 'package:messengerapp/component/drawer.dart';
import 'package:messengerapp/component/notification_controller.dart';
import 'package:messengerapp/component/scanqrcode.dart';
import 'package:messengerapp/component/themeprovide.dart';
import 'package:messengerapp/main.dart';
import 'package:messengerapp/models/chatusers.dart';
import 'package:messengerapp/widgets/chatusercard.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key, required this.title});
  final Text title;

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<ChatUser> list = [];
  final List<ChatUser> _searchList = [];
  bool _isSearching = false;

  // go to profile page
  void goToProfile() {
    Navigator.pop(context);

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Profile(user: APIs.me),
        ));
  }

  // go to Dictionary
  void _goDictionary() {
    Navigator.pop(context);

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const Dictionary(),
        ));
  }

  @override
  void initState() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod:
          NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod:
          NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod:
          NotificationController.onDismissActionReceivedMethod,
    );
    super.initState();
    APIs.getSelfInfo();

    // for update user active status
    // resume - active or online
    // pause - inactive or offline
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message: $message');

      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
      }

      return Future.value(message);
    });

    Future.delayed(const Duration(seconds: 2), () {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          systemNavigationBarColor: Colors.white));
    });
  }

  void goToChat() {
    Navigator.pop(context);
  }

  void _darklightMode() {
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return GestureDetector(
      // hide keyboard when a tap is detected on screen
      onTap: () => FocusScope.of(context).unfocus(),

      // ignore: deprecated_member_use
      child: WillPopScope(
        // Intercept the back button press and exit the app
        // if search is on & back button is press then close search
        onWillPop: () {
          if (_isSearching) {
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            actions: [
              // search user button
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                  });
                },
                icon: Icon(
                  _isSearching
                      ? CupertinoIcons.clear_circled_solid
                      : Icons.search,
                ),
              ),

              // search user button
              IconButton(
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScanQRCode(),
                        ));
                  });
                },
                icon: const Icon(
                  Icons.qr_code_scanner_rounded,
                ),
              ),
            ],
            elevation: 1,
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                  icon: const Icon(
                    Icons.list,
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  tooltip:
                      MaterialLocalizations.of(context).openAppDrawerTooltip,
                );
              },
            ),
            title: _isSearching
                ? TextField(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Name, Email, ...',
                    ),
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 17,
                      letterSpacing: 0.5,
                    ),
                    // when search text changes then updated search list
                    onChanged: (val) {
                      // search logic
                      _searchList.clear();

                      for (var i in list) {
                        if (i.username
                                .toLowerCase()
                                .contains(val.toLowerCase()) ||
                            i.email.toLowerCase().contains(val.toLowerCase())) {
                          _searchList.add(i);
                        }
                        setState(() {
                          _searchList;
                        });
                      }
                    },
                  )
                : Text(
                    'C H A T',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
            backgroundColor: Theme.of(context).colorScheme.background,
          ),
          body: StreamBuilder(
            stream: _isSearching
                ? _isSearching
                    ? APIs.getAllUsersSearch()
                    : APIs.getMyUsersId()
                : APIs.getMyUsersId(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                // if data is loading
                case ConnectionState.waiting:
                case ConnectionState.none:
                // return const Center(child: CircularProgressIndicator());

                // if some or all data is loaded then it shows it
                case ConnectionState.active:
                case ConnectionState.done:
                  if (snapshot.data?.docs.isEmpty ?? true) {
                    return const Center(
                      child: Text('No Friends? Scan!',
                          style: TextStyle(fontSize: 20)),
                    );
                  } else if (snapshot.data?.docs.isEmpty ?? false) {
                    return ListView.builder(
                      itemCount:
                          _isSearching ? _searchList.length : list.length,
                      padding: EdgeInsets.only(top: mq.height * .01),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return ChatUserCard(
                          user: _isSearching ? _searchList[index] : list[index],
                        );
                      },
                    );
                  }

                  return StreamBuilder(
                    stream: _isSearching
                        ? APIs.getAllUsersSearch()
                        : APIs.getAllUsers(
                            snapshot.data?.docs.map((e) => e.id).toList() ?? [],
                          ),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const Center(
                              child: CircularProgressIndicator());

                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          list = data
                                  ?.map((e) => ChatUser.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (list.isNotEmpty) {
                            return ListView.builder(
                              itemCount: _isSearching
                                  ? _searchList.length
                                  : list.length,
                              padding: EdgeInsets.only(top: mq.height * .01),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                return ChatUserCard(
                                  user: _isSearching
                                      ? _searchList[index]
                                      : list[index],
                                );
                              },
                            );
                          } else {
                            return const Center(
                              child: Text('No Connections Found!',
                                  style: TextStyle(fontSize: 20)),
                            );
                          }
                      }
                    },
                  );
              }
            },
          ),
          drawer: Mydrawer(
            onProfileTap: goToProfile,
            onLogOut: _logOut,
            onChat: goToChat,
            onDarkLightMode: _darklightMode,
            onDictionary: _goDictionary,
          ),
        ),
      ),
    );
  }

  Future<void> _logOut() async {
    // Show a confirmation dialog
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false); // User chose not to log out
            },
            child: Text(
              'No',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true); // User chose to log out
            },
            child: Text(
              'Yes',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    // If the user confirmed the logout or dismissed the dialog, then log out
    if (confirmLogout == true) {
      try {
        await _auth.signOut();

        // Clear login state
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('isLoggedIn', false);

        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => const SignIn(),
          ),
        );
      } catch (e) {
        // ... (existing code)
      }
    } else if (confirmLogout == null) {}
  }
}
