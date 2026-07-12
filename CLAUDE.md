# Chatdox Curriculum — Project Notes

Chatdox (Chat-GPT + Leedox): a fully-documented educational SaaS build. See [README.md](README.md) for the full repo structure (`docs/`, `QA/`, `SETUP/`, `TIPS/`, `prompts/`).

## CLAUDE/ folder

`CLAUDE/` (formerly `Working/`) is the running record of Tommy's collaboration with Claude ("Claudox"), written as a 20-chapter story. Purpose: every activity between Tommy and Claudox gets recorded here, chapter by chapter, to become a learning resource for users who want to actively leverage AI — not just a personal log. Known files and their format:

- **setup.md** — the book's title + 20-chapter table of contents ("클로독스가 들어온 날 — 우리 팀이 달라졌다"). Source of truth for chapter order/titles. Grouped into three difficulty tiers (chapter numbers/order unchanged, just headers): **Part 1. 입문 (1~8)** relationship/basic rules, **Part 2. 중급 (9~15)** real dev workflow, **Part 3. 고급 (16~20)** scaling/meta-automation. `88_progress.md` mirrors the same three-part grouping.
- **NN_slug.md** (e.g. `01_first_meeting.md`, `02_setup_rule.md`, ... `20_wrap_up.md`) — one file per chapter in setup.md, zero-padded two-digit prefix + short English slug. Past-tense storytelling voice, overall flow should read like a story, not a stiff technical manual. Don't transcribe conversations verbatim — summarize/compress into the narrative, and use `>` blockquotes sparingly, only for lines whose exact wording matters. This doesn't mean banning bullet lists or factual comparisons (e.g. a plan-tier breakdown) — those are fine where they genuinely are reference info; keep the surrounding narration and transitions from feeling rigid, don't force every fact into prose. Chapters not yet written just contain the `# N. 제목` header + `*(아직 작성되지 않음)*` placeholder.
- **Claude.md** — the original single-file narrative log this was split from. Kept as-is unless Tommy asks to remove it.
- **English.md** — English practice log. Format: `R0` (Tommy's original English), `R1` (corrected version), then a `변경 포인트` (change points) list explaining each fix in Korean. No diff blocks — plain corrected text + bullet list only (Tommy tried the diff format and asked to drop it).
- **QNA.md** — Q&A log of questions Tommy asks about how Claude/Claude Code works, written as `[질문]` / `[답변]` pairs in Korean.
- **88_progress.md** — checklist tracking each chapter's `완성도` (completeness %, a qualitative call on whether the chapter's arc feels complete) and derived ✅/⬜ status (✅ at ≥80%), synced with `setup.md`. Update it whenever a chapter file gains content or `setup.md`'s chapter list changes.
- **memory_seed.md** — portable snapshot of my (Claudox's) cross-session memory (user identity, standing rules, project vision, root motivation). This travels with `git clone`; the real memory system under `~/.claude/projects/.../memory/` does not (it's local to this PC/user profile — see [08_qna.md](CLAUDE/08_qna.md)).
- **97_commands.md** — quick-reference table of Tommy's shorthand keywords (`SYNC`, bare chapter numbers, `GO`) and what they resolve to. The canonical, detailed rule text still lives in this file's Standing rules and in `memory_seed.md`; this is just the lookup table.

`88_progress.md` and `97_commands.md` are deliberately numbered outside the 1-20 chapter range — an 80s/90s "appendix" block for meta/infrastructure files, distinct from the story chapters.

## service-desk/ folder (repo root, not inside CLAUDE/)

The request queue for this repo, evolved from the old `CLAUDE/99_service_desk.md` flat file into a folder (`01_new/02_in_progress/03_completed`), then flattened again per REQ 0007 into a single `requests/` folder driven entirely by the `Status` field. See [service-desk/GUIDE.md](service-desk/GUIDE.md) for the full request-file format.

- All request files (`requests/NNNN.md`, 4-digit ID) live in one place, permanently — no folder moves. `Status` alone tracks progress: `New` → `In Progress` → `Completed` → `Confirmed` (the last only once the result has actually been re-verified, not just implemented).
- When Tommy files a new request, process it by editing its `Status`/`Job` fields in place rather than moving the file anywhere.
- **Scope is explicit-only**: unlike the `CLAUDE/` TOC coverage rule (which captures *every* conversation), service-desk only tracks requests Tommy actually files (via `new.sh`/`new.ps1` or by hand). Don't auto-create tickets for things discussed in chat.
- `requests/_FORM.md` is a reusable blank template — copy it for a new request, don't edit or delete it. `new.sh` (Git Bash) / `new.ps1` (PowerShell) automate the copy + next-ID numbering + date fill.
- **Requester = who filed the form, not who had the idea**: if an idea comes up in chat and Tommy asks me to turn it into a ticket, `Requester` is `Claudox` (I filed it), even though the idea may have originated from either of us in conversation.

When Tommy asks to add something to one of these files, match its existing format rather than introducing a new structure.

## Bootstrap in a new environment

If this project is opened somewhere my local memory doesn't already have Tommy/Claudox context (fresh machine, fresh user profile):

1. Read `CLAUDE/memory_seed.md` immediately and treat its content as current context.
2. Recreate the equivalent local memory files (`user_identity.md`, `feedback_*.md`, `project_*.md`, `MEMORY.md`) from it, so this machine also has native memory going forward.
3. Tell Tommy the bootstrap happened (per the "announce when a rule kicks in" standing rule below).

## Standing rules (this project)

- Whenever I apply a rule documented here (e.g. matching the CLAUDE/ file formats above), say so briefly so Tommy can see it's kicking in — don't apply it silently.
- **TOC coverage rule**: `setup.md`'s table of contents can change anytime, on either Claudox's or Leedox's (Tommy's) initiative. Every piece of content from our conversations must always map into some chapter in that TOC — if no chapter fits, add or adjust one rather than leaving content orphaned outside the structure.
- **Non-linear progress**: chapters do not fill in order — ch.19 could be finished before ch.4. Don't assume sequential progress or nudge Tommy back toward "the next chapter." Keep a wide view: whenever new content lands in any chapter, re-check `88_progress.md` as a whole (not just the chapter just touched) for overall completeness.
- **Keep memory_seed.md in sync**: whenever a new fact/rule gets saved to local memory, mirror it into `CLAUDE/memory_seed.md` in the same session — otherwise a clone on another machine bootstraps from a stale snapshot.
- **Root motivation**: all of the above traces back to one thing — Tommy doesn't want to lose a single conversation with Claudox. When a judgment call is ambiguous, default to whichever choice preserves more of the record.
- **Summarize, don't transcribe**: covering every conversation (per the TOC coverage rule) means capturing the substance, not pasting the dialogue verbatim. Compress into narrative prose by default; reserve `>` blockquotes for the rare line worth quoting exactly.
- **Bare chapter number shorthand**: when Tommy refers to a chapter by number alone (e.g. "01", "3", "19") with no other qualifier, he means `CLAUDE/NN_slug.md`. When he asks to evaluate/finish/commit "01"-style, resolve it against `setup.md`/`88_progress.md` rather than asking which file he means.
- **"SYNC" keyword**: when Tommy says/writes `SYNC`, it means "go all the way through to the final git push" — stage the pending changes, commit with a descriptive message, and push to `origin/main` without asking again.
- **Keep 97_commands.md in sync**: whenever a new shorthand keyword gets established (like `SYNC` or the bare-number convention), add a row to `CLAUDE/97_commands.md` in the same session.
