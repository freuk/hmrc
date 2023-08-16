provide-module type-expand %{
  map global insert <a-!> '<esc>: type-expand-expansion<ret>'
  map global insert <a-:> '<esc>: type-expand-command-prompt<ret>'
  define-command type-expand-expansion -docstring 'Expand the typed expansions in currently entered text' %{
    execute-keys '<a-m><a-:><a-;><a-F>%'
    evaluate-commands -itersel -save-regs '"' %{
      execute-keys ': set-register dquote <c-r>.<ret>R'
    }
    execute-keys -with-hooks 'a<a-;>;'
  }
  define-command type-expand-command -params 1.. -command-completion -docstring 'Send the given command in currently entered text' %{
    execute-keys '<a-m>i<del><esc>a<backspace><esc>'
    evaluate-commands -verbatim -- %arg{@}
    execute-keys -with-hooks 'a<a-;>;'
  }
  define-command type-expand-command-prompt -docstring 'Prompt for type-expand-command' %{
    prompt type-expand-command: -command-completion %{
      evaluate-commands type-expand-command %val{text}
    } -on-abort %{
      execute-keys -with-hooks ';i'
    }
  }
}

require-module type-expand
