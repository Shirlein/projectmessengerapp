import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messengerapp/component/listtile.dart';
import 'package:messengerapp/main.dart';

class Mydrawer extends StatefulWidget {
  final void Function()? onProfileTap;
  final void Function()? onLogOut;
  final void Function()? onChat;
  final void Function()? onDarkLightMode;
  final void Function()? onDictionary;
  // final ChatUser user;

  const Mydrawer({
    super.key,
    required this.onProfileTap,
    required this.onLogOut,
    required this.onChat,
    required this.onDarkLightMode,
    required this.onDictionary,
    // required this.user,
  });

  @override
  _MydrawerState createState() => _MydrawerState();
}

bool isDarkMode = true;

class _MydrawerState extends State<Mydrawer> {
  StorageService storage = StorageService();
  final user = FirebaseAuth.instance.currentUser;

  String? imageUrl;

  @override
  void initState() {
    super.initState();
    getImageUrlFromFirebase();
  }

  Future<void> getImageUrlFromFirebase() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;
        Reference ref =
            FirebaseStorage.instance.ref().child('profile_pictures/$uid.jpg');
        String url = await ref.getDownloadURL();
        setState(() {
          imageUrl = url;
        });
      }
    } catch (e) {
      print("Error getting image URL: $e");
    }
  }

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    runApp(const MyApp());
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: isPortrait
          ? _buildPortraitDrawer()
          : SingleChildScrollView(
              child: _buildPortraitDrawer(),
            ),
    );
  }

  Widget _buildPortraitDrawer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            const SizedBox(height: 75),

            Center(
              // ignore: unnecessary_null_comparison
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(mq.height * 3),
                      child: Image.network(
                        imageUrl!,
                        width: mq.height * .17,
                        height: mq.height * .17,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),

            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;

                  // You can build your ListView based on the userData here
                  return Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child:
                        // Add your widgets based on userData
                        Text(
                      userData['username'],
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  // Add a default return statement, for example, an empty Container
                  return Container();
                }
              },
            ),

            const SizedBox(height: 30),
            const Divider(
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 20),

            // Chat Page
            MyListTile(
              icon: Icons.chat_bubble,
              text: 'C H A T',
              onTap: widget.onChat,
            ),

            // Profile
            MyListTile(
              icon: Icons.person,
              text: 'P R O F I L E',
              onTap: widget.onProfileTap,
            ),

            // Dictionary
            MyListTile(
              icon: Icons.menu_book_rounded,
              text: 'D I C T I O N A R Y',
              onTap: widget.onDictionary,
            ),
          ],
        ),

        //
        Column(
          children: [
            // dark & light mode

            Padding(
              padding: const EdgeInsets.only(bottom: 0.0),
              child: MyListTile(
                // Change the icon and text based on the current mode
                icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                text: isDarkMode ? 'D A R K   M O D E' : 'L I G H T   M O D E',
                onTap: () {
                  // Toggle the mode when clicked
                  setState(() {
                    isDarkMode = !isDarkMode;
                  });

                  // Call the provided callback for dark/light mode toggle
                  widget.onDarkLightMode?.call();
                },
              ),
            ),

            // Logout
            Padding(
              padding: const EdgeInsets.only(bottom: 25.0),
              child: MyListTile(
                icon: Icons.logout,
                text: 'L O G O U T',
                onTap: widget.onLogOut,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<Uint8List?> getProfilePic() async {
    // Get the current user's email
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final email =
          user.email; // Assuming email is used as the unique identifier

      try {
        return await storage.getFile("${email}_profile_pic.jpg");
      } catch (e) {
        print('Error getting profile picture: $e');
        return null;
      }
    }

    return null;
  }
}

class StorageService {
  StorageService() : ref = FirebaseStorage.instance.ref();
  final Reference ref;

  Future<void> uploadFile(String fileName, XFile file) async {
    try {
      final imageRef = ref.child(fileName);
      final imageBytes = await file.readAsBytes();
      await imageRef.putData(imageBytes);
    } catch (e) {
      print('Could not upload file. $e');
    }
  }

  Future<Uint8List?> getFile(String fileName) async {
    try {
      final imageRef = ref.child(fileName);
      return imageRef.getData();
    } catch (e) {
      print('Could not get file. $e');
    }
    return null;
  }
}
