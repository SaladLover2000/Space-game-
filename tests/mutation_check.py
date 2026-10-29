"""Prove important assertions reject real defects in isolated project copies.

python tests/mutation_check.py --godot C:/Tools/Godot.exe --scratch C:/Temp/orbit-tests
No dependencies; the real project and player saves are not modified.
"""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--scratch", type=Path, required=True)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[1]
    scratch = args.scratch.resolve()
    scratch.mkdir(parents=True, exist_ok=True)
    cases = [
        ("disconnect hatch toggle", "assets/ship_view.gd", "door_open[id] = not door_open[id]",
         "door_open[id] = door_open[id]", "test_interior.gd", "bridge hatch click closes the correct door"),
        ("double completion credits", "scripts/game.gd", "state.credits += credits",
         "state.credits += credits * 2", "test_game.gd", "completion grants configured rewards"),
        ("count down while paused", "scripts/game.gd", "if active.is_empty() or active.paused:",
         "if active.is_empty():", "test_game.gd", "paused time earns no progress"),
        ("allow duplicate purchases", "scripts/game.gd", "if id in state.owned:",
         "if false:", "test_game.gd", "owned item cannot charge credits again when affordable"),
        ("disconnect Pause button", "ui/main.gd",
         'pause_button = button(controls, "Pause", func(): Game.toggle_pause())',
         'pause_button = button(controls, "Pause", func(): pass)',
         "test_ui.gd", "Pause button pauses game state and becomes Resume"),
    ]
    results = []
    with tempfile.TemporaryDirectory(prefix="orbit-mutation-", dir=scratch) as temp:
        target_root = Path(temp).resolve()
        # Verify the only automatically cleaned directory is inside requested scratch.
        if not target_root.is_relative_to(scratch):
            raise RuntimeError("Temporary target escaped scratch")
        for index, (name, file, before, after, test, expected) in enumerate(cases):
            target = target_root / str(index)
            shutil.copytree(source, target, ignore=shutil.ignore_patterns(".godot", "__pycache__", "*.png", "*.import"))
            script = target / file
            original = script.read_text(encoding="utf-8")
            if original.count(before) != 1:
                raise RuntimeError(f"Mutation anchor must occur once: {name}")
            script.write_text(original.replace(before, after), encoding="utf-8")
            result = subprocess.run([args.godot, "--headless", "--path", str(target),
                                     "--script", f"res://tests/{test}"],
                                    capture_output=True, text=True, timeout=30)
            output = result.stdout + result.stderr
            detected = (result.returncode != 0 and expected in output
                        and "RESULT:" in output and "SCRIPT ERROR:" not in output)
            results.append({"defect": name, "detected": detected,
                            "exit_code": result.returncode, "assertion": expected})
            print(f"{'PASS' if detected else 'FAIL'}: tests reject {name}")
            if not detected:
                print(output)
    if args.report:
        args.report.write_text(json.dumps(results, indent=2), encoding="utf-8")
    return 0 if all(item["detected"] for item in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
