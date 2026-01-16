// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:ffi';

import 'package:falcon_gui/utils/logger.dart';
import 'package:falcon_gui/utils/zmq/zmq_constants.dart';
import 'package:ffi/ffi.dart';

// Lightweight client-only zmq implementation
// using FFI for REQ/REP communication with
// Falcon process in Linux environment.

/// FFI wrapper for the ZeroMQ library.
///
/// This class provides a low-level interface to the ZeroMQ C library.
/// It is implemented as a singleton to ensure the library is loaded only once.
class ZMQFFi {
  factory ZMQFFi() {
    return _instance;
  }
  ZMQFFi._internal() {
    _initLibrary();
    _fns = ZMQFunctionTable(_lib);
  }
  static final ZMQFFi _instance = ZMQFFi._internal();

  late final DynamicLibrary _lib;
  late final ZMQFunctionTable _fns;

  /// Loads the ZeroMQ dynamic library.
  /// Tries 'libzmq.so' first, then falls back to 'libzmq.so.5'.
  void _initLibrary() {
    try {
      _lib = DynamicLibrary.open('libzmq.so');
    } catch (_) {
      try {
        _lib = DynamicLibrary.open('libzmq.so.5');
      } catch (_) {
        throw Exception('Could not load libzmq');
      }
    }
  }

  /// Creates a new ZeroMQ context.
  ZMQContext ctxNew() => _fns.zmq_ctx_new();

  /// Terminates a ZeroMQ context.
  void ctxTerm(ZMQContext ctx) {
    final rc = _fns.zmq_ctx_term(ctx);
    if (rc != 0) {
      final err = _fns.zmq_errno();
      final errStr = _fns.zmq_strerror(err).toDartString();
      throw Exception('zmq_ctx_term failed: $errStr');
    }
  }

  /// Creates a new ZeroMQ socket.
  ZMQSocket socket(ZMQContext ctx, int type) => _fns.zmq_socket(ctx, type);

  /// Connects the socket to an endpoint.
  /// Uses arena allocator for automatic memory management of the string
  /// pointer.
  int connect(ZMQSocket sock, String endpoint) {
    return using((arena) {
      final ptr = endpoint.toNativeUtf8(allocator: arena);
      final result = _fns.zmq_connect(sock, ptr);
      if (result != 0) {
        final errno = _fns.zmq_errno();
        throw Exception('zmq_connect failed: errno=$errno');
      }
      return result;
    });
  }

  /// Sets a socket option and verifies it by reading it back.
  int setSocketOption(ZMQSocket sock, int option, int value) {
    return using((arena) {
      final ptr = arena<Int32>()..value = value;
      final result = _fns.zmq_setsockopt(
        sock,
        option,
        ptr.cast<Void>(),
        sizeOf<Int32>(),
      );
      if (result != 0) {
        final err = _fns.zmq_errno();
        final errStr = _fns.zmq_strerror(err).toDartString();
        throw Exception('zmq_setsockopt failed: $errStr');
      }

      final readPtr = arena<Int32>();
      final sizePtr = arena<Size>()..value = sizeOf<Int32>();

      final readResult = _fns.zmq_getsockopt(
        sock,
        option,
        readPtr.cast<Void>(),
        sizePtr,
      );
      if (readResult != 0) {
        final err = _fns.zmq_errno();
        final errStr = _fns.zmq_strerror(err).toDartString();
        throw Exception('zmq_getsockopt failed: $errStr');
      }
      return result;
    });
  }

  /// Sets a socket option with binary data (for ZMQ_SUBSCRIBE, etc).
  int setSocketOptionBinary(ZMQSocket sock, int option, List<int> value) {
    return using((arena) {
      final ptr = arena.allocate<Uint8>(value.isEmpty ? 1 : value.length);
      if (value.isNotEmpty) {
        ptr.asTypedList(value.length).setAll(0, value);
      }
      final result = _fns.zmq_setsockopt(
        sock,
        option,
        ptr.cast<Void>(),
        value.length,
      );
      if (result != 0) {
        final err = _fns.zmq_errno();
        final errStr = _fns.zmq_strerror(err).toDartString();
        throw Exception('zmq_setsockopt failed: $errStr');
      }
      return result;
    });
  }

  /// Subscribe to all messages on a SUB socket (empty topic filter).
  bool subscribeAll(ZMQSocket sock) {
    final result = setSocketOptionBinary(sock, ZMQ_SUBSCRIBE, []);
    return result == 0;
  }

  /// Subscribe to a specific topic on a SUB socket.
  bool subscribe(ZMQSocket sock, String topic) {
    final result = setSocketOptionBinary(
      sock,
      ZMQ_SUBSCRIBE,
      utf8.encode(topic),
    );
    return result == 0;
  }

  /// Gets a socket option as an integer.
  int getSocketOptionInt(ZMQSocket sock, int option) {
    return using((arena) {
      final readPtr = arena<Int32>();
      final sizePtr = arena<Size>()..value = sizeOf<Int32>();

      final result = _fns.zmq_getsockopt(
        sock,
        option,
        readPtr.cast<Void>(),
        sizePtr,
      );
      if (result != 0) {
        final err = _fns.zmq_errno();
        final errStr = _fns.zmq_strerror(err).toDartString();
        throw Exception('zmq_getsockopt failed: $errStr');
      }
      return readPtr.value;
    });
  }

