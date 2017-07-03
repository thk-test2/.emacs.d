;;; utils-indentation.el

;; Written by Yunsik Jang <doomsday@kldp.org>
;; You can use/modify/redistribute this freely.

(require 'utils-macros)

(defun my:c-lineup-first-column (langelem)
  "Indent to the first column."
  (let ((pos (cdr arg)))
    (- (save-excursion
         (goto-char pos)
         (line-beginning-position))
       pos)))

(c-add-style "default"
             `((c-basic-offset . 2)
               (indent-tabs-mode . nil)
               (c-hanging-braces-alist
                (defun-open before)
                (defun-close before after)
                (class-open before)
                (close-close before after)
                (inexpr-class-open after)
                (inexpr-class-close before)
                (inline-open after)
                (inline-close before after)
                (block-open after)
                (block-close . c-snug-do-while)
                (extern-lang-open after)
                (extern-lang-close after)
                (statement-case-open after)
                (substatement-open after)
                )
               (c-hanging-colons-alist
                (case-label)
                (label after)
                (access-label after)
                (member-init-intro before)
                (inher-intro)
                )
               (c-offsets-alist
                (topmost-intro . 0)
                (topmost-intro-cont . c-lineup-topmost-intro-cont)
                (defun-open . 0)
                (defun-close . 0)
                (defun-block-intro . +)
                (class-open . 0)
                (class-close . 0)
                (inher-intro . ++)
                (inher-cont . 0)
                (access-label . /)
                (inline-open . 0)
                (inline-close . 0)
                (namespace-open . 0)
                (namespace-close . 0)
                (innamespace . 0)
                (extern-lang-open . 0)
                (extern-lang-close . 0)
                (inextern-lang . 0)
                (func-decl-cont . ++)
                (arglist-intro . ++)
                (arglist-cont-nonempty . 0)
                (label . my:c-lineup-first-column)
                (case-label . +)
                (member-init-intro . ++)
                (statement-case-intro . +)
                (statement-case-open . 0)
                (substatement-open . 0)
                (statement-block-intro . +)
                (statement-cont
                 .
                 (,(when (fboundp 'c-no-indent-after-java-annotations)
                     'c-no-indent-after-java-annotations)
                  ,(when (fboundp 'c-lineup-assignments)
                     'c-lineup-assignments)
                  ++))
                ))
             "My default C/C++ style.")

(c-add-style "webkit"
             `("default"
               (c-basic-offset . 4)
               (indent-tabs-mode . nil)
               (c-offsets-alist
                (access-label . -)
                (case-label . 0)
                (member-init-intro . +))))

(c-add-style "kernel"
             `("linux"
               (c-basic-offset . 4)
               (indent-tab-mode . t)))
(setq-default
 c-default-style '((java-mode . "java") (awk-mode . "awk") (python-mode . "python")
                   (other . "default"))
 c-basic-offset 4
 tab-width 8 ; tab width
 indent-tabs-mode nil ; don't insert tabs in indent
 tab-always-indent nil)

(provide 'utils-indentation)
