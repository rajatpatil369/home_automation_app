import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

class LoginScreen extends StatefulWidget {
  final MqttServerClient mqttClient;

  LoginScreen({required this.mqttClient}) : super() {
    mqttClient.logging(on: true);
  }

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var _processInitiated = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void authenticate() async {
    setState(() => _processInitiated = true);

    final String username = _usernameController.text;
    final String password = _passwordController.text;

    final connMessage = MqttConnectMessage()
        // .startClean()
        .authenticateAs(username, password)
        // .authenticateAs('nokia', 'password') // WATCHOUT!
        .withWillTopic('willtopic')
        .withWillMessage('Goodbye.')
        .withWillQos(MqttQos.exactlyOnce);
    widget.mqttClient.keepAlivePeriod = 60;
    widget.mqttClient.connectionMessage = connMessage;

    widget.mqttClient.connect().onError((error, stackTrace) {
      if (error is! NoConnectionException) {
        throw error!;
      }
      final connectionStatus = widget.mqttClient.connectionStatus!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'MQTT Error: ',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: connectionStatus.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ],
          ),
        ),
      ));
      setState(() => _processInitiated = false);
      return connectionStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    // authenticate(); // WATCHOUT!
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32.0, 64.0, 32.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Pleas sign in to continue.',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 80.0),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              onSubmitted: (_) {
                if (!_processInitiated) {
                  authenticate();
                }
              },
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
            SizedBox(height: 32.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processInitiated ? null : authenticate,
                child: Text('Login'),
              ),
            ),
            SizedBox(height: 80.0),
          ],
        ),
      ),
    );
  }
}
