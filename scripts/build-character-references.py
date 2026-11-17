#!/usr/bin/env python3
"""Embed current reference PNGs in PDFs; refresh artwork checksums.

Requires Pillow and ReportLab. Source artwork is never modified or resampled.
Run from any directory; paths are relative to this script's repository.
"""

import hashlib
import json
from pathlib import Path

from PIL import Image
from reportlab import rl_config
from reportlab.pdfgen.canvas import Canvas


ROOT = Path(__file__).resolve().parents[1]
CHARACTERS = ROOT / "art/characters"
PROVENANCE = CHARACTERS / "reference-generation-v4.json"
MANIFEST = ROOT / "art/asset-manifest.json"


def describe(relative_path: str) -> dict:
    source = ROOT / relative_path
    raw = source.read_bytes()
    entry = {
        "path": relative_path,
        "bytes": len(raw),
        "sha256": hashlib.sha256(raw).hexdigest(),
    }
    if source.suffix.lower() == ".png":
        with Image.open(source) as picture:
            entry["dimensions"] = list(picture.size)
            picture.verify()
    return entry


def make_pdf(relative_path: str, title: str, sheets: list[tuple[str, str]]) -> None:
    output = ROOT / relative_path
    output.parent.mkdir(parents=True, exist_ok=True)
    # Binary lossless streams avoid ASCII85 overhead; no image downsampling.
    rl_config.useA85 = 0
    # 12-inch-wide landscape pages, preserving each source's aspect ratio.
    pdf = Canvas(str(output), pagesize=(864, 576), pageCompression=1, invariant=1)
    pdf.setTitle(title)
    pdf.setAuthor("Fight Guild")
    pdf.setSubject("Generated character reference candidates; model and action direction")
    for index, (name, filename) in enumerate(sheets):
        source = CHARACTERS / filename
        with Image.open(source) as picture:
            width, height = picture.size
        page_width, page_height = 864, 864 * height / width
        pdf.setPageSize((page_width, page_height))
        pdf.bookmarkPage(f"sheet-{index}")
        pdf.addOutlineEntry(name, f"sheet-{index}", level=0)
        pdf.drawImage(str(source), 0, 0, width=page_width, height=page_height)
        pdf.showPage()
    pdf.save()
    print(f"{relative_path}: {len(sheets)} pages")


def main() -> None:
    # Do not silently rewrite a past generation's provenance after artwork changes.
    provenance = json.loads(PROVENANCE.read_text())
    paths = set()
    for job in provenance["jobs"]:
        output = describe(job["path"])
        references = [describe(path) for path in job["references"]]
        for key, observed in (("output_metadata", output), ("reference_metadata", references)):
            if key in job and job[key] != observed:
                raise ValueError(f"{job['id']}: {key} changed; archive and record a new art revision first")
            job[key] = observed
        paths.add(job["path"])
        paths.update(job["references"])

    for carried in provenance.get("carried_forward", []):
        output, source = describe(carried["path"]), describe(carried["source"])
        if output["sha256"] != source["sha256"]:
            raise ValueError(f"{carried['path']}: carried-forward artwork differs from its source")
        carried["output_metadata"], carried["source_metadata"] = output, source
        paths.update((carried["path"], carried["source"]))

    make_pdf(
        "exports/character-reference-guides.pdf",
        "Fight Guild — Current Character References",
        [(name.title(), f"{name}.png") for name in ("anvil", "smoke", "tapper", "shark", "fillet", "hammer")],
    )
    make_pdf(
        "exports/FightGuild-Fillet-Shark-References-v4.pdf",
        "Fight Guild — Fillet and Shark Reference 04",
        [
            ("Fillet — Model", "fillet.png"),
            ("Fillet — Windup and Active", "fillet-actions.png"),
            ("Shark — Model", "shark.png"),
            ("Shark — Windup and Active", "shark-actions.png"),
        ],
    )

    PROVENANCE.write_text(json.dumps(provenance, indent=2, ensure_ascii=False) + "\n")

    manifest = json.loads(MANIFEST.read_text())
    existing = {entry["path"]: entry for entry in manifest["assets"]}
    paths.update({
        "exports/character-reference-guides.pdf",
        "exports/FightGuild-Fillet-Shark-References-v4.pdf",
        "art/archive/reference-guides-v3/character-reference-guides.pdf",
    })
    for path in sorted(paths):
        existing[path] = {**existing.get(path, {}), **describe(path)}
    manifest["assets"] = list(existing.values())
    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    print(f"Updated provenance and manifest metadata for {len(paths)} files.")


if __name__ == "__main__":
    main()
