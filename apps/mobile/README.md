# Android Flutter shell

App owner workspace. `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run`.
Flutter shell delegates UI to inspection_ui and controller to inspection_runtime. Baseline camera/image service buttons intentionally return Unable to Verify; they do not acquire images. No model/data/reference is bundled. Android wrapper generated with local Flutter 3.47.1; verify team tooling compatibility. Release config is template debug signing, suitable only if explicitly chosen/documented for hackathon sideload; not store-ready.

If Gradle launcher files are absent from Git, regenerate wrappers with `flutter create --platforms=android --project-name pluto_inspector --org org.plutoinspection .` only after backing up and preserving existing source/config; inspect changes carefully. The launcher JAR is a generated binary; no SDK paths or signing material are committed. See root README and app prompt.
