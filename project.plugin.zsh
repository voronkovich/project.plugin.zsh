#!/usr/bin/env zsh

PROJECTS="${PROJECTS:-$HOME/projects}";
PROJECTS_TMP="${PROJECTS_TMP:-/tmp/${USER}_projects}";
PROJECTS_RECIPES="${PROJECTS_RECIPES:-${PROJECTS}/.recipes}";

hash -d p="$PROJECTS";
hash -d pt="$PROJECTS_TMP";

function p() {
    zparseopts -D -E {h,-help}=help {t,-temporary}=tmp {l,-list}=list {r,-recipe}:=recipe

    [[ $? -gt 0 ]] && return $?;

    if [[ -n $help ]]; then
        echo -en "
\e[32mProject manager\e[0m (\e[96m${PROJECTS}\e[0m)

\e[33mUsage:\e[0m

\e[32mp\e[0m [options] [project_name]

\e[33mOptions:\e[0m

    \e[32m-h, --help\e[0m       Display this help message
    \e[32m-l, --list\e[0m       List all existing projects
    \e[32m-r, --recipe\e[0m     Use recipe (\e[96m${PROJECTS_RECIPES}\e[0m)
    \e[32m-t, --temporary\e[0m  Use temporary dir (\e[96m${PROJECTS_TMP}\e[0m)

\e[33mExamples:\e[0m

    \e[37m# Creates a new project (if it doesn't exists yet) with a name \"symfony-app\" in the \"${PROJECTS}\"
    # and changes the current working dir to the \"${PROJECTS}/symfony-app\"\e[0m
    \e[32mp\e[0m symfony-app

    \e[37m# Creates a new temporary project with a name \"play-with-webpack\" in the \"${PROJECTS_TMP}\"\e[0m
    \e[32mp\e[0m -t play-with-webpack

    \e[37m# Creates a new project by cloning a repo\e[0m
    \e[32mp\e[0m https://github.com/zsh-users/zsh-completions.git
    \e[32mp\e[0m -t ohmyzsh https://github.com/robbyrussell/oh-my-zsh.git

    \e[37m# Lists all temporary projects\e[0m
    \e[32mp\e[0m -tl
"
        return 0;
    fi

    if [[ -n $tmp ]]; then
        local dir="${PROJECTS_TMP}";
    else
        local dir="$PROJECTS";
    fi

    if [[ -n $list ]]; then
        ls "$dir";
        return 0;
    fi

    local name="$1";
    if [[ "$name" =~ '^git@|https?://' ]]; then
        local repo="$name";
        local name="${${repo##*/}%.git}";
    else
        local repo="$2";
    fi

    [[ ! -d "$dir/$name" ]] && mkdir -p "$dir/$name";
    cd "$dir/$name";

    [[ -n "$repo" ]] && git clone "$repo" "$dir/$name";

    if [[ -n "$recipe" ]]; then
        if [[ ! -n "$name" ]]; then
            echo -e "\e[31mYou can't use the recipes when the project name is not specified." >&2;
        else
            "$PROJECTS_RECIPES/${recipe[2]}";
        fi
    fi

    return 0;
}

function _p() {
    local curcontext="$curcontext" context state state_descr line ret=1;
    typeset -A opt_args

    _arguments -s -A '-h' -A '--help' \
        '(-h --help)'{-h,--help}'[Show help]' \
        '(-l --list)'{-l,--list}'[List all existing projects]' \
        '(-r --recipe)'{-r,--recipe}"[Use recipe]:recipe:_files -W ${PROJECTS_RECIPES}" \
        '(-t --temporary)'{-t,--temporary}"[Use temporary dir (${PROJECTS_TMP})]" \
        "::project name:_files -W ${PROJECTS}" \
    && ret=0;

    return ret;
}

compdef _p p;
