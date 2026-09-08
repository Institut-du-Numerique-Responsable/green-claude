# Ecodesign for Shell (sh, bash, zsh)

**Version:** 1.0.0 | **Rules:** 6 | **Extensions:** sh, bash, zsh

Ecodesign rules for shell scripts: no process spawned per line, no polling, streamed data, temporary files cleaned up.

---

## Metadata

| Property | Value |
|---|---|
| **File** | `skills/green-claude/rules/langages/shell.json` |
| **Globs** | `**/*.{sh,bash,zsh}` |
| **Extensions** | `sh, bash, zsh` |
| **Rule Count** | 6 |

## Rules by Category

### Shell — processes

A shell script pays for every process it starts; in a loop, that is the whole cost (RGESN Algorithms).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-SH-01 | High | Command substitution inside a loop | Do the work in one pass: awk, sed or a single pipeline. Where the loop must stay, hoist whatever does not depend on the iteration out of it. |
| ECO-SH-02 | Low | Useless use of cat | Redirect instead: command < file, or pass the filename as an argument. |
| ECO-SH-03 | Low | Chained greps and cuts | Collapse the chain into one awk or sed pass, as long as it stays readable. Readability wins over a saved fork. |

<details>
<summary>Example for ECO-SH-01</summary>

**Before:**
```
for f in $(ls); do wc -l "$f"; done
```

**After:**
```
find . -type f -print0 | xargs -0 wc -l
```

</details>

### Shell — waiting and I/O

Never wait actively, never grow a file without bound (RGESN Backend/Hosting).

| ID | Impact | Title | Recommendation |
|---|---|---|---|
| ECO-SH-04 | Medium | Polling loop | Block on the event instead: wait for the PID, inotifywait, a queue, or a signal. Where polling is the only option, widen the interval and give the loop a bound. |
| ECO-SH-05 | Medium | Temporary file with no cleanup | Pair every mktemp with a trap that removes it on EXIT, so the cleanup happens on the error paths too. |
| ECO-SH-06 | Low | Unbounded output to a log or a file | Bound what you write: a log level, rotation, or a retention job. A script that writes a log should also say who deletes it. |

---

[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)