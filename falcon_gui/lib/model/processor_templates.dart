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
      'throttle/enabled': const BoolOption(
        value: false,
        displayName: 'Throttle',
      ),
      'throttle/threshold': const DoubleOption(
        value: 0.3,
        displayName: 'Throttle Threshold',
      ),
      'throttle/smooth': const DoubleOption(
        value: 0.5,
        displayName: 'Throttle Smooth',
      ),
      'preamble': const BoolOption(value: true, displayName: 'Preamble'),
    },
    ports: const [
      Port(name: 'data', type: 'AnyType', isIn: true),
    ],
    uiMetadata: UIMetadata(),
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
    uiMetadata: UIMetadata(),
  ),
  'burst_detector': Processor(
    id: 'burst_detector',
    className: 'BurstDetector',
    isTemplate: true,
    options: const {
      'threshold dev': DoubleOption(
        value: 3,
        displayName: 'Threshold Dev',
      ),
      'smooth time': DoubleOption(
        value: 1,
        displayName: 'Smooth Time',
      ),
      'detection lockout time': DoubleOption(
        value: 1,
        displayName: 'Detection Lockout Time',
      ),
      'stream events': BoolOption(
        value: true,
        displayName: 'Stream Events',
      ),
      'stream statistics': BoolOption(
        value: false,
        displayName: 'Stream Statistics',
      ),
      'statistics buffer size': DoubleOption(
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
        name: 'event',
        type: 'EventType',
        isIn: false,
      ),
      Port(
        name: 'statistics',
        type: 'TimeSeriesType<double>',
        isIn: false,
      ),
    ],
    uiMetadata: UIMetadata(),
  ),
  'digital_output': Processor(
    id: 'digital_output',
    className: 'DigitalOutput',
    isTemplate: true,
    options: {
      'pulse width': const IntOption(
        value: 400,
        displayName: 'Pulse Width',
      ),
      'device/type': const StringOption(
        value: 'dummy',
        displayName: 'Device Type',
      ),
      'device/nchannels': const IntOption(
        value: 16,
        displayName: 'Device Channels',
      ),
      'protocols': YamlMapOption(
        value: YamlMap.wrap({
          'event_a': {
            'high': [0, 1],
          },
        }),
        displayName: 'Protocols',
      ),
      'event logging': const BoolOption(
        value: true,
        displayName: 'Event Logging',
      ),
    },
    ports: const [
      Port(
        name: 'event',
        type: 'EventType',
        isIn: true,
      ),
    ],
    uiMetadata: UIMetadata(),
  ),
};
