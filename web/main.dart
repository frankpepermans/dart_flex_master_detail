import 'dart:html';

import 'package:dart_flex_master_detail/master_detail_example.dart';

void main() {
  Controller C = new Controller()
    ..wrapTarget(querySelector('#dart_flex_container'))
    ..percentWidth = 100.0
    ..percentHeight = 100.0;
}
