import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TextEntryPage extends StatefulWidget {
  final String username;

  const TextEntryPage({super.key, required this.username});

  @override
  _TextEntryPageState createState() => _TextEntryPageState();
}

class _TextEntryPageState extends State<TextEntryPage> {
  final TextEditingController _textController = TextEditingController();
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTexts();
  }

  Future<void> _saveText() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xabarni kiriting')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://hbnnarzullayev.pythonanywhere.com/save_text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user': widget.username,
          'text': _textController.text,
          'author_text': 'uztools',
        }),
      );

      if (response.statusCode == 200) {
        _textController.clear();
        await _fetchTexts(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xabar muvaffaqqiyatli yuborildi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xabar yuborishda xatolik: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xabar yuborishda xatolik: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTexts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://hbnnarzullayev.pythonanywhere.com/fetch_texts/${widget.username}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _entries = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xabarlarni yuklashda xatolik: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xabarlarni yuklashda xatolik: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dasturchiga xabar yo'llash"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Telegramdan @hbn_company ga yozing',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveText,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Xabar yo'llash"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading && _entries.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    color: entry['author_text'] == widget.username
                        ? Colors.blue // Light green if this entry matches
                        : null, // Default card color if no match
                    child: ListTile(
                      title: Text(entry['text']),
                      subtitle: Text(
                        'ID: ${entry['id']} | Kimdan: ${entry['user']} | Kimga: ${entry['author_text']} | Vaqt: ${entry['time']} | ${entry['as_answer']}-xabarga javob',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}