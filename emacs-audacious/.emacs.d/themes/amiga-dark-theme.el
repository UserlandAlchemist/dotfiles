;; amiga-dark-theme.el --- Foot-matched dark theme -*- lexical-binding: t; -*-
(deftheme amiga-dark "Amiga-inspired dark theme to match foot.ini")

;; Palette from foot.ini  :contentReference[oaicite:3]{index=3}
(let* ((bg        "#303030")
       (bg-alt    "#262626")
       (fg        "#E6E6E6")
       (fg-strong "#FFFFFF")
       (shadow    "#606060")
       (blue      "#5078FF")
       (teal      "#40C8FF")
       (yellow    "#FFDC40")
       (orange    "#FFA040")
       (gray      "#E6E6E6"))

  (custom-theme-set-faces
   'amiga-dark
   ;; Basics
   `(default                       ((t (:background ,bg :foreground ,fg))))
   `(fringe                        ((t (:background ,bg))))
   `(region                        ((t (:background ,blue :foreground ,fg-strong))))
   `(highlight                     ((t (:background ,bg-alt))))
   `(cursor                        ((t (:background ,yellow))))
   `(shadow                        ((t (:foreground ,shadow))))
   `(link                          ((t (:foreground ,teal :underline t))))
   `(success                       ((t (:foreground ,teal :weight bold))))
   `(warning                       ((t (:foreground ,yellow :weight bold))))
   `(error                         ((t (:foreground ,orange :weight bold))))

   ;; Modeline
   `(mode-line                     ((t (:background ,bg-alt :foreground ,fg :box (:line-width -1 :color ,shadow)))))
   `(mode-line-inactive            ((t (:background ,bg :foreground ,shadow :box (:line-width -1 :color ,bg-alt)))))

   ;; Line numbers
   `(line-number                   ((t (:foreground ,shadow :background ,bg))))
   `(line-number-current-line      ((t (:foreground ,fg :background ,bg))))

   ;; Minibuffer / prompts
   `(minibuffer-prompt             ((t (:foreground ,teal :weight bold))))
   `(icomplete-first-match         ((t (:foreground ,orange :weight semi-bold))))

   ;; Syntax
   `(font-lock-builtin-face        ((t (:foreground ,blue))))
   `(font-lock-comment-face        ((t (:foreground ,shadow :slant italic))))
   `(font-lock-constant-face       ((t (:foreground ,teal))))
   `(font-lock-function-name-face  ((t (:foreground ,fg))))
   `(font-lock-keyword-face        ((t (:foreground ,blue :weight semi-bold))))
   `(font-lock-string-face         ((t (:foreground ,yellow))))
   `(font-lock-type-face           ((t (:foreground ,teal))))
   `(font-lock-variable-name-face  ((t (:foreground ,fg))))
   `(font-lock-warning-face        ((t (:foreground ,orange :weight bold))))

   ;; Dired / file-ish
   `(dired-directory               ((t (:foreground ,blue :weight bold))))
   `(dired-flagged                 ((t (:foreground ,orange))))
   `(dired-marked                  ((t (:foreground ,yellow))))
   `(dired-perm-write              ((t (:foreground ,shadow))))

   ;; Search
   `(isearch                       ((t (:background ,orange :foreground ,bg :weight bold))))
   `(lazy-highlight                ((t (:background ,shadow :foreground ,fg))))

   ;; Show-paren
   `(show-paren-match              ((t (:background ,teal :foreground ,bg :weight bold))))
   `(show-paren-mismatch           ((t (:background ,orange :foreground ,bg :weight bold))))

   ;; Tabs
   `(tab-bar                       ((t (:background ,bg :foreground ,fg))))
   `(tab-bar-tab                   ((t (:background ,bg-alt :foreground ,fg :weight bold))))
   `(tab-bar-tab-inactive          ((t (:background ,bg :foreground ,shadow))))

   ;; Widgets/misc
   `(vertical-border               ((t (:foreground ,shadow))))
   `(header-line                   ((t (:background ,bg :foreground ,fg :box (:line-width -1 :color ,shadow))))))
  )

(provide-theme 'amiga-dark)
;;; amiga-dark-theme.el ends here
