#!/usr/bin/env zsh

PROJECTS="${PROJECTS:-$HOME/projects}";
PROJECTS_TMP="${PROJECTS_TMP:-/tmp/${USER}_projects}";
PROJECTS_RECIPES="${PROJECTS_RECIPES:-${PROJECTS}/.recipes}";

hash -d p="$PROJECTS";
hash -d pt="$PROJECTS_TMP";

function p() {
    zparseopts -D {h,-help}=help {t,-temporary}=tmp {l,-list}=list {r,-recipe}:=recipe || return 1;

    for o in $@; do
        if [[ ${o[1]} == '-' ]]; then
            echo "Unknown option: $o." >&2;
            return 1;
        fi
    done;
    if [[ -n $recipe && ${recipe[2][1]} == '-' ]]; then
        echo "Recipe option requires a value." >&2;
        return 1;
    fi

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

    \e[37m# Creates a new project using a \"rails\" recipe. See \"${PROJECTS_RECIPES}\"\e[0m
    \e[32mp\e[0m -r rails my-app

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

    if [[ -n "$recipe" ]]; then
        recipe=$recipe[2];

        if [[ ! -n "$name" ]]; then
            echo "You can't use the recipes when the project name is not specified." >&2;
            return 1;
        fi

        if [[ ! -x "$PROJECTS_RECIPES/$recipe" ]]; then
            echo "Recipe \"$recipe\" is not exist or not executable." >&2;
            return 1;
        fi
    fi

    [[ ! -d "$dir/$name" ]] && mkdir -p "$dir/$name";
    cd "$dir/$name";

    [[ -n "$repo" ]] && git clone "$repo" "$dir/$name";

    if [[ -n "$recipe" ]]; then
        "$PROJECTS_RECIPES/$recipe";
    fi

    return 0;
}

function _p() {
    local context state state_descr line ret=1;
    typeset -A opt_args

    _arguments -s -A '-h' -A '--help' \
        '(-h --help)'{-h,--help}'[Show help]' \
        '(-l --list)'{-l,--list}'[List all existing projects]' \
        '(-r --recipe)'{-r,--recipe}"[Use recipe (${PROJECTS_RECIPES})]:recipe:_files -W ${PROJECTS_RECIPES}" \
        '(-t --temporary)'{-t,--temporary}"[Create temporary project (${PROJECTS_TMP})]" \
        "::project name:->project" \
    && ret=0;

    if [[ "$state" == 'project' ]]; then
        if [[ "$words" =~ '\s-\w*t' ]]; then
            _files -W "${PROJECTS_TMP}";
        else
            _files -W "${PROJECTS}";
        fi
    fi

    return ret;
}

compdef _p p;
