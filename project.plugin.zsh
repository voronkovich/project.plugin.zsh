PROJECTS=${PROJECTS:-~/projects}
hash -d p=$PROJECTS

function p() {
    [[ -d $PROJECTS/$1 ]] && cd $PROJECTS/$1 || mkdir $PROJECTS/$1 && cd $PROJECTS/$1;
}

function _p() {
    _files -W $PROJECTS
}

compdef _p p
