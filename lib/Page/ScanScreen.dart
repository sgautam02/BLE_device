import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'DeviceInfo.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<ScanResult> scanResultList = [];
  final List<BluetoothDevice> _devicesList = [];
  IconData? bluetoothIcon;
  var scan_mode = 0;
  bool isScanning = false;
  bool isBluetoothOn = false;
  String? readableValue;


  @override
  void initState() {
    initBleList();
    super.initState();
  }

  Future initBleList() async {
    isScanning=true;
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothAdvertise.request();
    flutterBlue.connectedDevices.asStream().listen((devices) {
      for (var device in devices) {
        _addDeviceTolist(device);
      }
    });
    flutterBlue.scanResults.listen((scanResults) {
      for (var result in scanResults) {

        _addDeviceTolist(result.device);
      }
    });
    await flutterBlue.startScan();
    setState(() {
      isScanning=true;
    });
  }

  Future<void> _addDeviceTolist(BluetoothDevice device) async {
    if (!_devicesList.contains(device)) {
      setState(() {
        _devicesList.add(device);
      });
      // if(device.name=='ESP32-Staqo'){
      //   // setState(() {
      //   //   _devicesList.add(device);
      //   // });
      // }
    }
  }
  List<BluetoothService>? bluetoothServices;
  List<ControlButton> controlButtons = [];
  ListView _buildListViewOfDevices() {
    List<Widget> containers = [];
    for (BluetoothDevice device in _devicesList.where((element) => element.name.isNotEmpty)) {
      containers.add(
        SizedBox(
          height: 60,
          child: Row(
            children: <Widget>[
              Expanded(
                  child: Column(
                      children: <Widget>[
                        GestureDetector(
                          onTap:(){ Get.to(DeviceInfo(scanDevice: device));},
                            child: Text(device.name)
                        ),
                        Text(device.id.toString()
                        )
                      ]
                  )
              ),
              ElevatedButton(
                child: const Text('Connect', style: TextStyle(color: Colors.white)),
                onPressed: (){ Get.to(DeviceInfo(scanDevice: device));},
              ),
              SizedBox(width: 10,),
              ElevatedButton(
                  onPressed: () async{
                      if (device.name.contains("ESP32-Staqo")) {
                      try {
                      await device.disconnect();
                      }catch(e){
                        print(e);
                      }
                      }

                  },
                  child: Text("Disconnect"))
            ],
          ),
        ),
      );
    }
    return ListView(padding: const EdgeInsets.all(8), children: <Widget>[...containers]);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('BLE Scanner')),
        body: _buildListViewOfDevices() ,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          initBleList();
          },
        child: Icon(isScanning?Icons.stop:Icons.search),

      ),

    );
  }

}

class ControlButton {
  final String buttonName;
  final Function() onTap;

  ControlButton({required this.buttonName, required this.onTap});
}

