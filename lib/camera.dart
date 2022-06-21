import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class Camera extends StatefulWidget {
  const Camera({Key? key}) : super(key: key);

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> with WidgetsBindingObserver {
  late List<CameraDescription> cameras;
  CameraController? controller;
  List<XFile?> images = [];
  int _selectPage = 0;

  @override
  void initState() {
    super.initState();
    unawaited(initCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _onNewCameraSelected(cameraController.description);
    }
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();

    controller = CameraController(cameras.first, ResolutionPreset.max);
    await controller!.initialize();
    setState(() {});
  }

  void _onSelectPage(int index) {
    setState(() {
      _selectPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _selectPage == 0 ? const Text('Camera preview') : const Text('Images gallery'),
          ],
        ),
      ),
      body: _selectPage == 0
          ? controller?.value.isInitialized == true
              ? Center(
                  child: CameraPreview(controller!),
                )
              : const SizedBox()
          : ListView.builder(
              itemCount: images.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  height: 200,
                  child: Image.file(
                    File(images[index]!.path),
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera),
        onPressed: () async {
          images.add(await controller?.takePicture());
          setState(() {});
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            label: 'Camera',
            icon: Icon(Icons.camera),
          ),
          BottomNavigationBarItem(
            label: 'Gallery',
            icon: Icon(Icons.photo),
          ),
        ],
        currentIndex: _selectPage,
        onTap: _onSelectPage,
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    final CameraController? oldController = controller;
    if (oldController != null) {
      controller = null;
      await oldController.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      kIsWeb ? ResolutionPreset.max : ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    if (mounted) {
      setState(() {});
    }
  }
}
