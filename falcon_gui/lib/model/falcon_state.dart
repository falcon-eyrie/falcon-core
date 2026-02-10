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
        return 'Unknown';
      case FalconState.noGraph:
        return 'NoGraph';
      case FalconState.constructing:
        return 'Constructing';
      case FalconState.preparing:
        return 'Preparing';
      case FalconState.ready:
        return 'Ready';
      case FalconState.starting:
        return 'Starting';
      case FalconState.processing:
        return 'Processing';
      case FalconState.stopping:
        return 'Stopping';
      case FalconState.error:
        return 'Error';
    }
  }
}
