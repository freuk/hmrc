#!/usr/bin/env bash

shopt -s histappend

export HISTFILESIZE=
export HISTSIZE=
export HISTTIMEFORMAT="[%F %T] "
export HISTFILE="$HOME/.bash_eternal_history"
export PROMPT_DIRTRIM=2
export NNN_PLUG="f:preview-tui"
export NNN_FIFO="/tmp/nnn.fifo"
export LANG="C.UTF-8"
export LESS="-R"
export TERM="tmux-256color"
export EDITOR="kak"
export VISUAL="kak"
export PAGER="less"
export FZF_TMUX_HEIGHT="100%"

parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

function restore() {
  if [ "$PS1" != "$PROMPT" ]; then
    PS1=$PROMPT
    PROMPT_COMMAND=""
  fi
}
PROMPT_COMMAND=restore

if [ -z "$IN_NIX_SHELL" ]; then
  PROMPT="\[\e[40;0;37m\][\u@\h:\w\$(parse_git_branch)]$ \[\e[40;0;37m\]"
else
  if [ "$IN_NIX_SHELL" = impure ]; then
    PROMPT="\[\e[40;0;33m\][nix-shell:\w\$(parse_git_branch)]$ \[\e[40;0;37m\]"
  else
    PROMPT="\[\e[40;0;32m\][nix-shell:\w\$(parse_git_branch)]$ \[\e[40;0;37m\]"
  fi
fi
export PS1=$PROMPT

bind -m emacs-standard '"\er": redraw-current-line'
bind -m vi-command '"\C-z": emacs-editing-mode'
bind -m vi-insert '"\C-z": emacs-editing-mode'
bind -m emacs-standard '"\C-z": vi-editing-mode'
bind -x '"\C-l": clear'


__fzfcmd() {
  [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; } &&
    echo "fzf-tmux ,${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

__fzf_select__() {
  local cmd="${FZF_CTRL_T_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type f -print \
    -o -type d -print \
    -o -type l -print 2> /dev/null | cut -b3-"}"
  eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) --preview 'bat {}' -m "$@" | while read -r item; do
    printf '%q ' "$item"
  done
  echo
}

__fzf_select_file__() {
  local cmd="${FZF_CTRL_T_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type f -print \
    -o -type l -print 2> /dev/null | cut -b3-"}"
  eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) --preview 'bat {}' -m "$@" | while read -r item; do
    printf '%q ' "$item"
  done
  echo
}

