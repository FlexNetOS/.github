# Research: ai-top-utility

**Status:** Pre-adoption research. No upstream — first-party FlexNetOS.
**Action gated by this dossier:** Move `repos/ai-top-utility/` → `repos/owned/ai-top-utility/` as a submodule + add MANIFEST entry.

**Cross-reference:** Corrects [my-github-reconciliation.md](my-github-reconciliation.md) Reservation 2 — its claim that ai-top-utility is "likely UNSAFE-MISMATCH" is incorrect. Verified origin is `FlexNetOS/ai-top-utility` (FlexNetOS-owned, no upstream). Expected G3a exit: 0 (SAFE) or 11 (unpushed branches), not 13.


### *(drdave_input)* (Vision-Target): A full Rust and mojo implementation that can train all models, and covert any data to training data. Think "AI Model Gym" to train small models <1B parameter with perfect memory on their assigned role. 
- leverages all available harware in unity

## 1. Identity


| Field                 | Value                                                                               |
| --------------------- | ----------------------------------------------------------------------------------- |
| Origin                | `https://github.com/FlexNetOS/ai-top-utility.git`                                   |
| Upstream              | none (first-party owned)                                                            |
| License               | LICENSE file present — verify content during adoption                               |
| Default branch        | `main`                                                                              |
| Current local branch  | `fix/phase4-security-hardening`                                                     |
| Local state           | clean, no ahead/behind vs `origin/fix/phase4-security-hardening`                    |
| Latest local commit   | `1d19b98 docs(changelog): record Phase 4 follow-up sessions`                        |
| Other remote branches | `main`, `claude/cu132-session-2026-05-25`, `refactor/aitop-cu132-stage1-and-stage2` |


## 2. Purpose (per README)

> *"A cu132 refactor of the GIGABYTE AI TOP Utility 4.2.1 for hardware sync, model training prep, and on-device inference on dual RTX 5090 (Blackwell, sm_120) + CUDA 13.2 + torch 2.12. The vendor app shipped as an Electron front-end against a PyInstaller-bundled..."*

FlexNetOS-authored rework of GIGABYTE's vendor utility for the AI TOP
motherboard family — repackaged for the user's dual-RTX-5090 + CUDA 13.2 +
torch 2.12 hardware target. Includes reference manuals (PDF), an `aitop/`
core, `backend/`, `model-training-prep/`, `training/` modules, plus the
`Ubuntu 26.04 / NVIDIA 595 / CUDA 13.2 / ROCm / Torch 2.12` install
reference asset.

High-signal sub-directories:

- `aitop/`, `ai-top-map/`, `backend/`, `model-training-prep/`, `training/`,
`packaging/`, `openspec/`, `multi_files_test_dataset/`, `RAG_test_files/`
- `Ubuntu 26.04 _ NVIDIA 595 Driver_Cuda 13.2 toolkit_ Pytorch 2.12_…/`
- Top-level docs: `CHANGELOG.md`, `CLAUDE.md`, `HANDOFF.md`, `SESSIONS.md`,  
`STAGE1.md`, `STAGE2.md`, `STATUS.md`,  
`please_first_update_bios_for_AI_TOP_motherboard.txt`

- (drdave_input):I moved removed the sub-directories from the mnt patitions at `/mnt/aitop-train`, to `my-github/repos/ai-top-utility/training`, and `mnt/aitop-data` to `my-github/repos/ai-top-utility/data`
- (drdave_input): `/mnt/aitop-train` must remain empty and replaces:[gabyte.com/SSD/AI-TOP-Capable?fid=3049&page=1]

### 2.1 *(drdave_input)* Critical features!!!

### - Design leverages all hardware at the same to train. (Core Benifit: you can train a 500B on hardware designed to only train a 36B parameter model by using GPU, CPU, Ram, and SSD at the same time. That mean the SSD is mounted and blank. 

- Auto detects and loads hardware
- Monitores harwardware

### 2.2 *(drdave_input)* Referances

