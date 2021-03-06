// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;

final String buildDirName = 'web_transformed';
final Random rand = new Random();
final int portNum = rand.nextInt(10) + 8090;

Process startupProcess;

void main(List<String> args) {
  var parser = new ArgParser()
      ..addOption('port', abbr: 'p', defaultsTo: '8089');

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
  
  Process.start('C:\\dart\\dart-sdk\\bin\\pub.bat', <String>['serve', '--port=8082', '--mode=debug', 'web'], workingDirectory: Directory.current.path).then(
    (Process P) {
      startupProcess = P;
    
      Process.runSync('C:\\dart\\chromium\\chrome.exe', <String>['http://localhost:8082/test_transform.html']);
    }
  );
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

void _makeBuildTarget(List<Map<String, String>> data) {
  final Directory libDir = Directory.current;
  final Directory buildDir = new Directory.fromUri(Uri.parse(buildDirName));
  final List<FileSystemEntity> L = libDir.listSync(recursive: true);
  final bool buildDirExists = buildDir.existsSync();
  
  L.retainWhere(
    (FileSystemEntity FSE) {
      if (
          FSE.path.contains(buildDirName) ||
          FSE.path.contains('packages') || 
          FSE.path.contains('.git') || 
          FSE.path.contains('.pub')
      ) return false;
    
      return true;
    }
  );
  
  if (buildDirExists) buildDir.deleteSync(recursive: true);
  
  buildDir.createSync();
  
  L.forEach(
    (FileSystemEntity FSE) {
      if (FSE is File) {print(FSE.path);
        _readFile(FSE, data);
      } else if (FSE is Directory) {
        final Directory CD = new Directory(_getBuildPath(FSE.path, Directory.current.path));
        
        CD.createSync();
      }
    }
  );
  
  
  final bool isStopped = startupProcess.kill();
  final String generatedDir = _getBuildPath(Directory.current.path, Directory.current.path);
  
  Process.start('C:\\dart\\dart-sdk\\bin\\pub.bat', <String>['serve', '--port=8083', '--mode=debug', 'web'], workingDirectory: generatedDir).then(
    (Process P) => Process.runSync('C:\\dart\\chromium\\chrome.exe', <String>['http://localhost:8083/index.html'])  
  );
}

String _getBuildPath(String fromPath, String dirPath) => fromPath.replaceFirst(dirPath, '$dirPath\\$buildDirName');

void _readFile(File F, List<Map<String, String>> data) {
  if (F.path.split('.').last.toLowerCase() == 'dart') {
    final String codeBody = F.readAsStringSync();
    final RegExp exp = new RegExp(r"@Skin\('[^']+'\)");
    final RegExp exp2 = new RegExp(r"{");
    final Iterable<Match> matches = exp.allMatches(codeBody);
    final File FC = F.copySync(_getBuildPath(F.path, Directory.current.path));
    
    if ((matches != null) && matches.isNotEmpty) {
      final String skin = codeBody.substring(matches.first.start + 7, matches.first.end - 2);
      final Map<String, String> codeToInject = data.firstWhere(
        (Map<String, String> entry) => entry['xml'] == skin,
        orElse: () => null
      );
      final String beforeSkin = codeBody.substring(0, matches.first.start);
      final String afterSkin = codeBody.substring(matches.first.end);
      final String updatedCodeBody = beforeSkin + afterSkin.replaceFirst(exp2, '{${new String.fromCharCode(10)}${new String.fromCharCode(9)}${codeToInject['code']}');
      
      FC.writeAsStringSync(updatedCodeBody);
    }
  } else F.copySync(_getBuildPath(F.path, Directory.current.path));
}