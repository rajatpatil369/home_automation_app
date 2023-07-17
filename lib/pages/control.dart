import 'package:flutter/material.dart';

class ControlModel extends ChangeNotifier {
  final _key = 'CONTROL';
  final context;

  ControlModel({this.context}) : super() {
    // TODO: restore the state
  }
}

class ControlPage extends StatefulWidget {
  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  @override
  Widget build(BuildContext context) {
    return Placeholder(child: Text('`TODO: ControlPage`'));
  }
}
