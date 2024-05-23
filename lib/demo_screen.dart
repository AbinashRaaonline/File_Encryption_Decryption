import 'dart:typed_data';
import 'package:flutter/material.dart' hide Key;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    requestStoragePermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool isGranted = true;
  String filename = "Raaonline.mp4";
  String videUrl =
      "https://player.vimeo.com/progressive_redirect/playback/505946464/rendition/720p/file.mp4?loc=external&log_user=0&signature=bcdb8d02eee121accb4c0efbeaad89d007c384b19aed8b0c020f883f2c09041d";

  Future<Directory> get getAppDir async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir;
  }

  Future<Directory> get getExternalVisibleDir async {
    if (await Directory('/storage/emulated/0/MyEncFolder').exists()) {
      final externalDir = Directory('/storage/emulated/0/MyEncFolder');
      return externalDir;
    } else {
      await Directory('/storage/emulated/0/MyEncFolder')
          .create(recursive: true);
      final externalDir = Directory('/storage/emulated/0/MyEncFolder');
      return externalDir;
    }
  }

  requestStoragePermission() async {
    if (!await Permission.storage.isGranted) {
      PermissionStatus result = await Permission.storage.request();
      if (result.isGranted) {
        setState(() {
          isGranted = true;
        });
      } else {
        setState(() {
          isGranted = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text('File Downloader'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                //if (isGranted) {
                  Directory? appDocDir =
                        await getExternalStorageDirectory();
                    print("dta wwwww......");
                    downloadAndCreate(videUrl, appDocDir!, filename);
                // } else {
                //   requestStoragePermission();
                // }
              },
              child: const Text("Download & Encrypt"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                //if (isGranted) {
                   Directory? appDocDir =
                        await getExternalStorageDirectory();
                    getNormalFile(appDocDir!, filename);
                // } else {
                //   requestStoragePermission();
                // }
              },
              child: const Text("Decrypt File"),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> downloadAndCreate(String url, Directory d, String filename) async {
  Get.rawSnackbar(message: 'File downloading', duration: const Duration(seconds: 2));
  debugPrint("Data downloading");

  var request = http.Request('GET', Uri.parse(url));
  var response = await request.send();

  final tempFile = File('${d.path}/$filename.aes');
  final output = tempFile.openWrite();

  final encrypter = MyEncrypt.myEncrypter;
  final iv = MyEncrypt.myIv;

  await for (var chunk in response.stream) {
    var encryptedChunk = encrypter.encryptBytes(Uint8List.fromList(chunk), iv: iv).bytes;
    output.add(encryptedChunk);
  }

  await output.close();
  debugPrint("File encrypted successfully: ${tempFile.path}");

  Get.rawSnackbar(message: 'File encrypted successfully', duration: const Duration(seconds: 2));
}

Future<void> getNormalFile(Directory d, String filename) async {
  Get.rawSnackbar(message: 'Start decryption', duration: const Duration(seconds: 2));

  final tempFile = File('${d.path}/$filename.aes');
  final outputFile = File('${d.path}/$filename');
  final output = outputFile.openWrite();

  final inputStream = tempFile.openRead();
  final encrypter = MyEncrypt.myEncrypter;
  final iv = MyEncrypt.myIv;

  await for (var chunk in inputStream) {
    var decryptedChunk = encrypter.decryptBytes(enc.Encrypted(Uint8List.fromList(chunk)), iv: iv);
    output.add(Uint8List.fromList(decryptedChunk));
  }

  await output.close();
  debugPrint("File decrypted successfully: ${outputFile.path}");

  Get.rawSnackbar(message: 'File decrypted successfully', duration: const Duration(seconds: 2));
}

class MyEncrypt {
  static final myKey = enc.Key.fromUtf8('TechWithVPTechWithVPTechWithVP12');
  static final myIv = enc.IV.fromUtf8('VivekPanchal1122');
  static final myEncrypter = enc.Encrypter(enc.AES(myKey, mode: enc.AESMode.cbc, padding: 'PKCS7'));
}