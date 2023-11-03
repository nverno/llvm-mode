# llvm-mode - Major mode for the LLVM IR language

Major mode for editing LLVM IR files.

Modified  from https://github.com/llvm-mirror/llvm//utils/emacs/llvm-mode.el  to
include:

- additional syntax
- font-lock for globals (vars/declares/defines)
- imenu
- indentation: `llvm-mode-indent-offset` and `llvm-mode-label-offset`
- basic completion for:
 + global variables
 + global declares/defines

TODO:

 + keywords / attributes
 + could add labels / %uids as well


References:
- https://github.com/llvm-mirror/llvm/docs/LangRef.rst
- [vim syntax](https://github.com/llvm-mirror/llvm/utils/vim/syntax/llvm.vim)

### Installation

 Add to `load-path` and generate autoloads or
```lisp
(require 'llvm-mode)
```
