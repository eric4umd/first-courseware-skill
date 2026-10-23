---
name: eric-teaching-press
description: Companion to the Eric带你学AI tutorials. Create editable bilingual A4 lesson handouts in D1 Marginalia, D2 Grid or D3 Index Cards, with student tasks and teacher explanations.
metadata:
  version: 0.3.1
---

# Eric Teaching Press

Companion Skill for the 「Eric带你学AI」 teaching tutorials. Start with [the repository guide](../README.md). D1 Marginalia, D2 Grid and D3 Index Cards share one lesson-content source. Choose a style from [styles.md](references/styles.md) to fit the material.

Use the skill directory containing this file as `SKILL_ROOT`; resolve a symlink to its target. All resource paths below are relative to that root. Work in a new authorized output folder, never inside the installed assets or the original exploration.

Requires existing Python 3 and Typst with embedded Libertinus Serif; pixel QA requires an existing PDF renderer. Do not install dependencies implicitly.

## Produce a lesson

1. Establish topic, level, learning target, requested pages, student/teacher audience and style from the request. Reuse supplied evidence; examples here are fictional, not learner records. Read [authoring.md](references/authoring.md) for the specimen schema and limits before adapting it.
2. Create an editable project using the existing runtime:

   `python3 SKILL_ROOT/scripts/press.py init OUTPUT_DIR --style d1`

   Styles are `d1`, `d2`, `d3`. For D2/D3, also supply an explicit `--font-mode original-system` (preserve the selected original look for local review; rights unverified) or `--font-mode ofl-candidate` (portable OFL option; visible type changes). If the user has not chosen a font policy, present the original and candidate previews before making that material choice. There is no silent D2/D3 font default. Select only requested roles with `--roles grammar` or comma-separated `cover,words,grammar,reading,cloze,writing,teacher-reading`. Default is the seven-role comparison specimen. The helper refuses to overwrite an existing project.
3. Edit `OUTPUT_DIR/content.typ` and, when necessary, that project's `style.typ`. The source is a worked grammar-and-reading example, not a universal content generator. Replace every lesson-specific label, question, answer, timeline, gloss and illustration that no longer fits. Do not rename only the cover and leave a stale lesson underneath. Keep student tasks free of keys. For a full teacher edition reproduce all student tasks in order, with answers, evidence, tempting errors and repair moves beside each task; the bundled teacher-reading role covers only reading.
4. Compile: `python3 SKILL_ROOT/scripts/press.py build OUTPUT_DIR`. In `ofl-candidate` mode it uses only bundled OFL font assets plus Typst's embedded Libertinus; system font lookup is disabled. In `original-system` mode it retains the original Mac font references for local review and prints a rights warning; it does not bundle system font binaries or establish permission to publish. Read [fonts.md](references/fonts.md) before discussing font fidelity or publishing. D2/D3 are explicitly labeled OFL candidates: Inter replaces the proprietary Latin sans faces; Noto Serif SC replaces Chinese system faces. D3 loses the original rounded lettering. Preserve that distinction in review notes, not student pages.
5. Render every changed PDF page and inspect actual full-page pixels. Check clipping, overlap, page count, writing space, student/teacher alignment, full cloze passage with numbered A-D rows, and glyphs. Verify the actual embedded font identities. A successful compile or font allowlist alone is not layout approval. If the renderer is unavailable, report the missing check.

Use US spelling. IPA uses Libertinus Serif and American dictionary conventions; verify the particular vocabulary before claiming it checked. Body tasks should generally be at least 10 pt; smaller rail labels and teacher notes require readable full-size proofing. Meaning must survive grayscale without depending only on color. Keep student pages free of technical notes, personal paths, MBTI labels and revision commentary.

Deliver editable source and readable PDF/Markdown as requested, with a concise QA note stating what was inspected and what remains untested. Do not claim printed, classroom-tested, accessible/tagged or publisher-ready without the relevant evidence. Browser checks require a supported permitted browser; do not work around a browser permission refusal. Installing this skill does not authorize publishing, sharing changes, software installation, account changes or persistent access grants.
