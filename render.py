#!/usr/bin/env python3
"""Export print-oriented parts; assemblies/previews explicitly opt in.

No Python packages required; BOSL2 supplies metric screw geometry. Failed exports never replace
successful files. OpenSCAD sometimes exits 0 after a SCAD assertion error, so
diagnostic text is checked as well as exit status.
"""
import argparse
from functools import lru_cache
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
PRINT_PARTS = ("body", "locking_ring", "palm_cap", "coupon")
OPTIONAL_PRINT_PARTS = ("connection_coupon",)
VERSIONS = {"oboe": ("oboe", 3, 10.0), "bassoon": ("bassoon", 4, 25.0),
            "obeh": ("oboe", 3, 10.0), "bsn": ("bassoon", 4, 25.0)}
VIEWS = ("assembly", "section", "exploded", "operation", "palm_cap")


def find_openscad(explicit=None):
    candidates = [explicit, os.environ.get("OPENSCAD"), shutil.which("openscad"),
                  "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"]
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            result = subprocess.run([candidate, "--version"], capture_output=True,
                                    text=True, timeout=30)
            if result.returncode == 0 and "OpenSCAD version" in result.stderr + result.stdout:
                return str(candidate)
    raise RuntimeError("No working OpenSCAD executable. Use --openscad /path/to/OpenSCAD.")


def circular_precision(source):
    """Read the numeric circular settings actually used by the current model."""
    text = Path(source).read_text()
    result = {}
    for name in ("fa", "fs", "fn"):
        match = re.search(r"^\s*\$" + name + r"\s*=\s*(\d+(?:\.\d+)?)\s*;", text, re.M)
        if not match:
            raise RuntimeError("Expected an explicit circular setting: $" + name)
        result[name] = float(match.group(1))
    if result["fa"] <= 0 or result["fs"] <= 0 or result["fn"] != 0:
        raise RuntimeError("Use positive $fa/$fs and $fn=0 for automatic circular precision")
    return result


def definitions(args, part):
    values = {"cfg_part": part, "cfg_instrument": VERSIONS[args.version][0]}
    for name in ("cane_diameter", "blade_length", "blade_width", "blade_thickness",
                 "back_thickness", "back_width", "blade_slot_clearance", "back_slot_clearance",
                 "notch_depth", "notch_width", "notch_from_edge",
                 "thread_radial_clearance", "thread_axial_clearance", "locator_diameter",
                 "locator_height", "locator_diameter_clearance", "locator_depth_clearance",
                 "m4_thread_slop"):
        value = getattr(args, name)
        if value is not None:
            values["cfg_" + name] = value
    return values


@lru_cache(maxsize=None)
def backend_options(executable, backend="Manifold"):
    help_text = subprocess.run([executable, "--help"], capture_output=True,
                               text=True, timeout=30)
    if "--backend" in help_text.stdout + help_text.stderr:
        return ["--backend=" + backend]
    if backend == "CGAL":
        return []  # Older OpenSCAD releases only have CGAL.
    raise RuntimeError("This OpenSCAD does not offer Manifold. Use a version with "
                       "Manifold support, or explicitly pass --backend CGAL.")


def export_one(executable, source, destination, values, preview=False, backend="Manifold"):
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_name(destination.stem + ".pending" + destination.suffix)
    command = [executable] + backend_options(executable, backend) + ["-o", str(temporary)]
    for name, value in values.items():
        command += ["-D", name + "=" + json.dumps(value)]
    if preview:
        command += ["--imgsize=1200,1000", "--autocenter", "--viewall", "--preview",
                    "--projection=o", "--camera=0,0,0,65,0,35,700"]
    elif destination.suffix == ".stl":
        # Inspect the actual float32 mesh delivered to the slicer.
        command += ["--export-format", "binstl"]
    command.append(str(source))
    result = subprocess.run(command, capture_output=True, text=True, timeout=600)
    diagnostics = result.stdout + result.stderr
    failed = result.returncode != 0 or "ERROR:" in diagnostics or "WARNING:" in diagnostics
    if failed or not temporary.is_file() or temporary.stat().st_size == 0:
        temporary.unlink(missing_ok=True)
        raise RuntimeError(f"Export failed for {values['cfg_part']}:\n{diagnostics.strip()}")
    temporary.replace(destination)
    print(destination)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version", nargs="?", choices=VERSIONS)
    parser.add_argument("--list-versions", action="store_true")
    parser.add_argument("--parts", help="Comma-separated printable parts")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--preview", choices=VIEWS, help="Render a PNG, not printable geometry")
    parser.add_argument("--assembly-only", action="store_true", help="Export assembly CSG for inspection")
    parser.add_argument("--openscad")
    parser.add_argument("--backend", choices=("Manifold", "CGAL"), default="Manifold")
    for option in ("cane-diameter", "blade-length", "blade-width", "blade-thickness",
                   "back-thickness", "back-width", "blade-slot-clearance", "back-slot-clearance",
                   "notch-depth", "notch-width", "notch-from-edge",
                   "thread-radial-clearance", "thread-axial-clearance", "locator-diameter",
                   "locator-height", "locator-diameter-clearance", "locator-depth-clearance",
                   "m4-thread-slop"):
        parser.add_argument("--" + option, type=float)
    args = parser.parse_args()
    if args.list_versions:
        for version, (instrument, count, diameter) in VERSIONS.items():
            if version != instrument:
                continue
            print(f"{version}: {instrument}, {count} sectors, nominal guide {diameter:g} mm")
        return 0
    if not args.version:
        parser.error("Specify oboe or bassoon")
    if sum(bool(x) for x in (args.parts, args.preview, args.assembly_only)) > 1:
        parser.error("Use only one of --parts, --preview and --assembly-only")
    parts = args.parts.split(",") if args.parts else list(PRINT_PARTS)
    parts = [part.strip() for part in parts]
    if any(part not in PRINT_PARTS + OPTIONAL_PRINT_PARTS for part in parts):
        parser.error("Unknown part; available: " + ", ".join(PRINT_PARTS + OPTIONAL_PRINT_PARTS))
    output = args.output or ROOT / "3D_files" / VERSIONS[args.version][0]
    source = ROOT / "cane-splitter.scad"
    if args.preview:
        parts, extension = [args.preview], ".png"
    elif args.assembly_only:
        parts, extension = ["assembly"], ".csg"
    else:
        extension = ".stl"
    try:
        executable = find_openscad(args.openscad)
        for part in parts:
            export_one(executable, source, output / (part + extension),
                       definitions(args, part), bool(args.preview), args.backend)
    except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
