const age = 29;
const totalAge = age * 2;

String getFullName(String fName, String lName) {
  return '$fName $lName';
}

class Person {
  final String name;
  Person(this.name);

  void printName() {
    print(name);
  }
}

class Car extends Person {
  Car(super.name);
}

extension Run on Person {
  void run() {
    print('$name is running');
  }
}

Future<int> heavyFutureMulitply(int a) {
  return Future.delayed(const Duration(seconds: 2), () => a * 2);
}

void test() async {
  final result = await heavyFutureMulitply(10);
  print(result);
  final person = Car('Joney spark');
  person.run();
}
