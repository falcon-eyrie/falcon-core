import 'package:falcon_gui/model/falcon_graph.dart';

OneOfOption _createEncodingOption() => OneOfOption(
  value: 'binary',
  allowed: ['binary', 'yaml', 'flatbuffer'],
  displayName: 'Encoding',
);

OneOfOption _createFormatOption() => OneOfOption(
  value: 'full',
  allowed: ['none', 'full', 'compact', 'headeronly', 'streamheader'],
  displayName: 'Format',
);

final Map<String, Processor> processorDefinitions = () {
  // return sources first,
  // processors second
  // sinks last
  // within each group, sort alphabetically
  final sortedKeys = _processorDefinitionsUnsorted.keys.toList()
    ..sort((a, b) {
      final procA = _processorDefinitionsUnsorted[a]!;
      final procB = _processorDefinitionsUnsorted[b]!;

      int groupA;
      int groupB;

      if (procA.ports.any((port) => port.isSrc) &&
          !procA.ports.any((port) => !port.isSrc)) {
        groupA = 0; // source
      } else if (procA.ports.any((port) => !port.isSrc) &&
          !procA.ports.any((port) => port.isSrc)) {
        groupA = 2; // sink
      } else {
        groupA = 1; // processor
      }

      if (procB.ports.any((port) => port.isSrc) &&
          !procB.ports.any((port) => !port.isSrc)) {
        groupB = 0; // source
      } else if (procB.ports.any((port) => !port.isSrc) &&
          !procB.ports.any((port) => port.isSrc)) {
        groupB = 2; // sink
      } else {
        groupB = 1; // processor
      }

      if (groupA != groupB) {
        return groupA.compareTo(groupB);
      } else {
        return procA.className.compareTo(procB.className);
      }
    });

  return {
    for (final key in sortedKeys) key: _processorDefinitionsUnsorted[key]!,
  };
}();

