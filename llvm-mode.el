;;; llvm-mode.el --- Major mode for the LLVM IR language -*- lexical-binding: t; -*-
;;
;; This is free and unencumbered software released into the public domain.
;;
;; Author: Noah Peart <noah.v.peart@gmail.com>
;; URL: https://github.com/nverno/llvm-mode
;; Package-Requires: ((emacs "25.1"))
;; Created: 16 February 2020
;; Version: 0.1.0

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:

;; Major mode for editing LLVM IR files.

;; Modified from https://github.com/llvm-mirror/llvm//utils/emacs/llvm-mode.el
;; to include
;; - additional syntax
;; - font-lock for globals (vars/declares/defines)
;; - imenu
;; - indentation: `llvm-mode-indent-offset' and `llvm-mode-label-offset'
;; - completion:
;;  + global variables
;;  + global declares/defines
;; TODO:
;;  + keywords / attributes
;;  + could add labels / %uids as well
;;
;; - vim syntax => https://github.com/llvm-mirror/llvm/utils/vim/syntax/llvm.vim
;;
;; Reference:
;; https://github.com/llvm-mirror/llvm/docs/LangRef.rst
;;
;;; Installation:
;;
;;  Add to `load-path' and generate autoloads or
;; ```lisp
;; (require 'llvm-mode)
;; ```
;;
;;; Code:
(require 'smie)

(defgroup llvm nil
  "Major mode for editing llvm assembly source code."
  :group 'languages
  :prefix "llvm-")

(defcustom llvm-mode-indent-offset 2
  "Indentation column following opening braces."
  :group 'llvm
  :type 'integer)

(defcustom llvm-mode-label-offset 0
  "Indentation column for labels."
  :group 'llvm
  :type 'integer)

(defvar llvm-mode-lookup-instruction-uri
  "https://llvm.org/docs/LangRef.html#%s-instruction")

(defvar llvm-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?% "_" table)
    (modify-syntax-entry ?. "_" table)
    (modify-syntax-entry ?\; "< " table)
    (modify-syntax-entry ?\n "> " table)
    (modify-syntax-entry ?: "." table)
    (modify-syntax-entry ?* "." table)
    table)
  "Syntax table used while in LLVM mode.")

(defconst llvm-mode-font-lock-keywords
  (list
   ;; Attributes
   `(,(regexp-opt
       '("alwaysinline" "argmemonly" "builtin" "cold" "convergent" "immarg"
         "inaccessiblemem_or_argmemonly" "inaccessiblememonly" "inlinehint"
         "jumptable" "minsize" "naked" "nobuiltin" "noduplicate"
         "noimplicitfloat" "noinline" "nonlazybind" "norecurse" "noredzone"
         "noreturn" "nounwind" "optnone" "optsize" "readnone" "readonly"
         "returns_twice" "safestack" "sanitize_address" "sanitize_hwaddress"
         "sanitize_memory" "sanitize_memtag" "sanitize_thread" "speculatable"
         "ssp" "sspreq" "sspstrong" "strictfp" "uwtable" "writeonly")
       'symbols)
     . font-lock-constant-face)
   ;; Globals
   '("@[[:alnum:]_]+" . font-lock-function-name-face)
   ;; Variables
   '("%[-a-zA-Z$._][-a-zA-Z$._0-9]*" . font-lock-variable-name-face)
   ;; Labels
   '("[-a-zA-Z$._0-9]+:" . font-lock-variable-name-face)
   ;; Unnamed variable slots
   '("%[-]?[0-9]+" . font-lock-variable-name-face)
   ;; Types
   `(,(regexp-opt
       '("void" "i1" "i8" "i16" "i32" "i64" "i128" "float" "double" "type"
         "label" "opaque")
       'symbols)
     . font-lock-type-face)
   ;; Integer literals
   '("\\b[-]?[0-9]+\\b" . font-lock-preprocessor-face)
   ;; Floating point constants
   '("\\b[-+]?[0-9]+.[0-9]*\\([eE][-+]?[0-9]+\\)?\\b" . font-lock-preprocessor-face)
   ;; Hex constants
   '("\\b0x[0-9A-Fa-f]+\\b" . font-lock-preprocessor-face)
   ;; Keywords
   `(,(regexp-opt
       '(;; Toplevel entities
         "declare" "define" "module" "target" "source_filename" "global"
         "constant" "const" "attributes" "uselistorder" "uselistorder_bb"
         ;; Linkage types
         "private" "internal" "weak" "weak_odr" "linkonce" "linkonce_odr"
         "available_externally" "appending" "common" "extern_weak" "external"
         "uninitialized" "implementation" "..."
         ;; Values
         "true" "false" "null" "undef" "zeroinitializer" "none" "c" "asm"
         "blockaddress"
         ;; Calling conventions
         "ccc" "fastcc" "coldcc" "webkit_jscc" "anyregcc" "preserve_mostcc"
         "preserve_allcc" "cxx_fast_tlscc" "swiftcc" "atomic" "volatile"
         "personality" "prologue" "section")
       'symbols)
     . font-lock-keyword-face)
   ;; Arithmetic and Logical Operators
   `(,(regexp-opt
       '("add" "sub" "mul" "sdiv" "udiv" "urem" "srem" "and" "or" "xor" "setne"
         "seteq" "setlt" "setgt" "setle" "setge")
       'symbols)
     . font-lock-keyword-face)
   ;; Floating-point operators
   `(,(regexp-opt '("fadd" "fsub" "fneg" "fmul" "fdiv" "frem") 'symbols)
     . font-lock-keyword-face)
   ;; Special instructions
   `(,(regexp-opt
       '("phi" "tail" "call" "select" "to" "shl" "lshr" "ashr" "fcmp" "icmp"
         "va_arg" "landingpad")
       'symbols)
     . font-lock-keyword-face)
   ;; Control instructions
   `(,(regexp-opt
       '("ret" "br" "switch" "invoke" "resume" "unwind" "unreachable"
         "indirectbr")
       'symbols)
     . font-lock-keyword-face)
   ;; Memory operators
   `(,(regexp-opt
       '("malloc" "alloca" "free" "load" "store" "getelementptr" "fence"
         "cmpxchg" "atomicrmw")
       'symbols)
     . font-lock-keyword-face)
   ;; Casts
   `(,(regexp-opt
       '("bitcast" "inttoptr" "ptrtoint" "trunc" "zext" "sext" "fptrunc" "fpext"
         "fptoui" "fptosi" "uitofp" "sitofp" "addrspacecast")
       'symbols)
     . font-lock-keyword-face)
   ;; Vector ops
   `(,(regexp-opt '("extractelement" "insertelement" "shufflevector") 'symbols)
     . font-lock-keyword-face)
   ;; Aggregate ops
   `(,(regexp-opt '("extractvalue" "insertvalue") 'symbols) . font-lock-keyword-face)
   ;; Metadata types
   `(,(regexp-opt '("distinct") 'symbols) . font-lock-keyword-face)
   ;; Use-list order directives
   `(,(regexp-opt '("uselistorder" "uselistorder_bb") 'symbols)
     . font-lock-keyword-face))
  "Syntax highlighting for LLVM.")


