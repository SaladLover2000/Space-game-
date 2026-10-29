"""Run Godot checks, rejecting script errors even when Godot exits with code zero.

python tests/run_checks.py --godot /path/to/godot --report results.json
Headless by default, with fresh isolated saves even if APPDATA is not set.
Graphical mode requires explicit user permission before invocation.
"""
import argparse
import json
import os
import tempfile
from pathlib import Path
import re
import subprocess


SUITES = ["test_game", "test_ui", "test_rooms", "test_interior", "test_drift", "test_usability", "test_workshop", "test_robot_store", "test_pixel_art", "test_modular_robot", "test_seat_pan", "test_expedition", "test_focus_cruise", "test_diorama_damage", "test_robot_service", "test_component_workshop", "test_visual_rebuild", "test_immersive_progression", "test_structure"]
HEADLESS_ONLY = {"test_game", "test_ui", "test_structure"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--graphical", action="store_true")
    parser.add_argument("--report", type=Path)
    parser.add_argument("--save-root", type=Path, help="Parent directory for fresh isolated test runs")
    args = parser.parse_args()

    save_parent = args.save_root or args.project / "work" / "test-runs"
    save_parent.mkdir(parents=True, exist_ok=True)
    save_root = Path(tempfile.mkdtemp(prefix="little-orbit-checks-", dir=save_parent)).resolve()
    env = os.environ.copy()
    for variable, directory in [("APPDATA", "appdata"), ("LOCALAPPDATA", "localappdata"), ("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache")]:
        target = save_root / directory
        target.mkdir()
        env[variable] = str(target)
    print(f"Isolated saves: {save_root}", flush=True)
    results = []
    for suite in ["import"] + SUITES:
        cmd = [args.godot, "--windowed", "--path", str(args.project.resolve())]
        if suite == "import":
            cmd += ["--headless", "--editor", "--quit"]
        else:
            if not args.graphical or suite in HEADLESS_ONLY:
                cmd += ["--headless"]
            cmd += ["--script", f"res://tests/{suite}.gd"]
            if args.graphical and suite not in HEADLESS_ONLY and suite != "import":
                cmd += ["--", "--capture"]
        try:
            run = subprocess.run(cmd, capture_output=True, text=True, timeout=45, env=env)
            output = run.stdout + run.stderr
            errors = [line for line in output.splitlines() if any(marker in line for marker in
                      ["SCRIPT ERROR:", "Failed to load script", "Failed to instantiate", "Parse Error:"])]
            passed = run.returncode == 0 and not errors and (suite == "import" or "RESULT:" in output)
            result = {"suite": suite, "passed": passed, "exit_code": run.returncode,
                      "assertions": len(re.findall(r"^PASS:", output, re.MULTILINE)), "script_errors": errors}
        except subprocess.TimeoutExpired:
            output = "Suite timed out after 45 seconds."
            result = {"suite": suite, "passed": False, "exit_code": None, "assertions": 0, "script_errors": [output]}
            passed = False
        results.append(result)
        print(f"{'PASS' if passed else 'FAIL'}: {suite} ({result['assertions']} assertions)", flush=True)
        if not passed:
            print(output[:12000])
            if suite == "import":
                break
    report = {"passed": all(item["passed"] for item in results),
              "assertions": sum(item["assertions"] for item in results), "suites": results,
              "save_root": str(save_root), "headless": not args.graphical}
    if args.report:
        args.report.write_text(json.dumps(report, indent=2), encoding="utf-8")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
