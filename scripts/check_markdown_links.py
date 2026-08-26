import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LINK_PATTERN = re.compile(r"\[[^\]]+\]\(([^)]+)\)")


def main() -> int:
    missing: list[str] = []
    for document in [ROOT / "README.md", *sorted((ROOT / "docs").rglob("*.md"))]:
        for target in LINK_PATTERN.findall(document.read_text(encoding="utf-8")):
            target = target.split("#", 1)[0]
            if not target or "://" in target or target.startswith("mailto:"):
                continue
            resolved_target = (document.parent / target).resolve()
            if not resolved_target.is_relative_to(ROOT) or not resolved_target.exists():
                missing.append(f"{document.relative_to(ROOT)} -> {target}")
    if missing:
        print("Broken relative Markdown links:", *missing, sep="\n", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
