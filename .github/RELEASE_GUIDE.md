# Release Guide for AucorsaBus

This guide explains how to create a new release using the automated GitHub workflow.

## 📋 Prerequisites

1. **Update version in `pubspec.yaml`**:
   ```yaml
   version: 1.2.0+3  # Format: version+buildNumber
   ```
   - First number: Major version (breaking changes)
   - Second number: Minor version (new features)
   - Third number: Patch version (bug fixes)
   - `+3`: Build number (increment each release)

2. **Commit all changes**:
   ```bash
   git add .
   git commit -m "Release v1.2.0: Description of changes"
   git push origin main
   ```

3. **Ensure tests pass** (if you have any):
   ```bash
   cd App
   flutter test
   ```

## 🚀 Creating a Release

### Method 1: Via Git Command Line

```bash
# Create and push a version tag
git tag v1.2.0
git push origin v1.2.0
```

### Method 2: Via GitHub Web Interface

1. Go to your repository on GitHub
2. Click "Releases" in the right sidebar
3. Click "Draft a new release"
4. Click "Choose a tag" and type `v1.2.0` (create new tag)
5. Click "Create new tag: v1.2.0 on publish"
6. Title: `AucorsaBus v1.2.0`
7. Click "Publish release"

### Method 3: Using GitHub CLI

```bash
# Create tag and release in one command
gh release create v1.2.0 --generate-notes --title "AucorsaBus v1.2.0"
```

## ⚙️ What the Workflow Does

Once you push a tag, the workflow automatically:

