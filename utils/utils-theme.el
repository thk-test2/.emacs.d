;;; theme.el -- theme related

;; Written by Yunsik Jang <doomsday@kldp.org>
;; You can use/modify/redistribute this freely.

(defvar my:use-theme t
  "Enable theme if it is not nil.")
(defvar my:can-theme nil
  "Auto configured variable. Check environment and make decision to use theme or not.")

(when (or (string-match "256color" (concat "" (getenv "TERM")))
          (display-graphic-p)
          (daemonp))
    (setq my:can-theme my:use-theme))

(defconst my:theme-function 'color-theme-tomorrow-night-eighties)

(if my:can-theme
    (let ((envtheme (getenv "EMACS_THEME")))
      (if (and (stringp envtheme) ; if emacs theme is set, apply that theme to all frames
               (string-match "\\`color-theme-" envtheme)
               (functionp (intern envtheme)))
          (funcall (intern envtheme))
        (when (functionp my:theme-function)
          (funcall my:theme-function)
          (set-face-attribute 'mode-line nil :background "olive drab" :foreground "white")
          (set-face-attribute 'mode-line-buffer-id nil :foreground "gold"))))
  (color-theme-standard))

;; (when (fboundp 'powerline-default-theme)
;;   (powerline-default-theme))

;; my custom mode-line (inspired from emacs-fu)
(defface my:mode-line-readonly-buffer-id
  '((t :inherit mode-line-buffer-id :background "red"))
  "Used for highlight readonly buffer")

(setq-default
 mode-line-format
 (list
  " %I "
  ;; modified
  '(:eval (propertize (if (buffer-modified-p) "* " "  ")
                      'face 'compilation-mode-line-fail))
  ;; relative position, size of file

  ;; buffer name
  '(:eval (propertize " %20b "
                      'face (if buffer-read-only 'my:mode-line-readonly-buffer-id 'mode-line-buffer-id)
                      'help-echo (buffer-file-name)))

  " "
  ;; line/column
  (propertize "%02l" 'face 'font-lock-type-face)
  ":"
  (propertize "%02c" 'face 'font-lock-type-face)

  " "
  (propertize "%m"
              'face 'bold
              'help-echo
              (mapconcat
               (lambda (minor-mode)
                 (let* ((minor (car minor-mode))
                        (lighterexp (cadr minor-mode))
                        (lighter (cond ((and (symbolp lighterexp)
                                             (boundp lighterexp))
                                        (symbol-value lighterexp))
                                       ((stringp lighterexp) lighterexp)
                                       (t (format "%s" lighterexp))))
                        (active (ignore-errors
                                  (and (symbolp minor)
                                       (symbol-value minor)
                                       minor))))
                   (when active
                     (if (and (listp lighter) (plist-get lighter :eval))
                         (eval (plist-get lighter :eval))
                       lighter))))
               minor-mode-alist
               ""))

  '("" mode-line-process)

  " "
  '(:eval (list (nyan-create)))

  ))

(when (display-graphic-p)
  (setq-default nyan-wavy-trail t)
  ;; (setq-default nyan-bar-length 10)
  (nyan-mode 1)
  (nyan-start-animation))

(provide 'utils-theme)
