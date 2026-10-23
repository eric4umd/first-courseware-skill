# Adapting the source

`assets/template/content.typ` is the shared fictional Past Perfect lesson. It exports `lesson`, `grammar`, `vocab`, `words-page`, `sound`, `reading`, `cloze`, `writing`, `labels` and semantic helpers (`pp`, `pp-show`, `fill-blanks`, `stem-with-blank`). Copy it with the helper and edit the project copy.

- `lesson` carries title, number, bilingual taglines, level, duration and brand.
- `grammar` carries form, rule, earlier/reference events, contrasts, signals, caution, checks and sentence repair. Inspect the skin's timeline labels, decorative cover words and form box when changing grammar topic. Some worked examples remain intentionally lesson-specific in the specimen skin.
- `vocab` includes word, part of speech, IPA, translation and example fields. Verify all IPA entries actually used, including stress, vowel and rhotic symbols; the exploration checked only shelf and entry.
- `reading` includes full paragraphs, questions, zero-based correct-choice indexes, explanations, traps and repair moves. Reading highlights and D1 margin glosses in the specimen skin are topic-specific and need updating alongside content.
- `cloze` uses numbered `{1}` markers in the full passage plus corresponding option rows. Changing the question count also requires reviewing the answer-row geometry.
- `writing` has combine tasks, continuation prompt and checklist. Do not make answer-writing room depend on screen size.

The default seven pages are a design specimen with a student section and one reading teacher page. When a complete paired edition is requested, extend the copied project with teacher versions of every task; do not deliver the specimen as though it already satisfies that request. A bounded single-page sample may use a subset of roles.

After editing metadata or changing text length, recompile and inspect every affected page. D1's two-line cover assumes a short title; D2/D3 have fixed-height cover artwork. A new topic may need illustration changes, not just text changes. The helper does not make semantic or pedagogical decisions.

The helper does not accept JSON/Markdown lesson input and does not validate teaching semantics. Its CLI schema validates style, selected roles, output-directory nonexistence, and explicit D2/D3 font mode. Typst validates syntax and required property access at build time. Arbitrary lessons still require an agent to author the content and review topic-specific skin elements.
