#!/usr/bin/env python3
"""Rename Tinycast to Bradycast in the text a user reads, inside a build copy of the source.

The committed source stays upstream's, so a tag merge never conflicts over the name. Run by
`bradycast.sh build` against build/src; never point it at the repo itself.

Kept as Tinycast on purpose: the copyright, the tinycast:// URL scheme's name, code identifiers
such as TinycastApp (the whole-word match never touches them), and Support, whose checkout pays
Tinycast's author. FORK_EDITS then say in About and Support that this is a fork of Tinycast.
"""
import pathlib
import re
import sys

WORD = re.compile(r"\bTinycast\b")
KEEP_LINES = ("Join the Tinycast community",)
PLIST_TEXT = re.compile(r"(<string>)Tinycast(\s)")
ABOUT_LINK = """        AboutLink(
            id: "bradycast", glyph: .brand("BrandGitHub"), title: "Bradycast",
            detail: "github.com/bradystroud/bradycast",
            url: URL(string: "https://github.com/bradystroud/bradycast")!),
"""
# Applied after the rename, so a Tinycast in the new text stays; each old text must match once.
FORK_EDITS = {
    "Windows/About/AboutView.swift": (
        ('Text("A tiny, native macOS launcher.")',
         'Text("Brady Stroud\'s personal fork of Tinycast, a tiny, native macOS launcher.")'),
        ('Text("Free and open source, funded out of pocket.")',
         'Text("Tinycast is free and open source. Support goes to its author, Abue Ammar.")'),
        ('Text("© 2026 Abue Ammar · Released under AGPL-3.0")',
         'Text("Tinycast © 2026 Abue Ammar · Bradycast fork by Brady Stroud · AGPL-3.0")'),
        ("    static let all: [AboutLink] = [\n", "    static let all: [AboutLink] = [\n" + ABOUT_LINK),
        ('title: "Website",', 'title: "Tinycast Website",'),
        ('title: "GitHub",', 'title: "Tinycast on GitHub",'),
        ('detail: "@abue_ammar"', 'detail: "@abue_ammar, Tinycast\'s author"'),
    ),
    "Features/Support/UI/SupportWindowView.swift": (
        ('Text("Support \\(Bundle.main.appDisplayName)")', 'Text("Support Tinycast")'),
        ('Text("Built with love.")',
         'Text("Bradycast is a fork of Tinycast. This supports its author, Abue Ammar.")'),
        ('title: "Support \\(Bundle.main.appDisplayName)"', 'title: "Support Tinycast"'),
    ),
    "Features/Support/UI/SupportCoordinator.swift": (
        ('"Support Bradycast"', '"Support Tinycast"'),
    ),
    "Features/Launcher/Model/CommandID.swift": (
        ('return "Support Bradycast"', 'return "Support Tinycast"'),
    ),
    "Palette/RootPaletteView.swift": (
        ('title: "Support Bradycast"', 'title: "Support Tinycast"'),
    ),
    "App/MenuBarItem.swift": (
        ('Button("Support \\(appName)...")', 'Button("Support Tinycast...")'),
    ),
}
RUNTIME_PHRASES = (
    ("in Tinycast extensions", "in Bradycast extensions"),
    ("outside Tinycast.", "outside Bradycast."),
)


def rewrite(path: pathlib.Path, transform) -> int:
    text = path.read_text()
    new, count = transform(text)
    if count:
        path.write_text(new)
    return count


def swift(text: str):
    total = 0
    lines = []
    for line in text.splitlines(keepends=True):
        if not any(keep in line for keep in KEEP_LINES):
            line, count = WORD.subn("Bradycast", line)
            total += count
        lines.append(line)
    return "".join(lines), total


def runtime(text: str):
    total = 0
    for old, new in RUNTIME_PHRASES:
        total += text.count(old)
        text = text.replace(old, new)
    return text, total


def fork_edits(source: pathlib.Path) -> int:
    for name, edits in FORK_EDITS.items():
        path = source / name
        text = path.read_text()
        for old, new in edits:
            if text.count(old) != 1:
                sys.exit(f"fork edit matched {text.count(old)} times in {name}: {old}")
            text = text.replace(old, new)
        path.write_text(text)
    return sum(len(edits) for edits in FORK_EDITS.values())


def main() -> None:
    root = pathlib.Path(sys.argv[1]).resolve()
    if (root / ".git").exists():
        sys.exit("refusing to rebrand a git checkout; pass the build copy")
    source = root / "Tinycast"
    counts = {
        "swift": sum(rewrite(p, swift) for p in source.rglob("*.swift")),
        "plist": rewrite(source / "Info.plist", lambda t: PLIST_TEXT.subn(r"\1Bradycast\2", t)),
        "runtime": rewrite(source / "Resources/RaycastRuntime.generated.js", runtime),
    }
    counts["fork"] = fork_edits(source)
    print("==> Renamed Tinycast to Bradycast: " + ", ".join(f"{n} {k}" for k, n in counts.items()))
    if not all(counts.values()):
        sys.exit("a rename matched nothing; upstream moved the text, so update this script")


main()
