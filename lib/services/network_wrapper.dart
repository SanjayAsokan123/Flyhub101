import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../CommonClass/offline_page.dart';

class NetworkWrapper extends StatefulWidget {
  final Widget child;
  const NetworkWrapper({required this.child, super.key});

  @override
  State<NetworkWrapper> createState() => _NetworkWrapperState();
}

class _NetworkWrapperState extends State<NetworkWrapper> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateStatus(results);
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateStatus(results);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    setState(() {
      // In connectivity_plus 6.x, if there's no connection, 
      // the list contains ConnectivityResult.none
      _isOnline = !results.contains(ConnectivityResult.none);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isOnline ? widget.child : const OfflinePage();
  }
}
