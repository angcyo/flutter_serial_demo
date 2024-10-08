import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:usb_serial/usb_serial.dart';

var logger = Logger();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Serial Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<UsbDevice>? deviceList;
  UsbPort? usbPort;

  void updateState() {
    setState(() {});
  }

  void _incrementCounter() {
    () async {
      logger.i("开始扫描到设备...");
      deviceList = await UsbSerial.listDevices();
      //debugger();
      logger.i("扫描到设备:$deviceList");
      updateState();
    }();
  }

  void showMessenger(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2), // 提示持续时间
    );
    // 显示 SnackBar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void testDevice(UsbDevice device) async {
    await usbPort?.close();
    final port = await device.create();
    if (port == null) {
      logger.i("create failed");
      showMessenger("create failed");
      return;
    }
    final isOpen = await port.open();
    if (!isOpen) {
      logger.i("open failed");
      showMessenger("open failed");
      return;
    }

    usbPort = port;

    await port.setDTR(true);
    await port.setRTS(true);
    port.setPortParameters(
        115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    logger.i("...开始监听");

    // logger.i first result and close port.
    port.inputStream?.listen((Uint8List event) {
      logger.i("收到数据[${event.length}]");
      final data = utf8.decoder.convert(event);
      logger.i(data);
      showMessenger(data);
      //port.close();
    });

    logger.i("写入数据.");
    //await port.write(Uint8List.fromList([0x10, 0x00, 0xaa, 0xbb]));
    await port.write(utf8.encoder.convert("Hello port!"));
  }

  @override
  void dispose() {
    usbPort?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: ListView.builder(
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(deviceList![index].deviceName),
                subtitle: Text(deviceList![index].toString()),
                trailing: FloatingActionButton(
                  onPressed: () {
                    final data = "Hello usb!:${DateTime.now()}";
                    logger.i("[$usbPort]发送数据:$data");
                    usbPort?.write(utf8.encoder.convert(data));
                  },
                  child: const Icon(Icons.send),
                ),
                onTap: () {
                  showMessenger("click");
                  testDevice(deviceList![index]);
                },
              );
            },
            itemCount: deviceList?.length ?? 0),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: '扫描',
        child: const Icon(Icons.scanner),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
