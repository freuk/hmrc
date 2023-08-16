hook global BufCreate .*[.](daml) %{
    set-option buffer filetype haskell
}
