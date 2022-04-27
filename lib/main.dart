import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:async/async.dart' show StreamGroup;

import 'dart:developer' as devtools show log;

import 'package:flutter/material.dart';

extension Log on Object {
  void log() => devtools.log(toString());
}

/* for this purpose I used "Live Server" extension for "VSCode" and instead of using live server load the names from the "api" folder which contains a json file as a hard coded json object. so press
"cmd + shift + p" on mac or "ctrl + shift + p" on windows or linux and type live server and select on "open live server" and go to api/people.json, the url is your base url. (http://127.0.0.1:5500/api/people.json) */

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

@immutable
class Person {
  final String name;
  final int age;

  const Person({
    required this.name,
    required this.age,
  });

  Person.fromJson(Map<String, dynamic> json)
      : name = json["name"] as String,
        age = json["age"] as int;

  @override
  String toString() => "Person (name: $name, age: $age)";
}

/* our isolate main function, to send back the result object we pass the "SendPort" parameter here. sp.send() is our tunnel but it does not exit from the main function, so we pass the sp in Isolate.exit() and
pass the sp and our result. */
void _getPerson(SendPort sp) async {
  const url = "http://127.0.0.1:5500/api/people1.json";
  final persons = await HttpClient()
      .getUrl(Uri.parse(url))
      .then((req) => req.close())
      .then((res) => res.transform(utf8.decoder).join())
      .then((jsonString) => json.decode(jsonString) as List<dynamic>)
      .then((json) => json.map((element) => Person.fromJson(element)));
  Isolate.exit(
    sp,
    persons,
  );
}

/* our isolate enterance function, this function should setup our isolate and get the result and send the result back to it's caller. therefore here we have the ReceivePort and this receive port will use in
the function and say hey I'm the tunnel and will give you the responses from send port and it will return's streams. Receive port is Read/Write, but sent port is Write-Only. for receiving data from send port we should call Isolate.spawn()
method which gets from you a void function as first parameter(should be a void function), and for second parameter gives from you the message(data) which your first void function parameter accept's. */
Future<Iterable<Person>> getPerson() async {
  final rp = ReceivePort();
  Isolate.spawn(
    _getPerson,
    rp.sendPort,
  );
  return await rp.first;
}

/* our isolate main function, to send back the result object we pass the "SendPort" parameter here. sp.send() is our tunnel but it does not exit from the main function, so we pass the sp in Isolate.exit() and
pass the sp and our result. this Isolate.exit() works after 10 time that we defined and during this time sp.send(now) sending our date time to receive port. */
void _getMessage(SendPort sp) async {
  await for (final now in Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now().toIso8601String(),
  ).take(10)) {
    sp.send(now);
  }
  Isolate.exit(sp);
}

/* our isolate enterance function, this function should setup our isolate and get the result and send the result back to it's caller. therefore here we have the ReceivePort and this receive port will use in
the function and say hey I'm the tunnel and will give you the responses from send port and it will return's streams. Receive port is Read/Write, but sent port is Write-Only. for receiving data from send port we should call Isolate.spawn()
method which gets from you a void function as first parameter(should be a void function), and for second parameter gives from you the message(data) which your first void function parameter accept's.
for this example because of the function returns string of date time now, the Isolate.exit(sp) returns null, and we check the receive port until getting null value. */
Stream<String> getMessage() {
  final rp = ReceivePort();
  return Isolate.spawn(_getMessage, rp.sendPort)
      .asStream()
      .asyncExpand((_) => rp)
      .takeWhile((element) => element is String)
      .cast();
}

/* 3rd example */
@immutable
class Request {
  final SendPort sp;
  final Uri uri;
  const Request(
    this.sp,
    this.uri,
  );
  Request.fromPersonsRequest(PersonsRequest request)
      : sp = request.rp.sendPort,
        uri = request.uri;
}

void _getPeople(Request request) async {
  final persons = await HttpClient()
      .getUrl(request.uri)
      .then((req) => req.close())
      .then((res) => res.transform(utf8.decoder).join())
      .then((jsonString) => json.decode(jsonString) as List<dynamic>)
      .then((json) => json.map((element) => Person.fromJson(element)));
  // request.sp.send(persons);
  Isolate.exit(
    request.sp,
    persons,
  );
}

Stream<Iterable<Person>> getPeople() {
  final streams = PersonsRequest.all().map((req) =>
      Isolate.spawn(_getPeople, Request.fromPersonsRequest(req))
          .asStream()
          .asyncExpand((_) => req.rp)
          .takeWhile((element) => element is Iterable<Person>)
          .cast());

  return StreamGroup.merge(streams).cast();
}

/* we will create 3 times this persons request url */
@immutable
class PersonsRequest {
  final ReceivePort rp;
  final Uri uri;
  const PersonsRequest(
    this.rp,
    this.uri,
  );
  static Iterable<PersonsRequest> all() sync* {
    for (final i in Iterable.generate(3, (i) => i)) {
      yield PersonsRequest(
        ReceivePort(),
        Uri.parse("http://127.0.0.1:5500/api/people${i + 1}.json"),
      );
    }
  }
}

void tester() async {
  await for (final msg in getMessage()) {
    msg.log();
  }
  await for (final msg in getPeople()) {
    msg.log();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        centerTitle: true,
      ),
      body: TextButton(
        onPressed: () async {
          final person = await getPerson();
          person.log();
          tester();
        },
        child: const Text("Press"),
      ),
    );
  }
}
