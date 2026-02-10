# Falcon GUI

Linux GUI for Falcon backend. Main capabilities include:

- Design falcon pipelines with drag and drop interface
- Run falcon pipelines and monitor their state
- View falcon backend logs.

## To build and run the GUI

GUI is built using [Flutter](https://flutter.dev/). To build and run the GUI, `flutter` and `dart` must be installed with the matching version specified in the project's `pubspec.yaml`. Therefore it's recommended to use [Flutter Version Manager](https://fvm.app/) to install and manage the correct version of Flutter and Dart. You can install FVM and the required Flutter version with the following commands:

```bash
curl -fsSL https://fvm.app/install.sh | bash
fvm install 3.38.5
fvm global 3.38.5
```

And then ensure `flutter` and `dart` are in the `PATH` with correct versions:

```bash
flutter --version
dart --version
```

To build and run the GUI, you can use the VSCode launch configuration defined in `.vscode/launch.json`. Simply open the project in VSCode, go to the Run and Debug view, select "Flutter: Run Falcon GUI" and click the green play button. Alternatively, you can run the following command in the terminal at the root of the project:

```bash
flutter run -d linux
```

# Release build

To build a release version of the GUI, you can use the following command:

```bash
flutter build linux --release
```

