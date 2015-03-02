import 'dart:html';

import 'package:dart_flex_master_detail/master_detail_example.dart';
import 'package:dart_flex_master_detail/dart_flex_codegen.dart';

void main() {
  final Scanner S = new Scanner('package:dart_flex_master_detail/master_detail_example.dart');
  
  S.getCodeBlocks().then(sendResults);
}

void sendResults(String codeBlocks) {
  HttpRequest.request(
    'http://localhost:8089/', 
    method: 'POST', 
    sendData: codeBlocks,
    responseType: 'text'
  ).then(
    (HttpRequest request) {
      print(request.statusText);
    }
  );
}














