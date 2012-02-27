#!/bin/sh
#
# This is a git update hook that assigns each commit a monotonically increasing local revision number.
# The revision number is stored as a git note.  To see them, do "git log --show-notes=\*"
#
# Called by "git receive-pack" with arguments: refname sha1-old sha1-new
#
# To enable this hook, rename this file to "update".

NOTE_REF=localRevision
NEXTREV_REF=localRevisionNextRev
# This magic number is an empty tree object that exists in every git repo.  We store the
# next revision number as a note on it.  It is mentioned in the sample pre-commit hook.
NEXTREV_STORAGE=4b825dc642cb6eb9a060e54bf8d69288fbee4904

# --- Error checking
set -u  # No undefined variables
set -e  # Immediate exit on error

# --- Command line
refname="$1"
oldrev="$2"
newrev="$3"

# --- Safety check
if [ -z "$GIT_DIR" ]; then
	echo "Don't run this script from the command line." >&2
	echo " (if you want, you could supply GIT_DIR then run" >&2
	echo "  $0 <ref> <oldrev> <newrev>)" >&2
	exit 1
fi

if [ -z "$refname" -o -z "$oldrev" -o -z "$newrev" ]; then
	echo "Usage: $0 <ref> <oldrev> <newrev>" >&2
	exit 1
fi

# --- Check types
# if $newrev is 0000...0000, it's a commit to delete a ref.
zero="0000000000000000000000000000000000000000"
if [ "$newrev" = "$zero" ]; then
	exit 0
fi

# --- Mutex
theDir=`pwd`
repoID=`basename $theDir`
lockdir="/tmp/git/git-update-hook-$repoID.lock"
mkdir -p /tmp/git
TRIES=10
for (( i = 1; i <= $TRIES; i++ )); do
	if mkdir "$lockdir"; then
		# Remove lockdir when the script finishes, or when it receives a signal
		trap 'rm -rf "$lockdir"' EXIT INT TERM
		break
	else
		if [[ $i == $TRIES ]]; then
			echo >&2 "Please try again later (cannot acquire lock, giving up on $lockdir)"
			exit 1
		fi
		echo "Waiting for lock at: $lockdir"
		sleep 1
	fi
done

# --- Let's get to work

parent_commits () {
	echo `git cat-file commit $1 | grep '^parent ' | cut -f 2 -d ' '`
}

makeNextRevision () {
	# We store the next revision number as a note on the empty tree.
	# This is kind of an expensive way to store one int -- it keeps the history
	# of every value it's been!  Maybe I should just keep it in a file somewhere.
	x=`git notes --ref $NEXTREV_REF show $NEXTREV_STORAGE` > /dev/null 2>&1 || x=1
	if (( x % 10 == 9 )); then git update-ref -d refs/notes/$NEXTREV_REF; fi  # clear the history
	git notes --ref $NEXTREV_REF add -f $NEXTREV_STORAGE -m $((x+1)) > /dev/null 2>&1
	echo $x
}

# Yo dawg I herd you like functions
setLocalRevision () {
	local commit=$1
	#echo "Working on $commit"
	# If there's already a revision set, return
	git notes --ref $NOTE_REF show $commit > /dev/null 2>&1 && return

	# Update all parents, then self
	for parent in `parent_commits $commit`; do
		setLocalRevision $parent
	done

	next=`makeNextRevision`
	echo "Revision $next is $refname:$commit"
	git notes --ref $NOTE_REF add $commit -m $next > /dev/null
}

# If you want to clear out your revision numbers
# deleteRevisions () {
# 	# This is the hard way
# 	# for commit in `git log --pretty='format:%H' --branches`; do
# 	# 	git notes --ref $NOTE_REF remove $commit
# 	# done
# 	# git notes --ref $NEXTREV_REF remove $NEXTREV_STORAGE

# 	# And this is the easy way
# 	git update-ref -d refs/notes/$NOTE_REF
# 	git update-ref -d refs/notes/$NEXTREV_REF
# }
# deleteRevisions

setLocalRevision $newrev

# --- Finished
exit 0
