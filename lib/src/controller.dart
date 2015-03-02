part of master_detail_example;

@htmlInjectable('dart-flex-controller')
@Skin('dart_flex_master_detail|master_detail_view.xml')
class Controller extends UIWrapperChangeNotifier with ChangeNotifier {
  
  @observable VGroup verticalContainer;
  @observable DataGrid grid;
  @observable List<Person> personList;
  
  Controller() : super() {
    final MockPersonService service = new MockPersonService();
    
    service.getPersons().then(
      (ObservableList<Person> persons) => personList = persons  
    );
  }
  
}