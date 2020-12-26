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
  Widget loadingScreen() {
    return Scaffold(
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
        else if (snapshot.connectionState == ConnectionState.done)
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
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(
              child: CircularProgressIndicator(),
            );
          return ListView(
            children: snapshot.data.docs.map((DocumentSnapshot snapshot) {
              return Card(
                child: ListTile(
                  title: Text("${snapshot.data()['Categories']}"),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () => _firestore
                        .collection("Categories")
                        .doc("${snapshot.id}")
                        .delete(),
                  ),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => CategoryHome(
                                title: snapshot.data()['Categories'],
                                catId: snapshot.id,
                              ))),
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

  bool loading = false;

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _addData(context) {
    if (_fromkey.currentState.validate()) {
      setState(() {
        loading = true;
      });
      _firestore.collection("Categories").add({"Categories": category}).then(
          (value) => Navigator.pop(context));
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
                child: !loading
                    ? RaisedButton(
                        color: Colors.greenAccent,
                        child: Text(
                          "Confirm",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () => _addData(context),
                      )
                    : Center(
                        child: CircularProgressIndicator(),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryHome extends StatefulWidget {
  final String title, catId;
  CategoryHome({this.title, this.catId});

  @override
  _CategoryHomeState createState() => _CategoryHomeState();
}

class _CategoryHomeState extends State<CategoryHome> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  child: RaisedButton(
                    child: Text("Notes"),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                AddNotes(widget.catId))),
                  ),
                ),
                Text(
                  'Or',
                  textAlign: TextAlign.center,
                ),
                Container(
                  width: double.infinity,
                  child: RaisedButton(
                    child: Text("List"),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                AddList(widget.catId))),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection("ToDo")
            .where('catId', isEqualTo: widget.catId)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(
              child: CircularProgressIndicator(),
            );
          return ListView(
            children: snapshot.data.docs.map((DocumentSnapshot snapshot) {
              bool types = snapshot.data()['type'] == "notes";
              return Card(
                  child: ListTile(
                title: Text("${snapshot.data()['title']}"),
                leading: CircleAvatar(
                  child: types
                      ? Icon(Icons.book)
                      : Icon(Icons.format_list_numbered_outlined),
                  backgroundColor: Colors.greenAccent,
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () => _firestore
                      .collection("ToDo")
                      .doc("${snapshot.id}")
                      .delete(),
                ),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) =>
                           types? ViewNotes(snapshot):ViewList(snapshot)
                    )
                ),
              ));
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add), onPressed: _showMyDialog),
    );
  }
}

class ViewNotes extends StatelessWidget {
  final DocumentSnapshot snapshot;
  ViewNotes(this.snapshot);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notes"),
        actions: [
          IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => EditNotes(snapshot))))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                title: Text("${snapshot.data()['title']}"),
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            Card(
              child: Container(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${snapshot.data()['content']}"),
                  )),
            )
          ],
        ),
      ),
    );
  }
}

class EditNotes extends StatefulWidget {
  final DocumentSnapshot snapshot;
  EditNotes(this.snapshot);
  @override
  _EditNotesState createState() => _EditNotesState();
}

class _EditNotesState extends State<EditNotes> {
  String title, content;

