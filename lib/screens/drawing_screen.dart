import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/drawing_stroke.dart';
import '../widgets/drawing_canvas.dart';
import 'collaborative_drawing_screen.dart';

class DrawingScreen extends StatefulWidget {
  final String? sessionId;
  final bool isCollaborative;

  const DrawingScreen({
    super.key,
    this.sessionId,
    this.isCollaborative = false,
  });

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<DrawingStroke> _strokes = [];
  final String _userId = const Uuid().v4();
  
  Color _selectedColor = Colors.black;
  double _selectedWidth = 3.0;
  
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          widget.isCollaborative 
            ? 'Collaborative Drawing'
            : 'DoodleMate',
          style: const TextStyle(color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (!widget.isCollaborative) ...[
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: _showCollaborationOptions,
              tooltip: 'Collaborate',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportAndShare,
            tooltip: 'Export & Share',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main drawing canvas
          Positioned.fill(
            child: DrawingCanvas(
              key: _canvasKey,
              strokes: _strokes,
              onStrokeAdded: _addStroke,
              onUndo: _undo,
              onClear: _clear,
              selectedColor: _selectedColor,
              selectedWidth: _selectedWidth,
              userId: _userId,
            ),
          ),
          
          // Toolbar
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildToolbar(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Color picker
          GestureDetector(
            onTap: _showColorPicker,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _selectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
            ),
          ),
          
          // Brush size
          GestureDetector(
            onTap: _showBrushSizePicker,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Center(
                child: Container(
                  width: _selectedWidth * 2,
                  height: _selectedWidth * 2,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          
          // Undo
          IconButton(
            onPressed: _strokes.isNotEmpty ? _undo : null,
            icon: const Icon(Icons.undo),
            iconSize: 28,
          ),
          
          // Clear
          IconButton(
            onPressed: _strokes.isNotEmpty ? _showClearDialog : null,
            icon: const Icon(Icons.clear_all),
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  void _addStroke(DrawingStroke stroke) {
    setState(() {
      _strokes.add(stroke);
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
    });
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showBrushSizePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brush Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: _selectedWidth,
              min: 1.0,
              max: 20.0,
              divisions: 19,
              label: _selectedWidth.round().toString(),
              onChanged: (value) {
                setState(() {
                  _selectedWidth = value;
                });
              },
            ),
            Container(
              width: 100,
              height: 50,
              alignment: Alignment.center,
              child: Container(
                width: _selectedWidth * 2,
                height: _selectedWidth * 2,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Canvas'),
        content: const Text('Are you sure you want to clear the entire canvas? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clear();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showCollaborationOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Collaborate',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.add_link, color: Colors.blue),
              title: const Text('Create Link'),
              subtitle: const Text('Start a new collaborative session'),
              onTap: () {
                Navigator.of(context).pop();
                _createCollaborativeSession();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.login, color: Colors.green),
              title: const Text('Join Link'),
              subtitle: const Text('Join an existing session'),
              onTap: () {
                Navigator.of(context).pop();
                _showJoinDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createCollaborativeSession() {
    final sessionId = const Uuid().v4().substring(0, 8);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CollaborativeDrawingScreen(sessionId: sessionId),
      ),
    );
  }

  void _showJoinDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Session'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Session Code',
            hintText: 'Enter session code',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (controller.text.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CollaborativeDrawingScreen(
                      sessionId: controller.text,
                    ),
                  ),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAndShare() async {
    try {
      // Get the canvas key and render the drawing
      if (_canvasKey.currentContext == null) return;

      RenderRepaintBoundary boundary = _canvasKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();

        // Save to temporary directory
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);

        // Share the file
        await Share.shareXFiles([XFile(file.path)], text: 'Check out my drawing!');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting drawing: $e')),
      );
    }
  }
}
