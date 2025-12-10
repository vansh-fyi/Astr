import 'dart:async';
import 'dart:isolate';

/// Manages background Isolates for heavy astronomical calculations
///
/// This class ensures that calculations taking longer than 16ms (one frame at 60fps)
/// are offloaded to a background thread to maintain UI responsiveness.
class IsolateManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  final Map<int, Completer<dynamic>> _pendingRequests = {};
  int _nextRequestId = 0;
  bool _isInitialized = false;

  /// Initializes the isolate worker
  Future<void> initialize() async {
    if (_isInitialized) return;

    _receivePort = ReceivePort();

    // Spawn the isolate
    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _receivePort!.sendPort,
    );

    // Wait for the isolate to send back its SendPort
    final completer = Completer<SendPort>();
    late StreamSubscription subscription;

    subscription = _receivePort!.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
        subscription.cancel();
      }
    });

    _sendPort = await completer.future;

    // Now listen for responses
    _receivePort!.listen((message) {
      if (message is _IsolateResponse) {
        final completer = _pendingRequests.remove(message.requestId);
        if (completer != null) {
          if (message.error != null) {
            completer.completeError(message.error!, message.stackTrace);
          } else {
            completer.complete(message.result);
          }
        }
      }
    });

    _isInitialized = true;
  }

  /// Executes a calculation in the background isolate
  ///
  /// [computation] A function that performs the calculation
  ///
  /// Returns a Future that completes with the result of the computation
  Future<T> execute<T>(T Function() computation) async {
    if (!_isInitialized) {
      await initialize();
    }

    final requestId = _nextRequestId++;
    final completer = Completer<T>();
    _pendingRequests[requestId] = completer;

    // Send the request to the isolate
    _sendPort!.send(_IsolateRequest(
      requestId: requestId,
      computation: computation,
    ));

    return completer.future as Future<T>;
  }

  /// Disposes of the isolate and cleans up resources
  Future<void> dispose() async {
    if (_isolate != null) {
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
    }

    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;

    // Complete any pending requests with errors
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('IsolateManager disposed while request was pending'),
        );
      }
    }
    _pendingRequests.clear();

    _isInitialized = false;
  }

  /// Entry point for the isolate worker
  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();

    // Send our SendPort back to the main isolate
    sendPort.send(receivePort.sendPort);

    // Listen for computation requests
    receivePort.listen((message) {
      if (message is _IsolateRequest) {
        try {
          // Execute the computation
          final result = message.computation();

          // Send the result back
          sendPort.send(_IsolateResponse(
            requestId: message.requestId,
            result: result,
          ));
        } catch (error, stackTrace) {
          // Send the error back
          sendPort.send(_IsolateResponse(
            requestId: message.requestId,
            error: error,
            stackTrace: stackTrace,
          ));
        }
      }
    });
  }
}

/// Request message sent to the isolate
class _IsolateRequest {
  final int requestId;
  final Function computation;

  _IsolateRequest({
    required this.requestId,
    required this.computation,
  });
}

/// Response message from the isolate
class _IsolateResponse {
  final int requestId;
  final dynamic result;
  final Object? error;
  final StackTrace? stackTrace;

  _IsolateResponse({
    required this.requestId,
    this.result,
    this.error,
    this.stackTrace,
  });
}
