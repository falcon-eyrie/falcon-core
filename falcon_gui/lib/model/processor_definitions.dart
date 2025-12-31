import 'package:falcon_gui/model/falcon_graph.dart';

final processorDefinitions = {
  'source': Processor(
    id: 'source',
    className: 'SourceProcessor',
    isTemplate: true,
    options: {
      'nchannels': IntOption(value: 32, displayName: 'Number of Channels'),
      'format': OneOfOption(
        value: 'compact',
        allowed: ['compact', 'verbose'],
        displayName: 'Format',
      ),
      'enabled': BoolOption(value: true, displayName: 'Enabled'),
    },
    ports: [
      Port(name: 'ripple', type: 'TimeSeriesType<double>', isSrc: true),
    ],
    uiMetadata: UIMetadata(),
  ),
  'sink': Processor(
    id: 'sink',
    className: 'SinkProcessor',
    isTemplate: true,
    options: {
      'filepath': StringOption(
        value: '/path/to/output/file',
        displayName: 'File Path',
      ),
      'overwrite': BoolOption(value: false, displayName: 'Overwrite'),
    },
    ports: [
      Port(name: 'input', type: 'AnyType', isSrc: false),
    ],
    uiMetadata: UIMetadata(),
  ),
  'filter': Processor(
    id: 'filter',
    className: 'FilterProcessor',
    isTemplate: true,
    options: {
      'cutoff_frequency': DoubleOption(
        value: 0.5,
        displayName: 'Cutoff Frequency',
      ),
      'filter_type': OneOfOption(
        value: 'lowpass',
        allowed: [
          'lowpass',
          'highpass',
          'bandpass',
        ],
        displayName: 'Filter Type',
      ),
    },
    ports: [
      Port(name: 'input', type: 'TimeSeriesType<double>', isSrc: false),
      Port(name: 'trigger', type: 'EventType', isSrc: false),
      Port(name: 'output', type: 'TimeSeriesType<double>', isSrc: true),
      Port(name: 'threshold', type: 'EventType', isSrc: true),
      Port(name: 'noise', type: 'MeasurementType<double>', isSrc: true),
      Port(name: 'levels', type: 'LevelType', isSrc: true),
    ],
    uiMetadata: UIMetadata(),
  ),
  'distruptor': Processor(
    id: 'distruptor',
    className: 'DistruptorProcessor',
    isTemplate: true,
    options: {
      'intensity': DoubleOption(value: 1, displayName: 'Intensity'),
      'mode': OneOfOption(
        value: 'random',
        allowed: [
          'random',
          'patterned',
        ],
        displayName: 'Mode',
      ),
    },
    ports: [
      Port(name: 'input', type: 'TimeSeriesType<double>', isSrc: false),
      Port(name: 'output', type: 'TimeSeriesType<double>', isSrc: true),
    ],
    uiMetadata: UIMetadata(),
  ),
};
