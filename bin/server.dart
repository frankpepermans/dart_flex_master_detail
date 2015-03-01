// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;

void main(List<String> args) {
  var parser = new ArgParser()
      ..addOption('port', abbr: 'p', defaultsTo: '8081');

  var result = parser.parse(args);

  var port = int.parse(result['port'], onError: (val) {
    stdout.writeln('Could not parse port value "$val" into a number.');
    exit(1);
  });

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addMiddleware(shelf_cors.createCorsHeadersMiddleware())
      .addHandler(_decodeJSON);

  io.serve(handler, 'localhost', port).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  }).catchError((error) => print(error));
}

Future<shelf.Response> _decodeJSON(shelf.Request request) {
  final Completer<shelf.Response> C = new Completer<shelf.Response>();
  
  try {
    request.readAsString().then(
      (String incoming) {
        _makeBuildTarget(JSON.decode(incoming));
        
        C.complete(new shelf.Response.ok('OK'));
      }
    );
  } catch (error) {
    print('Oops');
    
    C.complete(new shelf.Response.internalServerError());
  }
  
  return C.future;
}

Future _makeBuildTarget(List<Map<String, String>> data) async {
  String p = Directory.current.path;
  final Directory libDir = new Directory.fromUri(Uri.parse('lib'));
  final Directory buildDir = new Directory.fromUri(Uri.parse('build'));
  final Directory webDir = new Directory.fromUri(Uri.parse('web'));
  final Stream<FileSystemEntity> S = await libDir.list(recursive: true);
  final List<FileSystemEntity> L = await S.toList();
  final bool buildDirExists = await buildDir.exists();
  
  L.retainWhere(
    (FileSystemEntity FSE) => !FSE.path.contains('packages')    
  );
  
  if (buildDirExists) await buildDir.delete(recursive: true);
  
  await buildDir.create();
  
  L.forEach(
    (FileSystemEntity FSE) {
      if (FSE is File) {
        _readFile(FSE, data);
      } else if (FSE is Directory) {
        final Directory CD = new Directory(FSE.path.replaceFirst('lib', 'build'));
        
        CD.createSync();
      }
    }
  );
}

Future _readFile(File F, List<Map<String, String>> data) async {
  if (F.path.split('.').last.toLowerCase() == 'dart') {
    final String codeBody = await F.readAsString();
    final RegExp exp = new RegExp(r"@Skin\('[^']+'\)");
    final RegExp exp2 = new RegExp(r"{");
    final Iterable<Match> matches = exp.allMatches(codeBody);
    final File FC = await F.copy(F.path.replaceFirst('lib', 'build'));
    
    if ((matches != null) && matches.isNotEmpty) {
      final String skin = codeBody.substring(matches.first.start + 7, matches.first.end - 2);
      final Map<String, String> codeToInject = data.firstWhere(
        (Map<String, String> entry) => entry['xml'] == skin,
        orElse: () => null
      );
      final String beforeSkin = codeBody.substring(0, matches.first.start);
      final String afterSkin = codeBody.substring(matches.first.end);
      final String updatedCodeBody = beforeSkin + afterSkin.replaceFirst(exp2, '{${new String.fromCharCode(10)}${new String.fromCharCode(9)}${codeToInject['code']}');
      
      await FC.writeAsString(updatedCodeBody);
    }
  }
}