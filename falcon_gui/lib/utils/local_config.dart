// ignore_for_file: deprecated_consistency,
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:io';
import 'package:falcon_gui/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

late LocalConfig _config;
LocalConfig get localConfig => _config;

abstract class LocalConfigManager {
  static final File _configFile = kDebugMode
      ? File('falcon/debug_config.yaml')
      : File('config.yaml');

  static Future<void> setThemeMode(String modeName) async {
    _config = _config.copyWith(themeMode: modeName);
    await _saveConfig();
  }

  static Future<void> setLastOpenedGraphFilePath(String path) async {
    _config = _config.copyWith(lastOpenedGraph: path);
    await _saveConfig();
  }

  static Future<void> loadConfig() async {
    try {
      // ignore: avoid_slow_async_io
      if (await _configFile.exists()) {
        final content = await _configFile.readAsString();
        final yamlMap = loadYaml(content) as YamlMap;
        _config = LocalConfig.fromMap(
          _yamlMapToMap(yamlMap) as Map<String, dynamic>,
        );
      } else {
        _config = LocalConfig();
      }
    } catch (e, s) {
      logError('Error loading local config: $e', s);
      _config = LocalConfig();
    }
  }

  static Future<void> _saveConfig() async {
    try {
      final yamlWriter = YamlWriter();
      final yamlString = yamlWriter.write(_config.toMap());
      await _configFile.writeAsString(yamlString);
    } catch (e, s) {
      logError('Error saving local config: $e', s);
    }
  }

  static dynamic _yamlMapToMap(dynamic yaml) {
    if (yaml is YamlMap) {
      return yaml.map(
        (key, value) => MapEntry(key.toString(), _yamlMapToMap(value)),
      );
    } else if (yaml is YamlList) {
      return yaml.map(_yamlMapToMap).toList();
    }
    return yaml;
  }
}

class LocalConfig {
  LocalConfig({
    this.themeMode,
    this.lastOpenedGraph,
    this.graphFile,
    this.graphAutostart,
    this.debugEnabled,
    this.networkPort,
    this.loggingPath,
  });
  factory LocalConfig.fromMap(Map<String, dynamic> map) {
    final graph = map['graph'] as Map?;
    final debug = map['debug'] as Map?;
    final network = map['network'] as Map?;
    final logging = map['logging'] as Map?;
    final ui = map['ui'] as Map?;

    return LocalConfig(
      graphFile: graph?['file'] as String?,
      graphAutostart: graph?['autostart'] as bool?,
      debugEnabled: debug?['enabled'] as bool?,
      networkPort: network?['port'] as int?,
      loggingPath: logging?['path'] as String?,
      themeMode: ui?['theme_mode'] as String?,
      lastOpenedGraph: ui?['last_opened_graph'] as String?,
    );
  }

  final String? themeMode;
  final String? lastOpenedGraph;

  @Deprecated("Do not use this field. It's for falcon backend.")
  final String? graphFile;
  @Deprecated("Do not use this field. It's for falcon backend.")
  final bool? graphAutostart;
  @Deprecated("Do not use this field. It's for falcon backend.")
  final bool? debugEnabled;
  @Deprecated("Do not use this field. It's for falcon backend.")
  final int? networkPort;
  @Deprecated("Do not use this field. It's for falcon backend.")
  final String? loggingPath;

  Map<String, dynamic> toMap() {
    return {
      'graph': {
        'file': graphFile,
        'autostart': graphAutostart,
      },
      'debug': {'enabled': debugEnabled},
      'network': {'port': networkPort},
      'logging': {'path': loggingPath},
      'ui': {
        'theme_mode': themeMode,
        'last_opened_graph': lastOpenedGraph,
      },
    };
  }

  LocalConfig copyWith({
    String? themeMode,
    String? lastOpenedGraph,
    String? graphFile,
    bool? graphAutostart,
    bool? debugEnabled,
    int? networkPort,
    String? loggingPath,
  }) {
    return LocalConfig(
      themeMode: themeMode ?? this.themeMode,
      lastOpenedGraph: lastOpenedGraph ?? this.lastOpenedGraph,
      graphFile: graphFile ?? this.graphFile,
      graphAutostart: graphAutostart ?? this.graphAutostart,
      debugEnabled: debugEnabled ?? this.debugEnabled,
      networkPort: networkPort ?? this.networkPort,
      loggingPath: loggingPath ?? this.loggingPath,
    );
  }
}
