# http://dhall-lang.org
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*[.](dhall) %{
    set-option buffer filetype dhall
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=dhall %{
    require-module dhall

    set-option window formatcmd 'dhall format'
    set-option window extra_word_chars '_' "'" '/' '-'
    hook window ModeChange insert:.* -group dhall-trim-indent  dhall-trim-indent
    hook window InsertChar \n -group dhall-indent dhall-indent-on-new-line

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window dhall-.+ }
}

hook -group dhall-highlight global WinSetOption filetype=dhall %{
    add-highlighter window/dhall ref dhall
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/dhall }
}


provide-module dhall %[

# Highlighters
# ‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter shared/dhall regions
add-highlighter shared/dhall/code  default-region group
add-highlighter shared/dhall/literal       region '"'                             (?<!\\)(\\\\)*"        group
add-highlighter shared/dhall/literal_block region "''"                            (?<!\\)(\\\\)*''(?!\$) group
add-highlighter shared/dhall/comment       region -recurse \{- \{-                  -\}                  fill comment
add-highlighter shared/dhall/line_comment  region --(?:[^!#$%&*+./<>?@\\\^|~=]|$) $                      fill comment

add-highlighter shared/dhall/code/ regex \b\d+ 0:value
# TODO: get Path/Location literals to work
#add-highlighter shared/dhall/code/ regex (\bhttps?:/|\s[.~])/[A-Fa-f0-9\-_.?=+]+(\s|$) 0:value
add-highlighter shared/dhall/code/ regex \b(False|True)\b 0:value
add-highlighter shared/dhall/code/ regex \b(let|in|merge|if|then|else)\b 0:keyword
#add-highlighter shared/dhall/code/ regex (?<!')\b(import)(?!')\b[^\n]+(?<!')\b(as)(?!')\b 2:keyword
#add-highlighter shared/dhall/code/ regex (?<!')\b(class|data|default|deriving|infix|infixl|infixr|instance|module|newtype|pattern|type|where)(?!')\b 0:keyword
#add-highlighter shared/dhall/code/ regex (?<!')\b(case|do|else|if|in|let|mdo|of|proc|rec|then)(?!')\b 0:attribute

add-highlighter shared/dhall/code/ regex \blet\s+([A-Za-z/_\-][0-9A-Za-z/_\-]*) 1:variable

add-highlighter shared/dhall/literal/       fill  string
add-highlighter shared/dhall/literal/       regex \$\{.*?\} 0:value
add-highlighter shared/dhall/literal_block/ fill  string
add-highlighter shared/dhall/literal_block/ regex \$\{.*?\} 0:value

add-highlighter shared/dhall/code/ regex (\bλ|\\|∀|\bforall|→|->) 0:function

add-highlighter shared/dhall/code/ regex (?<![~<=>|:!?/.@$*&#%+\^\-\\])(-|\+|#|⫽|//|∧|/\\|⩓|//\\\\)(?![~<=>|:!?/.@$*&#%+\^\-\\]) 0:operator

#add-highlighter shared/dhall/code/ regex (?<![~<=>|:!?/.@$*&#%+\^\-\\])(\?)(?![~<=>|:!?/.@$*&#%+\^\-\\]) 1:keyword

# Commands
# ‾‾‾‾‾‾‾‾

# http://en.wikibooks.org/wiki/Haskell/Indentation

define-command -hidden dhall-trim-indent %{
    # remove trailing white spaces
    try %{ execute-keys -draft -itersel <a-x> s \h+$ <ret> d }
}

define-command -hidden dhall-indent-on-new-line %{
    evaluate-commands -draft -itersel %{
        # copy -- comments prefix and following white spaces
        try %{ execute-keys -draft k <a-x> s ^\h*\K--\h* <ret> y gh j P }
        # preserve previous line indent
        try %{ execute-keys -draft \; K <a-&> }
        # align to first clause
        try %{ execute-keys -draft \; k x X s ^\h*(if|then|else)?\h*(([\w']+\h+)+=)?\h*(case\h+[\w']+\h+of|do|let|where)\h+\K.* <ret> s \A|.\z <ret> & }
        # filter previous line
        try %{ execute-keys -draft k : dhall-trim-indent <ret> }
        # indent after lines beginning with condition or ending with expression or =(
        try %{ execute-keys -draft \; k x <a-k> ^\h*(if)|(case\h+[\w']+\h+of|do|let|where|[=(])$ <ret> j <a-gt> }
    }
}

]
