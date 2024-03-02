import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';
import 'package:messengerapp/models/chatusers.dart';
import 'package:messengerapp/models/messages.dart';

class APIs {
  // Authetication
  static FirebaseAuth auth = FirebaseAuth.instance;

  // accessing firebase storage
  static FirebaseStorage storage = FirebaseStorage.instance;

  // for return current user
  static User get user => auth.currentUser!;

  // for storing self info
  static late ChatUser me;

// Accessing Cloud Firestore Database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // for accessing firebase messaging (Push Notif)
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  // getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log('Push Token: $t');
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
      }
    });
  }

  // send push notif
  static Future<void> sendPushNotification(
      ChatUser chatUser, String msg) async {
    try {
      final body = {
        "to": chatUser.pushToken,
        "notification": {
          "title:": chatUser.username,
          "body": msg,
          "android_channel_id": "chats",
        },
        "data": {
          "some_data": "User ID: ${me.id}",
        },
      };

      var res = await post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader:
              'key=AAAA5QflWkc:APA91bFaV2cTsXiPO-OGrYAiwqTt7PT64LEMq4ChfAdqkEjClYJY4WCeqn_9WsWaIXuM0VddpaAFDFuXUWFNNtv8v1cixstg1TTJZhH3_4xs6ostZbm3O5ZMZz1AceEtEUwgiTHBhlSr'
        },
        body: jsonEncode(body),
      );
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nsendPushNotificationE: $e');
    }
  }

  // for checking if user exists or not?
  static Future<bool> userExists() async {
    return (await firestore.collection('Users').doc(user.uid).get()).exists;
  }

  // add an chat user for our convo
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .get();

    log('data: ${data.docs}');

    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      // user exists
      log('user exists: ${data.docs.first.data()}');

      // Add the user to your list
      await firestore
          .collection('Users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});

      // Add yourself to the other user's list
      await firestore
          .collection('Users')
          .doc(data.docs.first.id)
          .collection('my_users')
          .doc(user.uid)
          .set({});

      return true; // Return true when the user is successfully added
    } else {
      // user not exists
      return false;
    }
  }

  // add an group chat

  // for getting user info
  static Future<void> getSelfInfo() async {
    return await firestore
        .collection('Users')
        .doc(user.uid)
        .get()
        .then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();

        // for setting user status to active
        APIs.updateActiveStatus(true);
        log('My Data: ${user.data()}');
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

// for creating a new user
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    // Retrieve user data from Firestore
    DocumentSnapshot userDataSnapshot =
        await firestore.collection('Users').doc(user.uid).get();

    // Check if user data exists
    // User data exists, use the existing values
    final existingData = userDataSnapshot.data() as Map<String, dynamic>;

    // If you want to update specific fields with new values, you can do it like this:
    // existingData['username'] = 'newUsername';
    // existingData['fullName'] = 'newFullName';

    // User data doesn't exist, create with default values
    final chatUser = ChatUser(
      id: user.uid,
      username: existingData['username'] ??=
          '', // Use existing value or default to empty string // Default value or handle as needed
      fullName: existingData['fullName'] ??=
          '', // Default value or handle as needed
      bio: "Empty Bio...",
      email: user.email.toString(),
      about: "Hey!",
      image: user.photoURL.toString(),
      createdAt: time,
      isOnline: false,
      lastActive: time,
      pushToken: '',
    );

    return await firestore
        .collection('Users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  // for creating a new user
  static Future<void> updateUserInfo() async {
    await firestore.collection('Users').doc(user.uid).update({
      'fullName': me.fullName,
      'email': me.email,
      'about': me.about,
      'bio': me.bio,
    });
  }

  // get id's of known users from firestore data
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore
        .collection('Users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  // get all users from firestore database that your selected
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> userIds) {
    log('\nUserIds: $userIds');
    return firestore
        .collection('Users')
        .where('id', whereIn: userIds)
        // .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  // get all users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsersSearch() {
    return firestore
        .collection('Users')
        .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  // add user to my user when first message is send
  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, Type type) async {
    await firestore
        .collection('Users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({}).then((value) {
      sendMessage(chatUser, msg, type);
    });

    // Add the user to your list
    await firestore
        .collection('Users')
        .doc(user.uid)
        .collection('my_users')
        .doc(chatUser.id)
        .set({});
  }

  static Future<void> updateProfilePic(File file) async {
    // Getting image file extension
    final ext = file.path.split('.').last;
    log('Extension: $ext');

    // Storing file reference
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');

    // Uploading data
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    me.image = await ref.getDownloadURL();
    await firestore
        .collection('Users')
        .doc(user.uid)
        .update({'image': me.image});

    // Getting download URL
    // String downloadURL = await ref.getDownloadURL();
    // log('Download URL: $downloadURL');

    // Updating image in Firestore database

    // Return the download URL
  }

  // for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUser chatUser) {
    return firestore
        .collection('Users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('Users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  ///*********************** Chat Screen Related API ********************/

  // chats (collection) --> conversation_id (doc) --> messages (collection) -- > messages (doc)

  // useful for getting conversation id
  static getConversationId(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  // get all messages on specific convo from firestore data
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    return firestore
        .collection('Chats/${getConversationId(user.id)}/ChatMessages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  // sending message
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
    // sending message time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    //  message to send
    final ChatMessages message = ChatMessages(
      msg: msg,
      read: '',
      toId: chatUser.id,
      type: type,
      fromId: user.uid,
      sent: time,
    );

    final ref = firestore
        .collection('Chats/${getConversationId(chatUser.id)}/ChatMessages/');
    await ref
        .doc(time)
        .set(
          message.toJson(),
        )
        .then(
          (value) => sendPushNotification(
            chatUser,
            type == Type.text ? msg : 'image',
          ),
        );

    // Trigger notification
    await _triggerNotification(chatUser, msg);
  }

  static Future<void> _triggerNotification(ChatUser user, String text) async {
    // Assuming you have a way to identify the current user, replace 'currentUserID' with the actual ID
    String currentUserID = user.id;

    // Check if the sender is not the current user
    if (user.id != currentUserID) {
      // Create a notification
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: 'basic_channel',
          title: user.username,
          body: text, // You can customize the notification body
          // bigPicture: user.image, // Set the user's image as the notification image
          // notificationLayout: NotificationLayout.BigPicture,
        ),
      );
    }
  }

  // update read status of message
  static Future<void> updateMessageReadStatus(ChatMessages message) async {
    firestore
        .collection('Chats/${getConversationId(message.fromId)}/ChatMessages/')
        .doc(message.sent)
        .update({
      'read': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  //get only last message of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user) {
    return firestore
        .collection('Chats/${getConversationId(user.id)}/ChatMessages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    // Getting image file extension
    final ext = file.path.split('.').last;
    log('Extension: $ext');

    // Storing file reference
    final ref = storage.ref().child(
        'images/${getConversationId(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    // Uploading data
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    // updating image in firestore data
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }
}