;; -------------------------------------------------------------------
;;; Indentation

(defconst llvm-mode-smie-grammar
  (smie-prec2->grammar
   (smie-precs->prec2
    '((assoc ":")))))

;; return ":" on label line
(defun llvm-mode--smie-forward-token ()
  (let ((tok (smie-default-forward-token)))
    (save-match-data
      (if (not (looking-at "[ \t]*:")) tok
        (goto-char (match-end 0))
        ":"))))

(defun llvm-mode-smie-rules (kind token)
  (pcase (cons kind token)
    (`(:elem       . basic) llvm-mode-indent-offset)
    (`(:elem       . args) 0)
    (`(:close-all  . ,_) t)
    (`(:before     . ":")
     (if (smie-rule-parent-p ":") 0
       llvm-mode-label-offset))
    (`(:after      . ":")
     (if (smie-rule-prev-p ":") llvm-mode-indent-offset
       (- llvm-mode-indent-offset llvm-mode-label-offset)))
    (`(:list-intro . ,(or ":" "")) t)))

;; -------------------------------------------------------------------
;;; Completion

(defconst llvm-mode-global-regexp
  (concat "^\\s-*" (regexp-opt '("declare" "define")) "\\s-*"
          "[^@\n]+@\\([[:alnum:]_]+\\)"
          "\\|^\\s-*@\\([[:alnum:]_]+\\) *="))

(defun llvm-mode--globals ()
  (let (res)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward llvm-mode-global-regexp nil t)
        (push (or (match-string-no-properties 1)
                  (match-string-no-properties 2))
              res)))
    res))

;; basic completion at point
(defun llvm-mode-completion-at-point ()
  (when-let* ((bnds (bounds-of-thing-at-point 'symbol)))
    (let ((table
           (cond
            ((eq ?@ (char-before (car bnds)))
             (list
              (completion-table-with-cache
               (lambda (_string) (llvm-mode--globals)))
              :annotation-function (lambda (_s) " <g>"))))))
      (when table
        (nconc (list (car bnds) (cdr bnds))
               table
               (list :exclusive 'no))))))

(defun llvm-mode-lookup-instruction-online (instr)
  "Lookup help for INSTR, default to thing at point, in online manual.
With prefix, query for INSTR."
  (interactive
   (list
    (or (and (not current-prefix-arg) (thing-at-point 'symbol))
        (read-from-minibuffer "LLVM help for: "))))
  (browse-url
   (format llvm-mode-lookup-instruction-uri instr)))

;; Imenu: defines / declares / labels
;; XXX: remove duplicate labels??
(defvar llvm-mode-imenu-regexp
  `((nil
     ,(concat (regexp-opt '("declare" "define")) "[^@\n]+@\\([[:alnum:]_]+\\)")
     1)
    ("Label" "^\\s-*\\([[:alpha:]][[:alnum:]_]*\\):" 1)))

(defvar llvm-mode-map
  (let ((km (make-sparse-keymap)))
    (define-key km (kbd "M-?") #'llvm-mode-lookup-instruction-online)
    km))


;;;###autoload
(define-derived-mode llvm-mode prog-mode "LLVM"
  "Major mode for editing LLVM source files.
\\{llvm-mode-map}
  Runs `llvm-mode-hook' on startup."
  (setq font-lock-defaults `(llvm-mode-font-lock-keywords))
  (setq-local comment-start ";")
  (setq-local imenu-generic-expression llvm-mode-imenu-regexp)
  (add-hook 'completion-at-point-functions #'llvm-mode-completion-at-point nil t)
  (smie-setup llvm-mode-smie-grammar #'llvm-mode-smie-rules
              :forward-token #'llvm-mode--smie-forward-token
              :backward-token #'smie-default-backward-token))

;; Associate .ll files with llvm-mode
;;;###autoload
(add-to-list 'auto-mode-alist (cons "\\.ll\\'" 'llvm-mode))

(provide 'llvm-mode)

;;; llvm-mode.el ends here
