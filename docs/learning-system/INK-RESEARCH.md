# Noesis handwriting and learning research — 23 October 2026

32 fresh targeted search queries; search results are discovery, not equivalent evidence.
Primary research and official documentation were followed up separately. Practitioner
threads identify friction, not causal proof. No claim of 32 fully read papers.

## Query ledger

1. retrieval practice conceptual learning science Karpicke Blunt 2011 concept mapping Science
2. Dunlosky 2013 improving students learning effective learning techniques practice testing distributed practice
3. National Academies How People Learn II knowledge integration self regulated learning
4. handwriting typing learning replication meta analysis note taking
5. drawing to learn generative drawing meta analysis Fiorella Mayer science education
6. Wammes drawing effect memory 2016 drawing benefits recall
7. self explanation worked examples guidance fading cognitive load research
8. mathematical handwriting digital pen note taking spatial external representations learning
9. site.xournalpp.github.io guide PDF annotation export SVG pressure tablet
10. site.xournalpp.github.io documentation command line export pdf png
11. site.obsidian.md help attachments embed PDF Canvas drawing
12. site.excalidraw-obsidian.com excalidraw pen tablet export svg markdown
13. site.opentabletdriver.net wiki output area pressure absolute mode Linux
14. site.github.com xournalpp xournalpp file format autosave backup PDF export
15. site.zotero.org support annotations pdf reader export notes embedded annotations
16. site.sioyek-documentation.readthedocs.io annotations portals PDF bookmarks
17. site.pnas.org active learning STEM Freeman 2014 failure rate
18. site.nature.com npj science learning retrieval feedback transfer interleaving review
19. site.retrievalpractice.org spacing retrieval feedback learning research
20. site.learningscientists.org interleaving elaboration dual coding evidence
21. site.jsoncanvas.org spec files edges nodes portable
22. site.obsidian.md help Bases formula filters properties templates
23. site.quarto.org reproducible computational notebooks manuscripts Jupyter
24. site.neurips.cc PaperChecklist reproducibility assumptions experimental results
25. site.reddit.com/r/ObsidianMD handwriting xournalpp excalidraw workflow friction
26. site.news.ycombinator note taking knowledge management learning over organizing
27. site.reddit.com/r/PhD research notes paper annotation reproducibility notebook
28. site.github.com xournalpp plugin autosave export PDF watcher Obsidian
29. site.karpathy.github.io recipe neural network small baseline inspect data
30. site.github.com geohot fromthetransistor curriculum project
31. site.andymatuschak.org notes spaced repetition understanding practice
32. site.pubmed.ncbi.nlm.nih.gov learning metacognition calibration transfer feedback self explanation

## Evidence → behavior

