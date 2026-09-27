#!/usr/bin/env python3
"""Rename Tinycast to Bradycast in the text a user reads, inside a build copy of the source.

The committed source stays upstream's, so a tag merge never conflicts over the name. Run by
`bradycast.sh build` against build/src; never point it at the repo itself.

Kept as Tinycast on purpose: the About window's credits and community link (they are upstream's),
the copyright, the tinycast:// URL scheme's name, and code identifiers such as TinycastApp, which
the whole-word match never touches.
"""
import pathlib
import re
import sys

WORD = re.compile(r"\bTinycast\b")
KEEP_LINES = ("Join the Tinycast community",)
PLIST_TEXT = re.compile(r"(<string>)Tinycast(\s)")
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
    print("==> Renamed Tinycast to Bradycast: " + ", ".join(f"{n} {k}" for k, n in counts.items()))
    if not all(counts.values()):
        sys.exit("a rename matched nothing; upstream moved the text, so update this script")


main()
