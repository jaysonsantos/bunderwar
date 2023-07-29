#!/bin/bash
set -eo pipefail
START_DIR="$PWD"

filter_earthly() {
    xargs -n1 dirname | sort -u | uniq | grep ^earthly/
}

get_changed_directories() {
    git ls-files -m | filter_earthly
}

get_added_directories() {
    git ls-files --others --exclude-standard | filter_earthly
}

commit_directory() {
    local dirname
    dirname="$(basename "$1")"
    git checkout main
    git checkout -b "$dirname"
    git add "$1"
    git commit -m"chore: $2 $dirname"
    git push -f origin "$dirname"
}

process_directories() {
    if [ "$2" == "" ]; then
        echo "No changes detected"
        return 0
    fi
    echo -E "$2" | while read -r directory; do
        commit_directory "$directory" "$1"
        gh pr create -f -B main
        echo -e "---------------------------------------------------------------------\n"
    done
}


main() {
    cd "$START_DIR" || exit 1
    process_directories "Update" "$(get_changed_directories)"    
    process_directories "Add" "$(get_added_directories)"    
}

main