import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:firedart/firedart.dart';

const apiKey = 'AIzaSyBFmAjLXBZRaCh9Ns3nb9gFsgntIZFPBqM';
const projectId = 'my-shoppy-cirrt';

void main() {
  Firestore.initialize(projectId);
  runApp(ShoppingListApp());
}

class ShoppingListApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ShoppingList(),
    );
  }
}

class ShoppingList extends StatefulWidget {
  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  final List<String> _items = [];
  final List<String> _checkedItems = [];
  late SharedPreferences _preferences;
  TextEditingController _textEditingController = TextEditingController();
  String _currentItem = '';
  CollectionReference groceryCollection =
      Firestore.instance.collection('articles');

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  _loadItems() async {
    _preferences = await SharedPreferences.getInstance();
    final savedItems = _preferences.getStringList('items');
    if (savedItems != null) {
      setState(() {
        _items.addAll(savedItems);
      });
    }
  }

  _saveItems() {
    _preferences.setStringList('items', _items);
  }

  void _addItem(String item) {
    setState(() {
      _items.add(item);
      _saveItems();
      _textEditingController.clear();
    });
  }

  void _checkItem(String item) {
    setState(() {
      _items.remove(item);
      _checkedItems.add(item);
      _saveItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('myShoppy - Shopping List App'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TypeAheadField<String>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _textEditingController,
                      decoration: InputDecoration(labelText: 'Enter an item'),
                    ),
                    suggestionsCallback: (pattern) async {
                      // Return a list of suggestions based on the stored items
                      return _items
                          .where((item) => item
                              .toLowerCase()
                              .contains(pattern.toLowerCase()))
                          .toList();
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion),
                      );
                    },
                    onSuggestionSelected: (suggestion) {
                      _addItem(
                          suggestion); // Add the selected suggestion to the list
                      _textEditingController
                          .clear(); // Clear the text input field
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    final item = _textEditingController.text.trim();
                    if (item.isNotEmpty) {
                      _addItem(item);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _items.removeAt(oldIndex);
                  _items.insert(newIndex, item);
                  _saveItems();
                });
              },
              children: _items
                  .map(
                    (item) => ListTile(
                      key: Key(item),
                      title: Text(item),
                      onTap: () {
                        _checkItem(item);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          Divider(),
          Text('Checked Items:', style: TextStyle(fontSize: 18)),
          Expanded(
            child: ListView.builder(
              itemCount: _checkedItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _checkedItems[index],
                    style: TextStyle(decoration: TextDecoration.lineThrough),
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: () async {
              final groceries = await groceryCollection.get();
              print(groceries);
            },
            icon: Icon(Icons.nature),
          ),
        ],
      ),
    );
  }
}
