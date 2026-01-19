import 'package:falcon_gui/model/falcon_graph.dart';
import 'package:falcon_gui/model/graph_serializer.dart';
import 'package:yaml/yaml.dart';

OptionValue<dynamic> optionFromScalar(
  OptionValue<dynamic> templateOption,
  dynamic value,
) {
  if (templateOption is IntOption) {
    return IntOption(
      value: value as int,
      displayName: templateOption.displayName,
    );
  }
  if (templateOption is DoubleOption) {
    return DoubleOption(
      value: value as double,
      displayName: templateOption.displayName,
    );
  }
  if (templateOption is BoolOption) {
    return BoolOption(
      value: value as bool,
      displayName: templateOption.displayName,
    );
  }
  if (templateOption is StringOption) {
    return StringOption(
      value: value as String,
      displayName: templateOption.displayName,
    );
  }
  if (templateOption is YamlNodeOption) {
    return YamlNodeOption(
      value: value as YamlNode,
      displayName: templateOption.displayName,
    );
  }
  if (templateOption is OneOfOption) {
    final v = value as String;
    if (!templateOption.allowed
        .map((allowed) => allowed.toLowerCase())
        .contains(v.toLowerCase())) {
      throw FalconGraphYamlParserException(
        'Value "$v" is not allowed for option "${templateOption.displayName}". '
        'Allowed values: ${templateOption.allowed.join(", ")}',
      );
    }
    return OneOfOption(
      value: v,
      allowed: templateOption.allowed,
      displayName: templateOption.displayName,
    );
  }
  throw FalconGraphYamlParserException(
    'Unsupported option type for "${templateOption.displayName}".',
  );
}
