import 'dart:async';
import 'dart:collection';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class DeviceServices extends StatefulWidget {
  final BluetoothDevice device;
  final List<BluetoothService> services;

  DeviceServices({super.key, required this.device, required this.services});

  @override
  State<DeviceServices> createState() => _DeviceServicesState();
}

class _DeviceServicesState extends State<DeviceServices> {
  late final BluetoothDevice device;
  List<BluetoothCharacteristic> characteristics = [];
  List chrValue=[];
  late int dataFromDevice =0;
  StreamController<int> dataStreamController = StreamController<int>.broadcast();
  Stream<int> get dataStream => dataStreamController.stream;
  Queue<int> receivedDataQueue = Queue<int>();
  StreamController<Queue<int>> dataQueue=StreamController<Queue<int>>();
  List<Map<String, dynamic>> chartData = [];





  @override
  void initState() {
    super.initState();
    device = widget.device;
    discoverServices();
    // convertStringToDataPoints(dataFromDevice);
  }

  Future<void> discoverServices() async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      List<BluetoothCharacteristic> newCharacteristics = [];

      for (BluetoothService service in services) {
        List<BluetoothCharacteristic> serviceCharacteristics = service.characteristics;

        for (BluetoothCharacteristic c in serviceCharacteristics) {
          if (c.properties.read) {
            if (c.uuid.toString() == 'f1b21c85-c362-4cf5-9c1f-91a7a837ddf9') {
              newCharacteristics.add(c);
              c.setNotifyValue(true);
              c.value.listen((value) {
                int dataFromDevice = value[0]; // Assuming you're receiving a single integer
                dataStreamController.add(dataFromDevice);
                receivedDataQueue.add(dataFromDevice);
                if (receivedDataQueue.length > 8) {
                  receivedDataQueue.removeFirst();
                }
                print(receivedDataQueue);
                dataQueue.add(receivedDataQueue);
                // You can add additional processing or actions here.
              });
            }
          }
        }
      }

      setState(() {
        characteristics = newCharacteristics;
      });
    } catch (error) {
      print('Error during service discovery: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Data: ${dataFromDevice}');
    return Scaffold(
      appBar: AppBar(
        title: Text("${device.name}"),
      ),
      body: Column(
        children: [
          Text('Connected Device: ${device.name ?? 'None'}'),
          Text('Characteristics:'),
          ElevatedButton(
              onPressed: discoverServices,
              child: Text("Discover")
          ),
          ElevatedButton(
              onPressed: (){},
              child: Text("chart")
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 50, // Set a fixed height or use another value that suits your layout
                  child: StreamBuilder<int>(
                    stream: dataStream,
                    builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                      if (snapshot.hasData) {
                        return Text('Received data: ${snapshot.data}');
                      } else {
                        return Text('No data received yet.');
                      }
                    },
                  ),
                ),
                Container(
                  height: 516,
                  child:StreamBuilder<Queue<int>>(
                    stream: dataQueue.stream,
                    builder: (BuildContext context, AsyncSnapshot<Queue<int>> snapshot) {
                      if (snapshot.hasData) {
                        List<int> dataList = snapshot.data!.toList();
                        return Column(
                          children: [
                            Text('Received data: ${snapshot.data}'),
                            Container(
                              height: 300,
                              child:AspectRatio(
                                aspectRatio: 1.5,
                                child: BarChart(
                                  BarChartData(
                                    borderData: FlBorderData(border: Border()),
                                    alignment: BarChartAlignment.start,
                                    groupsSpace: 10,
                                    barGroups: [
                                      BarChartGroupData(
                                        x: 0,
                                        barsSpace: 4,
                                        barRods: dataList.map((data) {
                                          return BarChartRodData(
                                            toY: data.toDouble(),
                                            width: 12,
                                            color: Colors.blue, // You can set the color as needed
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 200,
                              child: StreamBuilder<int>(
                                stream: dataStream,
                                builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                                  if (snapshot.hasData) {
                                    // Create a list to store data for the
                                    // Append the data from the stream to the chart data
                                    String currentTime = DateFormat.Hms().format(DateTime.now());
                                    chartData.add({'x': currentTime, 'y': snapshot.data});
                                    if (chartData.length == 8) {
                                      chartData.removeAt(0);
                                    }

                                    return SfCartesianChart(
                                      primaryXAxis: CategoryAxis(),
                                      series: <CartesianSeries>[
                                        ColumnSeries<dynamic, String>(
                                          name: 'Bar Chart',
                                          dataSource: chartData,
                                          xValueMapper: (dynamic data, _) => data['x'],
                                          yValueMapper: (dynamic data, _) => data['y'],
                                          width: 0.1, // Adjust bar width
                                          color: Colors.red,
                                        ),
                                        LineSeries<dynamic, String>(
                                          name: 'Line Chart',
                                          dataSource: chartData,
                                          xValueMapper: (dynamic data, _) => data['x'],
                                          yValueMapper: (dynamic data, _) => data['y'],
                                          width: 2, // Adjust line thickness
                                          color: Colors.blue,
                                          markerSettings: MarkerSettings(
                                            isVisible: true,
                                            shape: DataMarkerType.circle,
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Text('No data received yet.');
                                  }
                                },
                              ),
                            )

                            /*Container(
                              height:200,
                              child:   SfCartesianChart(
                                primaryXAxis: CategoryAxis(),
                                series: <CartesianSeries>[

                                  ColumnSeries<dynamic, String>(
                                    name: 'Bar Chart',
                                    dataSource: [
                                      {'x': 'A', 'y': 2},
                                      {'x': 'B', 'y': 4},
                                      {'x': 'C', 'y': 1},
                                      {'x': 'D', 'y': 5},
                                      {'x': 'E', 'y': 3},
                                      {'x': 'F', 'y': 4},
                                    ],
                                    xValueMapper: (dynamic data, _) => data['x'],
                                    yValueMapper: (dynamic data, _) => data['y'],
                                    width: 0.1, // Adjust bar width
                                    color: Colors.red,
                                  ),
                                  LineSeries<dynamic, String>(
                                    name: 'Line Chart',
                                    dataSource: [
                                      {'x': 'A', 'y': 2,'color': Colors.green},
                                      {'x': 'B', 'y': 4,},
                                      {'x': 'C', 'y': 1,'color': Colors.green},
                                      {'x': 'D', 'y': 5,'color': Colors.green},
                                      {'x': 'E', 'y': 3,'color': Colors.green},
                                      {'x': 'F', 'y': 4,'color': Colors.green},
                                    ],
                                    xValueMapper: (dynamic data, _) => data['x'],
                                    yValueMapper: (dynamic data, _) => data['y'],
                                    width: 2, // Adjust line thickness
                                    color: Colors.blue,
                                    markerSettings:MarkerSettings(
                                      isVisible: true,
                                      shape: DataMarkerType.circle
                                    ),

                                  ),

                                ],
                              )
                            )*/
                          ],
                        );
                      } else {
                        return Text('No data received yet.');
                      }
                    },
                  ) ,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

