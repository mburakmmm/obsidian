"""Build a local Graphify symbol and import index from tracked NOX code."""

import json
import os
from pathlib import Path
import re
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
DECLARATION = re.compile(r"^(\s*)(?:async\s+)?(class|def|protocol|enum)\s+(\w+)")
IMPORT = re.compile(r"^(?:from|import)\s+obsidian\.([\w.]+)\b")


def build_graph():
    output = ROOT / "graphify-out"
    output.mkdir(exist_ok=True)
    if output.is_symlink():
        raise ValueError("graphify-out must be a local directory")
    files = subprocess.check_output(["git", "ls-files", "-z", "--", "*.nox"], cwd=ROOT)
    paths = []
    for value in files.split(b"\0"):
        if value:
            relative = Path(os.fsdecode(value))
            path = ROOT / relative
            if path.is_file() and path.resolve() == path:
                paths.append(relative)
    modules = {path.with_suffix("").as_posix().replace("/", "."): path.as_posix() for path in paths}
    nodes, links = [], []

    def node(node_id, label, source, line):
        nodes.append({"id": node_id, "label": label, "source_file": source,
                      "source_location": f"L{line}", "file_type": "code"})

    def link(source, target, relation):
        links.append({"source": source, "target": target, "relation": relation,
                      "confidence": "EXTRACTED", "confidence_score": 1.0, "weight": 1})

    for relative in paths:
        source = relative.as_posix()
        node(source, source, source, 1)
        owner = source
        for line, contents in enumerate((ROOT / relative).read_text(encoding="utf-8").splitlines(), 1):
            match = DECLARATION.match(contents)
            if match:
                indent, kind, name = match.groups()
                if not indent:
                    owner = source
                node_id = f"{source}:{line}"
                node(node_id, f"{name}()" if kind == "def" else name, source, line)
                link(owner, node_id, "contains")
                if kind in {"class", "protocol", "enum"} and not indent:
                    owner = node_id
            imported = IMPORT.match(contents)
            if imported and imported[1] in modules:
                link(source, modules[imported[1]], "imports")

    data = {"directed": False, "multigraph": False, "graph": {}, "nodes": nodes, "links": links}
    with tempfile.NamedTemporaryFile("w", dir=output, encoding="utf-8", delete=False) as temporary:
        json.dump(data, temporary, ensure_ascii=False)
    os.replace(temporary.name, output / "graph.json")
    (output / "needs_update").unlink(missing_ok=True)
    print(f"Graphify NOX index: {len(paths)} files, {len(nodes)} nodes, {len(links)} links")


if __name__ == "__main__":
    build_graph()
