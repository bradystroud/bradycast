# Bradycast

A personal build of [Tinycast](https://github.com/abue-ammar/tinycast), signed with Brady's
Developer ID instead of upstream's self-signed identity, and cut from reviewed stable tags instead
of the daily release stream.

The build identity is all in `Scripts/bradycast.sh`: the name, bundle id `com.bradycast.app`, and
the signing identity go on the `xcodebuild` line, the same way upstream's `release.yml` sets them per
channel.

The build runs from a copy in `build/src`, where `Scripts/bradycast-rebrand.py` renames every
user-visible "Tinycast" (Swift strings, `Info.plist` usage text, extension-runtime errors) to
"Bradycast". The committed source keeps upstream's name, so the rename never conflicts. The
script's `FORK_EDITS` then credit Tinycast: About says this is a fork, links both repos and keeps
Abue Ammar's copyright, and Support stays "Support Tinycast", because its checkout pays him. The
`tinycast://` scheme keeps its name. If the script reports that an edit or rename matched
nothing, upstream moved that text: update the script.

The source carries two fork-only changes, kept small so a tag merge rarely conflicts:

- **AI emoji search** — `Features/Emoji/Model/EmojiSuggestion.swift` and
  `Features/Emoji/Service/EmojiSuggester.swift` are new. The edits to upstream files are one line in
  `AppCore.swift`, the section in `EmojiGridView.swift`, the task in `EmojiScreen.swift`, the harness
  line in `Scripts/run-tests.sh`, the tests in `Tests/emoji-search-test.swift`, and
  `docs/features/emoji.md`. On a conflict in `Tinycast.xcodeproj`, take upstream's and run
  `xcodegen generate`.
- **Escape as a back button** — on a screen summoned by its own hotkey, Escape and the back
  chevron fall to the root search instead of closing, and the launcher hotkey always opens the
  root search. The edits are in `PaletteEscapeAction.swift`, `RootPaletteView.swift`,
  `PaletteCoordinator.swift`, `Tests/palette-escape-test.swift` and `docs/features/palette.md`.

`com.bradycast.app` lands on `ReleaseChannel.development`, so the app never checks GitHub for
updates. Updating is a deliberate step here, so run `Scripts/bradycast.sh update` about every week
or two. Upstream merges dozens of PRs a week, and a stale fork turns into a large, slow review.

## Branches

- `main` — the last reviewed upstream stable tag, plus this file, the script and `.gitignore`, and
  a fork note at the top of `AGENTS.md`.
- `upstream` remote — `abue-ammar/tinycast`. Never build from its `main`.

## Update

```sh
Scripts/bradycast.sh update            # fetch, list stable tags newer than the one on main
git log --oneline v0.11.3..v0.11.9    # read what changed; PR numbers link to upstream
Scripts/bradycast.sh update v0.11.9    # merge the tag
Scripts/bradycast.sh install           # build, sign, replace /Applications/Bradycast.app, relaunch
git push
```

Skip a tag if the diff touches `Features/Updates`, `Features/Extensions/Service`,
`Platform/KeychainSecretStore.swift`, the entitlements, or `.github/workflows` without a reason you
understand. Those are the trust boundaries the original audit looked at.

### If upstream rewrites its history

Upstream rewrote history once, between v0.10.23 and v0.11.3, and moved its tags. The only merge base
left was the first commit, so a plain merge conflicted everywhere. The fix keeps `main`
fast-forward: take the tag's tree whole, then restore the fork's files.

```sh
git fetch --tags --force upstream
git merge --no-commit -s ours <tag>
git read-tree -u --reset <tag>
git checkout HEAD -- BRADYCAST.md Scripts/bradycast.sh   # then re-add the AGENTS.md fork note
```

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
