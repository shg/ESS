;;; ess-trns.el --- Support for manipulating S transcript files

;; Copyright (C) 1989-1994 Bates, Kademan, Ritter and Smith
;; Copyright (C) 1997,  Richard M. Heiberger <rmh@fisher.stat.temple.edu>
;;                              Kurt Hornik <hornik@ci.tuwien.ac.at>
;;                              Martin Maechler <maechler@stat.math.ethz.ch>
;;                              A.J. (Tony) Rossini <rossini@stat.sc.edu>

;; Author: David Smith <dsmith@stats.adelaide.edu.au>
;; Maintainer: A.J. Rossini <rossini@stat.sc.edu>
;; Created: 7 Jan 1994
;; Modified: $Date: 2000/03/30 14:49:26 $
;; Version: $Revision: 5.4 $
;; RCS: $Id: ess-trns.el,v 5.4 2000/03/30 14:49:26 maechler Exp $

;; This file is part of ESS

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;; Code for dealing with ESS transcripts.

;;; Code:

 ; Requires and autoloads

(require 'ess)

(eval-when-compile
  (require 'comint)
  (require 'ess-inf))

(autoload 'ess-eval-region "ess-mode" "[autoload]" t)
(autoload 'ess-eval-region-and-go "ess-mode" "[autoload]" t)
(autoload 'ess-eval-function "ess-mode" "[autoload]" t)
(autoload 'ess-eval-function-and-go "ess-mode" "[autoload]" t)
(autoload 'ess-eval-line "ess-mode" "[autoload]" t)
(autoload 'ess-eval-line-and-go "ess-mode" "[autoload]" t)
(autoload 'ess-beginning-of-function "ess-mode" "[autoload]" t)
(autoload 'ess-end-of-function "ess-mode" "[autoload]" t)

(autoload 'comint-previous-prompt "comint" "[autoload]" t)
(autoload 'comint-next-prompt "comint" "[autoload]" t)

(autoload 'ess-load-file "ess-inf" "[autoload]" t)
(autoload 'ess-request-a-process "ess-inf" "(autoload)" nil)
(autoload 'get-ess-buffer "ess-inf" "(autoload)" nil)
(autoload 'ess-switch-to-ESS "ess-inf" "(autoload)" nil)
(autoload 'ess-switch-to-end-of-ESS "ess-inf" "(autoload)" nil)
(autoload 'ess-eval-visibly "ess-inf" "(autoload)" nil)
(autoload 'inferior-ess-get-old-input "ess-inf" "(autoload)" nil)

 ; ess-transcript-mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; In this section:
;;;;
;;;; * The major mode ess-transcript-mode
;;;; * Commands for ess-transcript-mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;*;; Major mode definition
(defvar ess-transcript-mode-map nil "Keymap for `ess-transcript-mode'.")
(if ess-transcript-mode-map
    nil

  (cond ((string-match "XEmacs\\|Lucid" emacs-version)
	 ;; Code for XEmacs
 	 (setq ess-transcript-mode-map (make-keymap))
	 (set-keymap-parent ess-transcript-mode-map text-mode-map))
	((not (string-match "XEmacs\\|Lucid" emacs-version))
	 ;; Code for GNU Emacs
	 (setq ess-transcript-mode-map (make-sparse-keymap))))

  (define-key ess-transcript-mode-map "\C-c\C-s" 'ess-switch-process)
  (define-key ess-transcript-mode-map "\C-c\C-r" 'ess-eval-region)
  (define-key ess-transcript-mode-map "\C-c\M-r" 'ess-eval-region-and-go)
;;  (define-key ess-transcript-mode-map "\M-\C-x"  'ess-eval-function)
;;  (define-key ess-transcript-mode-map "\C-c\M-f" 'ess-eval-function-and-go)
;;  (define-key ess-transcript-mode-map "\C-c\C-j" 'ess-eval-line)
;;  (define-key ess-transcript-mode-map "\C-c\M-j" 'ess-eval-line-and-go)

  (define-key ess-transcript-mode-map "\C-c\C-k"    'ess-force-buffer-current)
  (define-key ess-transcript-mode-map "\C-c\C-q"    'ess-quit)

  (define-key ess-transcript-mode-map "\C-c\C-j" 'ess-transcript-send-command)
  (define-key ess-transcript-mode-map "\C-c\M-j" 'ess-transcript-send-command-and-move)
  (define-key ess-transcript-mode-map "\M-\C-a"  'ess-beginning-of-function)
  (define-key ess-transcript-mode-map "\M-\C-e"  'ess-end-of-function)
  (define-key ess-transcript-mode-map "\C-c\C-y" 'ess-switch-to-ESS)
  (define-key ess-transcript-mode-map "\C-c\C-z" 'ess-switch-to-end-of-ESS)
  (define-key ess-transcript-mode-map "\C-c\C-v" 'ess-display-help-on-object)
  (define-key ess-transcript-mode-map "\C-c\C-d" 'ess-dump-object-into-edit-buffer)
  (define-key ess-transcript-mode-map "\C-c\C-t" 'ess-execute-in-tb)
  (define-key ess-transcript-mode-map "\C-c\t"   'ess-complete-object-name)
  (define-key ess-transcript-mode-map "\M-\t"    'comint-replace-by-expanded-filename)
  (define-key ess-transcript-mode-map "\M-?"     'comint-dynamic-list-completions)
  (define-key ess-transcript-mode-map "\C-c\C-k" 'ess-request-a-process)
  (define-key ess-transcript-mode-map "{"        'ess-electric-brace)
  (define-key ess-transcript-mode-map "}"        'ess-electric-brace)
  (define-key ess-transcript-mode-map "\e\C-h"   'ess-mark-function)
  (define-key ess-transcript-mode-map "\e\C-q"   'ess-indent-exp)
  (define-key ess-transcript-mode-map "\177"     'backward-delete-char-untabify)
  (define-key ess-transcript-mode-map "\t"       'ess-indent-command)

  (define-key ess-transcript-mode-map "\C-c\C-p" 'comint-previous-prompt)
  (define-key ess-transcript-mode-map "\C-c\C-n" 'comint-next-prompt)
  ;; (define-key ess-transcript-mode-map "\C-c\C-n"    'ess-eval-line-and-next-line)

  (define-key ess-transcript-mode-map "\r"       'ess-transcript-send-command-and-move)
  (define-key ess-transcript-mode-map "\M-\r"    'ess-transcript-send-command)
  (define-key ess-transcript-mode-map "\C-c\r"   'ess-transcript-copy-command)
  (define-key ess-transcript-mode-map "\C-c\C-w" 'ess-transcript-clean-region))

(easy-menu-define
 ess-transcript-mode-menu ess-transcript-mode-map
 "Menu for use in S transcript mode."
 '("ess-trans"
   ["Describe"         describe-mode                     t]
   ["About"            (ess-goto-info "Transcript Mode") t]
   ["Send bug report"  ess-submit-bug-report             t]
   "------"
   ["Mark cmd group"   mark-paragraph         t]
   ["Previous prompt"  comint-previous-prompt t]
   ["Next prompt"      comint-next-prompt     t]
   "------"
   ["Send and move"  ess-transcript-send-command-and-move t]
   ["Copy command"   ess-transcript-copy-command          t]
   ["Send command"   ess-transcript-send-command          t]))


(if (not (string-match "XEmacs" emacs-version))
    (progn
       (if (featurep 'ess-trans)
	   (define-key ess-transcript-mode-map [menu-bar ess-trans]
	     (cons "ess-trans" ess-transcript-mode-menu))
	 (eval-after-load "ess-trans"
			  '(define-key ess-transcript-mode-map
			     [menu-bar ess-trans]
			     (cons "ess-trans"
				   ess-transcript-mode-menu))))))

(defun ess-transcript-mode-xemacs-menu ()
  "Hook to install `ess-transcript-mode' menu for XEmacs (w/ easymenu)."
  (if 'ess-transcript-mode
        (easy-menu-add ess-transcript-mode-menu)
    (easy-menu-remove ess-transcript-mode-menu)))

(if (string-match "XEmacs" emacs-version)
    (add-hook 'ess-transcript-mode-hook 'ess-transcript-mode-xemacs-menu))

(defun ess-transcript-mode (alist &optional proc)
  "Major mode for manipulating S transcript files.

Type \\[ess-transcript-send-command] to send a command in the
transcript to the current S process. \\[ess-transcript-copy-command]
copies the command but does not execute it, allowing you to edit it in
the process buffer first.

Type \\[ess-transcript-clean-region] to delete all outputs and prompts
in the region, leaving only the S commands.
o
\\{ess-transcript-mode-map}"
  (interactive)
  (require 'ess-inf)
  (kill-all-local-variables)
  (toggle-read-only t) ;; to protect the buffer.
  (ess-setq-vars-local alist (current-buffer))
  (setq major-mode 'ess-transcript-mode)
  (setq mode-name "ESS Transcript")
  (use-local-map ess-transcript-mode-map)
  (set-syntax-table ess-mode-syntax-table)
  (setq mode-line-process
	'(" [" ess-local-process-name "]"))
  (make-local-variable 'ess-local-process-name)
  (setq ess-local-process-name nil)
  (make-local-variable 'paragraph-start)
  (setq paragraph-start (concat "^" inferior-ess-primary-prompt "\\|^\^L"))
  (make-local-variable 'paragraph-separate)
  (setq paragraph-separate "^\^L")
  (setq inferior-ess-prompt
	;; Do not anchor to bol with `^'       ; (copied from ess-inf.el)
	(concat "\\("
		inferior-ess-primary-prompt
		"\\|"
		inferior-ess-secondary-prompt
		"\\)"))
  (make-local-variable 'comint-prompt-regexp)
  (setq comint-prompt-regexp (concat "^" inferior-ess-prompt))

  ;; font-lock support
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults
	'(ess-trans-font-lock-keywords nil nil ((?' . "."))))

  ;;; Keep <tabs> out of the code.
  (make-local-variable 'indent-tabs-mode)
  (setq indent-tabs-mode nil)

  (run-hooks 'ess-transcript-mode-hook))

;;*;; Commands used in S transcript mode

(defun ess-transcript-send-command ()
  "Send the command at point in the transcript to the S process
The line should begin with a prompt. The S process buffer is displayed if it
is not already."
  (interactive)
  (let* ((proc (or ess-local-process-name
		   (ess-request-a-process "Evaluate into which process? " t)))
	 (ess-buf (get-ess-buffer proc)))
    (setq ess-local-process-name proc)
    (if (get-buffer-window ess-buf) nil
      (display-buffer ess-buf t))
    (let ((input (inferior-ess-get-old-input)))
      (save-excursion
	(set-buffer ess-buf)
	(goto-char (point-max))
	(ess-eval-visibly input)))))

(defun ess-transcript-send-command-and-move ()
  "Send the ess-command on this line, and move point to the next command"
  (interactive)
  (ess-transcript-send-command)
  (goto-char ess-temp-point)
  (comint-next-prompt 1))

(defun ess-transcript-copy-command ()
  "Copy the command at point to the command line of the S process"
  (interactive)
  (let* ((proc (or ess-local-process-name
		   (ess-request-a-process "Evaluate into which process? " t)))
	 (ess-buf (process-buffer (get-process proc)))
	 (input (inferior-ess-get-old-input)))
    (setq ess-local-process-name proc)
    (if (get-buffer-window ess-buf) nil
      (display-buffer ess-buf t))
    (save-excursion
      (set-buffer ess-buf)
      (goto-char (point-max))
      (insert input)))
  (ess-switch-to-end-of-ESS))

(defun ess-transcript-clean-region (beg end)
  "Strip the transcript in the region, leaving only S commands.
Deletes any lines not beginning with an S prompt, and then removes the
prompt from those lines than remain."
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region beg end)
      (goto-char (point-min))
      (delete-non-matching-lines (concat "^" inferior-ess-prompt))
      (goto-char (point-min))
      (replace-regexp (concat "^" inferior-ess-prompt) ""))))

 ; Local variables section

;;; This file is automatically placed in Outline minor mode.
;;; The file is structured as follows:
;;; Chapters:     ^L ;
;;; Sections:    ;;*;;
;;; Subsections: ;;;*;;;
;;; Components:  defuns, defvars, defconsts
;;;              Random code beginning with a ;;;;* comment

;;; Local variables:
;;; mode: emacs-lisp
;;; mode: outline-minor
;;; outline-regexp: "\^L\\|\\`;\\|;;\\*\\|;;;\\*\\|(def[cvu]\\|(setq\\|;;;;\\*"
;;; End:

;;; ess-trans.el ends here
