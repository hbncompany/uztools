import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, String>> _notes = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notesString = prefs.getString('notes');
      if (notesString != null && notesString.isNotEmpty) {
        setState(() {
          _notes = List<Map<String, String>>.from(
            (json.decode(notesString) as List).map((item) => Map<String, String>.from(item)),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Qoralamalarni yuklashda xatolik: $e')),
      );
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notes', json.encode(_notes));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving notes: $e')),
      );
    }
  }

  void _addNote() {
    if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty) {
      setState(() {
        _notes.add({
          'title': _titleController.text,
          'content': _contentController.text,
          'date': DateTime.now().toString(),
        });
      });
      _titleController.clear();
      _contentController.clear();
      _saveNotes().then((_) {
        Navigator.pop(context);
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _editNote(int index) {
    _titleController.text = _notes[index]['title']!;
    _contentController.text = _notes[index]['content']!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tahrirlash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Titul',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Matn',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notes[index] = {
                  'title': _titleController.text,
                  'content': _contentController.text,
                  'date': _notes[index]['date']!, // Preserve original date
                };
              });
              _titleController.clear();
              _contentController.clear();
              _saveNotes().then((_) {
                Navigator.pop(context);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _deleteNote(int index) {
    setState(() {
      _notes.removeAt(index);
    });
    _saveNotes();
  }

  void _showAddNoteDialog() {
    _titleController.clear();
    _contentController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Yanqi qoralama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Titul',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Matn',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: _addNote,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNoteDetails(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_notes[index]['title']!.isEmpty ? 'Untitled' : _notes[index]['title']!),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _notes[index]['content']!,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Yaratilgan: ${_notes[index]['date']!.substring(0, 16)}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Yopish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Qoralamalarim'),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: _notes.isEmpty
            ? Center(
          child: Text(
            "Hali qoralamalaringiz yo'q. Yangi qo'shing!",
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        )
            : ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _notes.length,
          itemBuilder: (context, index) {
            return Card(
              color: Theme.of(context).cardColor,
              elevation: 2,
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  _notes[index]['title']!.isEmpty
                      ? 'Untitled'
                      : _notes[index]['title']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      _notes[index]['content']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Yaratilgan: ${_notes[index]['date']!.substring(0, 16)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showNoteDetails(index),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editNote(index),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteNote(index),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        backgroundColor: Colors.orange,
        child: Icon(Icons.add),
      ),
    );
  }
}