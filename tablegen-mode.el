;;; tablegen-mode.el --- Major mode for TableGen files (part of LLVM project)  -*- lexical-binding: t; -*-

;; Copyright for the llvm-project
;; See https://github.com/llvm/llvm-project/blob/main/LICENSE.TXT

;; Maintainer:  The LLVM team, http://llvm.org/
;; Version: 1.0
;; URL: https://github.com/llvm/llvm-project/llvm/utils/emacs/llvm-mir-mode.el
;; Package-Requires: ((emacs "25.1"))

;;; Commentary:
;; A major mode for TableGen description files in LLVM.
;;; Code:

(require 'comint)
(require 'custom)
(require 'ansi-color)

(defface tablegen-mode-td-decorators-face
  '((t (:inherit font-lock-preprocessor-face)))
  "Face for method decorators."
  :group 'tablegen-mode)

(defvar tablegen-font-lock-keywords
  (let ((kw (regexp-opt '("class" "defm" "def" "field" "include" "in"
                         "let" "multiclass" "foreach" "if" "then" "else"
                         "defvar" "defset" "dump" "assert")
                        'words))
        (type-kw (regexp-opt '("bit" "bits" "code" "dag" "int" "list" "string")
                             'words)))
    (list
     ;; Strings
     '("\"[^\"]+\"" . font-lock-string-face)
     ;; Hex constants
     '("\\<0x[0-9A-Fa-f]+\\>" . font-lock-preprocessor-face)
     ;; Binary constants
     '("\\<0b[01]+\\>" . font-lock-preprocessor-face)
     ;; Integer literals
     '("\\<[-]?[0-9]+\\>" . font-lock-preprocessor-face)
     ;; Floating point constants
     '("\\<[-+]?[0-9]+\.[0-9]*\([eE][-+]?[0-9]+\)?\\>" . font-lock-preprocessor-face)

     '("^[ \t]*\\(@.+\\)" 1 'tablegen-mode-td-decorators-face)
     ;; Keywords
     kw
     ;; Type keywords
     type-kw))
  "Additional expressions to highlight in TableGen mode.")

;;; Syntax table

(defvar tablegen-mode-syntax-table
  (let ((tab (make-syntax-table)))
    ;; whitespace (` ')
    (modify-syntax-entry ?\   " "      tab)
    (modify-syntax-entry ?\t  " "      tab)
    (modify-syntax-entry ?\r  " "      tab)
    (modify-syntax-entry ?\n  " "      tab)
    (modify-syntax-entry ?\f  " "      tab)
    ;; word constituents (`w')
    (modify-syntax-entry ?\%  "w"      tab)
    (modify-syntax-entry ?\_  "w"      tab)
    ;; comments
    (modify-syntax-entry ?/   ". 124b" tab)
    (modify-syntax-entry ?*   ". 23"   tab)
    (modify-syntax-entry ?\n  "> b"    tab)
    ;; open paren (`(')
    (modify-syntax-entry ?\(  "("      tab)
    (modify-syntax-entry ?\[  "("      tab)
    (modify-syntax-entry ?\{  "("      tab)
    (modify-syntax-entry ?\<  "("      tab)
    ;; close paren (`)')
    (modify-syntax-entry ?\)  ")"      tab)
    (modify-syntax-entry ?\]  ")"      tab)
    (modify-syntax-entry ?\}  ")"      tab)
    (modify-syntax-entry ?\>  ")"      tab)
    ;; string quote ('"')
    (modify-syntax-entry ?\"  "\""     tab)
    tab)
  "Syntax table used in `tablegen-mode' buffers.")


(defvar tablegen-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "TAB" 'tab-to-tab-stop)
    (define-key map "\es" 'center-line)
    (define-key map "\eS" 'center-paragraph)
    map))

;;;###autoload
(define-derived-mode tablegen-mode prog-mode "TableGen"
  "Major mode for editing TableGen description files.

\\{tablegen-mode-map}"
  (setq-local comment-start "//")
  (setq-local indent-tabs-mode nil)
  (setq-local font-lock-defaults '(tablegen-font-lock-keywords)))

;; Associate .td files with tablegen-mode
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.td\\'" . tablegen-mode))

(provide 'tablegen-mode)

;;; tablegen-mode.el ends here
