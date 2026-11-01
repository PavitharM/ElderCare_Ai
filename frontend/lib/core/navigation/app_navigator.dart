import 'package:flutter/material.dart';

/// Lets background services (BLE fall alerts) open screens without a BuildContext.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
