library master_detail_example;

import 'dart:async';
import 'package:dart_flex/dart_flex.dart';
import 'package:observe/observe.dart';
import 'model.dart';
import 'infrastructure.dart';
import 'dart_flex_codegen.dart';

part 'src/controller.dart';

abstract class UIWrapperChangeNotifier extends UIWrapper {
  
  UIWrapperChangeNotifier() : super(elementId: null) {}
  
}