import 'package:falcon_gui/model/falcon_graph.dart';

final processorTemplates = {
  'source': Processor(
    id: 'source',
    className: 'SourceProcessor',
    isTemplate: true,
    options: {
      'nchannels': IntOption(32),
      'format': OneOfOption(
        'compact',
        ['compact', 'verbose'],
      ),
      'enabled': BoolOption(true),
    },
    inputPorts: [],
    outputPorts: [
      Port(name: 'ripple', type: 'TimeSeriesType<double>'),
    ],
    uiMetadata: UIMetadata(),
  ),
  'sink': Processor(
    id: 'sink',
    className: 'SinkProcessor',
    isTemplate: true,
    options: {
      'filepath': StringOption('/path/to/output/file'),
      'overwrite': BoolOption(false),
    },
    inputPorts: [
      Port(name: 'input', type: 'TimeSeriesType<double>'),
    ],
    outputPorts: [],
    uiMetadata: UIMetadata(),
  ),
  'filter': Processor(
    id: 'filter',
    className: 'FilterProcessor',
    isTemplate: true,
    options: {
      'cutoff_frequency': DoubleOption(0.5),
      'filter_type': OneOfOption(
        'lowpass',
        [
          'lowpass',
          'highpass',
          'bandpass',
        ],
      ),
    },
    inputPorts: [
      Port(name: 'input', type: 'TimeSeriesType<double>'),
    ],
    outputPorts: [
      Port(name: 'output', type: 'TimeSeriesType<double>'),
    ],
    uiMetadata: UIMetadata(),
  ),
};
