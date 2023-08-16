# SPDX-License-Identifier: AGPL-3.0
 
# trailing colon: :lnum[:colnum[:]]
hook  global WinDisplay (.*?):(\d+)(?::(\d+):?)? %{ evaluate-commands %sh{
    file=$kak_hook_param_capture_1
    line=$kak_hook_param_capture_2
    col=$kak_hook_param_capture_3

    if ! [ -f "$file" ]; then
        echo "kak-fetch: file=$file does not exist" >&2
        exit 1
    fi

    echo "delete-buffer";
    echo "edit $file $line $col";
}}

# span: filename:(lnum:colnum)-(lnum:colnum):
hook  global WinDisplay (.*?):\((\d+),(\d+)\)(?:-\((\d+,\d+)\):?)? %{ evaluate-commands %sh{
    file=$kak_hook_param_capture_1
    line=$kak_hook_param_capture_2
    col=$kak_hook_param_capture_3

    if ! [ -f "$file" ]; then
        echo "kak-fetch: file=$file does not exist" >&2
        exit 1
    fi

    echo "delete-buffer";
    echo "edit $file $line $col";
}}

# trailing parentheses: (lnum[:colnum])
hook  global WinDisplay (.*?)\((\d+)(?::(\d+))?\) %{ evaluate-commands %sh{
    file=$kak_hook_param_capture_1
    line=$kak_hook_param_capture_2
    col=$kak_hook_param_capture_3

    if ! [ -f "$file" ]; then
        echo "kak-fetch: file=$file does not exist" >&2
        exit 1
    fi

    echo "delete-buffer";
    echo "edit $file $line $col";
}}
# trailing equals: =lnum=
hook  global WinDisplay (.*?)=(\d+)= %{ evaluate-commands %sh{
    file=$kak_hook_param_capture_1
    line=$kak_hook_param_capture_2

    if ! [ -f "$file" ]; then
        echo "kak-fetch: file=$file does not exist" >&2
        exit 1
    fi

    echo "delete-buffer";
    echo "edit $file $line";
}}

# trailing dash: -lnum-
hook  global WinDisplay (.*?)-(\d+)- %{ evaluate-commands %sh{
    file=$kak_hook_param_capture_1
    line=$kak_hook_param_capture_2

    if ! [ -f "$file" ]; then
        echo "kak-fetch: file=$file does not exist" >&2
        exit 1
    fi

    echo "delete-buffer";
    echo "edit $file $line";
}}

# Plan 9 type line spec: [:]#lnum
hook  global WinDisplay (.*?)(?::)?#(\d+) %{ evaluate-commands %sh{
    file=$kak_hook_param_capture_1
    line=$kak_hook_param_capture_2

    if ! [ -f "$file" ]; then
        echo "kak-fetch: file=$file does not exist" >&2
        exit 1
    fi

    echo "delete-buffer";
    echo "edit $file $line";
}}
