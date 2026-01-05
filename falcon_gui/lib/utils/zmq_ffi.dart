// ignore_for_file: constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

// Lightweight client-only zmq implementation
// using FFI for REQ/REP communication with
// Falcon process in Linux environment.

typedef ZMQContext = Pointer<Void>;
typedef ZMQSocket = Pointer<Void>;
typedef ZMQMessage = Pointer<Void>; // Opaque pointer for zmq_msg_t

// Function signatures
typedef ZmqCtxNewNative = ZMQContext Function();
typedef ZmqCtxNewDart = ZMQContext Function();

typedef ZmqCtxTermNative = Int32 Function(ZMQContext context);
typedef ZmqCtxTermDart = int Function(ZMQContext context);

typedef ZmqSocketNative = ZMQSocket Function(ZMQContext context, Int32 type);
typedef ZmqSocketDart = ZMQSocket Function(ZMQContext context, int type);

typedef ZmqConnectNative =
    Int32 Function(ZMQSocket socket, Pointer<Utf8> endpoint);
typedef ZmqConnectDart = int Function(ZMQSocket socket, Pointer<Utf8> endpoint);

typedef ZmqSendNative =
    Int32 Function(
      ZMQSocket socket,
      Pointer<Void> buffer,
      IntPtr size,
      Int32 flags,
    );
typedef ZmqSendDart =
    int Function(ZMQSocket socket, Pointer<Void> buffer, int size, int flags);

typedef ZmqRecvNative =
    Int32 Function(
      ZMQSocket socket,
      Pointer<Void> buffer,
      IntPtr size,
      Int32 flags,
    );
typedef ZmqRecvDart =
    int Function(ZMQSocket socket, Pointer<Void> buffer, int size, int flags);

// New ZMQ Message functions
typedef ZmqMsgInitNative = Int32 Function(ZMQMessage msg);
typedef ZmqMsgInitDart = int Function(ZMQMessage msg);

typedef ZmqMsgCloseNative = Int32 Function(ZMQMessage msg);
typedef ZmqMsgCloseDart = int Function(ZMQMessage msg);

typedef ZmqMsgRecvNative =
    Int32 Function(ZMQMessage msg, ZMQSocket socket, Int32 flags);
typedef ZmqMsgRecvDart =
    int Function(ZMQMessage msg, ZMQSocket socket, int flags);

typedef ZmqMsgDataNative = Pointer<Void> Function(ZMQMessage msg);
typedef ZmqMsgDataDart = Pointer<Void> Function(ZMQMessage msg);

typedef ZmqMsgSizeNative = IntPtr Function(ZMQMessage msg);
typedef ZmqMsgSizeDart = int Function(ZMQMessage msg);

typedef ZmqCloseNative = Int32 Function(ZMQSocket socket);
typedef ZmqCloseDart = int Function(ZMQSocket socket);

typedef ZmqSetsockoptNative =
    Int32 Function(
      ZMQSocket socket,
      Int32 option,
      Pointer<Void> optval,
      Size optvallen,
    );
typedef ZmqSetsockoptDart =
    int Function(
      ZMQSocket socket,
      int option,
      Pointer<Void> optval,
      int optvallen,
    );

typedef ZmqGetsockoptNative =
    Int32 Function(
      ZMQSocket socket,
      Int32 option,
      Pointer<Void> optval,
      Pointer<Size> optvallen,
    );
typedef ZmqGetsockoptDart =
    int Function(
      ZMQSocket socket,
      int option,
      Pointer<Void> optval,
      Pointer<Size> optvallen,
    );

typedef ZmqErrnoNative = Int32 Function();
typedef ZmqErrnoDart = int Function();

typedef ZmqStrerrorNative = Pointer<Utf8> Function(Int32 errnum);
typedef ZmqStrerrorDart = Pointer<Utf8> Function(int errnum);

// ZMQ socket types
const int ZMQ_REQ = 3;
const int ZMQ_REP = 4;

// ZMQ flags
const int ZMQ_DONTWAIT = 1;
const int ZMQ_SNDMORE = 2;
const int ZMQ_RCVMORE = 13;
const int ZMQ_RCVTIMEO = 27;

