import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grocery_list_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(GroceryApp());
}

class GroceryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery List',
      theme: ThemeData(primarySwatch: Colors.green),
      home: GroceryListScreen(),
    );
  }
}

class GroceryListScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference groceries = FirebaseFirestore.instance.collection('groceries');

  void _addItem() {
    if (_controller.text.isNotEmpty) {
      groceries.add({
        'name': _controller.text,
        'purchased': false,
        'dateAdded': Timestamp.now(),
      });
      _controller.clear();
    }
  }

  void _togglePurchased(DocumentSnapshot doc) {
    bool newStatus = !doc['purchased'];
    groceries.doc(doc.id).update({
      'purchased': newStatus,
      'purchaseDate': newStatus ? Timestamp.now() : null,
    });
  }

  void _deleteItem(String id) {
    groceries.doc(id).delete();
  }

  void _editItem(DocumentSnapshot doc, BuildContext context) {
    TextEditingController editController = TextEditingController(text: doc['name']);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Item"),
          content: TextField(controller: editController),
          actions: [
            TextButton(
              onPressed: () {
                if (editController.text.isNotEmpty) {
                  groceries.doc(doc.id).update({'name': editController.text});
                }
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Grocery List')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: groceries.orderBy('purchased', descending: true).orderBy('dateAdded', descending: false).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final items = snapshot.data!.docs;

                return ListView(
                  children: items.map((doc) {
                    Timestamp? dateAdded = doc['dateAdded'];
                    String formattedDate = dateAdded != null
                        ? DateTime.fromMillisecondsSinceEpoch(dateAdded.millisecondsSinceEpoch).toString().split(' ')[0]
                        : 'Unknown';

                    return ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc['name'],
                            style: TextStyle(
                              fontSize: 18, // Larger font
                              fontWeight: FontWeight.bold,
                              decoration: doc['purchased'] ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                          Text(
                            "Added: $formattedDate",
                            style: TextStyle(fontSize: 12, color: Colors.grey), // Smaller font for date
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: doc['purchased'],
                            onChanged: (value) => _togglePurchased(doc),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editItem(doc, context),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem(doc.id),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: 'Add Item'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addItem,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
