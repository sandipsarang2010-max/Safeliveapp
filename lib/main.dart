import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' hide Context;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SafeStreamApp());
}

class SafeStreamApp extends StatelessWidget {
  const SafeStreamApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const MainNavigation(),
      );
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  final List<Widget> _pages = const [DashboardScreen(), DemoScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _pages[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: "Demo"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  CameraController? _controller;
  bool _isLive = false;
  bool _isInitialized = false;
  final bool _isSubscribed = false; 

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(cameras.first, ResolutionPreset.medium);
        await _controller!.initialize();
        if (mounted) setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  void _toggleLive(BuildContext context) {
    if (!_isSubscribed) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Subscription Required"),
          content: const Text("Please subscribe to activate live streaming features."),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
    } else {
      setState(() => _isLive = !_isLive);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("SafeStream AI")),
        body: Column(children: [
          Container(
            height: 220, margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black),
            child: Stack(children: [
              if (_isInitialized) CameraPreview(_controller!),
              Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Text(_isLive ? "● LIVE" : "● PREVIEW", style: TextStyle(color: _isLive ? Colors.red : Colors.white))),
            ]),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            const Text("Live Performance Metrics", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(children: [
              _metricCard("Latency", _isLive ? "25ms" : "--ms"),
              _metricCard("Stream Health", _isLive ? "Nominal" : "Check Status: -"),
            ]),
          ])),
        ]),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _toggleLive(context),
          child: Icon(_isLive ? Icons.stop : Icons.play_arrow),
        ),
      );

  Widget _metricCard(String title, String val) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Text(title, style: const TextStyle(fontSize: 10)), Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]))));
}

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});
  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  String _result = "Enter text to test moderation.";
  final List<String> _bannedWords = ['badword1', 'spam', 'hate', 'toxic'];

  void _runTest() {
    String input = _msgCtrl.text.toLowerCase();
    String? foundWord = _bannedWords.firstWhere((word) => input.contains(word), orElse: () => "");
    
    setState(() {
      _result = foundWord.isNotEmpty 
          ? "❌ Status: BLOCKED (Contains: $foundWord)" 
          : "✅ Status: ALLOWED (Content is safe)";
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Moderation Sandbox")),
        body: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [
          TextField(controller: _msgCtrl, decoration: const InputDecoration(hintText: "Type a chat message...", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _runTest, child: const Text("TEST MESSAGE")),
          const SizedBox(height: 20),
          Text(_result, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          const Text("Banned Keywords:", style: TextStyle(color: Colors.grey)),
          Text(_bannedWords.join(", ")),
        ])),
      );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  Future<Database> _getDb() async => openDatabase(join(await getDatabasesPath(), 'safestream.db'),
      onCreate: (db, v) => db.execute('CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, isBlocked INTEGER)'), version: 1);

  Future<void> _refreshUsers() async {
    final db = await _getDb();
    final data = await db.query('users');
    setState(() => _users = data);
  }

  Future<void> _addUser() async {
    if (_nameCtrl.text.isEmpty) return;
    final db = await _getDb();
    await db.insert('users', {'name': _nameCtrl.text, 'isBlocked': 0});
    _nameCtrl.clear();
    _refreshUsers();
  }

  Future<void> _toggleBlock(int id, int status) async {
    final db = await _getDb();
    await db.update('users', {'isBlocked': status == 0 ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
    _refreshUsers();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Manage Users")),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: "Add User..."))),
        IconButton(icon: const Icon(Icons.add), onPressed: _addUser),
      ])),
      Expanded(child: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (ctx, i) => ListTile(
          title: Text(_users[i]['name']),
          trailing: IconButton(
            icon: Icon(_users[i]['isBlocked'] == 1 ? Icons.block : Icons.person),
            color: _users[i]['isBlocked'] == 1 ? Colors.red : Colors.green,
            onPressed: () => _toggleBlock(_users[i]['id'], _users[i]['isBlocked']),
          ),
        ),
      )),
    ]),
  );
}
