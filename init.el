;; init.el --- Prelude's configuration entry point.
;;
;; Copyright (c) 2011-2017 Bozhidar Batsov
;;
;; Author: Bozhidar Batsov <bozhidar@batsov.com>
;; URL: http://batsov.com/prelude
;; Version: 1.0.0
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This file simply sets up the default load path and requires
;; the various modules defined within Emacs Prelude.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
                                        ;(package-initialize)

(defvar current-user
  (getenv
   (if (equal system-type 'windows-nt) "USERNAME" "USER")))

(message "Prelude is powering up... Be patient, Master %s!" current-user)

(when (version< emacs-version "24.4")
  (error "Prelude requires at least GNU Emacs 24.4, but you're running %s" emacs-version))

;; Always load newest byte code
(setq load-prefer-newer t)

(defvar prelude-dir (file-name-directory load-file-name)
  "The root dir of the Emacs Prelude distribution.")
(defvar prelude-core-dir (expand-file-name "core" prelude-dir)
  "The home of Prelude's core functionality.")
(defvar prelude-modules-dir (expand-file-name  "modules" prelude-dir)
  "This directory houses all of the built-in Prelude modules.")
(defvar prelude-personal-dir (expand-file-name "personal" prelude-dir)
  "This directory is for your personal configuration.



;; Bootstrap `use-package`


;;Users of Emacs Prelude are encouraged to keep their personal configuration

changes in this directory.  All Emacs Lisp files there are loaded automatically
by Prelude.")
(defvar prelude-personal-preload-dir (expand-file-name "preload" prelude-personal-dir)
  "This directory is for your personal configuration, that you want loaded before Prelude.")
(defvar prelude-vendor-dir (expand-file-name "vendor" prelude-dir)
  "This directory houses packages that are not yet available in ELPA (or MELPA).")
(defvar prelude-savefile-dir (expand-file-name "savefile" prelude-dir)
  "This folder stores all the automatically generated save/history-files.")
(defvar prelude-modules-file (expand-file-name "prelude-modules.el" prelude-dir)
  "This files contains a list of modules that will be loaded by Prelude.")

(unless (file-exists-p prelude-savefile-dir)
  (make-directory prelude-savefile-dir))

(defun prelude-add-subfolders-to-load-path (parent-dir)
  "Add all level PARENT-DIR subdirs to the `load-path'."
  (dolist (f (directory-files parent-dir))
    (let ((name (expand-file-name f parent-dir)))
      (when (and (file-directory-p name)
                 (not (string-prefix-p "." f)))
        (add-to-list 'load-path name)
        (prelude-add-subfolders-to-load-path name)))))

;; add Prelude's directories to Emacs's `load-path'
(add-to-list 'load-path prelude-core-dir)
(add-to-list 'load-path prelude-modules-dir)
(add-to-list 'load-path prelude-vendor-dir)
(prelude-add-subfolders-to-load-path prelude-vendor-dir)

;; reduce the frequency of garbage collection by making it happen on
;; each 50MB of allocated data (the default is on every 0.76MB)
(setq gc-cons-threshold 50000000)

;; warn when opening files bigger than 100MB
(setq large-file-warning-threshold 100000000)

;; preload the personal settings from `prelude-personal-preload-dir'
(when (file-exists-p prelude-personal-preload-dir)
  (message "Loading personal configuration files in %s..." prelude-personal-preload-dir)
  (mapc 'load (directory-files prelude-personal-preload-dir 't "^[^#\.].*el$")))

(message "Loading Prelude's core...")
(setenv "NODE_NO_READLINE" "1")

(setq inferior-js-mode-hook
      (lambda ()
        ;; We like nice colors
        (ansi-color-for-comint-mode-on)
        ;; Deal with some prompt nonsense
        (add-to-list
         'comint-preoutput-filter-functions
         (lambda (output)
           (replace-regexp-in-string "\033\\[[0-9]+[GK]" "" output)))))



;; the core stuff
(require 'prelude-packages)
(require 'prelude-custom)  ;; Needs to be loaded before core, editor and ui
(require 'prelude-ui)
(require 'prelude-core)
(require 'prelude-mode)
(require 'prelude-editor)
(require 'prelude-global-keybindings)
(require 'prelude-ruby)
(require 'prelude-js)
;; OSX specific settings
(when (eq system-type 'darwin)
  (require 'prelude-osx))

(message "Loading Prelude's modules...")

;; the modules
(if (file-exists-p prelude-modules-file)
    (load prelude-modules-file)
  (message "Missing modules file %s" prelude-modules-file)
  (message "You can get started by copying the bundled example file from sample/prelude-modules.el"))

;; config changes made through the customize UI will be stored here
(setq custom-file (expand-file-name "custom.el" prelude-personal-dir))

;; load the personal settings (this includes `custom-file')
(when (file-exists-p prelude-personal-dir)
  (message "Loading personal configuration files in %s..." prelude-personal-dir)
  (mapc 'load (directory-files prelude-personal-dir 't "^[^#\.].*el$")))

(message "Prelude is ready to do thy bidding, Master %s!" current-user)

;; Patch security vulnerability in Emacs versions older than 25.3
(when (version< emacs-version "25.3")
  (eval-after-load "enriched"
    '(defun enriched-decode-display-prop (start end &optional param)
       (list start end))))

(prelude-eval-after-init
 ;; greet the use with some useful tip
 (run-at-time 5 nil 'prelude-tip-of-the-day))
(global-linum-mode 1)
(global-whitespace-mode 1)
;;; init.el ends here
;; javascript
(setq-default js2-basic-offset 2)
(setq inferior-js-mode-hook
      (lambda ()
        ;; We like nice colors
        (ansi-color-for-comint-mode-on)
        ;; Deal with some prompt nonsense
        (add-to-list
         'comint-preoutput-filter-functions
         (lambda (output)
           (replace-regexp-in-string "\033\\[[0-9]+[A-Z]" "" output)))))
(define-key js2-mode-map (kbd "M-.") nil)
(add-hook 'js2-mode-hook (lambda ()
                           (add-hook 'xref-backend-functions #'xref-js2-xref-backend nil t)))
;; json
(setq-default js-indent-level 2)
(add-to-list 'custom-theme-load-path "~/.emacs.d/themes/")

;;disable whitespace mode

;;customize
;;(define-key projectile-rails-mode-map (kbd "s-m")   'projectile-rails)
(projectile-rails-global-mode)
(require 'switch-window)
(global-set-key (kbd "C-x o") 'switch-window)
(global-set-key (kbd "C-x 1") 'switch-window-then-maximize)
(global-set-key (kbd "C-x 2") 'switch-window-then-split-below)
(global-set-key (kbd "C-x 3") 'switch-window-then-split-right)
(global-set-key (kbd "C-x 0") 'switch-window-then-delete)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)



(global-set-key "\M- " 'hippie-expand)


;;(setq ido-enable-flex-matching t)
;;(setq ido-everywhere t)
;;(ido-mode 1)

;; it looks like counsel is a requirement for swiper
(use-package counsel
  :ensure t
  )

(use-package swiper
  :ensure try
  :config
  (progn
    (ivy-mode 1)
    (setq ivy-use-virtual-buffers t)
    (global-set-key "\C-s" 'swiper)
    (global-set-key (kbd "C-c C-r") 'ivy-resume)
    (global-set-key (kbd "<f6>") 'ivy-resume)
    (global-set-key (kbd "M-x") 'counsel-M-x)
    (global-set-key (kbd "C-x C-f") 'counsel-find-file)
    (global-set-key (kbd "<f1> f") 'counsel-describe-function)
    (global-set-key (kbd "<f1> v") 'counsel-describe-variable)
    (global-set-key (kbd "<f1> l") 'counsel-load-library)
    (global-set-key (kbd "<f2> i") 'counsel-info-lookup-symbol)
    (global-set-key (kbd "<f2> u") 'counsel-unicode-char)
    (global-set-key (kbd "C-c g") 'counsel-git)
    (global-set-key (kbd "C-c j") 'counsel-git-grep)
    (global-set-key (kbd "C-c k") 'counsel-ag)
    (global-set-key (kbd "C-x l") 'counsel-locate)
    (global-set-key (kbd "C-S-o") 'counsel-rhythmbox)
    (define-key read-expression-map (kbd "C-r") 'counsel-expression-history)
    ))

;;tide
(defun setup-tide-mode ()
  (interactive)
  (tide-setup)
  p (flycheck-mode +1)
  (setq flycheck-check-syntax-automatically '(save mode-enabled))
  (eldoc-mode +1)
  (tide-hl-identifier-mode +1)
  ;; company is an optional dependency. You have to
  ;; install it separately via package-install
  ;; `M-x package-install [ret] company`
  (company-mode +1))

;; aligns annotation to the right hand side
(setq company-tooltip-align-annotations t)

;; formats the buffer before saving
(add-hook 'before-save-hook 'tide-format-before-save)

(add-hook 'typescript-mode-hook #'setup-tide-mode)

;;elipse code format typescript
(setq tide-format-options '(:insertSpaceAfterFunctionKeywordForAnonymousFunctions t :placeOpenBraceOnNewLineForFunctions nil))

;;(require 'auto-complete)
;;(define-key ac-mode-map (kbd "C-M-i") 'auto-complete)
;;(setq ac-delay 0.5)
;;(ac-config-default)


(use-package try
  :ensure t)

(add-hook 'after-init-hook 'global-company-mode)

;;org-bullets
(use-package org-bullets
  :ensure t
  :config
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))


;;ibuffer
(defalias 'list-buffers 'ibuffer)

;;tabbar
(use-package tabbar
  :ensure t
  :config (tabbar-mode 1))

;;org
(use-package org
  :ensure t
  )

;;revel js
(use-package ox-reveal
  :load-path "~/.emacs.d/elpa/ox-reveal") ;
(setq org-reveal-root "http://cdn.jsdelivr.net/reveal.js/3.0.0/")
(setq org-reveal-mathjax t)

(use-package htmlize
  :ensure t)


(defun reloading (cmd)
  (lambda (x)
    (funcall cmd x)
    (ivy--reset-state ivy-last)))
(defun given-file (cmd prompt) ; needs lexical-binding
  (lambda (source)
    (let ((target
           (let ((enable-recursive-minibuffers t))
             (read-file-name
              (format "%s %s to:" prompt source)))))
      (funcall cmd source target 1))))
(defun confirm-delete-file (x)
  (dired-delete-file x 'confirm-each-subdirectory))

(ivy-add-actions
 'counsel-find-file
 `(("c" ,(given-file #'copy-file "Copy") "copy")
   ("d" ,(reloading #'confirm-delete-file) "delete")
   ("m" ,(reloading (given-file #'rename-file "Move")) "move")))
(ivy-add-actions
 'counsel-projectile-find-file
 `(("c" ,(given-file #'copy-file "Copy") "copy")
   ("d" ,(reloading #'confirm-delete-file) "delete")
   ("m" ,(reloading (given-file #'rename-file "Move")) "move")
   ("b" counsel-find-file-cd-bookmark-action "cd bookmark")))



;;undo-tree
(use-package undo-tree
  :ensure t
  :init
  (global-undo-tree-mode))






;;company-web-mode
(use-package company-web
  :ensure t
  :config
  (add-to-list 'company-backends 'company-web-html)
  (add-to-list 'company-backends 'company-web-jade)
  (add-to-list 'company-backends 'company-web-slim)
  )

(add-hook 'web-mode-hook (lambda ()
                           (set (make-local-variable 'company-backends) '(company-web-html))
                           (company-mode t)))


(require 'font-lock)
(use-package font-lock+
  :load-path "~/.emacs.d/elpa/font-lock+") ;
(use-package all-the-icons)
(use-package all-the-icons-dired
  :hook (dired-mode . all-the-icons-dired-mode))

;;doom-theme
(use-package doom-themes
  :ensure t
  :init
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled

  ;; Load the theme (doom-one, doom-molokai, etc); keep in mind that each theme
  ;; may have their own settings.
  (load-theme 'doom-molokai t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)

  ;; Enable custom neotree theme (all-the-icons must be installed!)
  (doom-themes-neotree-config)
  ;; or for treemacs users
  (doom-themes-treemacs-config)

  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))


(setq projectile-switch-project-action 'neotree-projectile-action)

;;web-mode
(use-package web-mode
  :ensure t
  :config
  (add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.erb\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.mustache\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.hbs\\'" . web-mode))
  (setq web-mode-engines-alist
        '(("django"    . "\\.html\\'")))
  (setq web-mode-ac-sources-alist
        '(("css" . (ac-source-css-property))
          ("html" . (ac-source-words-in-buffer ac-source-abbrev))))

  (setq web-mode-enable-auto-closing t)
  (setq web-mode-enable-auto-quoting t)) ;


;;kill-ring
(use-package counsel
  :bind
  (("M-y" . counsel-yank-pop)
   :map ivy-minibuffer-map
   ("M-y" . ivy-next-line)))


(setq prelude-whitespace nil)
(require 'neotree)
(global-set-key [f8] 'neotree-toggle)

(setq doom-neotree-file-icons t)

                                        ;:ssh instead of scp for emacs
(setq tramp-default-method "ssh")

;;better-shell
(use-package better-shell
  :ensure t
  :bind (("C-'" . better-shell-shell)
         ("C-;" . better-shell-remote-open)))

(require 'counsel-spotify)
(setq counsel-spotify-client-id "763fdd1d558049e78e556ecd5b05abf5")
(setq counsel-spotify-client-secret "8283c19200284e978ed1985a30e078ac")

(global-set-key (kbd "S-C-h") 'shrink-window-horizontally)
(global-set-key (kbd "S-C-l") 'enlarge-window-horizontally)
(global-set-key (kbd "S-C-k") 'shrink-window)
(global-set-key (kbd "S-C-j") 'enlarge-window)
(global-set-key (kbd "C-c p s k") 'counsel-ag)

(global-set-key (kbd "C-x m") 'multi-term)
(display-battery-mode 1)

(setq powerline-arrow-shape 'curve)   ;; give your mode-line curves
(setq projectile-mode-line "Projectile")
(require 'powerline)
(powerline-default-theme)

;;ember mode
(require 'ember-mode)

;;fold this
(global-set-key (kbd "C-c C-F") 'fold-this-all)
(global-set-key (kbd "C-c C-f") 'fold-this)
(global-set-key (kbd "C-c M-F") 'fold-this-unfold-all)
;;goimports

;;global company mode
;;(add-hook 'after-init-hook 'global-company-mode)

;;/home/yelinaung/.emacs.d/vendor
(setq gofmt-command "goimports")
(add-to-list 'load-path "~/.emacs.d/vender/")
(require 'go-mode)
(add-hook 'before-save-hook 'gofmt-before-save)
(require 'company-go)
(setq company-tooltip-limit 20)                      ; bigger popup window
(setq company-idle-delay .3)                         ; decrease delay before autocompletion popup shows
(setq company-echo-delay 0)                          ; remove annoying blinking
(setq company-begin-commands '(self-insert-command)) ; start autocompletion only after typing

;;company mode color customizations
(custom-set-faces
 '(company-preview
   ((t (:foreground "darkgray" :underline t))))
 '(company-preview-common
   ((t (:inherit company-preview))))
 '(company-tooltip
   ((t (:background "lightgray" :foreground "black"))))
 '(company-tooltip-selection
   ((t (:background "steelblue" :foreground "white"))))
 '(company-tooltip-common
   ((((type x)) (:inherit company-tooltip :weight bold))
    (t (:inherit company-tooltip))))
 '(company-tooltip-common-selection
   ((((type x)) (:inherit company-tooltip-selection :weight bold))
    (t (:inherit company-tooltip-selection)))))


(add-hook 'go-mode-hook (lambda ()
                          (set (make-local-variable 'company-backends) '(company-go))
                          (company-mode)))
(use-package php-mode
  :ensure t
  :config
  (add-to-list 'auto-mode-alist '("\\.php$" . php-mode))
  (autoload 'php-mode "php-mode" "Major mode for editing PHP code." t)
  (add-to-list 'auto-mode-alist '("\\.inc$" . php-mode)))

(use-package php-mode
  :ensure t
  :config
  (add-to-list 'auto-mode-alist '("\\.php$" . php-mode))
  (autoload 'php-mode "php-mode" "Major mode for editing PHP code." t)
  (add-to-list 'auto-mode-alist '("\\.inc$" . php-mode)))
;; company-php

(add-to-list 'load-path
             "~/.emacs.d/vendor/yasnippet")
(require 'yasnippet)
(yas-global-mode 1)
(add-to-list 'load-path
             "~/.emacs.d/vendor/ac-php")

(add-hook 'php-mode-hook
          '(lambda ()
             (auto-complete-mode t)
             (require 'ac-php)
             (setq ac-sources  '(ac-source-php ) )
             (yas-global-mode 1)
             (ac-php-core-eldoc-setup ) ;; enable eldoc
             (define-key php-mode-map  (kbd "C-]") 'ac-php-find-symbol-at-point)   ;goto define
             (define-key php-mode-map  (kbd "C-t") 'ac-php-location-stack-back)    ;go back
             ))

(require 'dashboard)
(dashboard-setup-startup-hook)
;; Or if you use use-package
(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-startup-banner "/home/yelinaung/.emacs.d/bg.png")
  (setq dashboard-banner-logo-title "Hello Master"))

;; My Key binding to build build.sh
(require 'cl)
(defun bk-kill-buffers (regexp)
  "Kill buffers matching REGEXP without asking for confirmation."
  (interactive "sKill buffers matching this regular expression: ")
  (flet ((kill-buffer-ask (buffer) (kill-buffer buffer)))
    (kill-matching-buffers regexp)))

(defvar build_command "build_current_project")
(defun build&run ()
  "Lists the contents of the current directory."
  (interactive)
  (bk-kill-buffers "*Async Shell Command*")
  (async-shell-command build_command))
(global-set-key (kbd "C-x :") 'build&run);

;; Markdown export
(use-package ox-gfm
  :ensure t
  :config
  (eval-after-load "org"
    '(require 'ox-gfm nil t)))

;; Markdown export
(use-package multiple-cursors
  :ensure t
  :config
  (require 'multiple-cursors))

(setq org-agenda-files (list "~/Documents/orgs/work.org"
                             "~/Documents/orgs/school.org" 
                             "~/Documents/orgs/personal.org"))

;; Added Server
(server-start) 
(add-to-list 'load-path "~/.emacs.d/vendor/evil")

;; Evil
(require 'evil)
(evil-mode 1)
(evil-define-key 'normal neotree-mode-map (kbd "TAB") 'neotree-enter)
(evil-define-key 'normal neotree-mode-map (kbd "SPC") 'neotree-quick-look)
(evil-define-key 'normal neotree-mode-map (kbd "q") 'neotree-hide)
(evil-define-key 'normal neotree-mode-map (kbd "RET") 'neotree-enter)
(evil-define-key 'normal neotree-mode-map (kbd "g") 'neotree-refresh)
(evil-define-key 'normal neotree-mode-map (kbd "n") 'neotree-next-line)
(evil-define-key 'normal neotree-mode-map (kbd "p") 'neotree-previous-line)
(evil-define-key 'normal neotree-mode-map (kbd "A") 'neotree-stretch-toggle)
(evil-define-key 'normal neotree-mode-map (kbd "H") 'neotree-hidden-file-toggle)

;; Evil Leader
(require 'evil-leader)
(evil-leader/set-leader "<SPC>")
(global-evil-leader-mode)
(evil-leader/set-key "g" 'magit)
(evil-leader/set-key "d" 'dired)
(evil-leader/set-key "o" 'switch-window)
(evil-leader/set-key "e" 'move-end-of-line)
(evil-leader/set-key "f" 'find-file-in-project)
(evil-leader/set-key "b" 'projectile-switch-to-buffer)
(evil-leader/set-key "p" 'projectile-command-map)
(evil-leader/set-key "n r" 'neotree-refresh)
(evil-leader/set-key "n n" 'neotree)
(evil-leader/set-key "<SPC>" 'avy-goto-char)
(evil-leader/set-key-for-mode 'ruby "r" 'seeing-is-believing-run)
;;(setq projectile-rails-keymap-prefix (kbd "<SPC> p C-r"))

;; Evil Magit
(require 'evil-magit)

;; Enable Company Mode
(use-package company-quickhelp
  :ensure t
  :config
  (company-quickhelp-mode))

;; origami
(use-package origami
  :ensure t
  :config
  (require 'origami)
  (global-origami-mode))

;; seeing is believing
(use-package seeing-is-believing
  :ensure t
  :config
  (require 'seeing-is-believing)
  (add-hook 'ruby-mode-hook 'seeing-is-believing))
  ;;;;(evil-leader/set-key "r" 'seeing-is-believing-run))

;; Browser
(require 'eaf)

;;Avy
(use-package avy
  :ensure t
  :config
  (require 'avy)
  (evil-leader/set-key ":" 'avy-goto-char))

;;quick-run
(require 'quickrun)
;;Evil MC
(require 'evil-mc)

;; find-file-in-project
(require 'find-file-in-project)

;; Dart-Mode
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)
(unless (package-installed-p 'dart-mode)
  (package-refresh-contents)
  (package-install 'dart-mode))

;; Company-Dart
(add-hook 'dart-mode-hook (lambda ()
 (set (make-local-variable 'company-backends)
  '(company-dart (company-dabbrev company-yankpad)))))
