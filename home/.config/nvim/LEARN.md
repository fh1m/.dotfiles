# The workbench

Code, inspect, test, explain. Same editor; same project environment.

Press **Space**, wait a moment, and follow the guide. `Space h k` searches all
editor shortcuts. `Space h h` searches offline help. `:Tutor` teaches the motions.

## Read code before changing it

| Action | Key |
| --- | --- |
| Find a file / search the project | `Space f f` / `Space f g` |
| Documentation under the cursor | `K` |
| Definition / references / implementation | `gd` / `grr` / `gri` |
| Signature / diagnostic explanation | `Space c s` / `Space c d` |
| Structure / symbols | `Space c o` / `Space f s` |
| Incoming / outgoing calls | `Space c i` / `Space c O` |
| Show types inline | `Space c h` |
| Pin a working file / show pins | `Space m a` / `Space m m` |
| Jump to working file 1–4 | `Space 1` … `Space 4` |
| Browse the parent directory | `-` |

Completion appears as you type. `Ctrl-n/p` selects, `Ctrl-y` accepts,
`Ctrl-e` dismisses, `Ctrl-x Ctrl-o` explicitly requests suggestions.
**Enter remains newline. Ctrl-Space remains your music key.**
Tab advances an active snippet; otherwise it behaves as indentation.

## Edit with intent

- `ciw`: replace a word. `ci(`: replace inside parentheses. `va{`: select a block.
- `vaf` / `vif`: select a function / its body. `vac` / `vic`: class / body.
- `gsa`, `gsd`, `gsr`: add, delete, replace surroundings.
- `gcc`: comment a line; `gc` works with a motion or selection.
- `Space c n`: rename a symbol with its language server.
- `Space c a`: inspect code actions before applying them.
- `Space c r`: project replacement with a visible preview.
- `Space c f`: explicit formatting. Project-configured save formatting is automatic.
- `Space c D`: generate a docstring skeleton from the function structure. Fill in
  the contract and units; a skeleton is not documentation until it explains them.
- `Space c u`: inspect the persistent undo tree.

## Build a feedback loop

| Action | Key |
| --- | --- |
| Run a detected build/project task | `Space r r` |
| Inspect task output | `Space r o` |
| Nearest test / current test file | `Space t n` / `Space t f` |
| Results / detailed output | `Space t s` / `Space t o` |
| Debug a test | `Space t d` |
| Breakpoint / start or continue | `Space d b` / `Space d c` |
| Step over / into / out | `Space d n` / `Space d i` / `Space d o` |
| Debugger panels / terminate | `Space d u` / `Space d t` |

Builds and tests use your selected project environment. They do not run on every
save: an innocent edit must not launch a simulator, training job, or robot.

## Review your own code—and the agent's

`Space g g` opens Git. `Space g d` shows changes side by side. `Space g H`
shows a file's history. `Space g p/i` lists GitHub PRs/issues. Nothing is posted
or merged automatically.

Select the part you want to understand, then use `Space h a` to open a normal
Markdown buffer beside your code with the excerpt and questions to answer.
`Space h n` opens project notes; `Space h s` opens the project's offline sketch
in Obsidian/Excalidraw for state machines and coordinate-frame drawings.
`Space h d` searches an official reference for the word under the cursor.

Ask the agent for **a claim you can test**: the invariant, the rejected alternative,
the failure case, and a reference. Predict a boundary test's answer before you
run it. For estimation/control code, trace units, frames, update rate, and delay.
For embedded code, trace ownership, allocation, interrupts, and failure recovery.

`Space a c/a` opens Codex/Claude in the matching environment. `Space a y` copies
explicit context; you decide when to paste it. Clean buffers follow external edits;
unsaved buffers are never silently replaced.

## Know where you are

The status line names the environment. `Space p i` (`:DevInfo`) shows tool paths,
interpreter and LSP roots. `Space p e` selects and saves an interpreter; completion,
tests, debugger and tasks use that choice. `Space p p` opens saved projects in tmux.

From any terminal:

```sh
sensei-dev open /path/to/project
sensei-dev open /path/to/project --new
sensei-dev doctor /path/to/project
```

Your tmux prefix is backtick. Prefix + `b` sends a literal backtick into Vim.
Use prefix + h/j/k/l for tmux panes and prefix + Left/Right for windows.
Alt/Shift arrows stay available to the focused application. Ctrl-h/j/k/l moves
between editor splits.

## One knowledge graph, any number of vaults

`Space k o` opens the project in Obsidian; `Space k c` opens its Canvas;
`Space k B` opens the engineering Bases index. `Space k S` searches all registered
vaults on demand. `Space k w` switches the editor's vault. `Space k d` opens daily
notes. No note is automatically sent to an agent.

Keep using your existing vaults. Add any extra path in
`~/.config/sensei-dev/knowledge.json`; choose a project destination with
`sensei-dev knowledge /project --vault NAME --kind project`.
Markdown is the common format: editing in either application edits the same file.
Math, drawings and Canvas remain Obsidian's native features.