- gigabyte.com/Motherboard/TRX50-AI-TOP
- gigabyte.com/Motherboard/TRX50-AI-TOP/sp
- aorus.com/motherboards/TRX50-AI-TOP/Specification
- gigabyte.com/Consumer/ai-top
- (how to install ai-top youtube video):[youtube.com/watch?v=50IXFTBHkJ0]
- gigabyte.com/Press/News/2178
- (Refactored code to leverage other SSD. Orginal intented ssd here):[gigabyte.com/SSD/AI-TOP-Capable?fid=3049&page=1]

## 3. Stack inventory

Hardware-coupled Python + reference documentation. No `package.json`,
no `Cargo.toml`, no `pyproject.toml`, no `Dockerfile` at root. Manuals
(PDFs) bulk much of the disk. Treat as **docs/reference asset repo**, not
an app to build.

## 4. FlexNetOS-side intent

Bring into the umbrella as `repos/owned/ai-top-utility/` so it's part of
the single-clone reproducible workspace. Tag `[owned, reference]`, toolchain
`[docs]`. Not on the CI hot path — reusable lint/test workflows can skip
it (umbrella `verify.markdown` covers it). The PDF manuals and hardware
install asset are intentionally large; consider `partial_clone: "blob:none"` in MANIFEST if clone size becomes a concern.

## 5. Pre-adoption audit

- ✅ Origin is already FlexNetOS — no fork action required.
- ⚠️ Currently checked out on `fix/phase4-security-hardening`, not `main`.
Switch to `main` (or push the security-hardening branch first) before
converting to a submodule.
- ⚠️ Has its own `.claude/`, `.devcontainer/`, `.vscode/` directories.
Acceptable inside a submodule (each fork ships its own).
- ⚠️ Large binary assets (~35 MB total). Confirm committed to origin
(status is clean — they appear to be).
- ❌ No CI workflows of its own. It can inherit umbrella reusables via a
thin `ci.yml` caller — see adoption plan §6.

## 6. Adoption plan

Case: **first-party owned (no upstream)**.

1. Confirm `main` is current and the security-hardening branch is pushed:
  ```bash
   cd repos/ai-top-utility
   git checkout fix/phase4-security-hardening && git push origin HEAD
   git checkout main && git pull --ff-only origin main
  ```
2. From umbrella root, remove plain clone and add as submodule:
  ```bash
   rm -rf repos/ai-top-utility
   mkdir -p repos/owned
   git submodule add --depth=1 -b main \
       https://github.com/FlexNetOS/ai-top-utility.git \
       repos/owned/ai-top-utility
  ```
3. Add MANIFEST entry under OWNED section:
  ```yaml
   - path: repos/owned/ai-top-utility
     url: https://github.com/FlexNetOS/ai-top-utility
     branch: main
     toolchain: [docs]
     groups: [owned, reference]
     notes: |
       Cu132 refactor of GIGABYTE AI TOP Utility 4.2.1 for dual RTX 5090
       + CUDA 13.2 + torch 2.12. Reference manuals + install assets.
       FlexNetOS-original, no upstream.
  ```
4. Phase B (org-only rename) is **N/A** — no upstream to attribute.
5. Optional: add thin `.github/workflows/ci.yml` caller using umbrella
  reusables (`language: none` for markdown-only lint).

## 7. Sync risk

**None.** No upstream remote → no upstream sync → no merge conflict
surface. Evolves entirely under FlexNetOS control.

## 8. Verification

```bash
cd /home/drdave/workspace/my-github
make verify.manifest                       # MANIFEST schema OK
make submodules.status                     # submodule registered
ls repos/owned/ai-top-utility/README.md    # checkout present
```

## 9. Open decisions for user

- Is `fix/phase4-security-hardening` still active work, or can `main`  
be the tracked branch immediately? 
*(drdave_response)*:
  - First verify any work that is not commited then committ and creat PR
  - Switch to main branch, fix all conflicts and errors.
  - Create development branch were anywork is done
  - main canbe the tracked branched right away 
- PDF reference manuals: stay in-repo (current state) or move to LFS /
a separate asset repo?
*(drdave_response)*:
  - PDF references must be updated
  - create a submodule of ai-top-utility for archive
  - move old version to ai-top-utility-achive
- Any `.claude/` or `.devcontainer/` content here that needs to align
with the umbrella's `.claude/` setup, or intentionally independent?
*(drdave_response)*:
  - must align with with umbrella

## 10. Decision log

(empty — fill on adoption)