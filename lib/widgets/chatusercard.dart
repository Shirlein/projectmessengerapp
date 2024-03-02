import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:messengerapp/apilists/apis.dart';
import 'package:messengerapp/chatsite/chatscreen.dart';
import 'package:messengerapp/component/mydateutil.dart';
import 'package:messengerapp/models/chatusers.dart';
import 'package:messengerapp/models/messages.dart';

import '../main.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  //last message info (if null -> no message)
  ChatMessages? _message;

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: mq.width * .04,
        vertical: 4,
      ),
      // color: Colors.blue.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0.5,
      child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(user: widget.user)));
          },
          child: StreamBuilder(
            stream: APIs.getLastMessage(widget.user),
            builder: (context, snapshot) {
              final data = snapshot.data?.docs;
              // log('Data: ${jsonEncode(data![0].data())}');
              final list =
                  data?.map((e) => ChatMessages.fromJson(e.data())).toList() ??
                      [];

              if (list.isNotEmpty) {
                _message = list[0];
              }
              return ListTile(
                // user profile pic
                // leading: const CircleAvatar(child: Icon(Icons.person)),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * 3),
                  child: CachedNetworkImage(
                    width: mq.height * .055,
                    height: mq.height * .055,
                    imageUrl: widget.user.image,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const CircleAvatar(child: Icon(CupertinoIcons.person)),
                  ),
                ),

                // user name
                title: Text(widget.user.username),

                // last message
                subtitle: Text(
                  _message != null
                      ? _message!.type == Type.image
                          ? 'image'
                          : _message!.msg
                      : widget.user.about,
                  maxLines: 1,
                ),

                // last message time

                trailing: _message == null
                    ? null // show nothing when no message is sent
                    : _message!.read.isEmpty &&
                            _message!.fromId != APIs.user.uid
                        ?

                        // show for unread message
                        Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.shade400,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          )
                        :
                        // message sent time
                        // trailing: const
                        Text(
                            MyDateUtil.getLastMessageTime(
                              context: context,
                              time: _message!.sent,
                            ),
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
              );
            },
          )),
    );
  }
}
