# Changelog

All notable changes to the AucorsaBus project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.3] - 2025-01-24

### Fixed
- **CRITICAL**: Fixed missing bus arrival times by switching to Light API domain
  - Bus times were not displaying due to using wrong API endpoint
  - Now uses `lightapi.aucorsa.es` for real-time estimation requests
  - Main `aucorsa.es` domain blocks estimation endpoint with 403 Forbidden
  - All other endpoints remain on main domain

### Changed
- Updated `api_service.dart` to use Light API (`lightapi.aucorsa.es`) for estimations
- Enhanced API documentation with Light API discovery details

### Added
- **Documentation**: Comprehensive Light API analysis (`LIGHTAPI_ANALYSIS.md`)
- **Documentation**: Complete troubleshooting guide (`TROUBLESHOOTING.md`)
- **Documentation**: Updated API documentation (`AUCORSA_API.md`)
- **Documentation**: Release process guide (`.github/RELEASE_GUIDE.md`)
- **Documentation**: Workflow improvements summary (`.github/WORKFLOW_IMPROVEMENTS.md`)

### Improved
- **GitHub Workflow**: Enhanced release automation
  - Added caching for 40-50% faster builds
  - Now builds 4 APK variants (Universal, ARM64, ARM32, x86_64)
  - Generates SHA256 checksums for security verification
  - Creates professional release notes automatically
  - Extracts version from `pubspec.yaml` automatically
  - Runs tests before building
  - Preserves build artifacts for 30 days
  - Better debugging with detailed logs

### Technical Details
- API Service now uses dual-domain architecture:
  - `https://aucorsa.es/wp-json/aucorsa/v1` - Lines, stops, routes, alerts
  - `https://lightapi.aucorsa.es/wp-json/aucorsa/v1` - Real-time estimations
- Light API is behind Cloudflare CDN for better performance
- Maintains backward compatibility with existing code

---

## Version History

### Format
Each version will follow this structure:
- **Major.Minor.Patch+Build** (e.g., 1.2.0+3)
- Major: Breaking changes
- Minor: New features, backward compatible
- Patch: Bug fixes
- Build: Build number, increments each release

---

## How to Update

When releasing a new version:

1. Update `version` in `pubspec.yaml`
2. Add entry to this CHANGELOG under appropriate version
3. Commit changes
4. Create and push git tag matching the version
5. GitHub Actions will automatically build and release

---

## Links

- [GitHub Repository](https://github.com/ncc-288/AucorsaBus)
- [Issue Tracker](https://github.com/ncc-288/AucorsaBus/issues)
- [Releases](https://github.com/ncc-288/AucorsaBus/releases)
