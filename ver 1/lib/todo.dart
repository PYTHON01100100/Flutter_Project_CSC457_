// todo.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'auth_service.dart';

class SignInPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  User? user = await _authService.signInWithEmailAndPassword(
                    _emailController.text,
                    _passwordController.text,
                  );
                  if (user != null) {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => ToDoList()));
                  }
                } on FirebaseAuthException catch (e) {
                  final snackBar = SnackBar(
                    content: Text('Log in failed !!', style: TextStyle(color: Colors.red)),
                    backgroundColor: Colors.white,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              },
              child: Text('Sign In'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignUpPage()));
              },
              child: Text('Don\'t have an account? Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}





class SignUpPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  User? user = await _authService.signUpWithEmailAndPassword(
                    _emailController.text,
                    _passwordController.text,
                  );
                  if (user != null) {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => ToDoList()));
                  }
                } on FirebaseAuthException catch (e) {
                  final snackBar = SnackBar(content: Text(e.message ?? 'An error occurred'));
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              },
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}




class ToDoList extends StatefulWidget {
  const ToDoList({Key? key}) : super(key: key);

  @override
  _ToDoListState createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  final TextEditingController _textFieldController = TextEditingController();
  final AuthService _authService = AuthService();
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('todos');

  List<Map<String, dynamic>> _toDoList = [];

  @override
  void initState() {
    super.initState();
    _listenToDatabase();
  }

  void _listenToDatabase() {
    User? user = _authService.getCurrentUser();
    if (user != null) {
      _databaseRef.child(user.uid).onValue.listen((event) {
        final todosData = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _toDoList = todosData.entries.map((e) => {'key': e.key, 'text': e.value}).toList();
        });
      });
    }
  }

  void _addToDoItem(String task) {
    User? user = _authService.getCurrentUser();
    if (user != null && task.isNotEmpty) {
      _databaseRef.child(user.uid).push().set(task);
      _textFieldController.clear();
    }
  }

  void _removeToDoItem(int index) {
    User? user = _authService.getCurrentUser();
    if (user != null) {
      _databaseRef.child(user.uid).child(_toDoList[index]['key']).remove();
    }
  }

  Widget _buildToDoItem(Map<String, dynamic> toDoItem, int index) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(toDoItem['text']),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeToDoItem(index),
        ),
      ),
    );
  }

  void _showAddToDoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a New Task'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: 'Enter task here'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                _addToDoItem(_textFieldController.text);
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return SignInPage(); // Show sign-in page if user is not signed in
          }
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Tasks'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: () async {
                    await _authService.signOut();
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => SignInPage()));
                  }, // Sign out action
                ),
              ],
            ),
            body: ListView.builder(
              itemBuilder: (context, index) {
                if (index < _toDoList.length) {
                  return _buildToDoItem(_toDoList[index], index);
                }
                return Container();
              },
              itemCount: _toDoList.length,
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddToDoDialog(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Task', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return Scaffold(
          body: Center(child: CircularProgressIndicator()), // Show loading indicator while checking auth state
        );
      },
    );
  }
}