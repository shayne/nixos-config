import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from scripts.sort_nix_lists import main, sort_nix_text


class SortNixListsTests(unittest.TestCase):
    def test_sort_multiline_identifiers_with_comments(self):
        text = """
        packages = with pkgs; [
          b
          a # comment
          c
        ];
        """
        result = sort_nix_text(text)
        self.assertTrue(result.changed)
        out_lines = [line.strip() for line in result.new_lines]
        positions = {line: idx for idx, line in enumerate(out_lines) if line in {"a # comment", "b", "c"}}
        self.assertLess(positions["a # comment"], positions["b"])
        self.assertLess(positions["b"], positions["c"])

    def test_sort_commented_out_items_with_note(self):
        text = """
        casks = [
          "b"
          # reason
          # "a"
          "c"
        ];
        """
        result = sort_nix_text(text)
        self.assertTrue(result.changed)
        out_lines = [line.strip() for line in result.new_lines]
        positions = {line: idx for idx, line in enumerate(out_lines) if line in {'"b"', '# "a"', '"c"'}}
        # Commented-out item should move before b
        self.assertLess(positions['# "a"'], positions['"b"'])
        self.assertLess(positions['"b"'], positions['"c"'])

    def test_skip_non_package_string_list(self):
        text = """
        modules-left = [ "custom/nix" "wlr/workspaces" ];
        """
        result = sort_nix_text(text)
        self.assertFalse(result.changed)

    def test_sort_single_line_list(self):
        text = """
        shells = with pkgs; [ zsh bashInteractive fish ];
        """
        result = sort_nix_text(text)
        self.assertTrue(result.changed)
        out = "".join(result.new_lines)
        self.assertIn("[ bashInteractive fish zsh ]", out)

    def test_skip_complex_item(self):
        text = """
        packages = [ (builtins.path { path = ./fonts; }) ];
        """
        result = sort_nix_text(text)
        self.assertFalse(result.changed)

    def test_blank_lines_split_segments(self):
        text = """
        packages = [
          b
          a

          d
          c
        ];
        """
        result = sort_nix_text(text)
        self.assertTrue(result.changed)
        out_lines = [line.strip() for line in result.new_lines]
        positions = {line: idx for idx, line in enumerate(out_lines) if line in {"a", "b", "c", "d"}}
        self.assertLess(positions["a"], positions["b"])
        self.assertLess(positions["c"], positions["d"])
        self.assertLess(positions["b"], positions["c"])

    def test_single_item_segments_no_cross_sort(self):
        text = """
        packages = [
          b

          a
        ];
        """
        result = sort_nix_text(text)
        self.assertFalse(result.changed)

    def test_trailing_comment_stays_with_entry(self):
        text = """
        packages = [
          b
          # note about b
          a
        ];
        """
        result = sort_nix_text(text)
        self.assertTrue(result.changed)
        out_lines = [line.strip() for line in result.new_lines]
        positions = {line: idx for idx, line in enumerate(out_lines) if line in {"a", "b", "# note about b"}}
        self.assertLess(positions["a"], positions["b"])
        self.assertLess(positions["b"], positions["# note about b"])

    def test_commented_out_item_sorts_as_entry(self):
        text = """
        packages = [
          bar
          foo
          # baz
          qux
        ];
        """
        result = sort_nix_text(text)
        self.assertTrue(result.changed)
        out_lines = [line.strip() for line in result.new_lines]
        positions = {line: idx for idx, line in enumerate(out_lines) if line in {"bar", "foo", "# baz", "qux"}}
        self.assertLess(positions["bar"], positions["# baz"])
        self.assertLess(positions["# baz"], positions["foo"])
        self.assertLess(positions["foo"], positions["qux"])

    def test_fail_on_change_writes_and_exits_nonzero(self):
        fd, path = tempfile.mkstemp(suffix=".nix")
        os.close(fd)
        try:
            with open(path, "w", encoding="utf-8") as f:
                f.write("packages = [ b a ];\\n")
            exit_code = main(["--fail-on-change", "--files", path])
            self.assertEqual(exit_code, 1)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            self.assertIn("[ a b ]", content)
            self.assertEqual(main(["--check", "--files", path]), 0)
        finally:
            try:
                os.unlink(path)
            except OSError:
                pass


if __name__ == "__main__":
    unittest.main()
