#!/usr/bin/env python3
"""Sort simple package-like lists in Nix files.

This script targets lists for packages/casks/brews/etc and keeps formatting
by reordering whole item lines (with attached comment blocks).
"""

from __future__ import annotations

import argparse
import dataclasses
import os
import re
import subprocess
import sys
from typing import Iterable, List, Optional, Sequence, Tuple


PACKAGE_CONTEXT_RE = re.compile(
    r"\b(packages|systemPackages|defaultPackages|nativeBuildInputs|shells|brews|casks|permittedInsecurePackages)\b"
)
OPTIONALS_RE = re.compile(r"\blib\.optionals\b")

IDENT_TOKEN_RE = re.compile(r"^[A-Za-z0-9_][A-Za-z0-9._+\-${}]*$")
STRING_CONTENT_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9+._-]*$")


@dataclasses.dataclass(frozen=True)
class ListBlock:
    start_line: int
    start_col: int
    end_line: int
    end_col: int


@dataclasses.dataclass
class Entry:
    key: str
    lines: List[str]
    original_index: int


@dataclasses.dataclass
class SortResult:
    changed: bool
    new_lines: List[str]


def _strip_comment_segment(line: str) -> str:
    """Return line up to comment start (#) while respecting quoted strings."""
    in_double = False
    i = 0
    while i < len(line):
        ch = line[i]
        if in_double:
            if ch == "\\" and i + 1 < len(line):
                i += 2
                continue
            if ch == '"':
                in_double = False
            i += 1
            continue
        if ch == '"':
            in_double = True
            i += 1
            continue
        if ch == "#":
            return line[:i]
        i += 1
    return line


def _find_list_blocks(lines: Sequence[str]) -> List[ListBlock]:
    blocks: List[ListBlock] = []
    stack: List[Tuple[int, int]] = []
    in_double = False
    in_multiline = False

    for li, line in enumerate(lines):
        i = 0
        while i < len(line):
            if in_multiline:
                if line.startswith("''", i):
                    in_multiline = False
                    i += 2
                    continue
                i += 1
                continue
            if in_double:
                if line[i] == "\\" and i + 1 < len(line):
                    i += 2
                    continue
                if line[i] == '"':
                    in_double = False
                i += 1
                continue

            if line.startswith("''", i):
                in_multiline = True
                i += 2
                continue
            ch = line[i]
            if ch == '"':
                in_double = True
                i += 1
                continue
            if ch == "#":
                break
            if ch == "[":
                stack.append((li, i))
                i += 1
                continue
            if ch == "]":
                if stack:
                    start_line, start_col = stack.pop()
                    blocks.append(ListBlock(start_line, start_col, li, i))
                i += 1
                continue
            i += 1
    return blocks


def _tokenize_simple(content: str) -> List[str]:
    tokens: List[str] = []
    buf: List[str] = []
    in_double = False
    i = 0
    while i < len(content):
        ch = content[i]
        if in_double:
            if ch == "\\" and i + 1 < len(content):
                buf.append(ch)
                buf.append(content[i + 1])
                i += 2
                continue
            if ch == '"':
                in_double = False
                buf.append(ch)
                i += 1
                continue
            buf.append(ch)
            i += 1
            continue

        if ch == '"':
            in_double = True
            buf.append(ch)
            i += 1
            continue
        if ch == "#":
            break
        if ch.isspace():
            if buf:
                tokens.append("".join(buf))
                buf = []
            i += 1
            continue
        buf.append(ch)
        i += 1

    if buf:
        tokens.append("".join(buf))
    return tokens


def _parse_token(token: str) -> Optional[str]:
    if token.startswith('"') and token.endswith('"') and len(token) >= 2:
        inner = token[1:-1]
        inner = inner.replace('\\"', '"').replace('\\\\', '\\')
        if STRING_CONTENT_RE.match(inner):
            return inner
        return None

    if IDENT_TOKEN_RE.match(token):
        return token

    return None


def _parse_item_line(line: str) -> Optional[str]:
    code = _strip_comment_segment(line).strip()
    if not code:
        return None
    tokens = _tokenize_simple(code)
    if len(tokens) != 1:
        return None
    token = tokens[0]
    key = _parse_token(token)
    return key


def _is_package_context(lines: Sequence[str], block: ListBlock) -> bool:
    prefix = _strip_comment_segment(lines[block.start_line][: block.start_col])
    if PACKAGE_CONTEXT_RE.search(prefix):
        return True
    if OPTIONALS_RE.search(prefix):
        return True
    return False


def _sort_segment(segment_lines: Sequence[str]) -> Optional[Tuple[List[str], bool]]:
    entries: List[Entry] = []
    prefix: List[str] = []
    index = 0

    for line in segment_lines:
        stripped = line.strip()
        if stripped == "":
            return None

        if stripped.startswith("#"):
            # Possible commented-out item
            commented = stripped[1:].lstrip()
            key = _parse_item_line(commented)
            if key is not None:
                entries.append(Entry(key=key, lines=[line], original_index=index))
                index += 1
            else:
                if entries:
                    entries[-1].lines.append(line)
                else:
                    prefix.append(line)
            continue

        key = _parse_item_line(line)
        if key is None:
            return None
        entries.append(Entry(key=key, lines=[line], original_index=index))
        index += 1

    if not entries:
        return (list(segment_lines), False)

    sorted_entries = sorted(entries, key=lambda e: (e.key.lower(), e.original_index))
    changed = [e.key for e in sorted_entries] != [e.key for e in entries]

    new_segment: List[str] = []
    new_segment.extend(prefix)
    for entry in sorted_entries:
        new_segment.extend(entry.lines)

    return (new_segment, changed)


