import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodoListScreen(),
    );
  }
}

class Todo {
  String id;
  String title;
  String category;
  bool isCompleted;

  Todo({
    required this.id,
    required this.title,
    required this.category,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'isCompleted': isCompleted,
  };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'],
    title: json['title'],
    category: json['category'],
    isCompleted: json['isCompleted'],
  );
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  void _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todosJson = prefs.getString('todos');
    if (todosJson != null) {
      final List<dynamic> decodedJson = json.decode(todosJson);
      setState(() {
        _todos = decodedJson.map((item) => Todo.fromJson(item)).toList();
        _filteredTodos = List.from(_todos);
      });
    }
  }

  void _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedJson = json.encode(_todos.map((e) => e.toJson()).toList());
    await prefs.setString('todos', encodedJson);
  }

  void _addTodo(Todo todo) {
    setState(() {
      _todos.add(todo);
      _filteredTodos = List.from(_todos);
      _saveTodos();
    });
  }

  void _updateTodo(Todo todo) {
    setState(() {
      final index = _todos.indexWhere((element) => element.id == todo.id);
      if (index != -1) {
        _todos[index] = todo;
        _filteredTodos = List.from(_todos);
        _saveTodos();
      }
    });
  }

  void _deleteTodo(String id) {
    setState(() {
      _todos.removeWhere((element) => element.id == id);
      _filteredTodos = List.from(_todos);
      _saveTodos();
    });
  }

  void _filterTodos() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredTodos = List.from(_todos);
      } else {
        _filteredTodos = _todos
            .where((todo) =>
        todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            todo.category.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }
    });
  }

  void _showAddTodoBottomSheet({Todo? todo}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: todo?.title ?? '');
    final categoryController = TextEditingController(text: todo?.category ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final newTodo = Todo(
                          id: todo?.id ?? DateTime.now().toString(),
                          title: titleController.text,
                          category: categoryController.text,
                          isCompleted: todo?.isCompleted ?? false,
                        );
                        if (todo == null) {
                          _addTodo(newTodo);
                        } else {
                          _updateTodo(newTodo);
                        }
                        Navigator.pop(context);
                      }
                    },
                    child: Text(todo == null ? 'Add Todo' : 'Update Todo'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterTodos();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTodos.length,
              itemBuilder: (context, index) {
                final todo = _filteredTodos[index];
                return ListTile(
                  title: Text(todo.title),
                  subtitle: Text(todo.category),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: todo.isCompleted,
                        onChanged: (bool? value) {
                          setState(() {
                            todo.isCompleted = value!;
                            _updateTodo(todo);
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteTodo(todo.id),
                      ),
                    ],
                  ),
                  onTap: () => _showAddTodoBottomSheet(todo: todo),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoBottomSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
}