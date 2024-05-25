import 'package:file_downloader/pdf_screen.dart';
import 'package:file_downloader/video_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
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
                 Get.to(const VideoScreen());
                },
                child: const Text("Video & Encrypt"),
              ),
              const SizedBox(height: 30,),
              ElevatedButton(
                onPressed: () async {
                 Get.to(const PdfScreen());
                },
                child: const Text("Pdf & Encrypt"),
              ),
          ],
        ),
      ),
    );
  }
}