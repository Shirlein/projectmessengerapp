import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:messengerapp/account/profile.dart';
import 'package:messengerapp/account/signin.dart';
import 'package:messengerapp/apilists/apidictionary.dart';
import 'package:messengerapp/apilists/apis.dart';
import 'package:messengerapp/component/themeprovide.dart';
import 'package:messengerapp/homepage.dart';
import 'package:messengerapp/models/response_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'drawer.dart';

class Dictionary extends StatefulWidget {
  const Dictionary({super.key});

  @override
  State<Dictionary> createState() => _DictionaryState();
}

class _DictionaryState extends State<Dictionary> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSearching = false;
  List<Dictionary> list = [];
  final List<Dictionary> _searchList = [];
  bool inProgress = false;
  ResponseModel? responseModel;
  String noDataText = "Welcome, Start searching";

  //go to chat
  void goToChat() {
    Navigator.pop(context);

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Homepage(
            title: Text('Welcome'),
          ),
        ));
  }

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
  }

  // Log out
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
          context,
          MaterialPageRoute(
            builder: (context) => const SignIn(),
          ),
        );
      } catch (e) {}
    } else if (confirmLogout == null) {}
  }

  // dark & light mode
  void _darklightMode() {
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
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
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              );
            },
          ),
          title: _isSearching
              ? TextField(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search words...',
                  ),
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 17,
                    letterSpacing: 0.5,
                  ),
                  // when search text changes then updated search list
                  onSubmitted: (value) {
                    // search logic
                    _searchList.clear();

                    _getMeaningFromApi(value);
                  },
                )
              : Text(
                  'D I C T I O N A R Y',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
          backgroundColor: Theme.of(context).colorScheme.background,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        drawer: Mydrawer(
          onProfileTap: goToProfile,
          onLogOut: _logOut,
          onChat: goToChat,
          onDarkLightMode: _darklightMode,
          onDictionary: _goDictionary,
        ),
        body: Padding(
          padding: EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              if (inProgress)
                const LinearProgressIndicator()
              else if (responseModel != null)
                Expanded(child: _buildResponseWidget())
              else
                _noDataWidget()
            ],
          ),
        ),
      ),
    );
  }

  _buildResponseWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          responseModel!.word!,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        Text(
          responseModel!.phonetic ?? "",
        ),
        const SizedBox(
          height: 16,
        ),
        Expanded(
          child: ListView.builder(
            itemBuilder: (context, int index) {
              return _buildMeaningWidget(
                responseModel!.meanings![index],
              );
            },
            itemCount: responseModel!.meanings!.length,
          ),
        )
      ],
    );
  }

  _buildMeaningWidget(Meanings meanings) {
    String definitionsList = "";
    meanings.definitions?.forEach(
      (element) {
        int index = meanings.definitions!.indexOf(element);
        definitionsList += "\n${index + 1}. ${element.definition}\n";
      },
    );

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meanings.partOfSpeech!,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.orange.shade600
                    : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              "Definitions : ",
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black87
                    : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(definitionsList),
            _buildSet("Synonyms", meanings.synonyms),
            _buildSet("Antonyms", meanings.synonyms),
          ],
        ),
      ),
    );
  }

  _buildSet(String title, List<String>? setList) {
    if (setList?.isNotEmpty ?? false) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title : ",
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black87
                  : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(setList!
              .toSet()
              .toString()
              .replaceAll("{", "")
              .replaceAll("}", "")),
          const SizedBox(
            height: 10,
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  _noDataWidget() {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          noDataText,
          style: const TextStyle(
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  _getMeaningFromApi(String word) async {
    setState(() {
      inProgress = true;
    });
    try {
      responseModel = await APIDictionary.fetchMeaning(word);
      setState(() {});
    } catch (e) {
      responseModel = null;
    } finally {
      setState(() {
        inProgress = false;
      });
    }
  }
}
