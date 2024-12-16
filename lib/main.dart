import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const NoteApp());
}

class NoteApp extends StatelessWidget {
  const NoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notes',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const NoteHomePage(),
    );
  }
}

class NoteHomePage extends StatefulWidget {
  const NoteHomePage({super.key});

  @override
  State<NoteHomePage> createState() => _NoteHomePageState();
}

class _NoteHomePageState extends State<NoteHomePage> {
  late Future<List<String>> _notesFuture;
  final List<String> _notes = [];
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredNotes = [];

  @override
  void initState() {
    super.initState();
    _notesFuture = _loadNotes();
    _searchController.addListener(_filterNotes);
  }

  Future<List<String>> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notes = prefs.getStringList('notes') ?? [];
    setState(() {
      _notes.addAll(notes);
      _filteredNotes = List.from(notes);
    });
    return notes;
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('notes', _notes);
  }

  void _addOrEditNoteDialog([int? index]) {
    _controller.text = index == null ? '' : _notes[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? 'Add Note' : 'Edit Note'),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: 'Write your note here'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                setState(() {
                  if (index == null) {
                    _notes.add(_controller.text);
                  } else {
                    _notes[index] = _controller.text;
                  }
                  _filteredNotes = List.from(_notes);
                });
                _saveNotes();
                Navigator.pop(context);
              }
            },
            child: Text(index == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteNoteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _notes.removeAt(index);
                _filteredNotes = List.from(_notes);
              });
              _saveNotes();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _notes
          .where((note) => note.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        centerTitle: true,
        scrolledUnderElevation: 4.0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading notes'));
          } else if (_filteredNotes.isEmpty) {
            return const Center(
              child: Text(
                'No notes yet. Add one!',
                style: TextStyle(fontSize: 18),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: _filteredNotes.length,
              itemBuilder: (context, index) => Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                child: ListTile(
                  title: Text(
                    _filteredNotes[index],
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                        onPressed: () => _addOrEditNoteDialog(
                            _notes.indexOf(_filteredNotes[index])),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                        onPressed: () => _deleteNoteDialog(
                            _notes.indexOf(_filteredNotes[index])),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNoteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
