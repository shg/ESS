;;; ess-debug.el --- debugging start up for ESS

;; Copyright (C) 1997--1999 A.J. Rossini

;; Author: A.J. Rossini <rossini@biostat.washington.edu>
;; Maintainer: A.J. Rossini <rossini@biostat.washington.edu>
;; Created: November 1997
;; Modified: $Date: 1998/12/15 20:54:59 $
;; Version: $Revision: 5.3 $
;; RCS: $Id: ess-debug.el,v 5.3 1998/12/15 20:54:59 rossini Exp $
;;
;; Keywords: start up, configuration.

;; This file is part of ESS.

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

;;
;; Commentary:  Strictly for debugging and development.  usage is:
;;           xemacs -no-site-file -no-init-file -load ess-debug.el -f S4    
;; (or similar!)
;;

(defun ess-add-path (path &rest options)
  "Add PATH to `load-path' if it exists under `default-load-path'
directories and it does not exist in `load-path'.

You can use following PATH styles:
	load-path relative: \"PATH/\"
			(it is searched from `defaul-load-path')
	home directory relative: \"~/PATH/\" \"~USER/PATH/\"
	absolute path: \"/HOO/BAR/BAZ/\"

You can specify following OPTIONS:
	'all-paths	search from `load-path'
			instead of `default-load-path'
	'append		add PATH to the last of `load-path'.

For ESS, ONLY use load-path, since Emacs doesn't have
default-load-path."

  (let ((rest load-path)
	p)
    (if (and (catch 'tag
	       (while rest
		 (setq p (expand-file-name path (car rest)))
		 (if (file-directory-p p)
		     (throw 'tag p))
		 (setq rest (cdr rest))))
	     (not (member p load-path)))
	(setq load-path
	      (if (memq 'append options)
		  (append load-path (list p))
		(cons p load-path))))))

(setq-default debug-on-error t)
(ess-add-path "/biostat/student2/rossini/src/ess/lisp")
(require 'ess-site)

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

;;; ess-debug.el ends here

