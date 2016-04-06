;;; utils-readonly.el

;; Written by Yunsik Jang <doomsday@kldp.org>
;; You can use/modify/redistribute this freely

(defconst my:read-only-keybind-alist '(
  ("p" . previous-line)
  ("n" . next-line)
  ("f" . forward-char)
  ("b" . backward-char)
  ("a" . beginning-of-line)
  ("e" . end-of-line)

  ;; vi-like
  ("h" . (lambda ()
           (interactive)
           (if (bolp) (error "Beginning of line")
             (backward-char))))
  ("l" . (lambda ()
           (interactive)
           (if (eolp) (error "End of line")
             (forward-char))))
  ("j" . next-line)
  ("k" . previous-line)

  ;; page scroll
  ("SPC" . my:scroll-up-command)
  ("u" . my:scroll-down-command)

  ) "key binding for read-only buffer")

(defconst my:read-only-overridable-commands '(
  self-insert-command
  org-self-insert-command
  ) "Commands which can be overridden by my:read-only-mode.")

(defconst my:read-only-mode-blacklist '(
  magit-popup-mode
  magit-mode
  ) "The blacklist which can not be run well with my:read-only-mode.")

(defvar my:read-only-overridden-keys nil)
(make-variable-buffer-local 'my:read-only-overridden-keys)

(defun my:read-only-overridable (key)
  "Check if there is any key binding to other than overridable commands."
  (let ((command (or (lookup-key (current-local-map) key)
                      (lookup-key (current-global-map) key))))
    (or (null command) (member command my:read-only-overridable-commands))))

(define-minor-mode my:read-only-mode
  "Control-key-less keybind for read-only buffer."
  :lighter " RO"
  :variable buffer-read-only
  (let ((overwritten-keys my:read-only-overridden-keys))
    (if buffer-read-only
        (progn (dolist (keybind my:read-only-keybind-alist)
                 (when (my:read-only-overridable (kbd (car keybind)))
                   (add-to-list 'overwritten-keys (car keybind))
                   (local-set-key (kbd (car keybind)) (cdr keybind))))
               (setq my:read-only-overridden-keys overwritten-keys))
      (dolist (key overwritten-keys)
        (local-unset-key (kbd key)))
      (setq my:read-only-overridden-keys nil)))
  (read-only-mode (if buffer-read-only 1 -1)))

;; add my:read-only-mode when the buffer-read-only is set
(add-hook 'buffer-list-update-hook
          (lambda ()
            (with-current-buffer (current-buffer)
              (when (and buffer-read-only
                         (not (member major-mode my:read-only-mode-blacklist))
                         (not (member 'my:read-only-mode minor-mode-list)))
                (my:read-only-mode 1)))))

(provide 'utils-readonly)
