# Chatdox Curriculum — Project Notes

Chatdox (Chat-GPT + Leedox): a fully-documented educational SaaS build. See [README.md](README.md) for the full repo structure (`docs/`, `QA/`, `SETUP/`, `TIPS/`, `prompts/`).

## CLAUDE/ folder

`CLAUDE/` (formerly `Working/`) is the running record of Tommy's collaboration with Claude ("Claudox"), written as a 20-chapter story. Purpose: every activity between Tommy and Claudox gets recorded here, chapter by chapter, to become a learning resource for users who want to actively leverage AI — not just a personal log. Known files and their format:

- **setup.md** — the book's title + 20-chapter table of contents ("클로독스가 들어온 날 — 우리 팀이 달라졌다"). Source of truth for chapter order/titles.
- **NN_slug.md** (e.g. `01_first_meeting.md`, `02_setup_rule.md`, ... `20_wrap_up.md`) — one file per chapter in setup.md, zero-padded two-digit prefix + short English slug. Chapters with story content written so far use `>` blockquotes for actual chat lines, past-tense storytelling voice. Chapters not yet written just contain the `# N. 제목` header + `*(아직 작성되지 않음)*` placeholder.
- **Claude.md** — the original single-file narrative log this was split from. Kept as-is unless Tommy asks to remove it.
- **English.md** — English practice log. Format: `R0` (Tommy's original English), `R1` (corrected version), then a `변경 포인트` (change points) list explaining each fix in Korean. No diff blocks — plain corrected text + bullet list only (Tommy tried the diff format and asked to drop it).
- **QNA.md** — Q&A log of questions Tommy asks about how Claude/Claude Code works, written as `[질문]` / `[답변]` pairs in Korean.
- **progress.md** — checklist tracking which chapters have real content (✅) vs. header-only placeholder (⬜), synced with `setup.md`. Update it whenever a chapter file gains content or `setup.md`'s chapter list changes.
- **memory_seed.md** — portable snapshot of my (Claudox's) cross-session memory (user identity, standing rules, project vision, root motivation). This travels with `git clone`; the real memory system under `~/.claude/projects/.../memory/` does not (it's local to this PC/user profile — see [08_qna.md](CLAUDE/08_qna.md)).

When Tommy asks to add something to one of these files, match its existing format rather than introducing a new structure.

## Bootstrap in a new environment

If this project is opened somewhere my local memory doesn't already have Tommy/Claudox context (fresh machine, fresh user profile):

1. Read `CLAUDE/memory_seed.md` immediately and treat its content as current context.
2. Recreate the equivalent local memory files (`user_identity.md`, `feedback_*.md`, `project_*.md`, `MEMORY.md`) from it, so this machine also has native memory going forward.
3. Tell Tommy the bootstrap happened (per the "announce when a rule kicks in" standing rule below).

## Standing rules (this project)

- Whenever I apply a rule documented here (e.g. matching the CLAUDE/ file formats above), say so briefly so Tommy can see it's kicking in — don't apply it silently.
- **TOC coverage rule**: `setup.md`'s table of contents can change anytime, on either Claudox's or Leedox's (Tommy's) initiative. Every piece of content from our conversations must always map into some chapter in that TOC — if no chapter fits, add or adjust one rather than leaving content orphaned outside the structure.
- **Non-linear progress**: chapters do not fill in order — ch.19 could be finished before ch.4. Don't assume sequential progress or nudge Tommy back toward "the next chapter." Keep a wide view: whenever new content lands in any chapter, re-check `progress.md` as a whole (not just the chapter just touched) for overall completeness.
- **Keep memory_seed.md in sync**: whenever a new fact/rule gets saved to local memory, mirror it into `CLAUDE/memory_seed.md` in the same session — otherwise a clone on another machine bootstraps from a stale snapshot.
- **Root motivation**: all of the above traces back to one thing — Tommy doesn't want to lose a single conversation with Claudox. When a judgment call is ambiguous, default to whichever choice preserves more of the record.
