// ignore_for_file: deprecated_consistency,
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:io';
import 'package:falcon_gui/utils/logger.dart';
import 'package:falcon_gui/utils/misc.dart';
import 'package:flutter/foundation.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

ValueNotifier<LocalConfig> localConfigNotifier = ValueNotifier(LocalConfig());

abstract class LocalConfigManager {
  static final File _configFile = kDebugMode
      ? File('build/falcon/config.yaml')
      : File('config.yaml');

  static Future<void> setThemeMode(String modeName) async {
    if (localConfigNotifier.value.themeMode != modeName) {
      localConfigNotifier.value = localConfigNotifier.value.copyWith(
        themeMode: modeName,
      );
      await _saveConfig();
    }
  }

  static Future<void> setLastOpenedGraphFilePath(String path) async {
    if (localConfigNotifier.value.lastOpenedGraph != path) {
      localConfigNotifier.value = localConfigNotifier.value.copyWith(
        lastOpenedGraph: path,
      );
      await _saveConfig();
    }
  }

  static Future<void> setServerSideStorageResources(String path) async {
    if (localConfigNotifier.value.serverSideStorageResources != path) {
      localConfigNotifier.value = localConfigNotifier.value.copyWith(
        serverSideStorageResources: path,
      );
      await _saveConfig();
    }
  }

  static Future<void> setServerSideStorageEnvironment(String path) async {
    if (localConfigNotifier.value.serverSideStorageEnvironment != path) {
      localConfigNotifier.value = localConfigNotifier.value.copyWith(
        serverSideStorageEnvironment: path,
      );
      await _saveConfig();
    }
  }

  static Future<void> setLoggingPath(String path) async {
    if (localConfigNotifier.value.loggingPath != path) {
      localConfigNotifier.value = localConfigNotifier.value.copyWith(
        loggingPath: path,
      );
      await _saveConfig();
    }
  }

  static Future<void> loadConfig() async {
    try {
      // ignore: avoid_slow_async_io
      if (await _configFile.exists()) {
        final content = await _configFile.readAsString();
        final yamlMap = loadYaml(content) as YamlMap;
        localConfigNotifier.value = LocalConfig.fromMap(
          _yamlMapToMap(yamlMap) as Map<String, dynamic>,
        );
      } else {
        localConfigNotifier.value = LocalConfig();
        await _saveConfig();
      }
    } catch (e, s) {
      logError('Error loading local config: $e', s);
      localConfigNotifier.value = LocalConfig();
    }
  }

  static Future<void> _saveConfig() async {
    try {
      final yamlWriter = YamlWriter();
      final yamlString = yamlWriter.write(localConfigNotifier.value.toMap());
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
    this.themeMode = 'system',
    this.networkPort = 5555,
    this.loggingPath = r'$HOME/falcon/output/logs/',
    this.serverSideStorageEnvironment = r'$HOME/falcon/output/',
    this.serverSideStorageResources = r'$HOME/falcon/resources/',
    this.lastOpenedGraph,
    this.graphFile,
    this.graphAutostart,
    this.debugEnabled,
  });

  factory LocalConfig.fromMap(Map<String, dynamic> map) {
    final graph = map['graph'] as Map?;
    final debug = map['debug'] as Map?;
    final network = map['network'] as Map?;
    final logging = map['logging'] as Map?;
    final serverSideStorage = map['server_side_storage'] as Map?;
    final ui = map['ui'] as Map?;

    return LocalConfig(
      networkPort: network?['port'] as int? ?? 5555,
      loggingPath: logging?['path'] as String? ?? r'$HOME/falcon/output/logs/',
      serverSideStorageEnvironment:
          serverSideStorage?['environment'] as String? ??
          r'$HOME/falcon/output/',
      serverSideStorageResources:
          serverSideStorage?['resources'] as String? ??
          r'$HOME/falcon/resources/',
      themeMode: ui?['theme_mode'] as String? ?? 'system',
      graphFile: graph?['file'] as String?,
      graphAutostart: graph?['autostart'] as bool?,
      debugEnabled: debug?['enabled'] as bool?,
      lastOpenedGraph: ui?['last_opened_graph'] as String?,
    );
  }

  final String themeMode;
  final String? lastOpenedGraph;

  @Deprecated("Do not use this field. It's for falcon backend.")
  final String? graphFile;
  @Deprecated("Do not use this field. It's for falcon backend.")
  final bool? graphAutostart;
  @Deprecated("Do not use this field. It's for falcon backend.")
  final bool? debugEnabled;
  final int networkPort;
  final String loggingPath;
  final String serverSideStorageEnvironment;
  final String serverSideStorageResources;

  Map<String, dynamic> toMap() {
    return {
      'graph': {
        if (graphFile != null) 'file': graphFile!.absolutePath,
        if (graphAutostart != null) 'autostart': graphAutostart,
      },
      if (debugEnabled != null) 'debug': {'enabled': debugEnabled},
      'network': {'port': networkPort},
      'logging': {'path': loggingPath.absolutePath},
      'server_side_storage': {
        'environment': serverSideStorageEnvironment.absolutePath,
        'resources': serverSideStorageResources.absolutePath,
      },
      'ui': {
        'theme_mode': themeMode,
        'last_opened_graph': lastOpenedGraph?.absolutePath,
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
    String? serverSideStorageEnvironment,
    String? serverSideStorageResources,
  }) {
    return LocalConfig(
      themeMode: themeMode ?? this.themeMode,
      lastOpenedGraph: lastOpenedGraph ?? this.lastOpenedGraph,
      graphFile: graphFile ?? this.graphFile,
      graphAutostart: graphAutostart ?? this.graphAutostart,
      debugEnabled: debugEnabled ?? this.debugEnabled,
      networkPort: networkPort ?? this.networkPort,
      loggingPath: loggingPath ?? this.loggingPath,
      serverSideStorageEnvironment:
          serverSideStorageEnvironment ?? this.serverSideStorageEnvironment,
      serverSideStorageResources:
          serverSideStorageResources ?? this.serverSideStorageResources,
    );
  }
}

extension _AbsolutePath on String {
  String get absolutePath => getAbsolutePathForUbuntu(this);
}