  /// Sends data over the socket.
  /// Returns the number of bytes sent.
  int send(ZMQSocket sock, List<int> data, {int flags = 0}) {
    if (data.isEmpty) return 0;
    return using((arena) {
      final ptr = arena.allocate<Uint8>(data.length);
      ptr.asTypedList(data.length).setAll(0, data);
      final result = _fns.zmq_send(sock, ptr.cast<Void>(), data.length, flags);
      if (result < 0) {
        final errno = _fns.zmq_errno();
        throw Exception('zmq_send failed: errno=$errno');
      }
      return result;
    });
  }

  /// Sends a multipart message where each part is a separate frame.
  /// Equivalent to Python's socket.send_multipart()
  void sendMultipart(ZMQSocket sock, List<List<int>> parts) {
    for (var i = 0; i < parts.length; i++) {
      final isLastPart = i == parts.length - 1;
      final flags = isLastPart ? 0 : ZMQ_SNDMORE;
      final result = send(sock, parts[i], flags: flags);
      if (result < 0) {
        throw Exception('sendMultipart failed at part $i');
      }
    }
  }

  /// Receives a multipart message as a list of frames.
  /// Equivalent to Python's socket.recv_multipart()
  List<List<int>> recvMultipartSync(ZMQSocket sock) {
    final parts = <List<int>>[];
    while (true) {
      final part = recvSync(sock);
      if (part == null) {
        return parts;
      }
      // Add all parts, including empty ones for protocol correctness
      parts.add(part);

      // Check if there are more parts
      final hasMore = getSocketOptionInt(sock, ZMQ_RCVMORE);
      if (hasMore == 0) {
        break;
      }
    }
    return parts;
  }

  /// Sends a multipart message with string parts.
  /// Each part is UTF-8 encoded.
  void sendMultipartStrings(ZMQSocket sock, List<String> parts) {
    final encodedParts = parts.map(_encodeString).toList();
    sendMultipart(sock, encodedParts);
  }

  /// Receives a multipart message and decodes parts as UTF-8 strings.
  List<String> recvMultipartStringsSync(ZMQSocket sock) {
    final parts = recvMultipartSync(sock);
    return parts.map(_decodeString).toList();
  }

  /// Encodes a string to UTF-8 bytes using UTF-8 encoding.
  static List<int> _encodeString(String str) {
    return utf8.encode(str);
  }

  /// Decodes UTF-8 bytes to a string with error handling.
  static String _decodeString(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } catch (e, s) {
      logError('UTF-8 decoding error: $e', s);
      // Fallback for malformed UTF-8
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  /// Receives a message from the socket.
  ///
  /// Uses `zmq_msg_t` to handle dynamic message sizes.
  ///
  /// Note: To avoid blocking the UI thread, use `recv` instead.
  ///
  /// The receive timeout should be configured via `setSocketOption` with
  /// `ZMQ_RCVTIMEO` before calling this method.
  List<int>? recvSync(ZMQSocket sock, {int flags = 0}) {
    return using((arena) {
      // zmq_msg_t is opaque and size varies by platform, but 64 bytes is
      // generally sufficient for the structure.
      final msg = arena.allocate<Uint8>(64).cast<Void>();

      if (_fns.zmq_msg_init(msg) != 0) {
        throw Exception('zmq_msg_init failed');
      }

      try {
        while (true) {
          final n = _fns.zmq_msg_recv(msg, sock, flags);
          if (n >= 0) {
            final dataPtr = _fns.zmq_msg_data(msg);
            final size = _fns.zmq_msg_size(msg);
            if (size == 0) {
              // Return empty list for empty messages (not null)
              return <int>[];
            }
            return dataPtr.cast<Uint8>().asTypedList(size).toList();
          }

          final err = _fns.zmq_errno();
          if (err == EINTR) {
            // Interrupted system call, retry
            continue;
          }
          if (err == EAGAIN) {
            // Timeout or non-blocking mode with no message available
            return null;
          }
          if (err == ETERM) {
            // Context was terminated
            throw Exception('zmq_msg_recv failed: context terminated');
          }

          final errStr = _fns.zmq_strerror(err).toDartString();
          throw Exception('zmq_msg_recv failed: $errStr (errno=$err)');
        }
      } finally {
        _fns.zmq_msg_close(msg);
      }
    });
  }

  /// Closes the socket.
  void close(ZMQSocket sock) {
    final rc = _fns.zmq_close(sock);
    if (rc != 0) {
      final err = _fns.zmq_errno();
      final errStr = _fns.zmq_strerror(err).toDartString();
      throw Exception('zmq_close failed: $errStr (errno=$err)');
    }
  }

  /// Returns the value of `errno` for the calling thread.
  int getErrno() => _fns.zmq_errno();
}
