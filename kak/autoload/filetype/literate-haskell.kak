# Literate haskell

add-highlighter shared/literate-haskell regions

# This option is for changing the format of the documentation.
# Usually one wants to use one of latex or markdown.
declare-option -docstring 'The non-code format, it must match kakoune highlighter name, by default it is markdown' str literate_haskell_docs_format 'markdown'

add-highlighter shared/literate-haskell/docs default-region ref %opt{literate_haskell_docs_format}
add-highlighter shared/literate-haskell/code region ^\\begin\{code\} ^\\end\{code\} ref haskell
add-highlighter shared/literate-haskell/code-bird region ^> \n$ ref haskell

hook global BufCreate .*[.](lhs) %{
    set-option buffer filetype literate-haskell
}

hook -group literate-haskell-highlight global WinSetOption filetype=literate-haskell %{
    require-module haskell
    require-module %opt{literate_haskell_docs_format}

    add-highlighter window/literate-haskell ref literate-haskell
    hook -once -always window WinSetOption filetype=.* %{
        remove-highlighter window/literate-haskell
    }
}