1. ✅ **Checks out code** - Gets the latest code from your repository
2. ✅ **Sets up environment** - Installs Java 17 and Flutter (stable channel)
3. ✅ **Caches dependencies** - Speeds up builds by caching Gradle and Flutter
4. ✅ **Runs tests** - Executes any Flutter tests (won't fail if none exist)
5. ✅ **Builds APKs**:
   - Universal APK (works on all devices)
   - ARM64-v8a APK (modern 64-bit devices)
   - ARMeabi-v7a APK (older 32-bit devices)
   - x86_64 APK (emulators)
6. ✅ **Generates checksums** - Creates SHA256 hashes for verification
7. ✅ **Creates GitHub Release** - Uploads all APKs with detailed release notes
8. ✅ **Archives artifacts** - Keeps build artifacts for 30 days

## 📦 Release Artifacts

After the workflow completes, users will find:

### APK Files:
- `AucorsaBus-1.2.0.apk` - Universal (recommended for most users)
- `AucorsaBus-1.2.0-arm64-v8a.apk` - Modern Android devices
- `AucorsaBus-1.2.0-armeabi-v7a.apk` - Older Android devices
- `AucorsaBus-1.2.0-x86_64.apk` - Emulators

### Additional Files:
- `checksums.txt` - SHA256 checksums for verification

## 📝 Release Notes Format

The workflow automatically generates release notes with:
- Download instructions
- Architecture guide
- Build information (Flutter version, build date, commit hash)
- Automatic changelog from GitHub commits

## 🔍 Monitoring the Build

1. **View Workflow Progress**:
   - Go to "Actions" tab in GitHub
   - Click on the workflow run for your tag
   - Watch each step execute in real-time

2. **Check Build Logs**:
   - Click on "Build & Release" job
   - Expand any step to see detailed logs
   - Look for errors in red

3. **Download Build Artifacts**:
   - Even if release fails, artifacts are saved
   - Scroll to bottom of workflow run
   - Download `apk-build-vX.X.X.zip`

## ❌ Troubleshooting

### Build Fails During Flutter Test

**Problem**: Tests fail or don't exist
**Solution**: Tests won't fail the build (set to `continue-on-error: true`)

### Build Fails During APK Build

**Problem**: Compilation errors
**Solution**: 
1. Test locally first: `flutter build apk --release`
2. Check logs in GitHub Actions
3. Fix errors and create new tag

### Release Already Exists

**Problem**: Tag already exists
**Solution**:
```bash
# Delete local tag
git tag -d v1.2.0

# Delete remote tag
git push origin :refs/tags/v1.2.0

# Create new tag with patch version
git tag v1.2.1
git push origin v1.2.1
```

### Workflow Doesn't Trigger

**Problem**: Pushed tag but no workflow run
**Solution**:
1. Verify tag format: must start with `v` (e.g., `v1.0.0`)
2. Check `.github/workflows/release.yml` exists
3. Ensure repository has Actions enabled

## 🔐 Security Notes

### SHA256 Checksums

Users can verify APK integrity:
```bash
# On Linux/Mac
sha256sum AucorsaBus-1.2.0.apk

# On Windows (PowerShell)
Get-FileHash AucorsaBus-1.2.0.apk -Algorithm SHA256
```

Compare output with value in `checksums.txt`.

### Code Signing

⚠️ **Current limitation**: APKs are not code-signed. To add signing:

1. Create a keystore:
   ```bash
   keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
   ```

2. Add to GitHub Secrets:
   - `KEYSTORE_BASE64` - Base64 encoded keystore file
   - `KEYSTORE_PASSWORD` - Keystore password
   - `KEY_ALIAS` - Key alias
   - `KEY_PASSWORD` - Key password

3. Update workflow to use signing (requires workflow modification)

## 📊 Version Numbering Guidelines

Follow [Semantic Versioning](https://semver.org/):

- **Major** (1.0.0 → 2.0.0): Breaking changes, major redesign
- **Minor** (1.0.0 → 1.1.0): New features, backward compatible
- **Patch** (1.0.0 → 1.0.1): Bug fixes, minor improvements
- **Build** (+1 → +2): Increment for each build

### Examples:
- `v1.0.0+1` - Initial release
- `v1.0.1+2` - Bug fix release
- `v1.1.0+3` - Added new feature
- `v2.0.0+4` - Major overhaul

## 🎯 Pre-Release Checklist

Before creating a release:

- [ ] Update `pubspec.yaml` version
- [ ] Update `CHANGELOG.md` (if you have one)
- [ ] Test app on physical device
- [ ] Run `flutter analyze` (no errors)
- [ ] Run `flutter test` (all pass)
- [ ] Build locally: `flutter build apk --release`
- [ ] Install and test the local APK
- [ ] Commit all changes
- [ ] Write clear commit message
- [ ] Push to main branch
- [ ] Create and push version tag

## 📱 Testing Releases

### Test on Device:
```bash
# Install universal APK
adb install AucorsaBus-1.2.0.apk

# Or specific architecture
adb install AucorsaBus-1.2.0-arm64-v8a.apk
```

### Test on Emulator:
```bash
# Use x86_64 APK for emulator
adb install AucorsaBus-1.2.0-x86_64.apk
```

## 🔄 Hotfix Process

For urgent bug fixes:

1. Create hotfix branch:
   ```bash
   git checkout -b hotfix/1.0.1
   ```

2. Fix the bug and test

3. Update version to patch (e.g., 1.0.0 → 1.0.1)

4. Merge to main:
   ```bash
   git checkout main
   git merge hotfix/1.0.1
   git push origin main
   ```

5. Tag and release:
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

## 📈 Best Practices

1. **Always test locally** before creating release
2. **Write descriptive commit messages** - They appear in release notes
3. **Tag from main branch** - Ensure stable codebase
4. **Don't delete failed releases** - Keep for version history
5. **Document breaking changes** - Update README for major versions
6. **Keep consistent versioning** - Follow semantic versioning strictly

## 🛠️ Advanced: Manual Release

If workflow fails, create release manually:

```bash
# Build locally
cd App
flutter build apk --release --split-per-abi

# Create release via GitHub CLI
gh release create v1.2.0 \
  --title "AucorsaBus v1.2.0" \
  --notes "Manual release due to CI issues" \
  build/app/outputs/flutter-apk/*.apk
```

## 📞 Support

If you encounter issues with releases:
1. Check workflow logs in GitHub Actions
2. Review this guide
3. Check Flutter documentation
4. Open issue in repository

---

**Last Updated**: January 2025  
**Workflow Version**: 2.0
