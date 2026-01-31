# weather_app

A small, focused **Weather App** built with Flutter — a practice project while learning Flutter. It demonstrates networking, JSON parsing, simple state management, and a responsive UI.

---

## Features 
- Search and display current weather by city
- Clean, minimal UI for learning and extension
- Small codebase ideal for experimentation

---

## Tech Stack 🔧
- Flutter (stable)
- Dart
- OpenWeatherMap (or your preferred weather API)
- Minimal, idiomatic Flutter code (no heavy frameworks)

---

## Prerequisites ⚙️
- Flutter SDK (stable channel)
- Git
- An IDE with Flutter tooling (VS Code or Android Studio)

---

## Quick Start — Run locally 🚀
```bash
git clone https://github.com/<YOUR_USERNAME>/weather_app.git
cd weather_app
flutter pub get
flutter run
```

---

## Configuration 🔐
- The repository excludes secret keys (see `.gitignore`).
- Create `lib/secret_key.dart` (not committed) and add:

```dart
const String OPENWEATHER_API_KEY = 'YOUR_API_KEY_HERE';
```
Replace with your actual API key.

---

## Project Structure (high level) 📂
- `lib/main.dart` — app entrypoint
- `lib/weather_screen.dart` — main UI / weather view
- `lib/secret_key.dart` — local-only API key (ignored)
- `assets/` — images, `cities.json`, etc.
- `pubspec.yaml` — dependencies & assets

---

## Tests & Linting 🧪
- Add widget and unit tests under `test/`.
- Use `flutter test` to run tests and `flutter analyze` for static analysis.

---

## Contributing 🤝
- Fork → branch → PR
- Keep changes small and well-described
- Add tests for new logic where possible

---

## Notes 📝
This repository is explicitly a **practice project while learning Flutter** — designed for clarity and learning over production-ready complexity.

---
