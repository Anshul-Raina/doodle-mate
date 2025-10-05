import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/drawing_stroke.dart';
import '../widgets/drawing_canvas.dart';
import '../services/firebase_service.dart';

class CollaborativeDrawingScreen extends StatefulWidget {
  final String sessionId;

  const CollaborativeDrawingScreen({
    super.key,
    required this.sessionId,
  });

  @override
  State<CollaborativeDrawingScreen> createState() => _CollaborativeDrawingScreenState();
}

class _CollaborativeDrawingScreenState extends State<CollaborativeDrawingScreen> {
  final List<DrawingStroke> _strokes = [];
  final String _userId = const Uuid().v4();
  final FirebaseService _firebaseService = FirebaseService();

  Color _selectedColor = Colors.black;
  double _selectedWidth = 3.0;
  bool _isConnected = true;
  List<DrawingStroke> _pendingStrokes = []; // For offline support

  // Key to capture the RepaintBoundary for export
  final GlobalKey _repaintKey = GlobalKey();
  StreamSubscription? _strokesSubscription;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    _strokesSubscription?.cancel();
    _reconnectTimer?.cancel();
    _firebaseService.dispose();
    super.dispose();
  }

  void _initializeSession() {
    _strokesSubscription = _firebaseService
        .getStrokesStream(widget.sessionId)
        .listen(
          (strokes) {
        setState(() {
          _strokes.clear();
          _strokes.addAll(strokes);
          _isConnected = true;
        });
        _processPendingStrokes();
      },
      onError: (error) {
        print('Error listening to strokes: $error');
        setState(() {
          _isConnected = false;
        });
        _startReconnectTimer();
      },
    );
  }

  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _initializeSession();
    });
  }

  Future<void> _processPendingStrokes() async {
    if (_pendingStrokes.isEmpty) return;

    try {
      for (final stroke in _pendingStrokes) {
        await _firebaseService.addStroke(widget.sessionId, stroke);
      }
      _pendingStrokes.clear();
    } catch (e) {
      print('Error processing pending strokes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Collaborative Drawing',
              style: TextStyle(color: Colors.black87, fontSize: 18),
            ),
            Text(
              'Session: ${widget.sessionId}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // Connection status
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareSession,
            tooltip: 'Share Session',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportAndShare,
            tooltip: 'Export & Share',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main drawing canvas wrapped with RepaintBoundary so we can capture it
          Positioned.fill(
            child: RepaintBoundary(
              key: _repaintKey,
              child: DrawingCanvas(
                // pass the key to the child only if DrawingCanvas needs it; not required for export
                strokes: _strokes,
                onStrokeAdded: _addStroke,
                onUndo: _undo,
                onClear: _clear,
                selectedColor: _selectedColor,
                selectedWidth: _selectedWidth,
                userId: _userId,
              ),
            ),
          ),

          // Connection status banner
          if (!_isConnected)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.orange,
                child: const Text(
                  'Offline - Changes will sync when reconnected',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
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
            onPressed: _canUndo() ? _undo : null,
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

  bool _canUndo() {
    return _strokes.any((stroke) => stroke.userId == _userId);
  }

  void _addStroke(DrawingStroke stroke) async {
    // Add to local state immediately for responsiveness
    setState(() {
      _strokes.add(stroke);
    });

    // Try to sync to Firebase
    try {
      if (_isConnected) {
        await _firebaseService.addStroke(widget.sessionId, stroke);
      } else {
        _pendingStrokes.add(stroke);
      }
    } catch (e) {
      print('Error adding stroke: $e');
      setState(() {
        _isConnected = false;
      });
      _pendingStrokes.add(stroke);
      _startReconnectTimer();
    }
  }

  void _undo() async {
    try {
      // Find the last stroke by this user
      final userStrokes = _strokes.where((s) => s.userId == _userId).toList();
      if (userStrokes.isEmpty) return;

      final lastStroke = userStrokes.last;

      // Remove from local state immediately
      setState(() {
        _strokes.removeWhere((s) => s.id == lastStroke.id);
      });

      // Sync to Firebase
      if (_isConnected) {
        await _firebaseService.deleteStroke(widget.sessionId, lastStroke.id);
      }
    } catch (e) {
      print('Error undoing stroke: $e');
      setState(() {
        _isConnected = false;
      });
      _startReconnectTimer();
    }
  }

  void _clear() async {
    try {
      // Clear local state immediately
      setState(() {
        _strokes.clear();
      });

      // Sync to Firebase
      if (_isConnected) {
        await _firebaseService.clearSession(widget.sessionId);
      }
    } catch (e) {
      print('Error clearing canvas: $e');
      setState(() {
        _isConnected = false;
      });
      _startReconnectTimer();
    }
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
        content: const Text(
          'Are you sure you want to clear the entire canvas for all users? This cannot be undone.',
        ),
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

  void _shareSession() {
    Share.share(
      'Join my drawing session on DoodleMate!\nSession ID: ${widget.sessionId}',
    );
  }

  Future<void> _exportAndShare() async {
    try {
      // Grab the RenderRepaintBoundary from the RepaintBoundary key
      final boundaryObject = _repaintKey.currentContext?.findRenderObject();
      if (boundaryObject == null || boundaryObject is! RenderRepaintBoundary) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to capture drawing.')),
        );
        return;
      }

      RenderRepaintBoundary boundary = boundaryObject;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();

        // Save to temporary directory
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/collaborative_drawing_${widget.sessionId}.png');
        await file.writeAsBytes(pngBytes);

        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out our collaborative drawing from session ${widget.sessionId}!',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting drawing: $e')),
      );
    }
  }
}
