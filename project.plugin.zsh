PROJECTS="${PROJECTS:-$HOME/projects}"
PROJECTS_TMP="${PROJECTS_TMP:-/tmp/${USER}_projects}"
PROJECTS_RECIPES="${PROJECTS_RECIPES:-${PROJECTS}/.recipes}"

hash -d p="${PROJECTS}"
hash -d pt="${PROJECTS_TMP}"

alias p='project'

project() {
    local opt opt_help opt_tmp opt_list opt_recipe

    zparseopts -D \
        {h,-help}=opt_help \
        {t,-temporary}=opt_tmp \
        {l,-list}=opt_list \
        {r,-recipe}:=opt_recipe \
        || return 1

    for opt; do
        if [[ "${opt[1]}" == '-' ]]; then
            echo "Unknown option: ${opt}." >&2
            return 1
        fi
    done

    if [[ -n "${opt_recipe}" && "${opt_recipe[2][1]}" == '-' ]]; then
        echo "Recipe option requires a value." >&2
        return 1
    fi

    if [[ -n "${opt_help}" ]]; then
        __project_help
        return
    fi

    local projects_dir="${PROJECTS}"
    if [[ -n "${opt_tmp}" ]]; then
        projects_dir="${PROJECTS_TMP}"
    fi

    if [[ -n "${opt_list}" ]]; then
        ls "${projects_dir}"
        return
    fi

    local name="${1}"
    local repo="${2}"
    if [[ "${name}" =~ '^git@|https?://' ]]; then
        repo="${name}"
        name="${${repo##*/}%.git}"
    fi

    local recipe
    if [[ -n "${opt_recipe}" ]]; then
        recipe="${opt_recipe[2]}"

        if [[ ! -n "${name}" ]]; then
            echo "You can't use the recipes when the project name is not specified." >&2
            return 1
        fi

        if [[ ! -x "${PROJECTS_RECIPES}/${recipe}" ]]; then
            echo "Recipe \"${recipe}\" is not exist or not executable." >&2
            return 1
        fi
    fi

    if [[ ! -d "${projects_dir}/${name}" ]]; then
        mkdir -p "${projects_dir}/${name}"
    fi

    cd "${projects_dir}/${name}"

    if [[ -n "${repo}" ]]; then
        git clone "${repo}" "${projects_dir}/${name}"
    fi

    if [[ -n "${recipe}" ]]; then
        "${PROJECTS_RECIPES}/${recipe}"
    fi
}

__project_help() {
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
}

_project() {
    local context state state_descr line ret=1
    local -A opt_args

    _arguments -s -A '-h' -A '--help' \
        '(-h --help)'{-h,--help}'[Show help]' \
        '(-l --list)'{-l,--list}'[List all existing projects]' \
        '(-r --recipe)'{-r,--recipe}"[Use recipe (${PROJECTS_RECIPES})]:recipe:_files -W ${PROJECTS_RECIPES}" \
        '(-t --temporary)'{-t,--temporary}"[Create temporary project (${PROJECTS_TMP})]" \
        "::project name:->project" \
    && ret=0

    if [[ "${state}" == 'project' ]]; then
        if [[ "${words}" =~ '\s-\w*t' ]]; then
            _files -W "${PROJECTS_TMP}"
        else
            _files -W "${PROJECTS}"
        fi
    fi

    return ret
}

compdef _project project
