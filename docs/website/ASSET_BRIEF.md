# Website 3D asset brief

Owner: `frontend/website`. Consumer: `apps/website/src/viewer/` through the `DroneAsset` interface in `apps/website/src/viewer/types.ts`.

## Current state

- The site shows an **illustrative schematic** drawn in code (`src/viewer/schematic.ts`) plus a static SVG poster (`#drone-top` in `index.html`). Proportions were estimated by eye from team photos of the supplied drone. They do not establish the drone's geometry, dimensions, motor identities, propeller types or orientations. All four schematic propellers are drawn the same and flat on purpose.
- The team photos are **not** committed or published. Per AGENTS.md, raw private photos stay out of Git.
- No approved model exists. `pluto-x-glb.zip` is **excluded**: it belongs to another problem statement. Do not import it, reuse its geometry, or infer a motor map from it.

## Accepted formats

- Preferred: a single binary glTF (`.glb`, glTF 2.0).
- Also accepted: `.gltf` with embedded or co-located buffers and textures.
- Compression: Draco or Meshopt only if needed to meet the budget. If one is used, record it here so the matching decoder can be added. No decoder ships today.
- Note: the repository `.gitignore` ignores `*.glb`. Deliver large files through the team's shared resource location with a `resources/manifest.json` entry (owned by the app owner). Small approved files may be force-added to `apps/website/public/assets/` only by agreement.

## Coordinate system and conventions

- Right-handed, **+Y up**, units in **metres** (glTF default). Record real dimensions if they are measured. The viewer normalises scale either way.
- Model resting on its feet at y = 0, roughly centred in x/z (the loader re-centres anyway).
- **Front convention:** state which axis is the drone's front (preferably **+Z forward**) and where it comes from: the verified reference's `front_convention`. Until it is documented, set `front_defined: false`. The site then hides the Front view and says why.

## Expected hierarchy and stable identifiers

Node names drive component selection. Unnamed geometry is shown as part of the whole model and is never guessed into a component.

| Node name prefix | Meaning | Required |
|---|---|---|
| `part_body` | Body shell / canopy (may contain children) | optional |
| `part_arm_*` | Each arm | optional |
| `part_motor_*` | Each motor and its pod | optional |
| `part_prop_*` | Each propeller (pivot at the motor shaft, so a resting-angle rotation is about the shaft) | optional |
| `anchor_<name>` | Empty node used to place a label (e.g. `anchor_prop0`, `anchor_body`) | optional |

- Suffixes (`_0`, `_a`, etc.) are **drawing identifiers only**. They are not motor IDs.
- **Motor and propeller selection metadata:** a mapping from a node to a reference `motor_id` is accepted only from the verified reference (`contracts/reference.schema.json`, status `verified`) with its `source_evidence`. Put it in the manifest entry as `motor_nodes: { "<node name>": "<reference motor_id>" }`. Never derive it from mesh order, node order, or screen position.

## Single merged mesh

If the approved file is one merged mesh, the site still supports:

- whole-model rotation, zoom, views, 360° turn and lighting presets;
- story camera moves and annotations placed with `anchor_*` empties, or with points the team confirms;
- the schematic or SVG drawings for explaining parts.

The site will **not** offer separated parts or per-component highlighting for such a file. The `setExplode` capability is only enabled after the hierarchy has been inspected.

## Exploded view

Supported only when `part_*` groups exist and their pivots make sense. Each separable group moves along a direction the website team defines after inspecting the file. The schematic already demonstrates the behaviour.

## Materials and textures

- PBR metallic-roughness materials. Base colour in sRGB.
- Each component group should have its own material(s); the loader clones per-group materials so highlighting stays per group.
- Textures at most 2048 px on the longest side (1024 preferred), power of two, KTX2 only if a transcoder is agreed.
- No baked lighting that would contradict the lighting presets.

## Budgets

| Item | Budget |
|---|---|
| File size (compressed transfer) | ≤ 3 MB target, 6 MB hard limit |
| Triangles | ≤ 150 k |
| Draw calls | ≤ 60 |
| Texture memory | ≤ 32 MB GPU |
| Time to first frame on a mid-range Android phone | poster shown immediately; 3D replaces it when ready, with no blocking loader |

## Source, rights and attribution

Every asset entry records: author/source, licence or written permission, date obtained, whether it depicts the exact supplied variant, and the attribution text to show. Search-engine results are not a source or a licence. A model of a different drone must not be presented as the supplied hardware.

## Fallback poster

- An SVG or image in the same framing as the default view, under 150 kB, visibly labelled "illustrative" unless it is a verified photo or render of the supplied drone with rights cleared.
- It is shown before load, when WebGL is unavailable, after a load error and after context loss.

## Versioning and replacement

1. Add the file under the agreed location and record its `sha256`.
2. Add or replace the entry in `apps/website/public/assets/manifest.json`:

   ```json
   {
     "id": "drone-model-v1",
     "role": "drone-model",
     "status": "approved",
     "path": "assets/drone-model-v1.glb",
     "front_defined": false,
     "sha256": "<hash>",
     "source": "<who/where>",
     "rights": "<licence or permission>",
     "depicts_supplied_variant": true
   }
   ```

3. Set the previous entry's status to `pending` or remove it. Only `status: "approved"` with `role: "drone-model"` replaces the schematic (see `src/viewer/asset-source.ts`).
4. Update the stage captions in `index.html` if the illustrative label no longer applies. Keep the "not a motor map" wording until a verified reference exists.
5. Run `npm run check` and the browser checks in `docs/website/CHECKS.md`.
6. Propose the matching `resources/manifest.json` entry through `docs/handoffs/frontend-web.md`.
