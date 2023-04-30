import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:developer' as devtools show log;

extension Log on Object {
  void log() => devtools.log(toString());
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider(
        create: (_) => PersonBloc(),
        child: const MyHomePage(title: 'My First Flutter App'),
      ),
    );
  }
}

@immutable
abstract class LoadAction {
  const LoadAction();
}

class LoadPersonAction implements LoadAction {
  final PersonUrl url;

  const LoadPersonAction({required this.url}) : super();
}

enum PersonUrl { user, todo }

extension UrlString on PersonUrl {
  String get urlString {
    switch (this) {
      case PersonUrl.user:
        return "https://jsonplaceholder.typicode.com/users";
      case PersonUrl.todo:
        return "https://jsonplaceholder.typicode.com/todos";
    }
  }
}

@immutable
class Person {
  final String name;
  final String email;

  const Person({required this.name, required this.email});

  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        email = json['email'] as String;

  @override
  String toString() => 'Person (name: $name, email: $email';
}

Future<Iterable<Person>> getPersons(String url) => HttpClient()
    .getUrl(Uri.parse(url))
    .then((req) => req.close())
    .then((resp) => resp.transform(utf8.decoder).join())
    .then((str) => json.decode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));

@immutable
class FetchResult {
  final Iterable<Person> persons;
  final bool isRetrivedFromCache;

  const FetchResult({
    required this.persons,
    required this.isRetrivedFromCache,
  });

  @override
  String toString() =>
      'FetchResult (isRetrivedFromCache = $isRetrivedFromCache, persons = $persons';
}

class PersonBloc extends Bloc<LoadAction, FetchResult?> {
  final Map<PersonUrl, Iterable<Person>> _cache = {};

  PersonBloc() : super(null) {
    on<LoadPersonAction>((event, emit) async {
      final url = event.url;
      if (_cache.containsKey(url)) {
        // we have the cached value
        final cachedPersons = _cache[url]!;
        final result =
            FetchResult(persons: cachedPersons, isRetrivedFromCache: true);
        emit(result);
      } else {
        final persons = await getPersons(url.urlString);
        _cache[url] = persons;
        final result =
            FetchResult(persons: persons, isRetrivedFromCache: false);
        emit(result);
      }
    });
  }
}

extension Subscript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    context
                        .read<PersonBloc>()
                        .add(const LoadPersonAction(url: PersonUrl.user));
                  },
                  child: const Text('Load User'),
                ),
                TextButton(
                  onPressed: () {
                    context
                        .read<PersonBloc>()
                        .add(const LoadPersonAction(url: PersonUrl.todo));
                  },
                  child: const Text('Load Todo'),
                ),
              ],
            ),
            BlocBuilder<PersonBloc, FetchResult?>(
              buildWhen: (previousResult, currentRestult) {
                return previousResult?.persons != currentRestult?.persons;
              },
              builder: ((context, fetchResult) {
                fetchResult?.log();
                final persons = fetchResult?.persons;
                if (persons == null) {
                  return SizedBox();
                }
                return ListView.builder(
                    shrinkWrap: true,
                    itemCount: persons.length,
                    itemBuilder: (context, index) {
                      final person = persons[index]!;
                      return ListTile(
                        title: Text(
                          person.name,
                        ),
                      );
                    });
              }),
            )
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
