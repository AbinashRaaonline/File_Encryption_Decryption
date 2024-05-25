import 'dart:typed_data';
import 'package:flutter/material.dart' hide Key;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:open_file/open_file.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isGranted = true;
  String filename = "Raaonline.mp4";

  String videUrl = "https://player.vimeo.com/progressive_redirect/playback/505946464/rendition/720p/file.mp4?loc=external&log_user=0&signature=bcdb8d02eee121accb4c0efbeaad89d007c384b19aed8b0c020f883f2c09041d";

  final StreamController<double> _progressController = StreamController<double>();
  http.Client? _httpClient;
  bool _isDownloading = false;
  List<String> _downloadedFiles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressController.close();
    _httpClient?.close();
    super.dispose();
  }

  Future<Directory> get getAppDir async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir;
  }

  Future<Directory> get getExternalVisibleDir async {
    if (await Directory('/storage/emulated/0/MyEncFolder').exists()) {
      final externalDir = Directory('/storage/emulated/0/MyEncFolder');
      return externalDir;
    } else {
      await Directory('/storage/emulated/0/MyEncFolder').create(recursive: true);
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

  Future<void> downloadAndCreate(String url, Directory d, String filename) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    _httpClient = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await _httpClient!.send(request);

      final contentLength = response.contentLength;
      int receivedBytes = 0;

      List<int> bytes = [];

      response.stream.listen(
        (List<int> newBytes) {
          bytes.addAll(newBytes);
          receivedBytes += newBytes.length;
          _progressController.add(receivedBytes / (contentLength ?? 1));
        },
        onDone: () async {
          var encResult = encryptData(Uint8List.fromList(bytes));
          String p = await writeData(encResult, '${d.path}/$filename.aes');
          debugPrint("file encrypted successfully: $p");
          Get.rawSnackbar(message: 'File encrypted successfully', duration: const Duration(seconds: 2));
          setState(() {
            _isDownloading = false;
            _downloadedFiles.add(filename);
          });
        },
        onError: (error) {
          Get.rawSnackbar(message: 'Download failed', duration: const Duration(seconds: 2));
          setState(() {
            _isDownloading = false;
          });
        },
        cancelOnError: true,
      );
    } catch (e) {
      Get.rawSnackbar(message: 'Download failed', duration: const Duration(seconds: 2));
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> getNormalFile(Directory d, String filename) async {
    Get.rawSnackbar(message: 'Start decryption', duration: const Duration(seconds: 2));
    Uint8List encData = await readData('${d.path}/$filename.aes');
    var plainData = await decryptData(encData);
    String decryptedFilePath = '${d.path}/$filename';
    String p = await writeData(plainData, decryptedFilePath);
    debugPrint("file decrypted successfully: $p");
    Get.rawSnackbar(message: 'File decrypted successfully', duration: const Duration(seconds: 2));

    OpenFile.open(decryptedFilePath).then((result) {
      if (result.type == ResultType.done) {
        _deleteDecryptedFile(decryptedFilePath);
      }
    });
  }

  Future<void> _deleteDecryptedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        file.deleteSync();
        debugPrint("Decrypted file deleted: $filePath");
      }
    } catch (e) {
      debugPrint("Failed to delete file: $e");
    }
  }

  encryptData(Uint8List plainBytes) {
    debugPrint("Encrypting File......");
    final encrypted = MyEncrypt.myEncrypter.encryptBytes(plainBytes, iv: MyEncrypt.myIv);
    return encrypted.bytes;
  }

  decryptData(Uint8List encBytes) {
    debugPrint("File decryption in progress.....>>>>");
    enc.Encrypted en = enc.Encrypted(encBytes);
    return MyEncrypt.myEncrypter.decryptBytes(en, iv: MyEncrypt.myIv);
  }

  Future<Uint8List> readData(String fileNameWithPath) async {
    debugPrint("Reading data.....>>>>");
    File f = File(fileNameWithPath);
    return await f.readAsBytes();
  }

  Future<String> writeData(List<int> dataToWrite, String fileNameWithPath) async {
    debugPrint("Writing data.....>>>>");
    File f = File(fileNameWithPath);
    await f.writeAsBytes(dataToWrite);
    return f.absolute.toString();
  }

  @override
  Widget build(BuildContext context) {
    requestStoragePermission();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text('Video Downloader'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                Directory? appDocDir = await getApplicationDocumentsDirectory();
                downloadAndCreate(videUrl, appDocDir, filename);
              },
              child: const Text("Download & Encrypt"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                Directory? appDocDir = await getApplicationDocumentsDirectory();
                getNormalFile(appDocDir, filename);
              },
              child: const Text("Decrypt File"),
            ),
            const SizedBox(height: 20),
            StreamBuilder<double>(
              stream: _progressController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  double progress = snapshot.data ?? 0;
                  return Column(
                    children: [
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 10),
                      Text('${(progress * 100).toStringAsFixed(2)}%'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _isDownloading
                            ? () {
                                _httpClient?.close();
                                setState(() {
                                  _isDownloading = false;
                                });
                              }
                            : null,
                        child: const Text("Cancel Download"),
                      ),
                    ],
                  );
                } else {
                  return Container();
                }
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _downloadedFiles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_downloadedFiles[index]),
                    onTap: () async {
                      Directory? appDocDir = await getApplicationDocumentsDirectory();
                      getNormalFile(appDocDir, _downloadedFiles[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyEncrypt {
  static final myKey = enc.Key.fromUtf8('TechWithVPTechWithVPTechWithVP12');
  static final myIv = enc.IV.fromUtf8("VivekPanchal1122");
  static final myEncrypter = enc.Encrypter(enc.AES(myKey));
}
