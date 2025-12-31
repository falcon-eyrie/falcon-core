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
      'filepath': StringOption(
        value: '/path/to/output/file',
        displayName: 'File Path',
      ),
      'overwrite': BoolOption(value: false, displayName: 'Overwrite'),
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
    inputPorts: [
      Port(name: 'input', type: 'TimeSeriesType<double>'),
    ],
    outputPorts: [
      Port(name: 'output', type: 'TimeSeriesType<double>'),
    ],
    uiMetadata: UIMetadata(),
  ),
};
