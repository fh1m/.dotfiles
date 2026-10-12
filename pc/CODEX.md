# Codex on Windows, CachyOS, and the laptop

Use a fresh login on each OS. Do not put ~/.codex credentials, session databases, GitHub tokens or private keys in this public repository. A Git handoff shares documented state, not the full conversation or a live agent connection.

## CachyOS

Install baseline tools on the NEW CachyOS install:

```sh
sudo pacman -Syu --needed git curl
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

Open a new terminal if the installer changed PATH, then:

```sh
codex --version
codex
```

Complete the sign-in flow with your existing account. If you already manage Node/npm, OpenAI also documents `npm install -g @openai/codex`; use your user-managed npm prefix rather than blindly running global npm as root. [Official Codex CLI installation](https://learn.chatgpt.com/docs/codex/cli)

## Windows 11 Pro — native PowerShell

Run the documented installer in PowerShell:

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 | iex"
```

Open a fresh PowerShell window and run:

```powershell
codex --version
codex
```

Complete the sign-in flow. This is native Windows; WSL/VMs are not required. Use the supported native sandbox that works on the installed machine, and diagnose compatibility errors rather than forcing an unverified mode. Disk/firmware checks may need administrator privileges outside Codex's ordinary sandbox. [Official CLI installation](https://learn.chatgpt.com/docs/codex/cli), [Windows support](https://learn.chatgpt.com/docs/windows/windows-sandbox)

Install Git for Windows from [git-scm.com](https://git-scm.com/download/win), or, if winget is available:

```powershell
winget install --id Git.Git -e --source winget
```

Restart the terminal so Git is on PATH. GitHub CLI is optional for reading the public branch; authenticate locally before writing/pushing. If available, `winget install --id GitHub.cli -e --source winget`, then `gh auth login` and `gh auth setup-git` configure HTTPS access. Never paste a token into a commit or remote URL.

## Clone pc separately; keep laptop dotfiles intact

On Linux/laptop:

```sh
git clone --branch pc --single-branch https://github.com/fh1m/.dotfiles.git ~/.dotfiles-pc
cd ~/.dotfiles-pc/pc
codex "$(cat NEXT-AGENT.md)"
```

On Windows PowerShell:

```powershell
git clone --branch pc --single-branch https://github.com/fh1m/.dotfiles.git "$env:USERPROFILE\dotfiles-pc"
Set-Location "$env:USERPROFILE\dotfiles-pc\pc"
codex (Get-Content .\NEXT-AGENT.md -Raw)
```

These are first-clone commands; if the directory exists, inspect it and fetch/pull instead of cloning over it. Say whether Codex is running on the **laptop**, **desktop Windows**, or **desktop CachyOS**. The laptop agent must guide/review remotely, never repartition its local laptop disks according to the desktop plan.

Starting from `pc/` lets Codex load [AGENTS.md](AGENTS.md). Explicitly ask it to read the handoff and verify the actual machine before changes. Existing local chats can be reopened with `codex resume`; that alone does not transfer a chat between OSes. This branch is the reliable continuation mechanism. [AGENTS.md behavior](https://learn.chatgpt.com/docs/agent-configuration/agents-md), [CLI session continuation](https://learn.chatgpt.com/docs/codex/cli)

## Share progress through Git

Use one writer at a time. Before work, inspect `git status`, then fetch and pull `--ff-only` on a clean worktree. After a checkpoint, update STATE.md with observed results, commit only the intended pc/ files, and push origin pc. Another device should pull those changes before continuing. Do not force-push to resolve a race; inspect the remote change and integrate deliberately. Do not commit unreviewed local diagnostic output automatically.

The source repository includes laptop-specific configs. Cloning it does not apply them. Do not run its root installation script on the desktop until a desktop-specific profile has been reviewed.
