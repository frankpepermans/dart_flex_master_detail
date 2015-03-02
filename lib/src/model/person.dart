part of model;

class Person extends ChangeNotifier {
  
  @observable String firstName;
  @observable String lastName;
  @observable String nationality;
  @observable Job job;
  @observable Gender gender;
  @observable DateTime dateOfBirth;
  
  dynamic operator [](Symbol type) {
    if (type == #firstName) return firstName;
    else if (type == #lastName) return lastName;
    else if (type == #nationality) return nationality;
    else if (type == #job) return job;
    else if (type == #gender) return gender;
    else if (type == #dateOfBirth) return dateOfBirth;
    
    return null;
  }
  
  void operator []=(Symbol type, dynamic value) {
    if (type == #firstName) firstName = value;
    else if (type == #lastName) lastName = value;
    else if (type == #nationality) nationality = value;
    else if (type == #job) job = value;
    else if (type == #gender) gender = value;
    else if (type == #dateOfBirth) dateOfBirth = value;
    
    return null;
  }
  
}