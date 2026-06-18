// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef ZMQContext = Pointer<Void>;
typedef ZMQSocket = Pointer<Void>;
typedef ZMQMessage = Pointer<Void>;

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

typedef ZmqTSize = IntPtr;

// ZMQ socket types
const int ZMQ_SUB = 2;
const int ZMQ_REQ = 3;
const int ZMQ_REP = 4;
const int ZMQ_DEALER = 5;
const int ZMQ_ROUTER = 6;

// ZMQ flags
const int ZMQ_DONTWAIT = 1;
const int ZMQ_SNDMORE = 2;
const int ZMQ_RCVMORE = 13;
const int ZMQ_SUBSCRIBE = 6;
const int ZMQ_RCVTIMEO = 27;
const int ZMQ_TCP_KEEPALIVE = 42;
const int ZMQ_TCP_KEEPALIVE_CNT = 43;
const int ZMQ_TCP_KEEPALIVE_IDLE = 44;
const int ZMQ_TCP_KEEPALIVE_INTVL = 45;
const int ZMQ_REQ_RELAXED = 53;
const int ZMQ_REQ_CORRELATE = 54;

// Error constants
const int EINTR = 4;
const int EAGAIN = 11;
const int ETERM = 156384765; // Context was terminated

/// Function lookup table for ZMQ FFI functions.
class ZMQFunctionTable {
  ZMQFunctionTable(DynamicLibrary lib) {
    // Context functions
    zmq_ctx_new = lib.lookupFunction<ZmqCtxNewNative, ZmqCtxNewDart>(
      'zmq_ctx_new',
    );
    zmq_ctx_term = lib.lookupFunction<ZmqCtxTermNative, ZmqCtxTermDart>(
      'zmq_ctx_term',
    );

    // Socket functions
    zmq_socket = lib.lookupFunction<ZmqSocketNative, ZmqSocketDart>(
      'zmq_socket',
    );
    zmq_connect = lib.lookupFunction<ZmqConnectNative, ZmqConnectDart>(
      'zmq_connect',
    );
    zmq_send = lib.lookupFunction<ZmqSendNative, ZmqSendDart>('zmq_send');
    zmq_recv = lib.lookupFunction<ZmqRecvNative, ZmqRecvDart>('zmq_recv');
    zmq_close = lib.lookupFunction<ZmqCloseNative, ZmqCloseDart>('zmq_close');

    // Message functions
    zmq_msg_init = lib.lookupFunction<ZmqMsgInitNative, ZmqMsgInitDart>(
      'zmq_msg_init',
    );
    zmq_msg_close = lib.lookupFunction<ZmqMsgCloseNative, ZmqMsgCloseDart>(
      'zmq_msg_close',
    );
    zmq_msg_recv = lib.lookupFunction<ZmqMsgRecvNative, ZmqMsgRecvDart>(
      'zmq_msg_recv',
    );
    zmq_msg_data = lib.lookupFunction<ZmqMsgDataNative, ZmqMsgDataDart>(
      'zmq_msg_data',
    );
    zmq_msg_size = lib.lookupFunction<ZmqMsgSizeNative, ZmqMsgSizeDart>(
      'zmq_msg_size',
    );

    // Socket options
    zmq_setsockopt = lib.lookupFunction<ZmqSetsockoptNative, ZmqSetsockoptDart>(
      'zmq_setsockopt',
    );
    zmq_getsockopt = lib.lookupFunction<ZmqGetsockoptNative, ZmqGetsockoptDart>(
      'zmq_getsockopt',
    );

    // Error handling
    zmq_errno = lib.lookupFunction<ZmqErrnoNative, ZmqErrnoDart>('zmq_errno');
    zmq_strerror = lib.lookupFunction<ZmqStrerrorNative, ZmqStrerrorDart>(
      'zmq_strerror',
    );

    // Misc
    zmq_version = lib.lookupFunction<ZmqVersionNative, ZmqVersionDart>(
      'zmq_version',
    );
  }

  // Context functions
  late final ZmqCtxNewDart zmq_ctx_new;
  late final ZmqCtxTermDart zmq_ctx_term;

  // Socket functions
  late final ZmqSocketDart zmq_socket;
  late final ZmqConnectDart zmq_connect;
  late final ZmqSendDart zmq_send;
  late final ZmqRecvDart zmq_recv;
  late final ZmqCloseDart zmq_close;

  // Socket options
  late final ZmqSetsockoptDart zmq_setsockopt;
  late final ZmqGetsockoptDart zmq_getsockopt;

  // Message functions
  late final ZmqMsgInitDart zmq_msg_init;
  late final ZmqMsgCloseDart zmq_msg_close;
  late final ZmqMsgRecvDart zmq_msg_recv;
  late final ZmqMsgDataDart zmq_msg_data;
  late final ZmqMsgSizeDart zmq_msg_size;

  // Error handling
  late final ZmqErrnoDart zmq_errno;
  late final ZmqStrerrorDart zmq_strerror;

  // Misc
  late final ZmqVersionDart zmq_version;
}

typedef ZmqVersionNative =
    Void Function(
      Pointer<Int32> major,
      Pointer<Int32> minor,
      Pointer<Int32> patch,
    );
typedef ZmqVersionDart =
    void Function(
      Pointer<Int32> major,
      Pointer<Int32> minor,
      Pointer<Int32> patch,
    );
