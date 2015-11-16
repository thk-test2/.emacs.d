;;; utils-google-translate.el

;; Written by Yunsik Jang <doomsday@kldp.org>
;; You can use/modify/redistribute this freely.

(eval-after-load 'google-translate-default-ui
  '(progn
     (setq google-translate-default-source-language "auto"
           google-translate-default-target-language "ko")))
(eval-after-load 'google-translate-smooth-ui
  '(progn
     (setq google-translate-translation-directions-alist
           '(("en" . "ko") ("ko" . "en") ("de" . "ko") ("ko" . "de") ("ko" . "ja")))))
(global-set-key (kbd "M-+") 'google-translate-at-point)
(global-set-key (kbd "C-+") 'google-translate-smooth-translate)