def _sort_multiline_list(lines: Sequence[str], block: ListBlock) -> Optional[List[str]]:
    start_line, end_line = block.start_line, block.end_line

    if start_line == end_line:
        return None

    start_tail = _strip_comment_segment(lines[start_line][block.start_col + 1 :]).strip()
    if start_tail:
        return None

    end_head = _strip_comment_segment(lines[end_line][: block.end_col]).strip()
    if end_head:
        return None

    inner_lines = list(lines[start_line + 1 : end_line])

    chunks: List[List[str]] = []
    current: List[str] = []
    for line in inner_lines:
        if line.strip() == "":
            if current:
                chunks.append(current)
                current = []
            chunks.append([line])
        else:
            current.append(line)
    if current:
        chunks.append(current)

    changed_any = False
    new_inner: List[str] = []
    for chunk in chunks:
        if all(line.strip() == "" for line in chunk):
            new_inner.extend(chunk)
            continue
        result = _sort_segment(chunk)
        if result is None:
            return None
        segment_lines, changed = result
        new_inner.extend(segment_lines)
        changed_any = changed_any or changed

    if not changed_any:
        return None

    new_lines = list(lines)
    new_lines[start_line + 1 : end_line] = new_inner
    return new_lines


def _sort_single_line_list(lines: Sequence[str], block: ListBlock) -> Optional[List[str]]:
    if block.start_line != block.end_line:
        return None

    line = lines[block.start_line]
    prefix = line[: block.start_col + 1]
    content = line[block.start_col + 1 : block.end_col]
    suffix = line[block.end_col :]

    tokens = _tokenize_simple(content)
    if len(tokens) <= 1:
        return None

    parsed = []
    for token in tokens:
        key = _parse_token(token)
        if key is None:
            return None
        parsed.append((key, token))

    sorted_tokens = [t for _, t in sorted(parsed, key=lambda kv: kv[0].lower())]

    if [t for _, t in parsed] == sorted_tokens:
        return None

    new_content = " " + " ".join(sorted_tokens) + " "
    new_line = prefix + new_content + suffix

    new_lines = list(lines)
    new_lines[block.start_line] = new_line
    return new_lines


def sort_nix_text(text: str) -> SortResult:
    lines = text.splitlines(keepends=True)
    blocks = _find_list_blocks(lines)

    # Work from bottom to top to preserve indices
    changed = False
    for block in sorted(blocks, key=lambda b: (b.start_line, b.start_col), reverse=True):
        if not _is_package_context(lines, block):
            continue
        updated = _sort_single_line_list(lines, block)
        if updated is None:
            updated = _sort_multiline_list(lines, block)
        if updated is not None:
            lines = updated
            changed = True

    return SortResult(changed=changed, new_lines=lines)


def _iter_nix_files(paths: Optional[Sequence[str]]) -> Iterable[str]:
    if paths:
        for path in paths:
            yield path
        return

    try:
        root = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
    except Exception:
        root = os.getcwd()

    try:
        output = subprocess.check_output(["git", "ls-files", "*.nix"], text=True)
        for rel in output.splitlines():
            if rel.endswith(".enc.nix"):
                continue
            yield os.path.join(root, rel)
    except Exception:
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = [d for d in dirnames if d not in {".git", "result"}]
            for name in filenames:
                if not name.endswith(".nix"):
                    continue
                if name.endswith(".enc.nix"):
                    continue
                yield os.path.join(dirpath, name)


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Sort package-like lists in Nix files.")
    parser.add_argument("--check", action="store_true", help="Exit non-zero if changes are needed.")
    parser.add_argument(
        "--fail-on-change",
        action="store_true",
        help="Exit non-zero if any file was modified (after applying changes).",
    )
    parser.add_argument("--files", nargs="*", help="Specific files to process.")

    args = parser.parse_args(argv)

    changed_files: List[str] = []

    for path in _iter_nix_files(args.files):
        try:
            with open(path, "r", encoding="utf-8") as f:
                text = f.read()
        except OSError:
            continue

        result = sort_nix_text(text)
        if result.changed:
            changed_files.append(path)
            if not args.check:
                with open(path, "w", encoding="utf-8") as f:
                    f.writelines(result.new_lines)

    if args.check:
        if changed_files:
            print("Lists need sorting in:")
            for path in changed_files:
                print(f"- {path}")
            return 1
        return 0

    if changed_files:
        print("Sorted lists in:")
        for path in changed_files:
            print(f"- {path}")
        if args.fail_on_change:
            return 1
    else:
        print("No changes needed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
