"""Explicit local verification; never imported or automatically run by Noesis.

Hand-checked expectations and a Bellman-Ford oracle are independent of the editable
implementation. This reports software behavior, never learner understanding.
Run: python check_cases.py --output observations.json
"""
import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import subprocess

CASES = [
    ("discovery is not finalization", ["A", "B", "C"], [("A", "B", 10), ("A", "C", 1), ("C", "B", 1)], "A", {"A": 0, "B": 2, "C": 1}),
    ("stale queue entry", ["S", "A", "B", "T"], [("S", "A", 8), ("S", "B", 2), ("B", "A", 1), ("A", "T", 2), ("B", "T", 20)], "S", {"S": 0, "A": 3, "B": 2, "T": 5}),
    ("zero weights and cycle", ["S", "A", "B"], [("S", "A", 0), ("A", "S", 0), ("A", "B", 0), ("S", "B", 4)], "S", {"S": 0, "A": 0, "B": 0}),
    ("disconnected vertex", ["S", "A", "X"], [("S", "A", 3)], "S", {"S": 0, "A": 3, "X": math.inf}),
    ("parallel and equal cost edges", ["S", "A", "B"], [("S", "A", 9), ("S", "A", 2), ("S", "B", 2), ("A", "B", 0)], "S", {"S": 0, "A": 2, "B": 2}),
    ("single vertex", ["S"], [], "S", {"S": 0}),
]

def oracle(vertices, edges, source):
    distance = dict.fromkeys(vertices, math.inf)
    distance[source] = 0
    for _ in range(len(vertices)-1):
        changed = False
        for u, v, w in edges:
            if distance[u] + w < distance[v]:
                distance[v] = distance[u] + w
                changed = True
        if not changed:
            break
    return distance

def serial(value):
    if isinstance(value, dict):
        return {str(k): serial(v) for k, v in value.items()}
    if isinstance(value, float) and math.isinf(value):
        return "unreachable"
    return value

def inspect(include_transfer=False):
    file = Path(__file__).with_name("dijkstra.py")
    spec = importlib.util.spec_from_file_location("authored_implementation", file)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    rows = []
    cases = list(CASES)
    if include_transfer:
        cases.append(("transfer - distances to a destination via reversed edges", ["T", "A", "B", "C", "X"], [("T", "A", 7), ("T", "B", 2), ("B", "A", 1), ("A", "C", 0), ("B", "C", 8)], "T", {"T": 0, "A": 3, "B": 2, "C": 3, "X": math.inf}))
    for name, vertices, edges, source, expected in cases:
        assert oracle(vertices, edges, source) == expected, "Independent expected-case error"
        try:
            actual = module.shortest_paths(vertices[:], edges[:], source)
            rows.append(dict(case=name, observed=serial(actual), expected=serial(expected), agrees=actual == expected))
        except Exception as error:
            rows.append(dict(case=name, error=type(error).__name__+": "+str(error), expected=serial(expected), agrees=False))
    for name, vertices, edges, source in [
        ("negative counterexample must be rejected", ["S", "A", "B"], [("S", "A", 2), ("S", "B", 5), ("B", "A", -4)], "S"),
        ("unreachable negative edge must be rejected", ["S", "A", "B"], [("A", "B", -1)], "S"),
    ]:
        try:
            actual = module.shortest_paths(vertices, edges, source)
            rows.append(dict(case=name, observed=serial(actual), expected="ValueError", agrees=False))
        except ValueError:
            rows.append(dict(case=name, observed="ValueError", expected="ValueError", agrees=True))
        except Exception as error:
            rows.append(dict(case=name, error=type(error).__name__+": "+str(error), expected="ValueError", agrees=False))
    def git(*args):
        result = subprocess.run(["git", "-C", str(file.parent), *args], capture_output=True, text=True, timeout=5)
        return result.stdout.strip() if result.returncode == 0 else None
    return dict(evidence_kind="software-test", learner_achievement=False,
                conventions="directed graph, nonnegative integer weights, explicit isolated vertices, infinity for unreachable",
                implementation_sha256=hashlib.sha256(file.read_bytes()).hexdigest(),
                code_revision=git("rev-parse", "HEAD"), working_tree_dirty=bool(git("status", "--porcelain")),
                oracle="Bellman-Ford plus hand-checked expected distances; tests are inspectable, not reference-hidden",
                cases=rows, all_agree=all(row["agrees"] for row in rows))

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path)
    parser.add_argument("--transfer", action="store_true", help="Reveal/check the changed graph only after preserving its prediction")
    args = parser.parse_args()
    report = inspect(args.transfer)
    text = json.dumps(report, indent=2, allow_nan=False)+"\n"
    if args.output:
        args.output.write_text(text)
    print(text, end="")
    raise SystemExit(0 if report["all_agree"] else 1)
