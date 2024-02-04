import 'package:ble_scan_example2/Page/DeviceServices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class DeviceInfo extends StatefulWidget {
  final BluetoothDevice scanDevice;
   DeviceInfo({super.key, required this.scanDevice});

  @override
  State<DeviceInfo> createState() => _DeviceInfoState();
}

class _DeviceInfoState extends State<DeviceInfo> {
  late Stream<BluetoothDeviceState>? deviceStateStream;
  late BluetoothDevice scanDevice;
  List<BluetoothService> bluetoothServices = [];




   @override
   void initState() {
     super.initState();
     scanDevice=widget.scanDevice;
     deviceStateStream=widget.scanDevice.state;
   }

  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(
        title: Text('Device Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Name: ${scanDevice.name.isNotEmpty?"${scanDevice.name}":"N/A"}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Device id: ${scanDevice.id}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Device type: ${scanDevice.type}',
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 40),
            StreamBuilder<BluetoothDeviceState>(
              stream: deviceStateStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  BluetoothDeviceState? deviceState = snapshot.data;
                  return Text('Device State: $deviceState');
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Text('Loading...');
                }
              },
            ),
            SizedBox(height: 40),
            Row(
              children: [
                ElevatedButton(
                    onPressed: (){
                      scanDevice.connect();
                    },
                    child: Text("Connect")
                ),
                SizedBox(width: 10,),
                ElevatedButton(
                    onPressed: (){
                      scanDevice.disconnect();
                    },
                    child: Text("Disconnect")
                ),
                SizedBox(width: 10,),
                ElevatedButton(
                    onPressed: ()async{
                      try{
                        List<BluetoothService> services = await scanDevice.discoverServices();
                        setState(() {
                          bluetoothServices = services;
                            });
                        Get.to(DeviceServices(device: scanDevice, services: services,));
                    }catch(e){

                      }},
                    child: Text("Discover services")
                ),
              ],
            )

            // Add more device details as needed
          ],
        ),
      ),
    );
  }
}