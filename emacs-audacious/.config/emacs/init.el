;; --- Minimal UI ---
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(show-paren-mode 1)
(column-number-mode 1)

(setq inhibit-startup-screen t
      make-backup-files nil
      tab-width 4
      indent-tabs-mode nil
      compilation-scroll-output t)

;; --- Relative line numbers only in useful modes ---
(setq display-line-numbers-type 'relative)

(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
    (add-hook hook (lambda () (display-line-numbers-mode 1))))

;; --- Fonts: match foot.ini ---
;; --- UI Chrome in Topaz Plus NF Mono ---
(set-face-attribute 'mode-line nil
                    :font "Topaz Plus NF Mono"
                    :height 140)

(set-face-attribute 'mode-line-inactive nil
                    :font "Topaz Plus NF Mono"
                    :height 140)

(set-face-attribute 'tab-bar nil
                    :font "Topaz Plus NF Mono"
                    :height 140)

(set-face-attribute 'header-line nil
                    :font "Topaz Plus NF Mono"
                    :height 140)

(set-face-attribute 'minibuffer-prompt nil
                    :font "Topaz Plus NF Mono"
                    :height 140)

(set-face-attribute 'tooltip nil
                    :font "Topaz Plus NF Mono"
                    :height 140)

;; --- Buffer Fonts ---
(set-face-attribute 'default nil
                    :font "JetBrains Mono NL"
                    :height 140)

(set-face-attribute 'fixed-pitch nil
                    :font "JetBrains Mono NL"
                    :height 140)

(set-face-attribute 'variable-pitch nil
                    :font "JetBrains Mono NL"
                    :height 140)

;; --- Load our custom theme ---
(add-to-list 'custom-theme-load-path
             (expand-file-name "themes" "~/.config/emacs/"))
(load-theme 'amiga-dark t)

;; --- Wayland/Sway clipboard ---
(setq select-enable-clipboard t
      select-enable-primary t)

(require 'ansi-color)
(require 'cl-lib)

;; --- ANSI colors & vterm mapped to your palette ---
;; From foot.ini regular & bright tables  :contentReference[oaicite:2]{index=2}
(let* ((amiga-colors
        ["#303030" "#FFA040" "#40C8FF" "#FFDC40" "#5078FF" "#E6E6E6" "#40C8FF" "#E6E6E6"
         "#606060" "#FFA040" "#40C8FF" "#FFDC40" "#5078FF" "#FFFFFF" "#40C8FF" "#FFFFFF"]))
  (setq ansi-color-names-vector (cl-subseq amiga-colors 0 8))
  (setq ansi-color-map (ansi-color-make-color-map))
  (with-eval-after-load 'vterm
    (setq vterm-color-palette amiga-colors)))

;; --- IDE features (Emacs built-ins) ---
;; Minimal IDE setup using only built-in Emacs 30+ features

;; File and command history
(recentf-mode 1)                  ; Track recently opened files (C-x C-r)
(savehist-mode 1)                 ; Save minibuffer history across sessions

;; Editing enhancements
(global-hl-line-mode 1)           ; Highlight current line
(electric-pair-mode 1)            ; Auto-close parentheses, brackets, quotes

;; Completion UI
(fido-vertical-mode 1)            ; Vertical minibuffer completion (built-in alternative to ido/vertico)

;; Project navigation
(setq project-switch-commands 'project-find-file)  ; C-x p p goes straight to file search

;; Code search and navigation
(setq xref-search-program 'ripgrep)  ; Use ripgrep for project-wide search (requires ripgrep package)

;; LSP integration (requires language servers installed separately)
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(rust-ts-mode . ("rust-analyzer"))))
;; Note: Eglot is built-in to Emacs 30+. Install rust-analyzer with: rustup component add rust-analyzer

;; --- Debian ELPA packages ---
;; Add Debian's packaged Emacs extensions to load-path

(let ((default-directory "/usr/share/emacs/site-lisp/elpa/"))
  (when (file-directory-p default-directory)
    (add-to-list 'load-path default-directory)
    (normal-top-level-add-subdirs-to-load-path)))

(require 'package)
(setq package-enable-at-startup t)
(package-initialize)

;; --- Treemacs file tree sidebar ---
;; Requires: elpa-treemacs package
;; Toggle with: C-c t

(when (require 'treemacs nil t)  ; Load only if installed, don't error if missing
  (setq treemacs-width 30)
  (global-set-key (kbd "C-c t") #'treemacs))

;; --- Tree-sitter for Rust ---
;; Modern syntax highlighting and code parsing for Rust
;; After first use, run: M-x treesit-install-language-grammar RET rust RET

(when (fboundp 'treesit-available-p)
  (setq treesit-language-source-alist
        '((rust "https://github.com/tree-sitter/tree-sitter-rust")))
  (add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode)))
