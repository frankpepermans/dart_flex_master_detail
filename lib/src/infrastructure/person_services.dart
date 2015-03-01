part of infrastructure;

abstract class IPersonService {
  
  Future<ObservableList<Person>> getPersons();
  
}

class MockPersonService implements IPersonService {
  
  Future<ObservableList<Person>> getPersons() {
    const int count = 10000;
    final Completer<List<String>> C1 = new Completer<List<String>>(), C2 = new Completer<List<String>>(), C3 = new Completer<List<String>>();
    final Completer<ObservableList<Person>> waitCompleter = new Completer<ObservableList<Person>>();
    
    HttpRequest.getString('first_names.txt').then(
      (String content) => C1.complete(content.split(new String.fromCharCode(10)))
    );
    
    HttpRequest.getString('last_names.txt').then(
      (String content) => C2.complete(content.split(new String.fromCharCode(10)))
    );
    
    HttpRequest.getString('countries.txt').then(
      (String content) => C3.complete(content.split(new String.fromCharCode(10)))
    );
    
    Future.wait([C1.future, C2.future, C3.future]).then(
      (List<List<String>> R) {
        final ObservableList<Person> L = new ObservableList<Person>();
        final Random rand = new Random();
        final List<String> firstNames = R[0], lastNames = R[1], nationalities = R[2];
        
        for (int i=0; i<count; i++) L.add(
            new Person()
              ..firstName = firstNames[rand.nextInt(firstNames.length)]
              ..lastName = lastNames[rand.nextInt(lastNames.length)]
              ..nationality = nationalities[rand.nextInt(nationalities.length)]
              ..dateOfBirth = new DateTime.utc(1920 + rand.nextInt(80), rand.nextInt(12), rand.nextInt(31))
        );
        
        waitCompleter.complete(L);
      }
    );
    
    return waitCompleter.future;
  }
  
}