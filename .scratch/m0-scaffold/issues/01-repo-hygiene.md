# 01 — Repo hygiene

Status: done

Add `.gitignore` (Xcode user data, DerivedData, `.build/`, `.swiftpm/`, `.DS_Store`, `Secrets.xcconfig`) and a `.swift-format` config (4-space indent, 120 columns).

## Acceptance

- `git check-ignore Config/Secrets.xcconfig .build .DS_Store` lists all three.
- `swift format lint -r` runs with the committed config.
