import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//Code examples from https://medium.com/the-web-tub/making-a-todo-app-with-flutter-5c63dab88190

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(new ToDoApp());
}

class ToDoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(title: 'ToDo List', home: new ToDoList());
  }
}

class ToDoList extends StatefulWidget {
  @override
  createState() => new ToDoListState();
}

class ToDoListState extends State<ToDoList> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Todo List')),
      body: _buildTodoList(),
      floatingActionButton: new FloatingActionButton(
          onPressed:
              _pushAddTodoScreen, // pressing this button now opens the new screen
          tooltip: 'Add task',
          child: new Icon(Icons.add)),
    );
  }

  // This will be called each time the + button is pressed
  void _addTodoItem(String task) {
    CollectionReference todos = FirebaseFirestore.instance.collection('todos');

    // Only add the task if the user actually entered something
    if (task.length > 0) {
      todos.add({'description': task});
    }
  }

  //Show an alert dialog asking if the user wants to update the task or mark it as done
  void _promptUpdateOrRemoveItem(DocumentSnapshot document) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
              title: new Text('Do you want to update or delete the todo item?'),
              actions: <Widget>[
                new TextButton(
                    child: new Text('UPDATE'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      //Move to the screen to update the todo
                      _pushUpdateTodoScreen(document);
                    }),
                new TextButton(
                    child: new Text('DELETE'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      //Popup the dialog to confirm marking the to do as done
                      _promptRemoveTodoItem(document);
                    })
              ]);
        });
  }

  // Show an alert dialog asking the user to confirm that the task is done
  void _promptRemoveTodoItem(DocumentSnapshot document) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
              title: new Text('Do you want to delete the todo: "' +
                  document['description'].toString() +
                  '"?'),
              actions: <Widget>[
                new TextButton(
                    child: new Text('CANCEL'),
                    onPressed: () => Navigator.of(context).pop()),
                new TextButton(
                    child: new Text('CONFIRM'),
                    onPressed: () {
                      document.reference.delete();
                      Navigator.of(context).pop();
                    })
              ]);
        });
  }

  // Build the whole list of todo items
  Widget _buildTodoList() {
    CollectionReference todos = FirebaseFirestore.instance.collection('todos');
    return new StreamBuilder(
        stream: todos.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading");
          }
          return new ListView.builder(
            itemCount: snapshot.data.docs.length,
            itemBuilder: (context, index) =>
                _buildTodoItem(snapshot.data.docs[index], index),
          );
        });
  }

  // Build a single todo item
  Widget _buildTodoItem(DocumentSnapshot document, int index) {
    return new ListTile(
        title: new Text(document['description']),
        onTap: () => _promptUpdateOrRemoveItem(document));
  }

  void _pushAddTodoScreen() {
    // Push this page onto the stack
    Navigator.of(context).push(
        // MaterialPageRoute will automatically animate the screen entry, as well
        // as adding a back button to close it
        new MaterialPageRoute(builder: (context) {
      return new Scaffold(
          appBar: new AppBar(title: new Text('Add a new task')),
          body: new TextField(
            autofocus: true,
            onSubmitted: (val) {
              _addTodoItem(val);
              Navigator.pop(context); // Close the add todo screen
            },
            decoration: new InputDecoration(
                hintText: 'Enter something to do...',
                contentPadding: const EdgeInsets.all(16.0)),
          ));
    }));
  }

  //push the update todo screen
  void _pushUpdateTodoScreen(DocumentSnapshot document) {
    // Push this page onto the stack
    Navigator.of(context).push(
        // MaterialPageRoute will automatically animate the screen entry, as well
        // as adding a back button to close it
        new MaterialPageRoute(builder: (context) {
      return new Scaffold(
          appBar: new AppBar(title: new Text('Update this ToDo')),
          body: new TextField(
            autofocus: true,
            controller: TextEditingController()
              ..text = document['description'].toString(),
            onSubmitted: (val) {
              _updateToDo(document, val);
              Navigator.pop(context); // Close the udpate todo screen
            },
          ));
    }));
  }

  void _updateToDo(DocumentSnapshot document, String val) {
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot freshSnap = await transaction.get(document.reference);
      transaction.update(freshSnap.reference, {
        'description': val,
      });
    });
  }
}
