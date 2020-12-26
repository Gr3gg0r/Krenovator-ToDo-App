import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() => runApp(KrenovatorApp());

class KrenovatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primaryColor: Colors.green, accentColor: Colors.lightGreenAccent),
      title: "Krenovator Simple TodoApp",
      home: CloudInit(),
    );
  }
}

class CloudInit extends StatelessWidget {

  Widget loadingScreen(){
    return  Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future<void> initializeDefault() async {
    FirebaseApp app = await Firebase.initializeApp();
    assert(app != null);
    print('Initialized default app $app');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initializeDefault(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return loadingScreen();
        else if(snapshot.connectionState == ConnectionState.done)
          return HomePage();
        else
          return loadingScreen();
      },
    );
  }
}

class HomePage extends StatelessWidget {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("To Do App"),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _firestore.collection("Categories").snapshots(),
        builder: (BuildContext context , AsyncSnapshot<QuerySnapshot> snapshot){
          if(snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator(),);
          return ListView(
            children: snapshot.data.docs.map((DocumentSnapshot snapshot){
              return Card(
                child: ListTile(
                  title: Text("${snapshot.data()['Categories']}"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete,color: Colors.red,),
                    onPressed:() => _firestore.collection("Categories").doc("${snapshot.id}").delete(),
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (BuildContext context) => CategoryHome(title: snapshot.data()['Categories'],)
                  )),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => AddCategory())),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddCategory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text("Add Category"),
        centerTitle: true,
      ),
      body: AddCategoryForm(),
    );
  }
}

class AddCategoryForm extends StatefulWidget {

  @override
  _AddCategoryFormState createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends State<AddCategoryForm> {
  final _fromkey = GlobalKey<FormState>();

  String category;

  bool loading=false;

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _addData(context){
    if(_fromkey.currentState.validate()){
      setState(() {
        loading = true;
      });
      _firestore.collection("Categories").add({
        "Categories" : category
      }).then((value) => Navigator.pop(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double high = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    return Form(
      key: _fromkey,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "e.g Groceries",
                    labelText: "Category",
                    prefixIcon: Icon(Icons.list)),
                validator: (val) {
                  return val.isEmpty ? "Please enter valid text" : null;
                },
                onChanged: (val) => category = val,
              ),
              SizedBox(
                height: high * 0.05,
              ),
              Container(
                width: width * 0.9,
                height: high * 0.07,
                child: !loading?RaisedButton(
                  color: Colors.greenAccent,
                  child: Text(
                    "Confirm",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () => _addData(context),
                ):Center(child: CircularProgressIndicator(),),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryHome extends StatelessWidget {
  final String title;
  CategoryHome({this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      floatingActionButton:FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (BuildContext context) =>
        )),
      ),
    );
  }
}

class AddNotes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
