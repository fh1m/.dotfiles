# Neovim research ledger

33 targeted searches, then direct source inspection. Popularity was discovery;
maintainer documentation and local tests decide what ships.

| Evidence | Decision |
| --- | --- |
| [Current Kickstart](https://github.com/nvim-lua/kickstart.nvim) now uses native `vim.pack` | Borrow its readable configuration and education; retain lazy.nvim for feature triggers and profiling |
| [TJ's configuration](https://github.com/tjdevries/config.nvim) says it is personal | Borrow working-file navigation and discoverability; do not transplant his configuration |
| [Primeagen's source](https://github.com/ThePrimeagen/init.lua) | Persistent undo, quick navigation and manual Git review; preserve our desktop/tmux keys |
| [geohot's actual vimrc](https://github.com/geohot/configuration/blob/master/.vimrc) is small | Simplicity is a useful check on feature accumulation, not a reason to omit required tools |
| [lazy.nvim profiler](https://lazy.folke.io/usage/profiling) | Measure our laptop; do not borrow its author's 11 ms example as our performance result |
| [Blink stable docs](https://cmp.saghen.dev/configuration/completion) | Stable 1.10.2; deliberate selection, no speculative insertion; Enter stays newline |
| [fzf-lua](https://github.com/ibhagwan/fzf-lua) and its performance options | One picker; scoped rg/fd, external bat previews, bounded search roots |
| [Oil](https://github.com/stevearc/oil.nvim) discourages lazy loading | Load correctly and disable continuous filesystem watching |
| [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter) main has different APIs | Pin the compatible implementation; provision parsers explicitly; validate all parser files |
| [Neovim large-file tracking](https://github.com/neovim/neovim/issues/22426) | Disable expensive parsing, completion and LSP for oversized files; no blanket workspace scan |
| [clangd indexing](https://clangd.llvm.org/design/indexing) | Cached real indexes, two workers, separate first-index and warm-editing measurements |
| [Ruff editor integration](https://docs.astral.sh/ruff/editors/setup/) | Ruff owns lint/import actions; basedpyright owns types/navigation/hover |
| [Conform maintainer discussion](https://github.com/stevearc/conform.nvim/issues/401) | Slow formatter work is not allowed to block saves indefinitely; explicit async formatting available |
| [DAP](https://github.com/mfussenegger/nvim-dap) and [Python adapter](https://github.com/mfussenegger/nvim-dap-python) | Adapter environment is separate; debugged program uses the selected project interpreter |
| [Overseer](https://github.com/stevearc/overseer.nvim) | Explicit cancellable tasks, existing npm/CMake tasks, output and quickfix results |
| [Neotest Python](https://github.com/nvim-neotest/neotest-python) | On-demand discovery and execution; no startup pytest crawl |
| [Diffview](https://github.com/sindrets/diffview.nvim), [Fugitive](https://github.com/tpope/vim-fugitive), [Octo](https://github.com/pwntester/octo.nvim) | Separate roles: hunks, repository operations, historical/conflict review, GitHub collaboration |
| [Distrobox entry](https://distrobox.it/usage/distrobox-enter/) | Launch through the supported user/home environment, never raw docker exec for daily work |
| [Xournal++](https://xournalpp.github.io/guide/whirlwind-tour/) | Offline drawing/PDF annotation on demand, linked to project notes |
| [Fahim's portfolio](https://fh1m.github.io/) | Learning prompts about control timing, units/frames, numerical stability, firmware ownership and evidence |

## Search inventory

1. Neovim plugin startup / lazy.nvim profiling
2. Blink completion benchmarks and stable behavior
3. nvim-cmp large-buffer performance issues
4. fzf-lua versus Telescope performance evidence
5. Treesitter main large-file behavior
6. Neovim LSP large-Python-workspace diagnostics
7. clangd threads, background index and memory
8. basedpyright open-files diagnostic mode
9. Ruff/Pyright duplicate capabilities
10. Neotest Python discovery costs
11. debugpy virtualenv/interpreter separation
12. codelldb stdio adapter compatibility
13. TJ's actual navigation/completion configuration
14. Primeagen's undo and testing configuration
15. geohot's actual vimrc
16. Folke's Snacks and Flash architecture
17. AstroNvim loading/performance patterns
18. LazyVim Python/Ruff integration
19. Kickstart's current educational configuration
20. Oil's loading and confirmation requirements
21. which-key delay and rendering changes
22. mini textobjects/surround alternatives
23. Fugitive and Git worktrees
24. Diffview conflict/history workflows
25. grug-far replacement preview and recovery
26. mini module architecture
27. Aerial LSP/Treesitter outlines
28. Octo review support with fzf-lua
29. Conform timeout and asynchronous behavior
30. Neovim external edits, checktime and modified buffers
31. Distrobox editor export and environment handling
32. ROS/colcon CMake compilation databases
33. OSC52/Wayland clipboard through tmux

Issue reports establish failure cases to test, not proof that every current version
has those failures. No claims of "fastest" or "complete" are based on star counts.
