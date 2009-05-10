;;; texinfo-warn.el --- warn about tabs and more in texinfo

;; Copyright 2008 Kevin Ryde
;;
;; Author: Kevin Ryde <user42@zip.com.au>
;; Version: 2
;; Keywords: tex
;; URL: http://www.geocities.com/user42_kevin/texinfo-warn/index.html
;;
;; texinfo-warn.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by the
;; Free Software Foundation; either version 3, or (at your option) any later
;; version.
;;
;; texinfo-warn.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
;; Public License for more details.
;;
;; You can get a copy of the GNU General Public License online at
;; <http://www.gnu.org/licenses>.


;;; Commentary:

;; `texinfo-warn-enable' puts a warning face overlay on tabs and on @: or })
;; at the end of a line, to warn you that those things are not handled well
;; by makeinfo.  See the `texinfo-warn-enable' docstring below for more.

;;; Install:
;;
;; Put texinfo-warn.el somewhere in your `load-path', and in your
;; .emacs put
;;
;;     (autoload 'texinfo-warn-enable "texinfo-warn")
;;     (add-hook 'texinfo-mode-hook 'texinfo-warn-enable)
;;
;; There's autoload cookies for `update-file-autoloads' and friends.  They
;; don't to the hook as such, you customize `texinfo-mode-hook' if you want
;; it.

;;; Emacsen:

;; Designed for Emacs 21 and 22, works in XEmacs with its overlay.el.

;;; History:

;; Version 1 - the first version
;; Version 2 - tweaks for multiple tabs, and for defface in xemacs21


;;; Code:

(require 'overlay) ;; xemacs21

(defface texinfo-warn
  '((((class color))
     (:background "red"))
    (t
     (:inverse-video t)))
  "Face for warning of bad bits in texinfo source.
The default is the same as `trailing-whitespace' face, namely red
background on a colour screen, or inverse video for black and
white."
  :group 'whitespace-faces ;; in absense of a better place
  :link  '(url-link :tag "texinfo-warn.el home page"
                    "http://www.geocities.com/user42_kevin/texinfo-warn/index.html"))

(defun texinfo-warn-remove-overlays (beg end)
  "Remove `texinfo-warn' overlays between BEG and END."
  ;; emacs21 and xemacs21 don't have `remove-overlay' new in emacs22
  (dolist (overlay (overlays-in beg end))
    (if (eq 'texinfo-warn (overlay-get overlay 'face))
        (delete-overlay overlay))))

(defun texinfo-warn-after-change (beg end prev-len)
  "Put a warning face on tabs between BEG and END.
This function is meant for use from `after-change-functions'."

  (save-excursion
    ;; Extend a bit in case @: newly established at end of line.
    ;; Don't go past point-at-bol in case that overlaps an @: on the
    ;; previous line, wrongly removing some of its warning; likewise
    ;; point-at-eol and an @: on the next line.
    ;;
    (goto-char beg)
    (setq beg (max (point-at-bol) (- beg 2)))
    (goto-char end)
    (setq end (min (+ end 3) (1+ (point-at-eol)) (point-max)))

    ;; lose existing overlays in case offending bits are now ok; or
    ;; offending bits have been deleted leaving a zero-length overlay; and
    ;; so as not to add multiple overlays onto unchanged bits
    (texinfo-warn-remove-overlays beg end)

    ;; match each tab individually, so we can delete-overlay instead of
    ;; having to split or whatnot when new text inserted in between tabs
    (goto-char beg)
    (while (re-search-forward "\t\\|\\(@:\\|})\\)\\(\n\\|$\\)" end t)
      (let ((overlay (make-overlay (match-beginning 0) (match-end 0)
                                   (current-buffer) nil nil)))
        (overlay-put overlay 'face 'texinfo-warn)))))

;;;###autoload
(defun texinfo-warn-enable ()
  "Add a `texinfo-warn' highlight overlay on doubtful bits.
This shows things which don't work quite right in makeinfo
4.11 (September 2007).

* Tabs in the source end up moved by indentation or paragraph
  flowing in the final info output so no longer line up where
  they did in the source.

* \"@:\" to mean \"not the end of a sentence\" doesn't have the
  desired effect at the end of a source line.  In info output you
  get two spaces where you wanted one.

* An xref like \"(@pxref{Fooing,,, foo, Foo Manual})\" at the end
  of a source line ends up with two spaces in the info output,
  where you wanted one.  `texinfo-warn' highlights any line
  ending \"})\", which is a bit loose, but ok in practice.

The overlay face is designed to be relatively unobtrusive.  It
shows a likely problem, but doesn't force you to act.  In your
own documents you might like something more aggressive like
always `untabify', or refuse to save.  But that tends to be
unhelpful when working on a shared or external document and
you're trying to make an isolated patch or change.

Because the warnings are just overlays, any text cut and pasted
gets only the buffer contents, not the fontification.

See also `texinfo-nobreak-enable' which helps you avoid line
breaks with \"@:\" or \"})\" at the end of a line."

  (interactive)
  (texinfo-warn-after-change (point-min) (point-max) 0) ;; initial
  (add-hook 'after-change-functions
            'texinfo-warn-after-change
            t   ;; append
            t)) ;; buffer-local

(defun texinfo-warn-disable ()
  "Disable `texinfo-warn' face highlighting."
  (interactive)
  (texinfo-warn-remove-overlays (point-min) (point-max))
  (remove-hook 'after-change-functions
               'texinfo-warn-after-change
               t)) ;; buffer local

;;;###autoload
(custom-add-option 'texinfo-mode-hook 'texinfo-warn-enable)

(provide 'texinfo-warn)

;;; texinfo-warn.el ends here
