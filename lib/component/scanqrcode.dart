import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:messengerapp/apilists/apis.dart';
import 'package:messengerapp/homepage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQRCode extends StatefulWidget {
  const ScanQRCode({super.key});

  @override
  State<ScanQRCode> createState() => _ScanQRCodeState();
}

class _ScanQRCodeState extends State<ScanQRCode> {
  String email = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: _appBar(),
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          returnImage: true,
        ),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          final Uint8List? image = capture.image;
          for (final barcode in barcodes) {
            print('Barcode Found! ${barcode.rawValue}');
          }
          if (image != null) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    email = barcodes.first.rawValue ?? '',
                  ),
                  content: Image(
                    image: MemoryImage(image),
                  ),
                  actions: [
                    MaterialButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                    MaterialButton(
                      onPressed: () async {
                        // Navigator.pop(context);
                        if (email.isNotEmpty) {
                          await APIs.addChatUser(email).then(
                            (value) {
                              if (value) {
                                AlertDialog(
                                  content: const Text('User Exists!'),
                                  actions: [
                                    MaterialButton(
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
                                      child: const Text(
                                        'Okay',
                                        style: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    )
                                  ],
                                );
                              }
                            },
                          );
                        }
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
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    )
                  ],
                );
              },
            );
          } else {
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
          }
        },
      ),
    );
  }

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
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
                ),
              ),
              const Text(
                'SCAN A FRIEND',
                style: TextStyle(
                  fontSize: 21,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
