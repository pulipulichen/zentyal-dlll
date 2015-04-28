if [ -z "$GIT_BRANCH" ]; then GIT_BRANCH=kals/master; fi
if [ -z "$GIT_PATH" ]; then GIT_PATH=/var/www/moodle/kals; fi

#echo $GIT_PATH

cd $GIT_PATH
git --git-dir="$GIT_PATH"/.git clean -f -d
git --git-dir="$GIT_PATH"/.git reset --hard "$GIT_BRANCH"
git --git-dir="$GIT_PATH"/.git pull --rebase --force kals

git --git-dir="$GIT_PATH"/.git merge "$GIT_BRANCH" --no-commit
