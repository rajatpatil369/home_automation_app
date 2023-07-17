import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

const textFieldUi = <Map<String, dynamic>>[
  {
    'label': 'Motion detected?',
    'icon': [Icons.security, Icons.warning], // change the color?
    'unit': null, // bool
  },
  {
    'label': 'Ambient Illuminance',
    'icon': Icons.light,
    'unit': 'lx', // int
  },
  {
    'label': 'Ambient Temperature',
    'icon': Icons.thermostat,
    'unit': '°C', // double
  },
  {
    'label': 'Ambient Humidity',
    'icon': Icons.dew_point,
    'unit': '%', // double
  },
  {
    'label': 'Tank Water Level',
    'icon': Icons.water,
    'unit': 'cm', // int
  },
  {
    'label': 'LPG Concentration',
    'icon': Icons.local_fire_department, // gas_meter
    'unit': 'ppm', // int
  },
  {
    'label': 'Door Status',
    'icon': [Icons.lock, Icons.lock_open],
    'unit': null, // bool
  },
];

class MonitorPage extends StatefulWidget {
  final MqttServerClient mqttClient;
  final _topic = 'has/monitored_parameters';
  final _monitoredParameters = <num>[];

  MonitorPage({required this.mqttClient}) : super() {
    // this is only for linux development platform, a workarounf.. "sorta"
    if (mqttClient.connectionStatus!.state != MqttConnectionState.connected) {
      mqttClient.connect();
    }
    if (mqttClient.getSubscriptionsStatus(_topic) ==
        MqttSubscriptionStatus.doesNotExist) {
      mqttClient.subscribe(_topic, MqttQos.exactlyOnce);
    }
  }

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(flex: 3, child: Text(textFieldUi[0]['label'])),
                Icon(textFieldUi[0]['icon'][0]),
                SizedBox(width: 10.0),
                Expanded(
                  flex: 1,
                  child: Text('TODO'),
                ),
                SizedBox(width: 5.0),
                Expanded(
                  flex: 1,
                  child: Text(
                    "textFieldUi[0]['unit']",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            for (var i = 1; i < textFieldUi.length - 1; ++i)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(textFieldUi[i]['label'])),
                    Icon(textFieldUi[i]['icon']),
                    SizedBox(width: 10.0),
                    Expanded(
                      flex: 1,
                      child: Text('TODO'),
                    ),
                    SizedBox(width: 5.0),
                    Expanded(
                      flex: 1,
                      child: Text(
                        textFieldUi[i]['unit'],
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text(textFieldUi[textFieldUi.length - 1]['label'])),
                Icon(textFieldUi[textFieldUi.length - 1]['icon'][0]),
                SizedBox(width: 10.0),
                Expanded(
                  flex: 1,
                  child: Text('TODO'),
                ),
                SizedBox(width: 5.0),
                Expanded(
                  flex: 1,
                  child: Text(
                    "textFieldUi[textFieldUi.length - 1]['unit']",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
