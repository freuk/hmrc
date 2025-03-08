provide-module konflict %{

map global object m %{c^[<lt>=]{4\,}[^\n]*\n,^[<gt>=]{4\,}[^\n]*\n<ret>} -docstring 'conflict markers'
map global object <a-m> %{c^[<lt>]{4\,},^[<gt>]{4\,}[^\n]*<ret>} -docstring 'conflict'

define-command konflict-use-mine %{
  evaluate-commands -draft %{
    execute-keys ghh/^<lt>{4}<ret>xd
    execute-keys h/^={4}<ret>j
    execute-keys -with-maps <a-a>m
    execute-keys d
  }
} -docstring "resolve a conflict by using the first version"

define-command konflict-use-yours %{
  evaluate-commands -draft %{
    execute-keys ghj
    execute-keys -with-maps <a-a>m
    execute-keys dh/^>{4}<ret>xd
  }
} -docstring "resolve a conflict by using the second version"

define-command konflict-use-mine-then-yours %{
  evaluate-commands -draft %{
    execute-keys -with-maps <a-l><a-a><a-m>s[=]{4,}<ret>c<esc>[m<a-h><a-l>dd]m<a-h><a-l>dd
  }
} -docstring "resolve a conflict by using the first and then the second version"

define-command konflict-use-yours-then-mine %{
  evaluate-commands -draft -save-regs ^ %{
    execute-keys -with-maps <a-l><a-a><a-m>s[=]{4,}<ret>ghh[mJZ<a-l><a-a><a-m>s[=]{4,}<ret>ghj]mKL<a-z>a<a-(>
    execute-keys -with-maps <a-l><a-a><a-m>s[=]{4,}<ret>c<esc>[m<a-h><a-l>dd]m<a-h><a-l>dd
  }
} -docstring "resolve a conflict by using the second and then the first version"

define-command konflict-use-none %{
  evaluate-commands -draft %{
    execute-keys <a-l>
    execute-keys -with-maps <a-a><a-m>
    execute-keys <a-d>
  }
} -docstring "resolve a conflict by using none"

define-command konflicts-grep %{
  grep <<<<
}

define-command konflict-highlight-conflicts -override %{
  add-highlighter -override global/ regex %{^[<lt>=]{4,}[^\n]*\n.+^[<gt>=]{4,}[^\n]*\n} 0:default+rb
}

define-command konflict-start %{
  konflict-highlight-conflicts
  konflicts-grep
}

}
