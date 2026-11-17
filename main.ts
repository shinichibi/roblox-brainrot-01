// Brainrot Bay — hand-in program for the roblox-brainrot-01 bounty (Node 22, standard
// library only).
//
// The game itself is the Rojo project in this repository: src/ holds every Luau script
// and game.rbxl is the place Rojo builds from it. This program's one job is to hand the
// entry in: it stages game.rbxl, PLAY.json, src/ and screenshots/ into the output
// directory and writes dossier.json there with the vendored make.fun library
// (vendor/makefun-roblox.ts, untouched), which is the summary the gate re-derives and
// compares byte for byte.
//
// Two staging rules matter:
//   - nothing whose name starts with a dot may reach the output (a stray .gitkeep or
//     .DS_Store fails the entry), so the copy below skips dot-names at every depth;
//   - the dossier caps passed to buildDossier are the gate's own, so what is written
//     here is exactly what the scorer accepts.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, existsSync, mkdirSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const repoDir = dirname(fileURLToPath(import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** True when a file or directory name is allowed into the output (no dot-names). */
function isStagedName(name: string): boolean {
  return !name.startsWith('.');
}

/** Copy one file, or a whole directory tree, skipping dot-named entries at any depth. */
function stage(sourcePath: string, targetPath: string): void {
  if (!existsSync(sourcePath)) return;
  if (statSync(sourcePath).isDirectory()) {
    mkdirSync(targetPath, { recursive: true });
    for (const entry of readdirSync(sourcePath)) {
      if (isStagedName(entry)) stage(join(sourcePath, entry), join(targetPath, entry));
    }
  } else {
    mkdirSync(dirname(targetPath), { recursive: true });
    copyFileSync(sourcePath, targetPath);
  }
}

stage(join(repoDir, 'game.rbxl'), join(outputDir, 'game.rbxl'));
stage(join(repoDir, 'PLAY.json'), join(outputDir, 'PLAY.json'));
stage(join(repoDir, 'src'), join(outputDir, 'src'));
stage(join(repoDir, 'screenshots'), join(outputDir, 'screenshots'));

// The gate's caps, as the starter's hand-in used them: the dossier text is capped at
// 64 KiB, at most 4 screenshots of at most 256 KiB ride along, and the place may hold
// at most 500,000 instances, 8 MiB of script source and 1 MiB of script path text.
const DOSSIER_CAPS = {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
};

writeFileSync(join(outputDir, 'dossier.json'), buildDossier(outputDir, DOSSIER_CAPS));
