import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'localization.dart'; // Import your Localization class

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

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
        SnackBar(
          content: Text(
            Localization.translate("load_notes_error").replaceAll("{error}", e.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notes', json.encode(_notes));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localization.translate("save_notes_error").replaceAll("{error}", e.toString()),
          ),
        ),
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
        title: Text(Localization.translate("edit_note")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: Localization.translate("title_label"),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: Localization.translate("content_label"),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Localization.translate("cancel")),
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
            child: Text(Localization.translate("save")),
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
        title: Text(Localization.translate("add_note")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: Localization.translate("title_label"),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: Localization.translate("content_label"),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Localization.translate("cancel")),
          ),
          ElevatedButton(
            onPressed: _addNote,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(Localization.translate("save")),
          ),
        ],
      ),
    );
  }

  void _showNoteDetails(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _notes[index]['title']!.isEmpty
              ? Localization.translate("untitled_note")
              : _notes[index]['title']!,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _notes[index]['content']!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Text(
                Localization.translate("created_at")
                    .replaceAll("{date}", _notes[index]['date']!.substring(0, 16)),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Localization.translate("close")),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate("notes_title")),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: _notes.isEmpty
            ? Center(
          child: Text(
            Localization.translate("no_notes"),
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notes.length,
          itemBuilder: (context, index) {
            return Card(
              color: Theme.of(context).cardColor,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  _notes[index]['title']!.isEmpty
                      ? Localization.translate("untitled_note")
                      : _notes[index]['title']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      _notes[index]['content']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Localization.translate("created_at").replaceAll(
                          "{date}", _notes[index]['date']!.substring(0, 16)),
                      style: const TextStyle(
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
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editNote(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}