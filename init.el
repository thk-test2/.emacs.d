;; init.el

;; Written by Yunsik Jang <doomsday@kldp.org>
;; You can use/modify/redistribute this freely.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; package initializations

;; global (internal) minor modes
(require 'ido) (ido-mode t) ; ido
(column-number-mode)
(show-paren-mode)
(global-hl-line-mode t) ; highlight current line
(tool-bar-mode -1)
(unless (display-graphic-p) (menu-bar-mode -1))


;; el-get initialization
(add-to-list 'load-path "~/.emacs.d/el-get/el-get")
(unless (require 'el-get nil 'noerror)
  (with-current-buffer
      (url-retrieve-synchronously
       "https://raw.githubusercontent.com/dimitri/el-get/master/el-get-install.el")
    (goto-char (point-max))
    (eval-print-last-sexp)))
(add-to-list 'el-get-recipe-path "~/.emacs.d/recipes")
(el-get 'sync)

(el-get-bundle  ascope)
(el-get-bundle  ascope-ext)
(el-get-bundle  auto-complete)
(el-get-bundle  auto-complete-emacs-lisp)
(el-get-bundle! auto-complete-c-headers)
(if (executable-find "qmake")           ; qt headers
    (add-to-list 'achead:include-directories
                 (substring (shell-command-to-string "qmake -query QT_INSTALL_HEADERS") 0 -1)))

(el-get-bundle  franca-idl)
(el-get-bundle  google-c-style)
(el-get-bundle  iedit)
(el-get-bundle  iman)
(el-get-bundle  json)
(el-get-bundle  json-mode)
(el-get-bundle! linum+)
(el-get-bundle  magit) (setq magit-last-seen-setup-instructions "1.4.0")
                       (setq magit-auto-revert-mode nil)
(el-get-bundle  magit-gerrit)
(el-get-bundle  magit-gh-pulls)
(el-get-bundle  markdown-mode)
(el-get-bundle! markdown-preview-mode)
(el-get-bundle  multiple-cursors)
(unless (functionp 'org-mode) (el-get-bundle org-mode)) ; can be installed with linux-dist-package
(el-get-bundle  org-publish)
(el-get-bundle  org-readme)
(el-get-bundle  plantuml-mode)
(el-get-bundle  qmake-mode)
(el-get-bundle  qml-mode)
(el-get-bundle! redo+)
(el-get-bundle  windcycle)
(el-get-bundle  yasnippet) (yas-global-mode t)
(el-get-bundle  color-theme) (color-theme-initialize)
(el-get-bundle  color-theme-tomorrow) (if (or (string-match "256color" (concat "" (getenv "TERM")))
					      (display-graphic-p))
					  (if (and (stringp (getenv "EMACS_THEME"))
						   (string-match "\\`color-theme-" (getenv "EMACS_THEME"))
						   (functionp (intern (getenv "EMACS_THEME"))))
					      (funcall (intern (getenv "EMACS_THEME")))
					    (color-theme-tomorrow-night-eighties)))
(when (>= emacs-major-version 24) ;; >= 24
    (el-get-bundle  smex)
)

;; load files in utils/
(add-to-list 'load-path "~/.emacs.d/utils")
(if (file-exists-p "~/.emacs.d/utils")
  (dolist (filename (directory-files "~/.emacs.d/utils"))
    (when (string-match "\\([^.]+\\).el\\'" filename)
      (load-library (match-string 1 filename)))))


;; temporary
(when (file-exists-p "~/.emacs.d/slack/")
  (add-to-list 'load-path "~/.emacs.d/slack/")
  (if (file-exists-p "~/.emacs.d/slack/slack.el") (require 'slack)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; basic options
(setq-default
  c-default-style '((java-mode . "java") (awk-mode . "awk") (python-mode . "python")
                    (other . "linux"))
  c-basic-offset 4
  tab-width 4 ; tab width 4
  indent-tabs-mode nil ; don't insert tabs in indent
  tab-stop-list '(4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80)
  tab-always-indent nil
)

(setq
  truncate-partial-width-windows nil ; do not wrap
  visible-bell t ; ring a visible bell
  make-backup-files nil ; no backup files
  inhibit-startup-screen t ; no startup screen
  inhibit-startup-message t ; no startup message
)

(unless (server-running-p) (server-start)) ; start server
(ignore-errors
  (set-default-font "Lucida Console-10") ; set font
  (error nil))

;; from http://emacswiki.org/emacs/DeletingWhitespace
(defadvice kill-line (after kill-line-cleanup-whitespace activate compile)
  "cleanup whitespace on kill-line"
  (if (not (bolp))
      (delete-region (point) (progn (skip-chars-forward " \t") (point)))))

;; global keybindings
(defvar my:keys-mode-keymap
  (let ((map (make-sparse-keymap)))
    ;; windmove
    (define-key map (kbd "S-<left>")  'windmove-left)
    (define-key map (kbd "S-<right>") 'windmove-right)
    (define-key map (kbd "<select>")  'windmove-up) ; sometime, shift-up is sent as <select> to remote
    (define-key map (kbd "S-<up>")    'windmove-up)
    (define-key map (kbd "S-<down>")  'windmove-down)

    ;; windcycle
    (define-key map (kbd "M-<up>")    'buffer-up-swap) ; Switch window keybindings
    (define-key map (kbd "M-<down>")  'buffer-down-swap)
    (define-key map (kbd "M-<right>") 'buffer-right-swap)
    (define-key map (kbd "M-<left>")  'buffer-left-swap)

    (define-key map (kbd "M-S-<left>")  'shrink-window-horizontally) ; Window Resizing keybindings
    (define-key map (kbd "M-S-<right>") 'enlarge-window-horizontally)
    (define-key map (kbd "M-S-<down>")  'shrink-window)
    (define-key map (kbd "M-S-<up>")    'enlarge-window)

    (define-key map (kbd "C-x -")     'split-window-vertically) ; Window Split keybindings
    (define-key map (kbd "C-x |")     'split-window-horizontally)

    (define-key map (kbd "C-x x")     'delete-window) ; Window Close keybindings

    ;; frame
    (define-key map (kbd "C-<left>")  (lambda (p) (interactive "p")(select-frame (next-frame))))
    (define-key map (kbd "C-<right>") (lambda (p) (interactive "p")(select-frame (previous-frame))))
    (define-key map (kbd "C-x +")     (lambda (p) (interactive "p")
					(if (yes-or-no-p "Create a new frame? ")
					    (select-frame (make-frame)))))
    (define-key map (kbd "C-x _")     (lambda (p) (interactive "p")
					(if (yes-or-no-p "Delete current frame? ")
					    (delete-frame(selected-frame)))))
    ;; undo+
    (define-key map (kbd "C-_") 'undo)
    (define-key map (kbd "M-_") 'redo)

    ;; iedit
    (define-key map (kbd "M-#") 'iedit-mode)

    ;; multiple-cursors
    (define-key map (kbd "C-/") 'mc/edit-lines)
    (define-key map (kbd "C-.") 'mc/mark-next-like-this)
    (define-key map (kbd "C-,") 'mc/mark-previous-like-this)
    (define-key map (kbd "M-/") 'mc/mark-all-like-this)

    ;; vi-like line insertion
    (define-key map (kbd "C-o") (lambda (p) (interactive "p")(beginning-of-line)(open-line 1)))
    (define-key map (kbd "M-o") (lambda (p) (interactive "p")(end-of-line)(newline)))

    ;; smex
    (when (boundp 'smex)
      (define-key map (kbd "M-x") 'smex)
      (define-key map (kbd "M-X") 'smex-major-mode-commands))
    map)
  "global key mode keymap")

(define-minor-mode my:keys-mode
"My global key map to prevent annoying overriding of major modes

Key bindings:
\\{my:keys-mode-keymap}"
  t nil my:keys-mode-keymap)
(my:keys-mode t)

(defadvice load (after my:keybindings-priority)
  "Try to ensure that my keybindings always have priority."
  (if (not (eq (car (car minor-mode-map-alist)) 'my:keys-mode))
      (let ((mykeys (assq 'my:keys-mode minor-mode-map-alist)))
        (assq-delete-all 'my:keys-mode minor-mode-map-alist)
        (add-to-list 'minor-mode-map-alist mykeys))))
(ad-activate 'load)

;; ignore mouse
(dolist (k '([mouse-1] [down-mouse-1] [drag-mouse-1] [double-mouse-1] [triple-mouse-1]
             [mouse-2] [down-mouse-2] [drag-mouse-2] [double-mouse-2] [triple-mouse-2]
             [mouse-3] [down-mouse-3] [drag-mouse-3] [double-mouse-3] [triple-mouse-3]
             [mouse-4] [down-mouse-4] [drag-mouse-4] [double-mouse-4] [triple-mouse-4]
             [mouse-5] [down-mouse-5] [drag-mouse-5] [double-mouse-5] [triple-mouse-5]
             [mouse-6] [down-mouse-6] [drag-mouse-6] [double-mouse-6] [triple-mouse-6]
             [mouse-7] [down-mouse-7] [drag-mouse-7] [double-mouse-7] [triple-mouse-7]
             [mouse-8] [down-mouse-8] [drag-mouse-8] [double-mouse-8] [triple-mouse-8]
             [mouse-9] [down-mouse-9] [drag-mouse-9] [double-mouse-9] [triple-mouse-9]))
  (global-set-key k 'ignore))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; modes initialization

;; el-doc
(add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
(add-hook 'lisp-interaction-mode-hook 'turn-on-eldoc-mode)
(add-hook 'ielm-mode-hook 'turn-on-eldoc-mode)

;; simple minor modes
(define-minor-mode my:trailing-whitespace-mode
"Shows trailing whitespaces."
  nil nil nil
 (setq show-trailing-whitespace t))


;; Minor modes to apply
(setq prog-minor-mode-list '(linum-mode my:trailing-whitespace-mode))
(setq text-minor-mode-list '(linum-mode my:trailing-whitespace-mode))

;; enable minor modes for prog-mode(there's a case of that prog-mode is nil)
(let (value)
  (dolist (mode prog-minor-mode-list value)
    (if (fboundp 'prog-mode) (add-hook 'prog-mode-hook mode)
      (if (fboundp 'cc-mode)
          (add-hook 'cc-mode-hook mode)
        (add-hook 'c-mode-hook mode)
        (add-hook 'c++-mode-hook mode)
        (add-hook 'objc-mode-hook mode)
        (add-hook 'java-mode-hook mode)
        (add-hook 'idl-mode-hook mode))
      (add-hook 'emacs-lisp-mode-hook mode)
      (add-hook 'python-mode-hook mode)
      (add-hook 'ruby-mode-hook mode)
      (add-hook 'perl-mode-hook mode)
      (add-hook 'js-mode-hook mode)
      (add-hook 'sh-mode-hook mode))
    (add-hook 'qmake-mode-hook mode) ; not in prog-mode
))

;; enable minor modes for text-mode
(let (value)
  (dolist (mode text-minor-mode-list value)
    (if (functionp 'text-mode) (add-hook 'text-mode-hook mode)
      (add-hook 'org-mode-hook mode)
      (add-hook 'markdown-mode-hook mode)
)))

;; file assosiations
(add-to-list 'auto-mode-alist '("\\.uml\\'" . plantuml-mode))
(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode)) ; C++, rather than C

;; enable redspace for editors
;;(add-hook 'prog-mode-hook 'redspace-mode)
;;(add-hook 'text-mode-hook 'redspace-mode)
;;(define-globalized-minor-mode global-redspace-mode redspace-mode redspace-mode)
;;(global-redspace-mode t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; customized options
