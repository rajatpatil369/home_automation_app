import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const textFieldUi = <Map<String, dynamic>>[
  {
    'label': 'Illuminance [MIN]',
    'icon': Icons.light_mode_outlined,
    'unit': 'lx',
  },
  {
    'label': 'Illuminance [MAX]',
    'icon': Icons.light_mode,
    'unit': 'lx',
  },
  {
    'label': 'Temperature [MIN]',
    'icon': Icons.ac_unit_rounded,
    'unit': '°C',
  },
  {
    'label': 'Temperature [MAX]',
    'icon': Icons.thermostat,
    'unit': '°C',
  },
  {
    'label': 'Humidity',
    'icon': Icons.dew_point,
    'unit': '%',
  },
  {
    'label': 'Water Level [MIN]',
    'icon': Icons.water_drop_outlined,
    'unit': 'cm',
  },
  {
    'label': 'Water Level [MAX]',
    'icon': Icons.water_drop,
    'unit': 'cm',
  },
  {
    'label': 'LPG Level',
    'icon': Icons.fireplace_outlined,
    'unit': 'ppm',
  },
];

const defaultUserSettings = <num>[52, 106, 26.2, 33.7, 34.6, 15, 125, 160];

class SettingsModel extends ChangeNotifier {
  final BuildContext? context;
  final _formKey = GlobalKey<FormState>();
  final _prefKey = 'SETTINGS';
  var _isStateRestored = false;

  late bool _isHome;
  late bool _useDefaults;
  late List<num> _userSettings;

  SettingsModel({this.context}) : super() {
    assert(textFieldUi.length == defaultUserSettings.length,
        'Check `textFieldUi` and `defaultUserSettings`.');

    loadState().then((_) {
      _isStateRestored = true;
      notifyListeners();
    });
  }

  GlobalKey<FormState> get formKey => _formKey;
  List<num> get userSettings => _userSettings;

  bool get isStateRestored => _isStateRestored;
  bool get isHome => _isHome;
  bool get useDefaults => _useDefaults;

  void resetUserSettings() => _userSettings = List.from(defaultUserSettings);

  void setUserSetting(int index, num value) {
    _userSettings[index] = value;
  }

  set isHome(bool value) {
    _isHome = value;
    notifyListeners();
  }

  set useDefaults(bool value) {
    _useDefaults = value;
    notifyListeners();
  }

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefKey);
    if (jsonString != null) {
      final jsonMap = jsonDecode(jsonString);
      _isHome = jsonMap['_isHome'] as bool;
      _useDefaults = jsonMap['_useDefaults'] as bool;
      _userSettings = jsonMap['_userSettings'] as List<num>;
      print('debug: settings: SAVED STATE RESTORED -> $jsonMap');
    } else {
      _isHome = true;
      _useDefaults = true;
      resetUserSettings();
    }
  }
}

class SettingsPage extends StatelessWidget {
  final _topic = 'has/user_settings';
  final MqttServerClient mqttClient;

  final Map<String, String> stateData;

  SettingsPage({required this.mqttClient, required this.stateData});

  saveChanges(BuildContext context, SettingsModel notifier, Widget? child) {
    if (notifier.formKey.currentState!.validate()) {
      if (notifier.useDefaults) {
        notifier.resetUserSettings();
      } else {
        notifier.formKey.currentState!.save();
      }

      final builder = MqttClientPayloadBuilder();
      builder.addString(
          ':!${notifier.isHome ? 1 : 0} ${notifier.userSettings.join(' ')}\n');
      if (mqttClient.connectionStatus!.state != MqttConnectionState.connected) {
        mqttClient.publishMessage(
            _topic, MqttQos.exactlyOnce, builder.payload!);
      }

      final state = <String, dynamic>{
        '_isHome': notifier.isHome,
        '_useDefaults': notifier.useDefaults,
        '_userSettings': notifier.userSettings,
      };
      final jsonString = jsonEncode(state);
      stateData[notifier._prefKey] = jsonString;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            child: Text('Changes saved.'),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
      builder: (context, notifier, child) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: notifier.isStateRestored
            ? Form(
                key: notifier.formKey,
                child: ListView(
                  padding: const EdgeInsets.all(10.0),
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Row(
                          children: [
                            Text('Use Defaults?'),
                            SizedBox(width: 5.0),
                            Text(
                              notifier.useDefaults ? 'Yes' : 'No',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            )
                          ],
                        )),
                        Switch.adaptive(
                          value: notifier.useDefaults,
                          onChanged: (bool value) {
                            notifier.useDefaults = value;
                            if (value) {
                              notifier.formKey.currentState!.reset();
                            }
                          },
                        ),
                      ],
                    ),
                    Divider(thickness: 0.4),
                    Row(
                      children: [
                        Expanded(flex: 4, child: Text('My Status')),
                        Icon(Icons.my_location),
                        SizedBox(width: 10.0),
                        Expanded(
                          flex: 3,
                          child: DropdownButton(
                            isExpanded: true,
                            value: notifier.isHome ? 'home' : 'travelling',
                            onChanged: (String? value) =>
                                notifier.isHome = value == 'home',
                            items: [
                              DropdownMenuItem(
                                value: 'home',
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('I\'m home'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'travelling',
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Travelling'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 5.0),
                      ],
                    ),
                    SizedBox(height: 10.0),
                    for (var i = 0; i < textFieldUi.length; ++i)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 4, child: Text(textFieldUi[i]['label'])),
                            Icon(textFieldUi[i]['icon']),
                            SizedBox(width: 10.0),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue:
                                    notifier.userSettings[i].toString(),
                                autocorrect: false,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                inputFormatters: [
                                  (defaultUserSettings[i].runtimeType == int)
                                      ? FilteringTextInputFormatter.digitsOnly
                                      : FilteringTextInputFormatter.allow(
                                          RegExp('[0-9.]')),
                                  FilteringTextInputFormatter
                                      .singleLineFormatter,
                                ],
                                decoration: InputDecoration(
                                    hintText:
                                        defaultUserSettings[i].toString()),
                                enabled: !notifier.useDefaults,
                                validator:
                                    (defaultUserSettings[i].runtimeType == int)
                                        ? null
                                        : (String? value) {
                                            if (value != '' &&
                                                value!.split('.').length > 2) {
                                              return 'Please enter a valid decimal.';
                                            }
                                            return null;
                                          },
                                onSaved: (String? value) =>
                                    notifier.setUserSetting(
                                        i,
                                        value != ''
                                            ? (defaultUserSettings[i]
                                                        .runtimeType ==
                                                    int
                                                ? int.parse(value!)
                                                : double.parse(value!))
                                            : defaultUserSettings[i]),
                              ),
                            ),
                            SizedBox(width: 5.0),
                            Expanded(
                                flex: 1,
                                child: Text(
                                  textFieldUi[i]['unit'],
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                )),
                          ],
                        ),
                      ),
                    SizedBox(height: 25.0),
                    Align(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.check),
                        label: Text('Save Changes'),
                        onPressed: () => saveChanges(context, notifier, child),
                      ),
                    )
                  ],
                ))
            : Container(), // CircularProgressIndicator(),
      ),
    );
  }
}
