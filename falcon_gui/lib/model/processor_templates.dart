import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/utils/theme.dart';
import 'package:yaml/yaml.dart';

OneOfOption _createEncodingOption() => OneOfOption(
  value: 'binary',
  allowed: const ['binary', 'yaml', 'flatbuffer'],
  displayName: 'Encoding',
);

OneOfOption _createFormatOption() => OneOfOption(
  value: 'full',
  allowed: const ['none', 'full', 'compact', 'headeronly', 'streamheader'],
  displayName: 'Format',
);

final Map<String, Processor> processorTemplates = () {
  // Register default colors
  for (final processor in _processorTemplatesUnsorted.values) {
    DefaultProcessorColor.register(processor.className);
  }

  // Sort processors: sources first, then intermediates,
  // then sinks; each group alphabetically
  final sortedKeys = _processorTemplatesUnsorted.keys.toList()
    ..sort((a, b) {
      final procA = _processorTemplatesUnsorted[a]!;
      final procB = _processorTemplatesUnsorted[b]!;

      int rank(Processor p) {
        if (p.isSource) return 0;
        if (p.isSink) return 2;
        return 1;
      }

      final rankA = rank(procA);
      final rankB = rank(procB);

      if (rankA != rankB) {
        return rankA.compareTo(rankB);
      } else {
        return procA.className.compareTo(procB.className);
      }
    });

  return <String, Processor>{
    for (final key in sortedKeys) key: _processorTemplatesUnsorted[key]!,
  };
}();

