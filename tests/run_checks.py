"""Run Godot checks, rejecting script errors even when Godot exits with code zero.

python tests/run_checks.py --godot C:/Tools/Godot.exe --graphical --report results.json
Graphical mode captures current screenshots and verifies actual changing frames.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--graphical", action="store_true")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    suites = ["test_game", "test_ui", "test_rooms", "test_interior", "test_drift"]
    results = []
    for suite in ["import"] + suites:
        cmd = [args.godot, "--path", str(args.project.resolve())]
        if suite == "import":
            cmd += ["--headless", "--editor", "--quit"]
        else:
            if not args.graphical or suite in ["test_game", "test_ui"]:
                cmd += ["--headless"]
            cmd += ["--script", f"res://tests/{suite}.gd"]
            if args.graphical and suite in ["test_rooms", "test_interior", "test_drift"]:
                cmd += ["--", "--capture"]
        try:
            run = subprocess.run(cmd, capture_output=True, text=True, timeout=45)
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
        print(f"{'PASS' if passed else 'FAIL'}: {suite} ({result['assertions']} assertions)")
        if not passed:
            print(output[:12000])
            if suite == "import":
                break
    report = {"passed": all(item["passed"] for item in results),
              "assertions": sum(item["assertions"] for item in results), "suites": results}
    if args.report:
        args.report.write_text(json.dumps(report, indent=2), encoding="utf-8")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
