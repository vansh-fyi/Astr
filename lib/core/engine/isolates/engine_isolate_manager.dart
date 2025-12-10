import 'dart:async';
import 'dart:isolate';
import 'package:astr/core/engine/algorithms/coordinate_transformations.dart';
import 'package:astr/core/engine/algorithms/rise_set_calculator.dart';
import 'package:astr/core/engine/isolates/calculation_commands.dart';
import 'package:astr/core/engine/models/coordinates.dart';
import 'package:astr/core/engine/models/rise_set_times.dart';

/// Manages background Isolate for astronomical calculations
///
/// This specialized manager handles calculation commands with performance
/// measurement to determine whether to offload to an isolate (>16ms) or
/// execute on the main thread (<16ms).
class EngineIsolateManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  final Map<int, Completer<dynamic>> _pendingRequests = {};
  int _nextRequestId = 0;
  bool _isInitialized = false;

  /// Threshold for offloading to isolate (16ms = 1 frame at 60fps)
  static const Duration offloadThreshold = Duration(milliseconds: 16);

  /// Executes a position calculation, offloading to isolate if needed
  Future<HorizontalCoordinates> calculatePosition(
    CalculatePositionCommand command,
  ) async {
    // Measure execution time of a quick test run
    final stopwatch = Stopwatch()..start();
    final result = _calculatePositionSync(command);
    stopwatch.stop();

    // If calculation is fast enough, return immediately
    if (stopwatch.elapsed < offloadThreshold) {
      return result;
    }

    // Otherwise, offload to isolate for future calls
    return _executeInIsolate<HorizontalCoordinatesResult>(command)
        .then((r) => r.toCoordinates());
  }

  /// Executes a rise/set calculation, offloading to isolate if needed
  Future<RiseSetTimes> calculateRiseSet(
    CalculateRiseSetCommand command,
  ) async {
    // Measure execution time
    final stopwatch = Stopwatch()..start();
    final result = _calculateRiseSetSync(command);
    stopwatch.stop();

    // If calculation is fast enough, return immediately
    if (stopwatch.elapsed < offloadThreshold) {
      return result;
    }

    // Otherwise, offload to isolate
    return _executeInIsolate<RiseSetTimesResult>(command).then((r) =>
        RiseSetTimes(
          riseTime: r.riseTime,
          transitTime: r.transitTime,
          setTime: r.setTime,
          isCircumpolar: r.isCircumpolar,
          neverRises: r.neverRises,
        ));
  }

  /// Synchronous position calculation
  HorizontalCoordinates _calculatePositionSync(
    CalculatePositionCommand command,
  ) {
    return CoordinateTransformations.equatorialToHorizontal(
      command.equatorialCoordinates,
      command.location,
      command.dateTime,
    );
  }

  /// Synchronous rise/set calculation
  RiseSetTimes _calculateRiseSetSync(CalculateRiseSetCommand command) {
    return RiseSetCalculator.calculateRiseSetIterative(
      command.equatorialCoordinates,
      command.location,
      command.date,
    );
  }

  /// Executes a calculation command in the background isolate
  Future<T> _executeInIsolate<T>(CalculationCommand command) async {
    if (!_isInitialized) {
      await _initialize();
    }

    final requestId = _nextRequestId++;
    final completer = Completer<T>();
    _pendingRequests[requestId] = completer;

    _sendPort!.send(_IsolateRequest(
      requestId: requestId,
      command: command,
    ));

    return completer.future;
  }

  /// Initializes the isolate worker
  Future<void> _initialize() async {
    if (_isInitialized) return;

    _receivePort = ReceivePort();

    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _receivePort!.sendPort,
    );

    // Wait for the isolate's SendPort
    final completer = Completer<SendPort>();
    late StreamSubscription subscription;

    subscription = _receivePort!.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
        subscription.cancel();
      }
    });

    _sendPort = await completer.future;

    // Listen for responses
    _receivePort!.listen((message) {
      if (message is _IsolateResponse) {
        final completer = _pendingRequests.remove(message.requestId);
        if (completer != null) {
          if (message.error != null) {
            completer.completeError(
              Exception(message.error),
              message.stackTrace,
            );
          } else {
            completer.complete(message.result);
          }
        }
      }
    });

    _isInitialized = true;
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
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message is _IsolateRequest) {
        try {
          final result = _processCommand(message.command);
          sendPort.send(_IsolateResponse(
            requestId: message.requestId,
            result: result,
          ));
        } catch (error, stackTrace) {
          sendPort.send(_IsolateResponse(
            requestId: message.requestId,
            error: error.toString(),
            stackTrace: stackTrace,
          ));
        }
      }
    });
  }

  /// Processes a calculation command in the isolate
  static dynamic _processCommand(CalculationCommand command) {
    if (command is CalculatePositionCommand) {
      final result = CoordinateTransformations.equatorialToHorizontal(
        command.equatorialCoordinates,
        command.location,
        command.dateTime,
      );
      return HorizontalCoordinatesResult(
        altitude: result.altitude,
        azimuth: result.azimuth,
      );
    } else if (command is CalculateRiseSetCommand) {
      final result = RiseSetCalculator.calculateRiseSetIterative(
        command.equatorialCoordinates,
        command.location,
        command.date,
      );
      return RiseSetTimesResult(
        riseTime: result.riseTime,
        transitTime: result.transitTime,
        setTime: result.setTime,
        isCircumpolar: result.isCircumpolar,
        neverRises: result.neverRises,
      );
    }
    throw UnsupportedError('Unknown command type: ${command.runtimeType}');
  }
}

/// Request message sent to the isolate
class _IsolateRequest {
  final int requestId;
  final CalculationCommand command;

  _IsolateRequest({
    required this.requestId,
    required this.command,
  });
}

/// Response message from the isolate
class _IsolateResponse {
  final int requestId;
  final dynamic result;
  final String? error;
  final StackTrace? stackTrace;

  _IsolateResponse({
    required this.requestId,
    this.result,
    this.error,
    this.stackTrace,
  });
}