final _processorTemplatesUnsorted = {
  'file_serializer': Processor(
    id: 'file_serializer',
    className: 'FileSerializer',
    isTemplate: true,
    options: {
      'path': const StringOption(
        value: 'run://',
        displayName: 'Path',
      ),
      'encoding': _createEncodingOption(),
      'format': _createFormatOption(),
      'overwrite': const BoolOption(value: false, displayName: 'Overwrite'),
      'throttle_enabled': const BoolOption(
        value: false,
        displayName: 'Throttle',
      ),
      'throttle_threshold': const DoubleOption(
        value: 0.3,
        displayName: 'Throttle Threshold',
      ),
      'throttle_smooth': const DoubleOption(
        value: 0.5,
        displayName: 'Throttle Smooth',
      ),
      'preamble': const BoolOption(value: true, displayName: 'Preamble'),
    },
    ports: const [
      Port(name: 'data', type: 'AnyType', isIn: true),
    ],
  ),
  'nlx_pure_reader': Processor(
    id: 'nlx_pure_reader',
    className: 'NlxPureReader',
    isTemplate: true,
    options: const {
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
    ports: const [
      Port(name: 'udp', type: 'VectorType<uint32_t>', isIn: false),
    ],
  ),
  'burst_detector': Processor(
    id: 'burst_detector',
    className: 'BurstDetector',
    isTemplate: true,
    options: const {
      'threshold_dev': DoubleOption(
        value: 3,
        displayName: 'Threshold Dev',
      ),
      'smooth_time': DoubleOption(
        value: 1,
        displayName: 'Smooth Time',
      ),
      'detection_lockout_time': DoubleOption(
        value: 1,
        displayName: 'Detection Lockout Time',
      ),
      'stream_events': BoolOption(
        value: true,
        displayName: 'Stream Events',
      ),
      'stream_statistics': BoolOption(
        value: false,
        displayName: 'Stream Statistics',
      ),
      'statistics_buffer_size': DoubleOption(
        value: 1,
        displayName: 'Statistics Buffer Size',
      ),
    },
    ports: const [
      Port(
        name: 'mua',
        type: 'MUAType',
        isIn: true,
      ),
      Port(
        name: 'events',
        type: 'EventType',
        isIn: false,
      ),
      Port(
        name: 'statistics',
        type: 'TimeSeriesType<double>',
        isIn: false,
      ),
    ],
  ),
  'digital_output': Processor(
    id: 'digital_output',
    className: 'DigitalOutput',
    isTemplate: true,
    options: {
      'pulse_width': const IntOption(
        value: 400,
        displayName: 'Pulse Width',
      ),
      'device_type': const StringOption(
        value: 'dummy',
        displayName: 'Device Type',
      ),
      'device_nchannels': const IntOption(
        value: 16,
        displayName: 'Device Channels',
      ),
      'protocols': YamlNodeOption(
        value: YamlMap.wrap({
          'event_a': {
            'high': [0, 1],
          },
        }),
        displayName: 'Protocols',
      ),
      'event_logging': const BoolOption(
        value: true,
        displayName: 'Event Logging',
      ),
    },
    ports: const [
      Port(
        name: 'events',
        type: 'EventType',
        isIn: true,
      ),
    ],
  ),
  'event2state': Processor(
    id: 'event2state',
    className: 'Event2State',
    isTemplate: true,
    options: const {
      'target_event': StringOption(
        value: 'DEFAULT_EVENT',
        displayName: 'Target Event',
      ),
    },
    ports: const [
      Port(
        name: 'events',
        type: 'EventType',
        isIn: true,
      ),
      Port(
        name: 'events',
        type: 'EventType',
        isIn: false,
      ),
    ],
  ),
  'event_converter': Processor(
    id: 'event_converter',
    className: 'EventConverter',
    isTemplate: true,
    options: const {
      'event_name': StringOption(
        value: 'DEFAULT_EVENT',
        displayName: 'Event Name',
      ),
      'replace': BoolOption(
        value: true,
        displayName: 'Replace',
      ),
    },
    ports: const [
      Port(
        name: 'events',
        type: 'EventType',
        isIn: true,
      ),
      Port(
        name: 'events',
        type: 'EventType',
        isIn: false,
      ),
    ],
  ),
  'event_delayed': Processor(
    id: 'event_delayed',
    className: 'EventDelayed',
    isTemplate: true,
    options: {
      'detection_only_mode': const BoolOption(
        value: false,
        displayName: 'Detection Only Mode',
      ),
      'delayed_mode': const BoolOption(
        value: false,
        displayName: 'Delayed Mode',
      ),
      'delayed_range': YamlNodeOption(
        // TODO(ben): change to vector option for
        // options::Value<std::vector<long int>, true>
        //      initial_delayed_range_{{150, 200}};
        value: YamlList.wrap([150, 200]),
        displayName: 'Delayed Range (ms)',
      ),
      'message_detection': const StringOption(
        value: 'r',
        displayName: 'Detection Message',
      ),
      'message_delayed': const StringOption(
        value: 'd',
        displayName: 'Delayed Message',
      ),
      'message_ontime': const StringOption(
        value: 'o',
        displayName: 'On-time Message',
      ),
      'analysis_lockout_time_starting_time': YamlNodeOption(
        // TODO(ben): change to vector option for
        // options::Value<std::vector<int>, true>
        //      when_stop_analysis_period_{{0, 0}};
        value: YamlList.wrap([0, 0]),
        displayName: 'Analysis Lockout Start',
      ),
      'analysis_lockout_time_period': const DoubleOption(
        value: 50,
        displayName: 'Analysis Lockout Period (ms)',
      ),
      'event_trigger_lockout_time_period': const DoubleOption(
        value: 50,
        displayName: 'Detection Lockout Period (ms)',
      ),
      'event_trigger_lockout_time_detection': const BoolOption(
        value: false,
        displayName: 'Lockout After Detection',
      ),
      'event_trigger_lockout_time_stimulation': const BoolOption(
        value: true,
        displayName: 'Lockout After Stimulation',
      ),
      'enable_saving': const BoolOption(
        value: true,
        displayName: 'Enable Saving',
      ),
      'filename_prefix': const StringOption(
        value: 'stim_',
        displayName: 'Filename Prefix',
      ),
    },
    ports: const [
      Port(
        name: 'events',
        type: 'EventType',
        isIn: true,
      ),
      Port(
        name: 'events',
        type: 'EventType',
        isIn: false,
      ),
    ],
  ),
  'ripple_detector': Processor(
    id: 'ripple_detector',
    className: 'RippleDetector',
    isTemplate: true,
    options: const {
      'threshold_dev': DoubleOption(
        value: 6,
        displayName: 'Threshold Dev',
      ),
      'smooth_time': DoubleOption(
        value: 10,
        displayName: 'Smooth Time (s)',
      ),
      'analysis_lockout_time': DoubleOption(
        value: 30,
        displayName: 'Detection Lockout Time (ms)',
      ),
      'stream_events': BoolOption(
        value: true,
        displayName: 'Stream Events',
      ),
      'stream_statistics': BoolOption(
        value: true,
        displayName: 'Stream Statistics',
      ),
      'statistics_buffer_size': DoubleOption(
        value: 0.5,
        displayName: 'Statistics Buffer Size (s)',
      ),
      'statistics_downsample_factor': IntOption(
        value: 1,
        displayName: 'Statistics Downsample Factor',
      ),
      'use_power': BoolOption(
        value: true,
        displayName: 'Use Power',
      ),
    },
    ports: const [
      Port(
        name: 'data',
        type: 'TimeSeriesType<double>',
        isIn: true,
      ),
      Port(
        name: 'events',
        type: 'EventType',
        isIn: false,
      ),
      Port(
        name: 'statistics',
        type: 'TimeSeriesType<double>',
        isIn: false,
      ),
    ],
  ),
  'event_filter': Processor(
    id: 'event_filter',
    className: 'EventFilter',
    isTemplate: true,
    options: const {
      'block_duration': DoubleOption(
        value: 10,
        displayName: 'Block Duration (ms)',
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
      'detection_criterion': IntOption(
        value: 1,
        displayName: 'Detection Criterion',
      ),
    },
    ports: const [
      Port(
        name: 'events',
        type: 'EventType',
        isIn: true,
      ),
      Port(
        name: 'blocking_events',
        type: 'EventType',
        isIn: true,
      ),
      Port(
        name: 'events',
        type: 'EventType',
        isIn: false,
      ),
    ],
  ),
  'event_logger': Processor(
    id: 'event_logger',
    className: 'EventLogger',
    isTemplate: true,
    options: const {
      'target_event': StringOption(
        value: 'DEFAULT_EVENT',
        displayName: 'Target Event',
      ),
    },
    ports: const [
      Port(
        name: 'events',
        type: 'EventType',
        isIn: true,
      ),
    ],
  ),

  'event_source': Processor(
    id: 'event_source',
    className: 'EventSource',
    isTemplate: true,
    options: {
      'events': YamlNodeOption(
        value: YamlList.wrap(['DEFAULT_EVENT']),
        displayName: 'Events',
      ),
      'rate': const DoubleOption(
        value: 1,
        displayName: 'Event Rate (Hz)',
      ),
    },
    ports: const [
      Port(
        name: 'events',
        type: 'EventType',
        isIn: false,
      ),
    ],
  ),
  'event_sync': Processor(
    id: 'event_sync',
    className: 'EventSync',
    isTemplate: true,
    options: const {
      'target_event': StringOption(
        value: 'DEFAULT_EVENT',
        displayName: 'Target Event',
      ),
    },
    ports: const [
      Port(
        name: 'events',
        type: 'EventType',
        isIn: true,
      ),
      Port(
        name: 'events',
        type: 'EventType',
        isIn: false,
      ),
    ],
  ),
  'level_crossing_detector': Processor(
    id: 'level_crossing_detector',
    className: 'LevelCrossingDetector',
    isTemplate: true,
    options: const {
      'threshold': DoubleOption(
        value: 100,
        displayName: 'Threshold',
      ),
      'upslope': BoolOption(
        value: true,
        displayName: 'Upslope',
      ),
      'post_detect_block': IntOption(
        value: 2,
        displayName: 'Post Detect Block (samples)',
      ),
      'event': StringOption(
        value: 'threshold_crossing',
        displayName: 'Event Name',
      ),
    },
    ports: const [
      Port(
        name: 'data',
        type: 'TimeSeriesType<double>',
        isIn: true,
      ),
      Port(
        name: 'events',
        type: 'EventType',
        isIn: false,
      ),
    ],
  ),
  'mua_estimator': Processor(
    id: 'mua_estimator',
    className: 'MUAEstimator',
    isTemplate: true,
    options: const {
      'bin_size': DoubleOption(
        value: 10,
        displayName: 'Bin Size (ms)',
      ),
    },
    ports: const [
      Port(
        name: 'spikes',
        type: 'SpikeType',
        isIn: true,
      ),
      Port(
        name: 'mua',
        type: 'MUAType',
        isIn: false,
      ),
    ],
  ),
  'nlx_parser': Processor(
    id: 'nlx_parser',
    className: 'NlxParser',
    isTemplate: true,
    options: const {
      'batch_size': IntOption(
        value: 1,
        displayName: 'Batch Size',
      ),
      'update_interval': DoubleOption(
        value: 0,
        displayName: 'Update Interval (s)',
      ),
      'trigger_enabled': BoolOption(
        value: false,
        displayName: 'Trigger Enabled',
      ),
      'trigger_channel': IntOption(
        value: 0,
        displayName: 'Trigger Channel',
      ),
      'gap_fill': StringOption(
        value: 'none',
        displayName: 'Gap Fill',
      ),
    },
    ports: const [
      Port(
        name: 'udp',
        type: 'VectorType<uint32_t>',
        isIn: true,
      ),
      Port(
        name: 'data',
        type: 'TimeSeriesType<double>',
        isIn: false,
      ),
      Port(
        name: 'ttl',
        type: 'TimeSeriesType<uint32_t>',
        isIn: false,
      ),
    ],
  ),
  'zmq_serializer': Processor(
    id: 'zmq_serializer',
    className: 'ZMQSerializer',
    isTemplate: true,
    options: {
      'port': const IntOption(
        value: 5555,
        displayName: 'Port',
      ),
      'encoding': _createEncodingOption(),
      'format': _createFormatOption(),
      'interleave': const BoolOption(
        value: false,
        displayName: 'Interleave',
      ),
    },
    ports: const [
      Port(
        name: 'data',
        type: 'AnyType',
        isIn: true,
      ),
    ],
  ),
  'spike_detector': Processor(
    id: 'spike_detector',
    className: 'SpikeDetector',
    isTemplate: true,
    options: const {
      'threshold': DoubleOption(
        value: 0,
        displayName: 'Threshold',
      ),
      'invert_signal': BoolOption(
        value: false,
        displayName: 'Invert Signal',
      ),
      'buffer_size': DoubleOption(
        value: 1,
        displayName: 'Buffer Size (s)',
      ),
      'strict_time_bin_check': BoolOption(
        value: true,
        displayName: 'Strict Time Bin Check',
      ),
      'peak_lifetime': IntOption(
        value: 1,
        displayName: 'Peak Lifetime (samples)',
      ),
    },
    ports: const [
      Port(
        name: 'data',
        type: 'TimeSeriesType<double>',
        isIn: true,
      ),
      Port(
        name: 'spikes',
        type: 'SpikeType',
        isIn: false,
      ),
      Port(
        name: 'events',
        type: 'EventType',
        isIn: false,
      ),
    ],
  ),
  'serial_output': Processor(
    id: 'serial_output',
    className: 'SerialOutput',
    isTemplate: true,
    options: const {
      'port_address': StringOption(
        value: '/dev/ttyACM0',
        displayName: 'Port Address',
      ),
      'baud_rate': IntOption(
        value: 9600,
        displayName: 'Baudrate',
      ),
      'event_logging': BoolOption(
        value: true,
        displayName: 'Event Logging',
      ),
    },
    ports: const [
      Port(
        name: 'events',
        type: 'EventType',
        isIn: true,
      ),
    ],
  ),
  'running_stats': Processor(
    id: 'running_stats',
    className: 'RunningStats',
    isTemplate: true,
    options: const {
      'integration_time': DoubleOption(
        value: 1,
        displayName: 'Integration Time (s)',
      ),
      'outlier_protection': BoolOption(
        value: false,
        displayName: 'Outlier Protection',
      ),
      'outlier_zscore': DoubleOption(
        value: 6,
        displayName: 'Outlier Z-Score',
      ),
      'outlier_half_life': DoubleOption(
        value: 2,
        displayName: 'Outlier Half-Life',
      ),
    },
    ports: const [
      Port(
        name: 'data',
        type: 'TimeSeriesType<double>',
        isIn: true,
      ),
      Port(
        name: 'data',
        type: 'TimeSeriesType<double>',
        isIn: false,
      ),
    ],
  ),
  'rebuffer': Processor(
    id: 'rebuffer',
    className: 'Rebuffer',
    isTemplate: true,
    options: const {
      'downsample_factor': IntOption(
        value: 1,
        displayName: 'Downsample Factor',
      ),
      'buffer_size': DoubleOption(
        value: 10,
        displayName: 'Buffer Size (s)',
      ),
    },
    ports: const [
      Port(
        name: 'data',
        type: 'TimeSeriesType<double>',
        isIn: true,
      ),
      Port(
        name: 'data',
        type: 'TimeSeriesType<double>',
        isIn: false,
      ),
    ],
  ),
};
