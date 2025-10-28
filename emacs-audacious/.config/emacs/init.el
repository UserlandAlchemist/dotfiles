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
(add-to-list 'custom-theme-load-path (expand-file-name "themes" user-emacs-directory))
(load-theme 'amiga-dark t)

;; --- Wayland/Sway clipboard ---
(setq select-enable-clipboard t
      select-enable-primary t)

(require 'ansi-color)
;; --- ANSI colors & vterm mapped to your palette ---
;; From foot.ini regular & bright tables  :contentReference[oaicite:2]{index=2}
(let* ((amiga-colors
        ["#303030" "#FFA040" "#40C8FF" "#FFDC40" "#5078FF" "#E6E6E6" "#40C8FF" "#E6E6E6"
         "#606060" "#FFA040" "#40C8FF" "#FFDC40" "#5078FF" "#FFFFFF" "#40C8FF" "#FFFFFF"]))
  (setq ansi-color-names-vector (cl-subseq amiga-colors 0 8))
  (setq ansi-color-map (ansi-color-make-color-map))
  (with-eval-after-load 'vterm
    (setq vterm-color-palette amiga-colors)))