| Source / date / class | Finding and limits | Noesis decision |
|---|---|---|
| [Dunlosky et al., 2013](https://www.psychologicalscience.org/publications/journals/pspi/learning-techniques.html), research review | Practice testing and distributed practice have broad support; effectiveness varies by task. | Reconstruct a derivation without looking, then compare; a saved drawing does not imply competence. |
| [Karpicke & Blunt, 2011](https://pubmed.ncbi.nlm.nih.gov/21252317/), experiment | Retrieval improved conceptual learning in the tested materials; this does not make all maps useless. | Use diagrams both as working representations and later blank-page retrieval tests. |
| [Wammes et al., 2016](https://pubmed.ncbi.nlm.nih.gov/26444654/), seven experiments | Drawing helped free recall, largely with word stimuli. It does not establish engineering transfer. | Make drawing convenient; evaluate engineering ability with problems, predictions and builds. |
| [Weinstein et al., 2018](https://link.springer.com/article/10.1186/s41235-017-0087-y), tutorial review | Retrieval, spacing, interleaving, elaboration, examples and dual coding have different mechanisms. | Offer modes and explicit feedback, rather than one compulsory note template. |
| [How People Learn II, 2018](https://www.nationalacademies.org/read/24783/chapter/6), consensus synthesis | Existing knowledge, integration and self-regulation shape learning. | Link ink to the actual question/concept/path; preserve learner control and prerequisite classes. |
| [Freeman et al., 2014](https://doi.org/10.1073/pnas.1319030111), STEM meta-analysis | Active learning benefits classroom outcomes; not a direct evaluation of personal PKM software. | Favor attempts and feedback over counting pages or minutes. |
| [Karpathy, 2019](https://karpathy.github.io/2019/04/25/recipe/), primary engineering practice | Inspect data, verify simple baselines and increase complexity incrementally. | Ink calculations should connect to numerical checks, code and experiments. Anecdote is not learning-science proof. |
| [From the Transistor](https://github.com/geohot/fromthetransistor), primary project | An inspectable stack built through successive abstractions. | Keep deep descents available without blocking every interesting build. |
| [Matuschak, 2020](https://andymatuschak.org/prompts/), practitioner synthesis | Good retrieval prompts require careful scope and feedback. | Review a specific reconstruction, not an undifferentiated notebook. |
| [Xournal++ PDF guide](https://xournalpp.github.io/guide/pdfs/), official living docs | PDF backgrounds and editable journals are distinct; exports flatten marks and may omit original interactive PDF features. | Copy background beside journal, preserve original, export an explicitly derived PDF. |
| [OTD Linux guidance](https://opentabletdriver.net/Wiki/FAQ/LinuxAppSpecific), official living docs | Pressure requires a compatible artist-mode/application path. | Reuse working native driver and mapping; do not substitute mouse-only canvas emulation. |
| [Obsidian formats](https://obsidian.md/help/file-formats), [embeds](https://obsidian.md/help/embeds), official living docs | Native PDF/image embedding; Xournal journals need an external editor. | Markdown record links editable journal and embeds generated PDF. No opaque ink database. |
| [JSON Canvas 1.0](https://jsoncanvas.org/spec/1.0/), open specification | Portable spatial nodes/edges, not a pressure notebook format. | Preserve Canvas for relationship maps alongside native ink. |
| [Zotero PDF reader](https://www.zotero.org/support/pdf_reader), official living docs | Zotero annotations have their own authority/export lifecycle. | Do not claim two-way synchronization between Xournal and Zotero. |
| [Quarto manuscripts](https://quarto.org/docs/manuscripts/), [NeurIPS checklist](https://nips.cc/public/guides/PaperChecklist), official docs | Executable analysis and explicit experimental reporting solve different needs from handwriting. | Link actual repositories/runs; do not rebuild notebook execution in QML. |

## Existing tools and objections

[Xournal++ Obsidian integration](https://github.com/jonjampen/obsidian-xournalpp)
already offers journal embedding/export. It is a credible alternative for an
Obsidian-only workflow. This implementation instead reuses Noesis' existing stable
artifact identity, publication receipts and tablet watcher, avoiding another plugin
and two competing export owners. Xournal++ remains the ink engine.

[Pen behavior](https://www.reddit.com/r/ObsidianMD/comments/1ac6fu5),
[handwriting workflow friction](https://www.reddit.com/r/ObsidianMD/comments/1pswee9),
[Excalidraw smoothing](https://www.reddit.com/r/ObsidianMD/comments/1iex5u5), and
[org-xopp](https://www.reddit.com/r/emacs/comments/1habnh2) are practitioner reports,
not community consensus. Their useful design pressure is fewer manual exports,
clear editable originals, and reliable pen behavior—not more mandatory metadata.

Handwriting-versus-typing results are mixed and task-dependent. Search found
DOI 10.1016/j.cedpsych.2021.102025 and [a 2024 meta-analysis abstract](https://eric.ed.gov/?id=EJ1430416);
full-text access was limited. No claim that a tablet intrinsically outperforms typing
is justified here. Choose the representation that helps the current reasoning.

## Runtime follow-up

UI testing exposed Qt 6.12 versus a Qt 6.11.2 Quickshell binary. The primary
[upstream compatibility change](https://github.com/quickshell-mirror/quickshell/commit/5d5d49873fe8cf1f99ddfd5006ceb2057c5c9b13)
uses complete MOC includes and out-of-line bindables. A small attributed port is
kept with the pinned local build rather than downgrading the whole desktop.
