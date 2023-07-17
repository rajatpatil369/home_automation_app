import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/monitor.dart';
import 'pages/control.dart';
import 'pages/settings.dart';
import 'pages/login.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Automation',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purpleAccent),
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (context) => ControlModel(context: context)),
          ChangeNotifierProvider(
              create: (context) => SettingsModel(context: context)),
        ],
        child: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final mqttClient = MqttServerClient('192.168.43.31', 'client_id_APP');
  var _loggedIn = false;
  final _stateData = <String, String>{};
  final _subscribedTopics = <String, String>{};
  var i = 0;

  _MyHomePageState() : super() {
    mqttClient.onConnected = () {
      setState(() => _loggedIn = true);

      // only testing that multiple listners are able to the update at the same time
      mqttClient.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttReceivedMessage message = c[0];
        final String topic = message.topic;
        final String payload = MqttPublishPayload.bytesToStringAsString(
            message.payload.payload.message);
        print('debug: main: payload = "$payload", topic = "$topic"');
      });
    };
    mqttClient.onSubscribed = (topic) {
      _subscribedTopics[topic] = '';
      print('debug: main: subscribed to "$topic"');
    };
    mqttClient.onDisconnected = () {
      print('debug: main: disconnected');
    };
    mqttClient.pongCallback = () {
      print('debug: main: ping #$i');
      i += 1;
    };
    // mqttClient.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    //   final MqttReceivedMessage message = c[0];
    //   final String topic = message.topic;
    //   final String payload = MqttPublishPayload.bytesToStringAsString(
    //       message.payload.payload.message);
    //   _subscribedTopics[topic] = payload;
    //   print('debug: monitor: payload = "$payload", topic = "$topic"');
    // });
  }

  var _selectedIndex = 2;

  void setIndex(int value) {
    setState(() {
      _selectedIndex = value;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // purpose: see if the seeting.dart>saveChanges method is doing its job
    print('debug: main: _stateData = $_stateData');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // purpose: see if the seeting.dart>saveChanges method is doing its job
    print('debug: main: _stateData = $_stateData');
  }

  @override
  void dispose() {
    saveAppState();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        mqttClient.connect();
        for (final String topic in _subscribedTopics.keys) {
          mqttClient.subscribe(topic, MqttQos.exactlyOnce);
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        saveAppState();
        mqttClient.disconnect();
        break;
    }
  }

  Future<void> saveAppState() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _stateData.entries) {
      final key = entry.key;
      final value = entry.value;

      prefs.setString(key, value).then((bool success) {
        if (!success) {
          print('debug: main: Error: Failed to save shared preferences.');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (_selectedIndex) {
      case 0:
        page = MonitorPage(mqttClient: mqttClient);
        break;
      case 1:
        page = ControlPage();
        break;
      case 2:
        page = SettingsPage(mqttClient: mqttClient, stateData: _stateData);
        break;
      default:
        throw UnimplementedError('No widget for page index: $_selectedIndex.');
    }

    final mainArea = Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: page,
      ),
    );

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('Home Automation'),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          switchInCurve: Curves.bounceIn,
          child: _loggedIn
              ? LayoutBuilder(builder: (context, constraints) {
                  return (constraints.maxWidth < 450)
                      ? Column(
                          children: [
                            mainArea,
                            BottomNavigationBar(
                              items: const [
                                BottomNavigationBarItem(
                                    icon: Icon(Icons.monitor),
                                    label: 'Monitor'),
                                BottomNavigationBarItem(
                                    icon: Icon(Icons.settings_remote),
                                    label: 'Control'),
                                BottomNavigationBarItem(
                                    icon: Icon(Icons.settings),
                                    label: 'Settings')
                              ],
                              currentIndex: _selectedIndex,
                              onTap: setIndex,
                            )
                          ],
                        )
                      : Row(
                          children: [
                            NavigationRail(
                              extended: constraints.maxWidth >= 600,
                              destinations: const [
                                NavigationRailDestination(
                                    icon: Icon(Icons.monitor),
                                    label: Text('Monitor')),
                                NavigationRailDestination(
                                    icon: Icon(Icons.settings_remote),
                                    label: Text('Control')),
                                NavigationRailDestination(
                                    icon: Icon(Icons.settings),
                                    label: Text('Settings'))
                              ],
                              selectedIndex: _selectedIndex,
                              onDestinationSelected: setIndex,
                            ),
                            mainArea,
                          ],
                        );
                })
              : LoginScreen(
                  mqttClient: mqttClient,
                ),
        ),
      ),
    );
  }
}
