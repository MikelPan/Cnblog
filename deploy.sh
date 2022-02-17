#!/usr/bin/env sh

# If a command fails then the deploy stops
#set -e

push_code() {
	printf "\033[0;32mDeploying updates to code...\033[0m\n"

	# Add changes to git.
	git pull
	git add .

	# Commit changes.
	commit_time="$(date)"
	if [ -n "$*" ]
	then
	    echo 'ok!'
		msg="$*"
	fi
	git commit -m "$msg $commit_time"

	# Push source and build repos.
	git push origin master
    git push mayun master
    git push gitea master
}



main() {
	push_code $1
}

main "$*"