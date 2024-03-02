import 'dart:developer';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messengerapp/apilists/apis.dart';
import 'package:messengerapp/component/messagecard.dart';
import 'package:messengerapp/component/mydateutil.dart';
import 'package:messengerapp/component/notification_controller.dart';
import 'package:messengerapp/homepage.dart';
import 'package:messengerapp/models/chatusers.dart';
import 'package:messengerapp/models/messages.dart';

import '../main.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatMessages> _list = [];

  // for handling message text changes
  final _textController = TextEditingController();

  bool _showEmoji = false, _isUploading = false;

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

    Future.delayed(const Duration(seconds: 0), () {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Colors.black,
        systemNavigationBarColor: Colors.white,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () {
            if (_showEmoji) {
              setState(() => _showEmoji = !_showEmoji);
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appBar(),
              backgroundColor: Theme.of(context).colorScheme.background,
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Colors.black,

            // body
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: APIs.getAllMessages(widget.user),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const SizedBox();

                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          // log('Data: ${jsonEncode(data![0].data())}');
                          _list = data
                                  ?.map((e) => ChatMessages.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (_list.isNotEmpty) {
                            return ListView.builder(
                              reverse: true,
                              itemCount: _list.length,
                              padding: EdgeInsets.only(top: mq.height * .01),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                // return ChatUserCard(user: list[index]);
                                return MessageCard(
                                  message: _list[index],
                                );
                              },
                            );
                          } else {
                            return const Center(
                              child: Text('Say Hello!',
                                  style: TextStyle(fontSize: 20)),
                            );
                          }
                      }
                    },
                    // stream: null,
                  ),
                ),

                // progress if its uploading the image
                if (_isUploading)
                  const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )),

                // chat input field
                _chatInput(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return InkWell(
        onTap: () {},
        child: StreamBuilder(
          stream: APIs.getUserInfo(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

            return Row(
              children: [
                // back button
                IconButton(
                    onPressed: () {
                      setState(() {
                        Navigator.pop(context);

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Homepage(
                                title: Text(''),
                              ),
                            ));
                      });
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                    )),
                ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * .03),
                  child: CachedNetworkImage(
                    width: mq.height * .05,
                    height: mq.height * .05,
                    imageUrl:
                        list.isNotEmpty ? list[0].image : widget.user.image,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const CircleAvatar(child: Icon(CupertinoIcons.person)),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.isNotEmpty ? list[0].username : widget.user.username,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      list.isNotEmpty
                          ? list[0].isOnline
                              ? 'Online'
                              : MyDateUtil.getLastActiveTime(
                                  context: context,
                                  lastActive: list[0].lastActive)
                          : MyDateUtil.getLastActiveTime(
                              context: context,
                              lastActive: widget.user.lastActive),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                    )
                  ],
                ),
              ],
            );
          },
        ));
  }

  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: mq.height * .01,
        horizontal: mq.width * .025,
      ),
      child: Row(
        children: [
          // input field & buttons
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  // emoji button
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.emoji_emotions,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.blueAccent
                          : Colors.white,
                      size: 25,
                    ),
                  ),

                  // emoji button
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onTap: () {},
                      decoration: const InputDecoration(
                        hintText: 'Type Something...',
                        hintStyle: TextStyle(
                          color: Colors.blueAccent,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  // gallery button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        // pick multiple images
                        final List<XFile> images =
                            await picker.pickMultiImage(imageQuality: 70);

                        // upload multiple images one by one
                        for (var i in images) {
                          log('Image Path: ${i.path}');
                          setState(
                            () => _isUploading = true,
                          );
                          await APIs.sendChatImage(
                            widget.user,
                            File(i.path),
                          );
                          setState(
                            () => _isUploading = false,
                          );
                        }
                      },
                      icon: Icon(
                        Icons.image,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.blueAccent
                            : Colors.white,
                      )),

                  // camera button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // pick an image
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.camera,
                        );
                        if (image != null) {
                          log('Image Path: ${image.path}');
                          setState(
                            () => _isUploading = true,
                          );

                          await APIs.sendChatImage(
                            widget.user,
                            File(image.path),
                          );
                          setState(
                            () => _isUploading = false,
                          );
                        }
                      },
                      icon: Icon(
                        Icons.camera_alt_rounded,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.blueAccent
                            : Colors.white,
                      )),
                  SizedBox(
                    width: mq.width * .02,
                  )
                ],
              ),
            ),
          ),

          // send message button
          MaterialButton(
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  if (_list.isEmpty) {
                    // first message (add user to my_user collection of chat user)
                    APIs.sendFirstMessage(
                      widget.user,
                      _textController.text,
                      Type.text,
                    );
                  } else {
                    // simply send message
                    APIs.sendMessage(
                      widget.user,
                      _textController.text,
                      Type.text,
                    );
                  }
                  _textController.text = '';
                }
              },
              minWidth: 0,
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                right: 10,
                left: 10,
              ),
              shape: const CircleBorder(),
              color: Colors.blueAccent,
              child: Icon(
                Icons.send,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Colors.white,
                size: 26,
              ))
        ],
      ),
    );
  }
  // Inside the APIs class or wherever you handle sending messages
}
