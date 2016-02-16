;;; utils-terminal.el

;; Written by Yunsik Jang <doomsday@kldp.org>
;; You can use/modify/redistribute this freely.

;; To make colors in term mode derive emacs' ansi color map
(eval-after-load 'term
  '(let ((term-face-vector [term-color-black
                            term-color-red
                            term-color-green
                            term-color-yellow
                            term-color-blue
                            term-color-magenta
                            term-color-cyan
                            term-color-white]))
     (require 'ansi-color)
     (dotimes (index (length term-face-vector))
       (let ((fg (cdr (aref ansi-color-map (+ index 30))))
             (bg (cdr (aref ansi-color-map (+ index 40)))))
         (set-face-attribute (aref term-face-vector index) nil
                             :foreground fg
                             :background bg)))))

;;
;; I hate to type `ansi-term' and hope typing `term' to be ansi-term.
;; I also hate to type `enter' to choose program `/bin/bash' because I will
:; not use others than `bash' with `term' command.
;;

;; make "term" to be "ansi-term"
;;;###autoload
(defadvice term (around my:term-adviced (&optional program new-buffer-name directory))
  (interactive)
  (if (eq system-type 'windows-nt) (funcall 'shell)
    (funcall 'ansi-term (or program "/bin/bash") (or new-buffer-name "term"))))
(ad-activate 'term)

;; remote terminal
;;;###autoload
(defun rterm (host user &optional directory)
  (interactive (my:term-read-rterm-args))
  (let ((buffer (make-term "rterm" "ssh" nil
                           (format "%s%s" (or (and user (concat user "@")) "") host))))
    (with-current-buffer buffer
      (term-mode)
      (term-char-mode)
      (setq my:term-need-init-remote t)
      (setq my:term-desired-init-directory directory)) ; find shell prompt and do init remote
    (switch-to-buffer buffer)))

(defun my:term-read-rterm-args ()
  "Prompt the user for where to connect."
  (require 'tramp)
  (let* ((user-input (funcall (if (and (boundp 'ido-mode) ido-mode)
                                  'ido-completing-read 'completing-read)
                              "[user@]host: "
                              (mapcar 'cadr (delete nil (tramp-parse-sconfig "~/.ssh/config")))))
         (cred (when (string-match "\\`\\(\\([a-zA-Z0-9\\.\\_\\-]+\\)@\\)?\\(.+\\)\\'" user-input)
                 (split-string (replace-match "\\3 \\2" t nil user-input))))
         (host (car cred))
         (user (cadr cred)))
    (values host user)))

(defvar my:ansi-term-list nil
  "Multiple term mode list to iterate between. Ordered by creation.")

(defvar my:term-recent-history nil
  "The terminal buffer which used recently. Ordered by recent use.")

(defvar my:term-current-directory nil
  "Current directory of terminal.")
(make-variable-buffer-local 'my:term-current-directory)


;; This is a tricky way to get directory info from remote host when a user used ssh or telnet
;; in terminal

(defvar my:term-running-child-process nil
  "The child process is being run by term process.")
(make-variable-buffer-local 'my:term-running-child-process)

(defvar my:term-need-init-remote nil)
(make-variable-buffer-local 'my:term-need-init-remote)

(defvar my:term-desired-init-directory nil)
(make-variable-buffer-local 'my:term-desired-init-directory)

(defconst my:term-remote-shell-programs '("ssh" "rsh" "telnet"))

(defun my:term-init-remote-prompt ()
  (let* ((proc (get-buffer-process (current-buffer)))
         (filter (process-filter proc)))
    (term-send-string proc "function promptcmd { echo -e \"\\033AnSiTu $USER\\n\\033AnSiTc $PWD\\n\\033AnSiTh `hostname`\"; };PROMPT_COMMAND=promptcmd\r\n")
    (my:term-update-directory)))

(defun my:term-check-running-child-process ()
  (let* ((proc (get-buffer-process (current-buffer)))
         (pid (process-id proc))
         sys-proc-list child)
    (if (process-running-child-p proc)
        (when (null my:term-running-child-process)
          (setq sys-proc-list (list-system-processes))
          (while (and (null my:term-running-child-process)
                      sys-proc-list)
            (setq child (pop sys-proc-list))
            (when (equal pid (cdr (assq 'ppid (process-attributes child))))
              (setq my:term-running-child-process (process-attributes child))
              (when (member (car (split-string (cdr (assq 'args my:term-running-child-process))))
                            my:term-remote-shell-programs)
                ;; (message "found!")
                (setq my:term-need-init-remote t)))))
      (setq my:term-running-child-process nil))))

(defvar my:term-remote-shell-checker-timer nil)
(make-variable-buffer-local 'my:term-remote-shell-checker-timer)
(defun my:term-trigger-remote-shell-checker ()
  (if my:term-remote-shell-checker-timer
      (cancel-timer my:term-remote-shell-checker-timer))
  (setq my:term-remote-shell-checker-timer
        (run-at-time "0.1 sec" nil
                     (lambda ()
                       ;; (message "checking...")
                       (my:term-check-running-child-process)
                       (setq my:term-remote-shell-checker-timer nil)))))

;; The next two adviced functions are to trigger remote shell checker
;; this is way to find remote shell it doesn't print ansi message

;; for char mode
(defadvice term-send-raw-string (after my:term-send-raw-string (chars))
  (if (member ?\r (string-to-list chars))
      (my:term-trigger-remote-shell-checker)))
(ad-activate 'term-send-raw-string)

;; for line mode
(defadvice term-simple-send (after my:term-simple-send-adviced)
  (my:term-trigger-remote-shell-checker))
(ad-activate 'term-simple-send)

(defun my:term-buffer-p (&optional buffer)
  (let ((buf (or buffer (current-buffer))))
    (with-current-buffer buf
      (and (equal major-mode 'term-mode)
           my:term-current-directory))))

;; update ansi-term-list on kill-buffer
(add-hook 'kill-buffer-hook
          (lambda ()
            (when (my:term-buffer-p)
              (with-current-buffer (current-buffer)
                (if my:term-remote-shell-checker-timer
                    (cancel-timer my:term-remote-shell-checker-timer))
                (setq my:term-current-directory nil) ; to avoid buffer-list-update-hook insert it again
                (setq my:ansi-term-list (remove (current-buffer) my:ansi-term-list))
                (setq my:term-recent-history (remove (current-buffer) my:term-recent-history))))))

(add-hook 'buffer-list-update-hook
          (lambda ()
            (let ((buffer (car (buffer-list))))
              (when (and (my:term-buffer-p buffer)
                         (buffer-live-p buffer))
                (setq my:term-recent-history (remove buffer my:term-recent-history))
                (push buffer my:term-recent-history)))))

(defun my:term-select-prev-ansi-term ()
  "Find previous ansi-term in ringed list of buffers."
  (interactive)
  (let* ((pos (1+ (cl-position (current-buffer) my:ansi-term-list))) ; list is reversed
         (buffer (nth (% pos (length my:ansi-term-list)) my:ansi-term-list)))
    (and (equal (my:term-switch-to-buffer  buffer) (current-buffer))
         (message "Switching to %S" (buffer-name buffer)))))

(defun my:term-select-next-ansi-term ()
  "Find next ansi-term in ringed list of buffers."
  (interactive)
  (let* ((pos (1- (+ (length my:ansi-term-list)
                     (cl-position (current-buffer) my:ansi-term-list)))) ; list is reversed
         (buffer (nth (% pos (length my:ansi-term-list)) my:ansi-term-list)))
    (and (equal (my:term-switch-to-buffer  buffer) (current-buffer))
         (message "Switching to %S" (buffer-name buffer)))))

(defun my:term-update-directory ()
  "Update buffer-name when directory is changed."
  (and (not (equal my:term-current-directory default-directory))
       (setq-local my:term-current-directory default-directory)
       (my:term-refresh-buffer-name)))

;; to notify current major mode or directory is switched by changing its buffer name
(defun my:term-refresh-buffer-name (&optional buffer)
  (let* ((buf (or buffer (current-buffer)))
         (bufname (buffer-name buf))
         (ident (or (when (string-match
                           "\\*\\([^:]+\\)\\(:.+\\)?\\*\\(<.+>\\)?"
                           bufname)
                      (replace-match "\\3" t nil bufname))
                    (error "Unable to get original mode!")))
         (remote-directory (if (string-match "/\\([^:]+\\):\\(.+\\)" default-directory)
                               (split-string (replace-match "\\1 \\2" t nil default-directory))))
         (seed (if remote-directory
                   (concat "*" (car remote-directory)
                           ":" (abbreviate-file-name (cadr remote-directory)) "*")
                 (concat "*" "localhost"
                         ":" (abbreviate-file-name default-directory) "*")))
         (candidate (concat seed ident)))
    (or (equal candidate bufname)
        (rename-buffer (generate-new-buffer-name seed)))))

;;
;; There's no hooks for directory update or exit in term-mode
;; So, advice is used instead
;;
;; Try to update buffer-name with current directory
(defadvice term-command-hook (after my:term-command-hook-adviced (string))
  (my:term-update-directory))
(ad-activate 'term-command-hook)

(defadvice term-handle-ansi-terminal-messages
    (after my:term-handle-ansi-terminal-messages-adviced (message))
  (require 'tramp) ; to use prompt pattern
  (let (handled)
    (unless (eq message ad-return-value)
      (setq handled t)
      (while (string-match "\032.+\n" ad-return-value) ;; ignore this only if ansi messages are handled
        (setq ad-return-value (replace-match "" t t ad-return-value)))
      (my:term-update-directory))
    ;; user connected to remote and remote doesn't configured with eterm ansi messages
    (when (and my:term-need-init-remote
               (setq my:term-need-init-remote (not handled)))
      ;; (message "need init!")
      (when (and (not handled) (string-match tramp-shell-prompt-pattern ad-return-value))
        (my:term-init-remote-prompt)
        (setq my:term-need-init-remote nil))))
    ;; need to move directory
    (when (and my:term-desired-init-directory
               (string-match tramp-shell-prompt-pattern ad-return-value))
      (and (file-remote-p default-directory)
           (not (equal my:term-desired-init-directory
                       (abbreviate-file-name
                        (tramp-file-name-localname (tramp-dissect-file-name default-directory)))))
           (term-send-raw-string (format "cd %s\n" my:term-desired-init-directory)))
      (setq my:term-desired-init-directory nil))
  ad-return-value)
(ad-activate 'term-handle-ansi-terminal-messages)

;;close terminal buffer on exit
(defadvice term-handle-exit (after my:term-handle-exit-adviced)
  (kill-buffer (current-buffer)))
(ad-activate 'term-handle-exit)

;; install hook for term-mode
(add-hook 'term-mode-hook
          (lambda ()
            (and (boundp 'yas-minor-mode) ; yas-expand is bound on tab!!!!
                 (setq-local yas-dont-activate t)
                 (yas-minor-mode -1))
            (my:term-update-directory)
            (add-to-list 'my:ansi-term-list (current-buffer))
            (define-key term-raw-map (kbd "M-<left>") 'my:term-select-prev-ansi-term)
            (define-key term-raw-map (kbd "M-<right>") 'my:term-select-next-ansi-term)
            (define-key term-raw-map (kbd "C-c ?") 'my:term-list-popup)))


;; For hot-key functions
(defun my:term-switch-to-buffer (buffer-or-name)
  (let (term-win)
    (dolist (win (window-list))
      (with-current-buffer (window-buffer win)
        (and (eq (get-buffer buffer-or-name) (current-buffer))
             (setq term-win win))))
    (if term-win (select-window term-win)
      (switch-to-buffer buffer-or-name))))

(defun my:term-get-create ()
  "Get terminal for current directory or create if there's no such terminal buffer."
  (interactive)
  (with-current-buffer (current-buffer)
    (let* ((vec (and (file-remote-p default-directory)
                     (tramp-dissect-file-name default-directory)))
           (host (tramp-file-name-host vec))
           (user (tramp-file-name-user vec))
           (dir (abbreviate-file-name (or (tramp-file-name-localname vec)
                                          default-directory)))
           found)
      (dolist (buf my:ansi-term-list)
        (with-current-buffer buf
          (let ((bvec (and (file-remote-p default-directory)
                           (tramp-dissect-file-name default-directory))))
            (and (equal host (tramp-file-name-host bvec))
                 (equal user (tramp-file-name-user bvec))
                 (equal dir (abbreviate-file-name (or (tramp-file-name-localname bvec)
                                                      default-directory)))
                 (setq found buf)))))
      (or (and found (my:term-switch-to-buffer found))
          (if host (rterm host user dir) (term))))))

(defun my:term-get-recent ()
  "Pick last used terminal."
  (interactive)
  (if my:term-recent-history (my:term-switch-to-buffer (car my:term-recent-history))
      (my:term-get-create)))

;;
;; term-list-mode: a major mode for terminal listing popup
;;
(defvar my:term-list-parent-window nil
  "A reference to the window which called this popup.")
(make-variable-buffer-local 'my:term-list-parent-window)

(defvar my:term-list-parent-window-buffer nil
  "The buffer, the window, which called this popup, originally was displaying.")
(make-variable-buffer-local 'my:term-list-parent-window-buffer)

(defvar my:term-list-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "n") 'my:term-list-next)
    (define-key map (kbd "p") 'my:term-list-prev)
    (define-key map (kbd "RET") 'my:term-list-select)
    (define-key map (kbd "SPC") 'my:term-list-show)
    (define-key map (kbd "q") 'my:term-list-quit)
    (define-key map (kbd "C-g") 'my:term-list-quit)
    map)
  "Terminal list popup keybinding.")

(define-derived-mode my:term-list-mode fundamental-mode ""
  (use-local-map my:term-list-keymap)
  (set (make-local-variable 'buffer-read-only) t))

(defun my:term-list-next ()
  (interactive)
  (forward-line)
  (my:term-list-show))

(defun my:term-list-prev ()
  (interactive)
  (forward-line -1)
  (my:term-list-show))

(defun my:term-list-select ()
  (interactive)
  (let ((popup-window (selected-window))
        buffer-name)
    (with-current-buffer (window-buffer popup-window)
      (setq buffer-name (get-text-property (point) 'buffer-name)))
    (my:term-list-quit (get-buffer buffer-name))))

(defun my:term-list-show ()
  (interactive)
  (let ((popup-window (selected-window))
        (parent-window my:term-list-parent-window)
        buffer-name)
    (with-current-buffer (window-buffer popup-window)
      (setq buffer-name (get-text-property (point) 'buffer-name)))
    (when (and parent-window buffer-name)
      (select-window parent-window)
      (switch-to-buffer buffer-name)
      (select-window popup-window))))

(defun my:term-list-quit (&optional buffer)
  (interactive)
  (when (equal major-mode 'my:term-list-mode)
    (let (restore popup)
      (with-current-buffer (current-buffer)
        (setq popup (current-buffer))
        (setq restore (or buffer
                          (and (buffer-live-p my:term-list-parent-window-buffer)
                               my:term-list-parent-window-buffer))))
      (delete-window (selected-window))
      (and my:term-list-parent-window
           (select-window my:term-list-parent-window))
      (switch-to-buffer restore)
      (kill-buffer popup)
      (setq-local my:term-list-parent-window nil)
      (setq-local my:term-list-parent-window-buffer nil))))

(defun my:term-list-popup ()
  (interactive)
  (let ((parent-window (selected-window))
        (popup-buffer (get-buffer-create "*Terminal List*"))
        (inhibit-read-only t))
    (with-current-buffer popup-buffer
      (delete-region (point-min)(point-max))
      (goto-char (point-min))
      (dolist (term-buf my:term-recent-history)
        (insert (propertize (buffer-name term-buf)
                            'buffer-name (buffer-name term-buf))"\n"))
      (my:term-list-mode)
      (setq-local my:term-list-parent-window parent-window)
      (setq-local my:term-list-parent-window-buffer (window-buffer parent-window))
      (goto-char (point-min)))
    (select-window (display-buffer popup-buffer '(display-buffer-below-selected)))
    (fit-window-to-buffer (selected-window) 15 5)))

(provide 'utils-terminal)
