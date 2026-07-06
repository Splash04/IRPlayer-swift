# 2.0 Release Prep Design

## Summary

Prepare `IRPlayer-swift` for a `2.0` release candidate after `1.0.3`.
The release candidate should include the post-`1.0.3` hardening and coverage
work from `codex/expand-test-coverage`, bump Xcode project metadata to `2.0`,
and leave a verified path for merging, tagging, and publishing the final GitHub
release.

## Goals

- Base the `2.0` candidate on `1.0.3` plus `codex/expand-test-coverage`.
- Keep Swift Package Manager versioning tag-driven; do not add a package
  version field to `Package.swift`.
- Update Xcode generated Info.plist metadata from marketing version `1.0` to
  `2.0` and build version `1` to `2`.
- Document release notes before tagging so the GitHub release body can be
  created from reviewed repository text.
- Verify the candidate with a full iOS Simulator test run before tagging.

## Non-Goals

- Do not publish the `2.0` GitHub release before the candidate branch is
  reviewed or explicitly approved.
- Do not change public API names, notification payloads, or render mode
  semantics as part of release prep.
- Do not add a CocoaPods release path; the current repository documents SPM
  installation only.
- Do not retag `1.0.3`.

## Candidate Base

- Current latest release: `1.0.3`
- Current latest release commit: `793af9d`
- Candidate branch: `codex/prepare-2.0-release`
- Candidate base before release metadata: `origin/codex/expand-test-coverage`

The coverage branch adds runtime guard fixes and broad regression coverage after
`1.0.3`. Those commits should be part of the `2.0` candidate unless review finds
a blocker.

## Release Gates

- `git diff --check` exits with status `0`.
- Full iOS Simulator tests pass with zero failures.
- `2.0` tag does not already exist locally or remotely.
- GitHub Release `2.0` does not already exist.
- Candidate release notes exist at `docs/releases/2.0.md`.

## Acceptance Criteria

- `IRPlayer-swift.xcodeproj/project.pbxproj` contains `MARKETING_VERSION = 2.0`
  and `CURRENT_PROJECT_VERSION = 2`.
- `docs/releases/2.0.md` contains publish-ready release notes.
- `docs/superpowers/plans/2026-07-06-2-0-release-prep.md` describes the exact
  merge, tag, verification, and publish commands for the final release.
- The prep branch is pushed for review.
