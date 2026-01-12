enum FalconState {
  noGraph,
  constructing,
  preparing,
  ready,
  starting,
  processing,
  stopping,
  error,
  unknown
  ;

  factory FalconState.fromString(String stateStr) {
    switch (stateStr) {
      case 'UNKNOWN':
        return FalconState.unknown;
      case 'NOGRAPH':
        return FalconState.noGraph;
      case 'CONSTRUCTING':
        return FalconState.constructing;
      case 'PREPARING':
        return FalconState.preparing;
      case 'READY':
        return FalconState.ready;
      case 'STARTING':
        return FalconState.starting;
      case 'PROCESSING':
        return FalconState.processing;
      case 'STOPPING':
        return FalconState.stopping;
      case 'ERROR':
        return FalconState.error;
      default:
        throw ArgumentError('Unknown FalconState string: $stateStr');
    }
  }

  @override
  String toString() {
    switch (this) {
      case FalconState.unknown:
        return 'UNKNOWN';
      case FalconState.noGraph:
        return 'NOGRAPH';
      case FalconState.constructing:
        return 'CONSTRUCTING';
      case FalconState.preparing:
        return 'PREPARING';
      case FalconState.ready:
        return 'READY';
      case FalconState.starting:
        return 'STARTING';
      case FalconState.processing:
        return 'PROCESSING';
      case FalconState.stopping:
        return 'STOPPING';
      case FalconState.error:
        return 'ERROR';
    }
  }
}