  final _formKey = GlobalKey<FormState>();

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _saveData() {
    _firestore.collection("ToDo").doc('${widget.snapshot.id}').update({
      "catId": widget.snapshot.data()['catId'],
      "type": widget.snapshot.data()['type'],
      "title": title ?? widget.snapshot.data()['title'],
      "content": content ?? widget.snapshot.data()['content'],
    }).then((value) {
      var routecount = 0;
      Navigator.popUntil(context, (route) {
        return routecount++ == 2;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Notes"),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: [
              TextFormField(
                onChanged: (val) => title = val,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "e.g Chemist",
                  labelText: "Title",
                  prefixIcon: Icon(Icons.note_add),
                ),
                initialValue: widget.snapshot.data()['title'],
              ),
              SizedBox(
                height: 10.0,
              ),
              TextFormField(
                initialValue: widget.snapshot.data()['content'],
                onChanged: (val) => content = val,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Start write here .....",
                  labelText: "Content",
                ),
                maxLines: null,
              ),
              SizedBox(
                height: 10.0,
              ),
              Container(
                height: 60.0,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RaisedButton(
                    color: Colors.lightGreenAccent,
                    child: Text("Save Changes"),
                    onPressed: _saveData,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AddNotes extends StatelessWidget {
  final String catId;
  AddNotes(this.catId);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Notes"),
        centerTitle: true,
      ),
      body: AddNoteContent(catId),
    );
  }
}

class AddNoteContent extends StatelessWidget {
  final String catId;
  AddNoteContent(this.catId);

  String title, content;

  final _formKey = GlobalKey<FormState>();

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _addData(context) {
    if (_formKey.currentState.validate()) {
      _firestore.collection("ToDo").add({
        "catId": catId,
        "type": "notes",
        "title": title,
        "content": content,
      }).then((value) => Navigator.pop(context));
      print(title + content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            TextFormField(
              onChanged: (val) => title = val,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "e.g Chemist",
                labelText: "Title",
                prefixIcon: Icon(Icons.note_add),
              ),
              validator: (val) {
                return val.isEmpty ? "Title is required" : null;
              },
            ),
            SizedBox(
              height: 10.0,
            ),
            TextFormField(
              onChanged: (val) => content = val,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Start write here .....",
                labelText: "Content",
              ),
              maxLines: null,
            ),
            SizedBox(
              height: 10.0,
            ),
            Container(
              height: 60.0,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: RaisedButton(
                  color: Colors.lightGreenAccent,
                  child: Text("Add Notes"),
                  onPressed: () => _addData(context),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class AddList extends StatefulWidget {
  final String catId;
  AddList(this.catId);

  @override
  _AddListState createState() => _AddListState();
}

class _AddListState extends State<AddList> {
  final _formKey = GlobalKey<FormState>();
  String title;
  bool loading = false;

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _addData() {
    if (_formKey.currentState.validate()) {
      setState(() {
        loading = true;
      });
      _firestore
          .collection("ToDo")
          .add({"title": title, "type": "list", "catId": widget.catId}).then(
              (value) => Navigator.pop(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add List"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "List Title",
                      hintText: "e.g. Goods List",
                      prefixIcon: Icon(Icons.done)),
                  validator: (val) {
                    return val.isEmpty ? "Title is required" : null;
                  },
                  onChanged: (val) => title = val,
                ),
                SizedBox(
                  height: 10.0,
                ),
                Container(
                  width: double.infinity,
                  height: 40,
                  child: !loading
                      ? RaisedButton(
                          child: Text("Submit"),
                          color: Colors.greenAccent,
                          onPressed: _addData,
                        )
                      : Center(
                          child: CircularProgressIndicator(),
                        ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ViewList extends StatefulWidget {
  final DocumentSnapshot snapshot;
  ViewList(this.snapshot);

  @override
  _ViewListState createState() => _ViewListState();
}

class _ViewListState extends State<ViewList> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  String item;

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('AddItem'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Form(
                  key: _formKey,
                  child: Container(
                    width: double.infinity,
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Add Task",
                        hintText: "e.g. Lemon",
                      ),
                      onChanged: (val) => item = val,
                      validator: (val) {
                        return val.isEmpty ? "Please enter something" : null;
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('ADD'),
              onPressed: () {
                if(_formKey.currentState.validate()){
                  _firestore.collection("ListItem").add({
                    "item" : item,
                    "listId" : widget.snapshot.id,
                    "complete" : false
                  }).then((value) => Navigator.pop(context));
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("List Content"),
      ),
      body: Column(
        children: [
          Card(
              child: ListTile(
                title: Text("${widget.snapshot.data()['title']}"),
              ),
          ),
          SizedBox(height: 15,),
          Container(child: Text("List Item", )),
          SizedBox(height: 15,),
          Expanded(child: StreamBuilder(
            stream: _firestore.collection("ListItem").where("listId",isEqualTo: widget.snapshot.id).snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
              if(snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator(),);
              return ListView(
                children: snapshot.data.docs.map((DocumentSnapshot snapshot){
                  return ListItem(snapshot: snapshot,);
                }).toList(),
              );
            },
          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _showMyDialog,
      ),
    );
  }
}


class ListItem extends StatefulWidget {

  final DocumentSnapshot snapshot;

  ListItem({this.snapshot});
  @override
  _ListItemState createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  
  FirebaseFirestore _firestore=  FirebaseFirestore.instance;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text("${widget.snapshot.data()['item']}",
        style: TextStyle(
          decoration: widget.snapshot.data()["complete"] ? TextDecoration.lineThrough : TextDecoration.none,
          color: widget.snapshot.data()["complete"]? Colors.greenAccent : Colors.black
        ),
        ),
        onTap: ()=>_firestore.collection("ListItem").doc(widget.snapshot.id).update({
          "complete": !widget.snapshot.data()["complete"]
        }),
      ),
    );
  }
}
