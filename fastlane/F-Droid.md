# F-Droid Submission Notes

## License
Add an `LICENSE` file to the repository root (e.g. MIT or GPL-3.0). F-Droid requires a recognized FOSS license.

## Required Repository Setup
1. Create a public repository on GitHub / GitLab / Codeberg.
2. Add the release workflow (`.github/workflows/release.yml`) so tagged releases produce a signed or unsigned APK.
3. Tag releases as `v1.0.0`, `v1.1.0`, etc.

## F-Droid Metadata File
Submit a merge request to https://gitlab.com/fdroid/fdroiddata with a file named `com.yourdomain.dosh.yml` (or your actual package name):

```yaml
Categories:
  - Games
  - Reading
License: MIT
SourceCode: https://github.com/YOUR_USERNAME/dosh
IssueTracker: https://github.com/YOUR_USERNAME/dosh/issues

RepoType: git
Repo: https://github.com/YOUR_USERNAME/dosh.git

Builds:
  - versionName: 1.0.0
    versionCode: 1
    commit: v1.0.0
    output: build/app/outputs/flutter-apk/app-release.apk
    srclibs:
      - flutter@stable
    build:
      - $$flutter$$/bin/flutter config --no-analytics
      - $$flutter$$/bin/flutter pub get
      - $$flutter$$/bin/flutter build apk --release

AutoUpdateMode: Version v%v
UpdateCheckMode: Tags ^v[0-9.]+$
CurrentVersion: 1.0.0
CurrentVersionCode: 1
```

## Anti-Features Check
- No ads
- No tracking / analytics
- No proprietary dependencies
- No in-app purchases

If everything is FOSS, the app qualifies for the main F-Droid repository.
