hook global ModuleLoaded search-highlighter %{
  search-highlighter-enable
}

provide-module search-highlighter %{
  set-face global Search "rgb:EE7733"
  add-highlighter shared/search dynregex '%reg{/}' 0:Search
  define-command search-highlighter-enable -docstring 'Enable search-highlighter' %{
    search-highlighter-up
  }
  define-command search-highlighter-disable -docstring 'Disable search-highlighter' %{
    search-highlighter-down
    remove-hooks global search-highlighter
  }
  define-command -hidden search-highlighter-up %{
    add-highlighter global/search ref search
    hook -once -group search-highlighter global NormalKey '<esc>' %{
      search-highlighter-down
    }
  }
  define-command -hidden search-highlighter-down %{
    remove-highlighter global/search
    hook -once -group search-highlighter global NormalKey '[/?*nN]|<a-[/?*nN]>' %{
      search-highlighter-up
    }
  }
}

require-module search-highlighter
