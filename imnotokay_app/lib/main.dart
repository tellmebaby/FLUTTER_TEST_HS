import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'bloc/board_bloc.dart';
import 'models/board.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => BoardBloc()..add(FetchBoards()),
        child: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isMessageInputVisible = false;
  final TextEditingController _messageController = TextEditingController();

  void _showMessageInput() {
    setState(() {
      _isMessageInputVisible = true;
    });
  }

  void _hideMessageInput() {
    setState(() {
      _isMessageInputVisible = false;
      _messageController.clear();
    });
  }

  Future<void> _saveMessage() async {
    Board newBoard = Board(
      title: _messageController.text,
      writer: '',
      content: '',
    );

    final response = await http.post(
      Uri.parse('http://localhost:8080/boards'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(newBoard.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _hideMessageInput();
      BlocProvider.of<BoardBloc>(context).add(FetchBoards());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save message')),
      );
    }
  }

  Future<void> _deleteBoard(int id) async {
    final response = await http.delete(
      Uri.parse('http://localhost:8080/boards/$id'),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      BlocProvider.of<BoardBloc>(context).add(FetchBoards());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete message')),
      );
    }
  }

  void _showDeleteDialog(String title, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                  style: TextStyle(fontSize: 24.0),
            ),
            Text('완료!!!',
                  style: TextStyle(fontSize: 30.0),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteBoard(id);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "I'm Not Okay",
            style: TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _showMessageInput,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/back.jpg',
              fit: BoxFit.cover,
            ),
          ),
          BlocBuilder<BoardBloc, BoardState>(
            builder: (context, state) {
              if (state is BoardLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is BoardLoaded) {
                return BoardsDisplay(
                  boards: state.boards,
                  isDisabled: _isMessageInputVisible,
                  onLongPress: _showDeleteDialog,
                );
              } else if (state is BoardError) {
                return Center(child: Text(state.message));
              }
              return const Center(child: Text('Press button to load boards'));
            },
          ),
          if (_isMessageInputVisible)
            GestureDetector(
              onTap: _hideMessageInput,
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _messageController,
                          decoration: InputDecoration(labelText: 'Enter your message'),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saveMessage,
                          child: Text('Save Message'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BoardsDisplay extends StatefulWidget {
  final List<Board> boards;
  final bool isDisabled;
  final void Function(String, int) onLongPress;

  const BoardsDisplay({
    required this.boards,
    required this.isDisabled,
    required this.onLongPress,
  });

  @override
  _BoardsDisplayState createState() => _BoardsDisplayState();
}

class _BoardsDisplayState extends State<BoardsDisplay> {
  List<Offset> _positions = [];
  late List<Color> _colors;

  // 색상 팔레트
  final List<Color> palette = [
    Color(0xFFFAE3E3),
    Color(0xFFFED7D7),
    Color(0xFFFFEBE8),
    Color(0xFFFFF5F5),
    Color(0xFFE3F6F5),
    Color(0xFFD4EDED),
    Color(0xFFFFF8E1),
    Color(0xFFFFEFD5),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _initializePositions();
    });
    _colors = List.generate(widget.boards.length, (index) => _randomColor());
  }

  @override
  void didUpdateWidget(BoardsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.boards.length != oldWidget.boards.length) {
      _initializePositions();
    }
  }

  void _initializePositions() {
    final size = MediaQuery.of(context).size;
    setState(() {
      _positions = List.generate(widget.boards.length, (index) => _randomPosition(size));
    });
  }

  Offset _randomPosition(Size size) {
    final random = Random();
    return Offset(
      random.nextDouble() * (size.width - 100),
      random.nextDouble() * (size.height - 100),
    );
  }

  Color _randomColor() {
    final random = Random();
    return palette[random.nextInt(palette.length)];
  }

  void _updatePosition(int index, Offset newPosition) {
    setState(() {
      if (index < _positions.length) {
        final size = MediaQuery.of(context).size;
        final dx = newPosition.dx.clamp(0.0, size.width - 100);
        final dy = newPosition.dy.clamp(0.0, size.height - 100);
        _positions[index] = Offset(dx, dy);
      }
    });
  }

  String _getFirstWord(String? text) {
    if (text == null || text.isEmpty) {
      return 'No Title';
    }
    return text.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: widget.isDisabled,
      child: Stack(
        children: List.generate(widget.boards.length, (index) {
          return Positioned(
            left: _positions.isNotEmpty ? _positions[index].dx : 0,
            top: _positions.isNotEmpty ? _positions[index].dy : 0,
            child: GestureDetector(
              onPanUpdate: (details) {
                RenderBox box = context.findRenderObject() as RenderBox;
                Offset localOffset = box.globalToLocal(details.globalPosition);
                _updatePosition(index, localOffset);
              },
              onLongPress: () {
                widget.onLongPress(
                  widget.boards[index].title ?? 'No Title',
                  widget.boards[index].no ?? 0,
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _colors[index],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getFirstWord(widget.boards[index].title),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 74, 74, 74),
                      fontSize: 28, // 두 배로 키운 글자 크기
                      fontWeight: FontWeight.bold, // 두껍게 설정
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

extension on Board {
  Map<String, dynamic> toJson() {
    return {
      'title': title ?? '',
      'writer': writer ?? '',
      'content': content ?? '',
    };
  }
}