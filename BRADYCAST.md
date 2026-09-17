# Bradycast

A personal build of [Tinycast](https://github.com/abue-ammar/tinycast), signed with Brady's
Developer ID instead of upstream's self-signed identity, and cut from reviewed stable tags instead
of the daily release stream.

The source tree is upstream's, unchanged. Everything Bradycast-specific is in
`Scripts/bradycast.sh`: the name, bundle id `com.bradycast.app`, and the signing identity go on the
`xcodebuild` line, the same way upstream's `release.yml` sets them per channel. That keeps
`git merge <tag>` conflict-free.

`com.bradycast.app` lands on `ReleaseChannel.development`, so the app never checks GitHub for
updates. Updating is a deliberate step here.

## Branches

- `main` — the last reviewed upstream stable tag, plus this file, the script and `.gitignore`.
- `upstream` remote — `abue-ammar/tinycast`. Never build from its `main`.

## Update

```sh
Scripts/bradycast.sh update            # fetch, list stable tags newer than the one on main
git log --oneline v0.10.23..v0.10.30   # read what changed; PR numbers link to upstream
Scripts/bradycast.sh update v0.10.30   # merge the tag
Scripts/bradycast.sh install           # build, sign, replace /Applications/Bradycast.app, relaunch
git push
```

Skip a tag if the diff touches `Features/Updates`, `Features/Extensions/Service`,
`Platform/KeychainSecretStore.swift`, the entitlements, or `.github/workflows` without a reason you
understand. Those are the trust boundaries the original audit looked at.

## Build only

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer Scripts/bradycast.sh build
```

Needs Xcode 26+, and the `Developer ID Application: BRADY MATTHEW STROUD` identity in the login
keychain. `xcodegen` is only needed after editing `project.yml`.

## Data

Lives under `~/Library/Application Support/com.bradycast.app/` and
`~/Library/Preferences/com.bradycast.app.plist`. It was copied from `com.tinycast.app` on
2026-09-17. Clipboard history, snippets and notes are plain files, so keep secrets out of snippets.