// Error constants
const int EINTR = 4;
const int EAGAIN = 11;

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
    _lookupFunctions();
  }
  static final ZMQFFi _instance = ZMQFFi._internal();

  late final DynamicLibrary _lib;
  late final ZmqCtxNewDart zmq_ctx_new;
  late final ZmqCtxTermDart zmq_ctx_term;
  late final ZmqSocketDart zmq_socket;
  late final ZmqConnectDart zmq_connect;
  late final ZmqSendDart zmq_send;
  late final ZmqRecvDart zmq_recv;
  late final ZmqCloseDart zmq_close;
  late final ZmqSetsockoptDart zmq_setsockopt;
  late final ZmqGetsockoptDart zmq_getsockopt;
  late final ZmqErrnoDart zmq_errno;
  late final ZmqStrerrorDart zmq_strerror;

  // Message functions
  late final ZmqMsgInitDart zmq_msg_init;
  late final ZmqMsgCloseDart zmq_msg_close;
  late final ZmqMsgRecvDart zmq_msg_recv;
  late final ZmqMsgDataDart zmq_msg_data;
  late final ZmqMsgSizeDart zmq_msg_size;

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

  /// Looks up all required FFI functions from the loaded library.
  void _lookupFunctions() {
    zmq_ctx_new = _lib.lookupFunction<ZmqCtxNewNative, ZmqCtxNewDart>(
      'zmq_ctx_new',
    );
    zmq_ctx_term = _lib.lookupFunction<ZmqCtxTermNative, ZmqCtxTermDart>(
      'zmq_ctx_term',
    );
    zmq_socket = _lib.lookupFunction<ZmqSocketNative, ZmqSocketDart>(
      'zmq_socket',
    );
    zmq_connect = _lib.lookupFunction<ZmqConnectNative, ZmqConnectDart>(
      'zmq_connect',
    );
    zmq_send = _lib.lookupFunction<ZmqSendNative, ZmqSendDart>('zmq_send');
    zmq_recv = _lib.lookupFunction<ZmqRecvNative, ZmqRecvDart>('zmq_recv');
    zmq_close = _lib.lookupFunction<ZmqCloseNative, ZmqCloseDart>('zmq_close');

    zmq_msg_init = _lib.lookupFunction<ZmqMsgInitNative, ZmqMsgInitDart>(
      'zmq_msg_init',
    );
    zmq_msg_close = _lib.lookupFunction<ZmqMsgCloseNative, ZmqMsgCloseDart>(
      'zmq_msg_close',
    );
    zmq_msg_recv = _lib.lookupFunction<ZmqMsgRecvNative, ZmqMsgRecvDart>(
      'zmq_msg_recv',
    );
    zmq_msg_data = _lib.lookupFunction<ZmqMsgDataNative, ZmqMsgDataDart>(
      'zmq_msg_data',
    );
    zmq_msg_size = _lib.lookupFunction<ZmqMsgSizeNative, ZmqMsgSizeDart>(
      'zmq_msg_size',
    );

    zmq_setsockopt = _lib
        .lookupFunction<ZmqSetsockoptNative, ZmqSetsockoptDart>(
          'zmq_setsockopt',
        );
    zmq_getsockopt = _lib
        .lookupFunction<ZmqGetsockoptNative, ZmqGetsockoptDart>(
          'zmq_getsockopt',
        );
    zmq_errno = _lib.lookupFunction<ZmqErrnoNative, ZmqErrnoDart>('zmq_errno');
    zmq_strerror = _lib.lookupFunction<ZmqStrerrorNative, ZmqStrerrorDart>(
      'zmq_strerror',
    );
  }

  /// Creates a new ZeroMQ context.
  ZMQContext ctxNew() => zmq_ctx_new();

  /// Terminates a ZeroMQ context.
  void ctxTerm(ZMQContext ctx) {
    final rc = zmq_ctx_term(ctx);
    if (rc != 0) {
      final err = zmq_errno();
      final errStr = zmq_strerror(err).toDartString();
      throw Exception('zmq_ctx_term failed: $errStr');
    }
  }

  /// Creates a new ZeroMQ socket.
  ZMQSocket socket(ZMQContext ctx, int type) => zmq_socket(ctx, type);

  /// Connects the socket to an endpoint.
  /// Uses arena allocator for automatic memory management of the string
  /// pointer.
  int connect(ZMQSocket sock, String endpoint) {
    return using((arena) {
      final ptr = endpoint.toNativeUtf8(allocator: arena);
      final result = zmq_connect(sock, ptr);
      if (result != 0) {
        final errno = zmq_errno();
        throw Exception('zmq_connect failed: errno=$errno');
      }
      return result;
    });
  }

  /// Sets a socket option and verifies it by reading it back.
  int setSocketOption(ZMQSocket sock, int option, int value) {
    return using((arena) {
      final ptr = arena<Int32>()..value = value;
      final result = zmq_setsockopt(
        sock,
        option,
        ptr.cast<Void>(),
        sizeOf<Int32>(),
      );
      if (result != 0) {
        final err = zmq_errno();
        final errStr = zmq_strerror(err).toDartString();
        throw Exception('zmq_setsockopt failed: $errStr');
      }

      final readPtr = arena<Int32>();
      final sizePtr = arena<Size>()..value = sizeOf<Int32>();

      final readResult = zmq_getsockopt(
        sock,
        option,
        readPtr.cast<Void>(),
        sizePtr,
      );
      if (readResult != 0) {
        final err = zmq_errno();
        final errStr = zmq_strerror(err).toDartString();
        throw Exception('zmq_getsockopt failed: $errStr');
      }
      return result;
    });
  }

  /// Gets a socket option as an integer.
  int getSocketOptionInt(ZMQSocket sock, int option) {
    return using((arena) {
      final readPtr = arena<Int32>();
      final sizePtr = arena<Size>()..value = sizeOf<Int32>();

      final result = zmq_getsockopt(
        sock,
        option,
        readPtr.cast<Void>(),
        sizePtr,
      );
      if (result != 0) {
        final err = zmq_errno();
        final errStr = zmq_strerror(err).toDartString();
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
      final result = zmq_send(sock, ptr.cast<Void>(), data.length, flags);
      if (result < 0) {
        final errno = zmq_errno();
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
  List<List<int>> recvMultipart(ZMQSocket sock) {
    final parts = <List<int>>[];
    while (true) {
      final part = recv(sock);
      if (part == null) {
        throw Exception('recvMultipart failed: no data received');
      }
      // Only add non-empty parts
      if (part.isNotEmpty) {
        parts.add(part);
      }

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
  List<String> recvMultipartStrings(ZMQSocket sock) {
    final parts = recvMultipart(sock);
    return parts.map(_decodeString).toList();
  }

  /// Encodes a string to UTF-8 bytes using UTF-8 encoding.
  static List<int> _encodeString(String str) {
    return utf8.encode(str);
  }

  /// Decodes UTF-8 bytes to a string.
  static String _decodeString(List<int> bytes) {
    return utf8.decode(bytes);
  }

  /// Receives a message from the socket.
  ///
  /// Uses `zmq_msg_t` to handle dynamic message sizes.
  ///
  /// Note: To avoid blocking the UI thread, this should be called within a
  /// separate Isolate or with the `ZMQ_DONTWAIT` flag.
  ///
  /// The receive timeout should be configured via `setSocketOption` with
  /// `ZMQ_RCVTIMEO` before calling this method.
  List<int>? recv(ZMQSocket sock, {int flags = 0}) {
    return using((arena) {
      // zmq_msg_t is opaque and size varies by platform, but 64 bytes is
      // generally sufficient for the structure.
      final msg = arena.allocate<Uint8>(64).cast<Void>();

      if (zmq_msg_init(msg) != 0) {
        throw Exception('zmq_msg_init failed');
      }

      try {
        while (true) {
          final n = zmq_msg_recv(msg, sock, flags);
          if (n >= 0) {
            final dataPtr = zmq_msg_data(msg);
            final size = zmq_msg_size(msg);
            if (size == 0) {
              // Return empty list for empty messages (not null)
              return <int>[];
            }
            return dataPtr.cast<Uint8>().asTypedList(size).toList();
          }

          final err = zmq_errno();
          if (err == EINTR) {
            // Interrupted system call, retry
            continue;
          }
          if (err == EAGAIN) {
            // Non-blocking mode (ZMQ_DONTWAIT) and no message available
            return null;
          }

          final errStr = zmq_strerror(err).toDartString();
          throw Exception('zmq_msg_recv failed: $errStr');
        }
      } finally {
        zmq_msg_close(msg);
      }
    });
  }

  /// Closes the socket.
  void close(ZMQSocket sock) {
    final rc = zmq_close(sock);
    if (rc != 0) {
      final err = zmq_errno();
      final errStr = zmq_strerror(err).toDartString();
      throw Exception('zmq_close failed: $errStr');
    }
  }

  /// Returns the value of `errno` for the calling thread.
  int getErrno() => zmq_errno();
}