final _processorDefinitionsUnsorted = {
  'file_serializer': Processor(
    id: 'file_serializer',
    className: 'FileSerializer',
    isTemplate: true,
    options: {
      'path': StringOption(
        value: 'run://',
        displayName: 'Path',
      ),
      'encoding': _createEncodingOption(),
      'format': _createFormatOption(),
      'overwrite': BoolOption(value: false, displayName: 'Overwrite'),
      'throttle/enabled': BoolOption(value: false, displayName: 'Throttle'),
      'throttle/threshold': DoubleOption(
        value: 0.3,
        displayName: 'Throttle Threshold',
      ),
      'throttle/smooth': DoubleOption(
        value: 0.5,
        displayName: 'Throttle Smooth',
      ),
      'preamble': BoolOption(value: true, displayName: 'Preamble'),
    },
    ports: [
      Port(name: 'data', type: 'AnyType', isSrc: false),
    ],
    uiMetadata: UIMetadata(),
  ),
  'nlx_pure_reader': Processor(
    id: 'nlx_pure_reader',
    className: 'NlxPureReader',
    isTemplate: true,
    options: {
      'address': StringOption(
        value: '127.0.0.1',
        displayName: 'Address',
      ),
      'port': IntOption(
        value: 5000,
        displayName: 'Port',
      ),
      'npackets': IntOption(
        value: 0,
        displayName: 'Number of Packets',
      ),
      'nchannels': IntOption(
        value: 32,
        displayName: 'Number of Channels',
      ),
    },
    ports: [
      Port(name: 'udp', type: 'VectorType<uint32_t>', isSrc: true),
    ],
    uiMetadata: UIMetadata(),
  ),
  'zmq_serializer': Processor(
    id: 'zmq_serializer',
    className: 'ZMQSerializer',
    isTemplate: true,
    options: {
      'port': IntOption(
        value: 7777,
        displayName: 'Port',
      ),
      'encoding': _createEncodingOption(),
      'format': _createFormatOption(),
      'interleave': BoolOption(value: false, displayName: 'Interleave'),
    },
    ports: [
      Port(name: 'data_port', type: 'AnyType', isSrc: false),
    ],
    uiMetadata: UIMetadata(),
  ),
  'event_logger': Processor(
    id: 'event_logger',
    className: 'EventLogger',
    isTemplate: true,
    options: {
      'target_event': StringOption(
        value: 'DEFAULT_EVENT',
        displayName: 'Target Event',
      ),
    },
    ports: [
      Port(name: 'event_port', type: 'EventType', isSrc: false),
    ],
    uiMetadata: UIMetadata(),
  ),
  'event_sync': Processor(
    id: 'event_sync',
    className: 'EventSync',
    isTemplate: true,
    options: {
      'target_event': StringOption(
        value: 'DEFAULT_EVENT',
        displayName: 'Target Event',
      ),
    },
    ports: [
      Port(name: 'data_in_port', type: 'EventType', isSrc: false),
      Port(name: 'data_out_port', type: 'EventType', isSrc: true),
    ],
    uiMetadata: UIMetadata(),
  ),
  'event_filter': Processor(
    id: 'event_filter',
    className: 'EventFilter',
    isTemplate: true,
    options: {
      'target_event': StringOption(
        value: 'DEFAULT_EVENT',
        displayName: 'Target Event',
      ),
      'blockout_time': DoubleOption(
        value: 10,
        displayName: 'Blockout Time (ms)',
      ),
      'block_wait_time': DoubleOption(
        value: 1.5,
        displayName: 'Block Wait Time (ms)',
      ),
      'sync_time': DoubleOption(
        value: 3.5,
        displayName: 'Sync Time (ms)',
      ),
      'discard_warnings': BoolOption(
        value: false,
        displayName: 'Discard Warnings',
      ),
      'detections_to_criterion': IntOption(
        value: 1,
        displayName: 'Detections to Criterion',
      ),
    },
    ports: [
      Port(name: 'data_in_port', type: 'EventType', isSrc: false),
      Port(name: 'data_out_port', type: 'EventType', isSrc: true),
      Port(name: 'block_in_port', type: 'EventType', isSrc: false),
    ],
    uiMetadata: UIMetadata(),
  ),
  'ripple_detector': Processor(
    id: 'ripple_detector',
    className: 'RippleDetector',
    isTemplate: true,
    options: {
      'initial_threshold_dev': DoubleOption(
        value: 6,
        displayName: 'Initial Threshold Dev',
      ),
      'initial_smooth_time': DoubleOption(
        value: 10,
        displayName: 'Initial Smooth Time (s)',
      ),
      'initial_detection_lockout_time': DoubleOption(
        value: 30,
        displayName: 'Initial Detection Lockout Time (ms)',
      ),
      'default_stream_events': BoolOption(
        value: true,
        displayName: 'Default Stream Events',
      ),
      'initial_stats_out': BoolOption(
        value: true,
        displayName: 'Initial Stats Out',
      ),
      'stats_buffer_size': DoubleOption(
        value: 0.5,
        displayName: 'Stats Buffer Size (s)',
      ),
      'stats_downsample_factor': IntOption(
        value: 1,
        displayName: 'Stats Downsample Factor',
      ),
      'use_power': BoolOption(
        value: true,
        displayName: 'Use Power',
      ),
    },
    ports: [
      Port(name: 'data_in_port', type: 'TimeSeriesType<double>', isSrc: false),
      Port(name: 'event_out_port', type: 'EventType', isSrc: true),
      Port(name: 'stats_out_port', type: 'TimeSeriesType<double>', isSrc: true),
    ],
    uiMetadata: UIMetadata(),
  ),
  'multi_channel_filter': Processor(
    id: 'multi_channel_filter',
    className: 'MultiChannelFilter',
    isTemplate: true,
    options: {
      'filter_def': StringOption(
        value: '/path/to/default_filter_def.yaml',
        displayName: 'Filter Definition File',
      ),
    },
    ports: [
      Port(name: 'data_in_port', type: 'TimeSeriesType<double>', isSrc: false),
      Port(name: 'data_out_port', type: 'TimeSeriesType<double>', isSrc: true),
    ],
    uiMetadata: UIMetadata(),
  ),
  'nlx_reader': Processor(
    id: 'nlx_reader',
    className: 'NlxReader',
    isTemplate: true,
    options: {
      'channelmap': StringOption(
        value: '',
        displayName: 'Channel Map',
      ),
      'address': StringOption(
        value: '127.0.0.1',
        displayName: 'Address',
      ),
      'port': IntOption(
        value: 5000,
        displayName: 'Port',
      ),
      'npackets': IntOption(
        value: 0,
        displayName: 'Number of Packets',
      ),
      'batch_size': IntOption(
        value: 1,
        displayName: 'Batch Size',
      ),
      'nchannels': IntOption(
        value: 32,
        displayName: 'Number of Channels',
      ),
      'update_interval': IntOption(
        value: 20,
        displayName: 'Update Interval (s)',
      ),
      'triggered': BoolOption(
        value: false,
        displayName: 'Triggered',
      ),
      'hardware_trigger_channel': IntOption(
        value: 0,
        displayName: 'Hardware Trigger Channel',
      ),
    },
    ports: [
      // Note: Dynamic ports created based on channelmap
    ],
    uiMetadata: UIMetadata(),
  ),
  'event_delayed': Processor(
    id: 'event_delayed',
    className: 'EventDelayed',
    isTemplate: true,
    options: {
      'default_disabled': BoolOption(
        value: false,
        displayName: 'Default Disabled',
      ),
      'initial_stop_detection_period': DoubleOption(
        value: 50,
        displayName: 'Initial Stop Detection Period (ms)',
      ),
      'when_stop_analysis_period': StringOption(
        value: '0,0',
        displayName: 'When Stop Analysis Period',
      ),
      'initial_stop_analysis_period': DoubleOption(
        value: 50,
        displayName: 'Initial Stop Analysis Period (ms)',
      ),
      'start_after_detection': BoolOption(
        value: false,
        displayName: 'Start After Detection',
      ),
      'start_after_stimulation': BoolOption(
        value: true,
        displayName: 'Start After Stimulation',
      ),
      'initial_delayed_event': BoolOption(
        value: false,
        displayName: 'Initial Delayed Event',
      ),
      'save_events': BoolOption(
        value: true,
        displayName: 'Save Events',
      ),
      'prefix': StringOption(
        value: 'stim_',
        displayName: 'Prefix',
      ),
      'msg_delayed': StringOption(
        value: 'd',
        displayName: 'Message Delayed',
      ),
      'msg_detection': StringOption(
        value: 'r',
        displayName: 'Message Detection',
      ),
      'msg_ontime': StringOption(
        value: 'o',
        displayName: 'Message Ontime',
      ),
      'initial_delayed_range': StringOption(
        value: '150,200',
        displayName: 'Initial Delayed Range',
      ),
    },
    ports: [
      Port(name: 'data_in_port', type: 'EventType', isSrc: false),
      Port(name: 'output_port', type: 'EventType', isSrc: true),
    ],
    uiMetadata: UIMetadata(),
  ),
};
