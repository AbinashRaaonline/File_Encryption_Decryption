import 'dart:typed_data';

import 'package:flutter/material.dart' hide Key;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool isGranted = true;
  String filename = "Raaonline.mp4";

  String pdfUrl = "https://raaonline-podcast.s3.amazonaws.com/Mixed+and+multiple++valve+diseses+Part+1.pdf";

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
        isGranted = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    requestStoragePermission();
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
                 // if (isGranted) {
                    Directory? appDocDir =
                        await getApplicationDocumentsDirectory();
                    print("dta wwwww......");
                    downloadAndCreate(videUrl, appDocDir, filename);
                  // } else {
                  //   requestStoragePermission();
                  // }
                },
                child: const Text("Download & Encrypt")),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () async {
                  //if (isGranted) {
                    Directory? appDocDir =
                        await getApplicationDocumentsDirectory();
                        
                    getNormalFile(appDocDir, filename);
                  // } else {
                  //   requestStoragePermission();
                  // }
                },
                child: const Text("Decrypt File")),
          ],
        ),
      ),
    );
  }
}

downloadAndCreate(String url, Directory d, filename) async {
    Get.rawSnackbar(message: 'File downloading',duration: const Duration(seconds: 2));
    debugPrint("data downloading");
    var resp = await http.get(Uri.parse(url));
    var encResult = encryptData(resp.bodyBytes);
    String p = await writeData(encResult, d.path + '/$filename.aes');
    debugPrint("file encrypted successfully: $p");
    Get.rawSnackbar(message: 'File encrypted successfully',duration: const Duration(seconds: 2));
}

getNormalFile(Directory d, filename) async {
  Get.rawSnackbar(message: 'Start decryption',duration: const Duration(seconds: 2));
  Uint8List encData = await readData('${d.path}/$filename.aes');
  var plainData = await decryptData(encData);
  String p = await writeData(plainData, '${d.path}$filename');
  debugPrint("file decrypted successfully: $p");
  Get.rawSnackbar(message: 'File decrypted successfully',duration: const Duration(seconds: 2));
}

encryptData(plainString) {
  debugPrint("Encripting File......");
  final encrypted =
      MyEncrypt.myEncrypter.encryptBytes(plainString, iv: MyEncrypt.myIv);
  return encrypted.bytes;
}

decryptData(encData) {
  debugPrint("File decryption in progress.....>>>>");
  enc.Encrypted en = enc.Encrypted(encData);
  return MyEncrypt.myEncrypter.decryptBytes(en, iv: MyEncrypt.myIv);
}

Future<Uint8List> readData(fileNameWithPath) async {
  debugPrint("Reading data.....>>>>");
  File f = File(fileNameWithPath);
  return await f.readAsBytes();
}

Future<String> writeData(dataToWrite, fileNamewithPath) async {
  debugPrint("Writting data.....>>>>");
  File f = File(fileNamewithPath);
  await f.writeAsBytes(dataToWrite);
  return f.absolute.toString();
}

class MyEncrypt {
  static final myKey = enc.Key.fromUtf8('TechWithVPTechWithVPTechWithVP12');
  static final myIv = enc.IV.fromUtf8("VivekPanchal1122");
  static final myEncrypter = enc.Encrypter(enc.AES(myKey));
}
