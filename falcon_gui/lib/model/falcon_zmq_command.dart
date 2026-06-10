/// Falcon commands matching Python FalconCommand enum
enum FalconZmqCommand {
  graphStart,
  graphStop,
  graphTest,
  graphDestroy,
  graphState,
  graphYaml,
  info,
  documentation,
  quit,
  kill,
  testOn,
  testOff,
  testToggle,
  resourcesList;

  /// Convert command to list of string parts for ZMQ multipart message
  List<String> serialize() {
    switch (this) {
      case FalconZmqCommand.graphStart:
        return ['graph', 'start'];
      case FalconZmqCommand.graphStop:
        return ['graph', 'stop'];
      case FalconZmqCommand.graphTest:
        return ['graph', 'test'];
      case FalconZmqCommand.graphDestroy:
        return ['graph', 'destroy'];
      case FalconZmqCommand.graphState:
        return ['graph', 'state'];
      case FalconZmqCommand.graphYaml:
        return ['graph', 'yaml'];
      case FalconZmqCommand.info:
        return ['info'];
      case FalconZmqCommand.documentation:
        return ['documentation'];
      case FalconZmqCommand.quit:
        return ['quit'];
      case FalconZmqCommand.kill:
        return ['kill'];
      case FalconZmqCommand.testOn:
        return ['test', 'true'];
      case FalconZmqCommand.testOff:
        return ['test', 'false'];
      case FalconZmqCommand.testToggle:
        return ['test'];
      case FalconZmqCommand.resourcesList:
        return ['resources', 'list'];
    }
  }

  /// Create custom command with arbitrary parts
  static List<String> custom(List<String> parts) => parts;

  /// Create graph build command
  static List<String> graphBuild(String graphFile) => [
    'graph',
    'build',
    graphFile,
  ];

  /// Create resources list type command
  static List<String> resourcesListType(String resourceType) => [
    'resources',
    'list',
    resourceType,
  ];

  /// Create resources graph command
  static List<String> resourcesGraph(String graphPath) => [
    'resources',
    'graphs',
    graphPath,
  ];
}
