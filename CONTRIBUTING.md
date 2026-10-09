# Contributing to Tactile Widget Kit

Thanks for your interest in contributing! This project is a Flutter starter kit
that demonstrates native home-screen widgets, off-screen pixel rendering, and a
tactile skeuomorphic UI with chained choreography. Contributions that improve
the developer experience are very welcome.

## Getting started

1. Fork the repository and clone it locally.
2. Install the Flutter SDK (see the [README](./README.md) for the required version).
3. Run `flutter pub get` and `flutter analyze` to confirm a clean baseline.
4. Create a topic branch: `git checkout -b feat/my-feature`.

## Development workflow

- Follow [Conventional Commits](https://www.conventionalcommits.org/) for commit messages.
- Keep Dart formatting clean: `dart format .`.
- Run `flutter analyze` and `flutter test` before pushing.
- Add tests for new logic where practical.

## Pull request checklist

- [ ] Changes are focused and scoped to a single concern.
- [ ] `dart format --output=none --set-exit-if-changed .` passes.
- [ ] `flutter analyze` reports no issues.
- [ ] `flutter test` passes.
- [ ] Documentation is updated when public APIs change.

## Code style

- Prefer small, single-purpose widgets and objects.
- Keep domain models decoupled from storage and UI (see `lib/data/`).
- Document non-obvious rendering and bridge logic.

## Reporting issues

Use the issue templates under `.github/ISSUE_TEMPLATE/`. Provide a minimal
reproduction and your Flutter/device environment whenever possible.

## License

By contributing, you agree that your contributions will be licensed under the
MIT License.
