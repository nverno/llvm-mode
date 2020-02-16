# llvm-mode - Major mode for the LLVM assembler language

*Author:* Noah Peart <noah.v.peart@gmail.com><br>
*URL:* [https://github.com/nverno/llvm-mode](https://github.com/nverno/llvm-mode)<br>

Major mode for editing LLVM IR files.

Modified from https://github.com/llvm-mirror/llvm//utils/emacs/llvm-mode.el
to include
- additional syntax
- font-lock for globals (vars/declares/defines)
- imenu
- indentation: `llvm-mode-indent-offset` and `llvm-mode-label-offset`
- completion:
 + global variables
 + global declares/defines
TODO:
 + keywords / attributes
 + could add labels / %uids as well

- vim syntax => https://github.com/llvm-mirror/llvm/utils/vim/syntax/llvm.vim

Reference:
https://github.com/llvm-mirror/llvm/docs/LangRef.rst

### Installation

 Add to `load-path` and generate autoloads or
```lisp
(require 'llvm-mode)
```

Code:


---
Converted from `llvm-mode.el` by [*el2markdown*](https://github.com/Lindydancer/el2markdown).