fzf-file-widget() {
  local selected="$(__fzf_select__)"
  READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$selected${READLINE_LINE:$READLINE_POINT}"
  READLINE_POINT=$(( READLINE_POINT + ${#selected} ))
}
# bind -x '"\C-t": fzf-file-widget'

stty lnext undef

fzfEdit() {
  FILE=$(__fzf_select_file__);
  if [[ -n $FILE ]]; then
    $EDITOR $FILE
  fi
}

bind -x '"\C-p": fzfEdit'

__fzf_history__() {
  local output
  output=$(
    builtin fc -lnr -2147483648 |
      last_hist=$(HISTTIMEFORMAT='' builtin history 1) perl -n -l0 -e 'BEGIN { getc; $/ = "\n\t"; $HISTCMD = $ENV{last_hist} + 1 } s/^[ *]//; print $HISTCMD - $. . "\t$_" if !$seen{$_}++' |
      FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS +m --read0" $(__fzfcmd) --query "$READLINE_LINE"
  ) || return
  READLINE_LINE=${output#*$'\t'}
  if [ -z "$READLINE_POINT" ]; then
    echo "$READLINE_LINE"
  else
    READLINE_POINT=0x7fffffff
  fi
}

bind -x '"\C-r": __fzf_history__'

alias fzf-jump=cd

_fuzzyJump_ () {
    local cmd dir
    if [ "$PWD" == "$HOME" ]
    then
        cmd="fasd -dl | grep home";
    else
        cmd="command find -L . -mindepth 1 \
          \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o \
          -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
          -o -type d -print 2> /dev/null | cut -b3-"
    fi
    dir=$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" $(__fzfcmd) +m)
    printf 'fzf-jump %q' "$dir"
}

bind -m emacs-standard '"\C-v": " \C-b\C-k \C-u`_fuzzyJump_`\e\C-e\er\C-m\C-y\C-a\e \C-y\ey\C-x\C-x\C-d"'
bind -m vi-command '"\C-v": "\C-z\C-v\C-z"'
bind -m vi-insert '"\C-v": "\C-z\C-v\C-z"'

stty stop undef

_insertNixShell_ () {
    printf 'cached-nix-shell'
}

bind -m emacs-standard '"\C-s": " \C-b\C-k \C-u`_insertNixShell_`\e\C-e\er\C-m\C-y\C-a\e \C-y\ey\C-x\C-x\C-d"'
bind -m vi-command '"\C-s": "\C-z\C-s\C-z"'
bind -m vi-insert '"\C-s": "\C-z\C-s\C-z"'

nnn-jump ()
{
    if [ -n "$NNNLVL" ] && [ "${NNNLVL:-0}" -ge 1 ]; then
        echo "nnn is already running"
        return
    fi
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    nnn -eEDdifx 
    if [ -f "$NNN_TMPFILE" ]; then
            . "$NNN_TMPFILE"
            rm -f "$NNN_TMPFILE" > /dev/null
    fi
}
bind -m emacs-standard '"\C-n": " \C-b\C-k \C-unnn-jump\e\C-e\er\C-m\C-y\C-a\e \C-y\ey\C-x\C-x\C-d"'
bind -m vi-command '"\C-n": "\C-z\C-n\C-z"'
bind -m vi-insert '"\C-n": "\C-z\C-n\C-z"'

back-jump () { cd ..; }

bind -m emacs-standard '"\C-h": " \C-b\C-k \C-uback-jump\e\C-e\er\C-m\C-y\C-a\e \C-y\ey\C-x\C-x\C-d"'
bind -m vi-command '"\C-h": "\C-z\C-h\C-z"'
bind -m vi-insert '"\C-h": "\C-z\C-h\C-z"'

tigstatus ()
{
  tig status;
}

bind -m emacs-standard '"\C-t": " \C-b\C-k \C-utigstatus\e\C-e\er\C-m\C-y\C-a\e \C-y\ey\C-x\C-x\C-d"'
bind -m vi-command '"\C-t": "\C-z\C-t\C-z"'
bind -m vi-insert '"\C-t": "\C-z\C-t\C-z"'


notational ()
{
  rg "" ~/notational \
      --follow \
      --smart-case \
      --line-number \
      --color never \
      --no-messages \
      --no-heading  \
    | fzf \
      --preview='echo {} \
                  | cut -d: -f1,2 --output-delimiter=" " \
                  | xargs print_lines.py ' \
      --ansi \
      --multi \
      --exact \
      --inline-info \
      --delimiter=: \
    | cut -d: -f1 \
    | xargs -I '{}' kak -e 'delete-buffer *stdin*' '{}'

}

bind -m emacs-standard '"\C-g": " \C-b\C-k \C-unotational\e\C-e\er\C-m\C-y\C-a\e \C-y\ey\C-x\C-x\C-d"'
bind -m vi-command '"\C-g": "\C-z\C-g\C-z"'
bind -m vi-insert '"\C-g": "\C-z\C-g\C-z"'

# completion for justfiles
_just() {
    local i cur prev opts cmds
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cmd=""
    opts=""

    for i in ${COMP_WORDS[@]}
    do
        case "${i}" in
            "$1")
                cmd="just"
                ;;
            *)
                ;;
        esac
    done

    case "${cmd}" in
        just)
            opts=" -q -u -v -e -l -h -V -f -d -c -s  --check --dry-run --highlight --no-dotenv --no-highlight --quiet --shell-command --clear-shell-args --unsorted --unstable --verbose --changelog --choose --dump --edit --evaluate --fmt --init --list --summary --variables --help --version --chooser --color --dump-format --list-heading --list-prefix --justfile --set --shell --shell-arg --working-directory --command --completions --show --dotenv-filename --dotenv-path  <ARGUMENTS>... "
                if [[ ${cur} == -* ]] ; then
                    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
                    return 0
                elif [[ ${COMP_CWORD} -eq 1 ]]; then
                    local recipes=$(just --summary --color never 2> /dev/null)
                    if [[ $? -eq 0 ]]; then
                        COMPREPLY=( $(compgen -W "${recipes}" -- "${cur}") )
                        return 0
                    fi
                fi
            case "${prev}" in
                
                --chooser)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --color)
                    COMPREPLY=($(compgen -W "auto always never" -- "${cur}"))
                    return 0
                    ;;
                --dump-format)
                    COMPREPLY=($(compgen -W "just json" -- "${cur}"))
                    return 0
                    ;;
                --list-heading)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --list-prefix)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --justfile)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                    -f)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --set)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --shell)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --shell-arg)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --working-directory)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                    -d)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --command)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                    -c)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --completions)
                    COMPREPLY=($(compgen -W "zsh bash fish powershell elvish" -- "${cur}"))
                    return 0
                    ;;
                --show)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                    -s)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --dotenv-filename)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                --dotenv-path)
                    COMPREPLY=($(compgen -f "${cur}"))
                    return 0
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        
    esac
}
complete -F _just -o bashdefault -o default just

alias k=kak
alias z=zellij
alias t=tig
alias g=git
alias l='ls -lah'
alias gw='git commit -m wip'

if [ -f "$HOME"/.nix-profile/etc/profile.d/nix.sh ]; then
   . "$HOME"/.nix-profile/etc/profile.d/nix.sh
fi
# Generated by Groq bootstrap; START; DO NOT EDIT.
source $HOME/.config/groq-bootstrap/groq-bootstrap.bash
# Generated by Groq bootstrap; END; DO NOT EDIT.

. "$HOME/.local/bin/env"

export GROQ_API_KEY=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
