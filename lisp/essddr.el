;; essddr.el --- Support for editing R documentation (Rd) source

;;; Copyright (C) 1998--2000 KH <Kurt.Hornik@ci.tuwien.ac.at>, AJR, MM
;;;

;; Author: KH <Kurt.Hornik@ci.tuwien.ac.at>
;; Maintainer: A.J. Rossini <rossini@biostat.washington.edu>
;; Created: 25 July 1997
;; Modified: $Date: 2000/03/30 14:49:26 $
;; Version: $Revision: 5.11 $
;; RCS: $Id: essddr.el,v 5.11 2000/03/30 14:49:26 maechler Exp $

;; This file is part of ESS (Emacs Speaks Statistics).

;; This file is free software; you may redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation; either version 2, or (at your option) any
;; later version.
;;
;; This is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;; for more details.
;;
;; A copy of the GNU General Public License is available on the World
;; Wide Web at http://www.gnu.org/copyleft/gpl.html.  You can also
;; obtain it by writing to the Free Software Foundation, Inc., 675 Mass
;; Ave, Cambridge, MA 02139, USA.

;;; ESS RCS: $Id: essddr.el,v 5.11 2000/03/30 14:49:26 maechler Exp $

;;; Code:

;; To stave off byte compiler errors
(eval-when-compile (require 'ess-help))

(defvar essddr-version "0.1.8"
  "Current version of essddr.el.")

(defvar essddr-maintainer-address
  "Kurt Hornik <Kurt.Hornik@ci.tuwien.ac.at>"
  "Current maintainer of essddr.el.")

(autoload 'ess-eval-region	       "ess-mode" "[autoload]" t)
(autoload 'ess-eval-line-and-next-line "ess-mode" "[autoload]" t)
(autoload 'ess-nuke-help-bs	       "ess-help" "[autoload]" t)
(autoload 'ess-help-mode	       "ess-help" "[autoload]" t)

(defvar Rd-mode-abbrev-table nil
  "Abbrev table for R documentation keywords.
All Rd mode abbrevs start with a grave accent (`).")
(if Rd-mode-abbrev-table
    ()
  (define-abbrev-table 'Rd-mode-abbrev-table ())
  (define-abbrev Rd-mode-abbrev-table "`ag" "\\arguments")
  (define-abbrev Rd-mode-abbrev-table "`al" "\\alias")
  (define-abbrev Rd-mode-abbrev-table "`bf" "\\bold")
  (define-abbrev Rd-mode-abbrev-table "`co" "\\code")
  (define-abbrev Rd-mode-abbrev-table "`de" "\\describe")
  (define-abbrev Rd-mode-abbrev-table "`dn" "\\description")
  (define-abbrev Rd-mode-abbrev-table "`dt" "\\details")
  (define-abbrev Rd-mode-abbrev-table "`ex" "\\examples")
  (define-abbrev Rd-mode-abbrev-table "`em" "\\emph")
  (define-abbrev Rd-mode-abbrev-table "`em" "\\enumerate")
  (define-abbrev Rd-mode-abbrev-table "`fi" "\\file")
  (define-abbrev Rd-mode-abbrev-table "`fi" "\\format")
  (define-abbrev Rd-mode-abbrev-table "`it" "\\item")
  (define-abbrev Rd-mode-abbrev-table "`iz" "\\itemize")
  (define-abbrev Rd-mode-abbrev-table "`kw" "\\keyword")
  (define-abbrev Rd-mode-abbrev-table "`li" "\\link")
  (define-abbrev Rd-mode-abbrev-table "`na" "\\name")
  (define-abbrev Rd-mode-abbrev-table "`re" "\\references")
  (define-abbrev Rd-mode-abbrev-table "`sa" "\\seealso")
  (define-abbrev Rd-mode-abbrev-table "`se" "\\section")
  (define-abbrev Rd-mode-abbrev-table "`so" "\\source")
  (define-abbrev Rd-mode-abbrev-table "`sy" "\\synopsis")
  (define-abbrev Rd-mode-abbrev-table "`ta" "\\tabular")
  (define-abbrev Rd-mode-abbrev-table "`ti" "\\title")
  (define-abbrev Rd-mode-abbrev-table "`us" "\\usage")
  (define-abbrev Rd-mode-abbrev-table "`va" "\\value")
  (define-abbrev Rd-mode-abbrev-table "`ve" "\\verbatim"))

(defvar Rd-mode-syntax-table nil
  "Syntax table for Rd mode.")
(if Rd-mode-syntax-table
    ()
  (setq Rd-mode-syntax-table (copy-syntax-table text-mode-syntax-table))
  (modify-syntax-entry ?\\ "\\" Rd-mode-syntax-table)
  (modify-syntax-entry ?\{ "(}" Rd-mode-syntax-table)
  (modify-syntax-entry ?\} "){" Rd-mode-syntax-table)
  ;; Nice for editing, not for parsing ...
  (modify-syntax-entry ?\( "()" Rd-mode-syntax-table)
  (modify-syntax-entry ?\) ")(" Rd-mode-syntax-table)
  (modify-syntax-entry ?\[ "(]" Rd-mode-syntax-table)
  (modify-syntax-entry ?\] ")[" Rd-mode-syntax-table)
  ;; To get strings right
  ;; (modify-syntax-entry ?\' "\"" Rd-mode-syntax-table)
  (modify-syntax-entry ?\" "\"" Rd-mode-syntax-table)
  ;; To make abbrevs starting with a grave accent work ...
  (modify-syntax-entry ?\` "w" Rd-mode-syntax-table)
  ;; Comments
  (modify-syntax-entry ?\% "<" Rd-mode-syntax-table)
  (modify-syntax-entry ?\n ">" Rd-mode-syntax-table))

(defvar Rd-mode-parse-syntax-table nil
  "Syntax table for parsing Rd mode.")
(if Rd-mode-parse-syntax-table
    ()
  (setq Rd-mode-parse-syntax-table
	(copy-syntax-table Rd-mode-syntax-table))
  ;; To make parse-partial-sexps do the thing we want for computing
  ;; indentations
  (modify-syntax-entry ?\( "_" Rd-mode-parse-syntax-table)
  (modify-syntax-entry ?\) "_" Rd-mode-parse-syntax-table)
  (modify-syntax-entry ?\[ "_" Rd-mode-parse-syntax-table)
  (modify-syntax-entry ?\] "_" Rd-mode-parse-syntax-table))

(defvar Rd-section-names
  '("arguments" "alias" "author" "describe" "description" "details"
    "enumerate" "examples" "format" "itemize" "keyword" "name" "note"
    "references" "seealso" "section" "source" "synopsis" "tabular"
    "title" "usage" "value" "verbatim"))
(defvar Rd-keywords
  '("Alpha" "Gamma" "R" "alpha" "beta" "bold" "cr" "code" "deqn" "dots"
    "email" "emph" "epsilon" "eqn" "file" "ge" "item" "lambda" "ldots"
    "le" "left" "link" "mu" "pi" "right" "tab" "sigma" "url"))

;; Need to fix Rd-bold-face problem.
;;
;; (defvar Rd-bold-face 'bold)
;(defvar Rd-bold-face nil)
;(make-face Rd-bold-face "R documentation bold face")
;(make-face-bold Rd-bold-face

(defvar Rd-font-lock-keywords
  (list
   (cons
    (concat "\\\\\\("
	    (mapconcat 'identity Rd-section-names "\\|")
	    "\\>\\)")
    'font-lock-reference-face) ; Rd-bold-face
   (cons
    (concat "\\\\\\("
	    (mapconcat 'identity Rd-keywords "\\|")
	    "\\>\\)")
    'font-lock-keyword-face))
  "Additional Rd expressions to highlight.")

(defvar Rd-indent-level 2
  "*Indentation of Rd code with respect to containing blocks.")

(defvar Rd-mode-map nil
  "Keymap used in Rd mode.")
(if Rd-mode-map
    ()
  (let ((map (make-sparse-keymap)))
    (define-key map "\t" 'indent-according-to-mode)
    (define-key map "\C-j" 'reindent-then-newline-and-indent)
    (define-key map "\C-m" 'reindent-then-newline-and-indent)
    (define-key map "\C-c\C-p" 'Rd-preview-help)
    (define-key map "\C-c\C-j" 'Rd-mode-insert-item)
    (define-key map "\C-c\C-e" 'Rd-mode-insert-skeleton)
    (define-key map "\C-c\C-s" 'Rd-mode-insert-section)
    (define-key map "\C-c\C-w" 'ess-switch-process); is on C-c C-s in ess-mode..
    (define-key map "\C-c\C-r" 'ess-eval-region)
    (define-key map "\C-c\C-n" 'ess-eval-line-and-next-line)
    (define-key map "\C-c\C-y" 'ess-switch-to-ESS)
    (define-key map "\C-c\C-z" 'ess-switch-to-end-of-ESS)
    (setq Rd-mode-map map)))

(defvar Rd-mode-menu
  (list "Rd"
	["Insert Item"			Rd-mode-insert-item t]
	["Insert Section"		Rd-mode-insert-section t]
	["Insert Skeleton"		Rd-mode-insert-skeleton t]
	"-"
	["Preview"			Rd-preview-help t]
	"-"
	["Eval Line"			ess-eval-line-and-next-line t]
	["Eval Region"			ess-eval-region t]
	["Switch to ESS Process"	ess-switch-to-ESS t]
	["Switch to end{ESS Pr}"	ess-switch-to-end-of-ESS t]
	"-"
	["Toggle Abbrev Mode"		abbrev-mode t]
	["Toggle Auto-Fill Mode"	auto-fill-mode t]
	"-"
	["Submit Bug Report"		Rd-submit-bug-report t]
	"-"
	["Describe Rd Mode"		Rd-describe-major-mode t])
  "Menu used in Rd mode.")

(defvar Rd-mode-hook nil
  "*Hook to be run when Rd mode is entered.")

(defvar Rd-to-help-command "R CMD Rd2txt"
  "*Shell command for converting R documentation source to help text.")

;;;###autoload
(defun Rd-mode ()
  "Major mode for editing R documentation source files.

This mode makes it easier to write R documentation by helping with
indentation, doing some of the typing for you (with Abbrev mode) and by
showing keywords, strings, etc. in different faces (with Font Lock mode
on terminals that support it).

Type \\[list-abbrevs] to display the built-in abbrevs for Rd keywords.

Keybindings
===========

\\{Rd-mode-map}

Variables you can use to customize Rd mode
==========================================

`Rd-indent-level'
  Indentation of Rd code with respect to containing blocks.
  Default is 4.

Turning on Rd mode runs the hook `Rd-mode-hook'.

To automatically turn on the abbrev and font-lock features, add the
following lines to your `.emacs' file:

  (add-hook 'Rd-mode-hook
	    (lambda ()
	      (abbrev-mode 1)
	      (if (eq window-system 'x)
		  (font-lock-mode 1))))"

  (interactive)
  (text-mode)
  (kill-all-local-variables)
  (use-local-map Rd-mode-map)
  (setq mode-name "Rd")
  (setq major-mode 'Rd-mode)
  (setq local-abbrev-table Rd-mode-abbrev-table)
  (set-syntax-table Rd-mode-syntax-table)

  (set (make-local-variable 'indent-line-function) 'Rd-mode-indent-line)
  (set (make-local-variable 'fill-column) 72)
  (set (make-local-variable 'comment-start-skip) "\\s<+\\s-*")
  (set (make-local-variable 'comment-start) "% ")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'font-lock-defaults)
       '(Rd-font-lock-keywords nil nil))
  ;; (set (make-local-variable 'parse-sexp-ignore-comments) t)

  (require 'easymenu)
  (easy-menu-define Rd-mode-menu-map Rd-mode-map
		    "Menu keymap for Rd mode." Rd-mode-menu)
  (easy-menu-add Rd-mode-menu-map Rd-mode-map)

  (turn-on-auto-fill)
  (message "Rd mode version %s" essddr-version)
  (run-hooks 'Rd-mode-hook))

(defun ess-point (position)
  "Returns the value of point at certain positions."
  (save-excursion
    (cond
     ((eq position 'bol)  (beginning-of-line))
     ((eq position 'eol)  (end-of-line))
     ((eq position 'boi)  (back-to-indentation))
     ((eq position 'bonl) (forward-line 1))
     ((eq position 'bopl) (forward-line -1))
     (t (error "unknown buffer position requested: %s" position)))
    (point)))

(defun Rd-describe-major-mode ()
  "Describe the current major mode."
  (interactive)
  (describe-function major-mode))

(defun Rd-mode-in-verbatim-p ()
  (let ((pos (point)))
    (save-excursion
      (if (and (re-search-backward
		"\\\\\\(usage\\|examples\\|synopsis\\)" nil t)
	       (re-search-forward "\\s(" nil t))
	  (condition-case ()
	      (progn
		(up-list 1)
		(< pos (point)))
	    (error t))
	nil))))

(defun Rd-mode-calculate-indent ()
  "Return appropriate indentation for current line in Rd mode."
  (interactive)
  (save-excursion
    (beginning-of-line)
    (if (Rd-mode-in-verbatim-p)
	nil				; Don't do anything in verbatims
      (let ((p (progn
		 (re-search-forward "[ \t]*\\s)*" (ess-point 'eol) t)
		 (point))))
	(if (or (< (forward-line -1) 0)
		(Rd-mode-in-verbatim-p))
	    0
	  (set-syntax-table Rd-mode-parse-syntax-table)
	  (while (and (looking-at "[ \t]*$")
		      (not (bobp)))
	    (forward-line -1))
	  (re-search-forward "[ \t]*\\s)*" (ess-point 'eol) t)
	  (prog1
	      (+ (current-indentation)
		 (* (car (parse-partial-sexp (point) p))
		    Rd-indent-level))
	    (set-syntax-table Rd-mode-syntax-table)))))))

(defun Rd-mode-indent-line ()
  "Indent current line as Rd source."
  (interactive)
  (let ((ic (Rd-mode-calculate-indent))
	(rp (- (current-column) (current-indentation))))
    (if ic				; Not inside a verbatim
	(if (< ic 0)
	    (error "Unmatched parenthesis")
	  (indent-line-to ic)
	  (if (> rp 0)
	      (move-to-column (+ ic rp)))))))

(defun Rd-mode-insert-item ()
  (interactive)
  (reindent-then-newline-and-indent)
  (insert "\\item{")
  )

(defun Rd-mode-insert-section ()
  (interactive)
  (let ((s (completing-read
	    "Insert section: "
	    (mapcar '(lambda (x) (cons x x)) Rd-section-names)
	    nil t)))
    (if (string= s "")
	(progn (insert "\\section{}{") (backward-char 2))
      (insert (format "\\%s{" s)))))

(defun Rd-mode-insert-skeleton ()
  (interactive)
  (insert "\\name{}\n")
  (insert "\\alias{}\n")
  (insert "\\title{}\n")
  (insert "\\description{\n}\n")
  (insert "\\usage{\n}\n")
  (insert "\\arguments{\n}\n")
  (insert "\\value{\n}\n")
  (insert "\\details{\n}\n")
  (insert "\\references{\n}\n")
  (insert "\\seealso{\n}\n")
  (insert "\\examples{\n}\n")
  (insert "\\author{}\n")
  (insert "\\keyword{}"))

(defun Rd-preview-help ()
  (interactive)
  (require 'ess-help)
  (let ((sbuf buffer-file-name)
	(pbuf (get-buffer-create "R Help Preview")))
    (set-buffer pbuf)
    (erase-buffer)
    (shell-command (format "%s %s" Rd-to-help-command sbuf) t)
    (ess-nuke-help-bs)
    (ess-help-mode)
    (if (not (get-buffer-window pbuf 'visible))
	(display-buffer pbuf t))))

;; Bug reporting
(defun Rd-submit-bug-report ()
  "Submit a bug report on Rd mode via mail."
  (interactive)
  (require 'reporter)
  (and
   (y-or-n-p "Do you want to submit a bug report? ")
   (reporter-submit-bug-report
    essddr-maintainer-address
    (concat "Emacs version " emacs-version)
    (list
     'essddr-version
     'Rd-indent-level))))

;; Provide ourself
(provide 'essddr)

;; essddr.el ends here
