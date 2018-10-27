if [ -z "$GIT_BRANCH" ]; then GIT_BRANCH=origin/master; fi
if [ -z "$GIT_PATH" ]; then GIT_PATH=~/zentyal-dlll; fi

#echo $GIT_PATH

cd $GIT_PATH
git --git-dir="$GIT_PATH"/.git clean -f -d
git --git-dir="$GIT_PATH"/.git reset --hard "$GIT_BRANCH"
#git --git-dir="$GIT_PATH"/.git pull --rebase --force master
git --git-dir="$GIT_PATH"/.git pull

git --git-dir="$GIT_PATH"/.git merge "$GIT_BRANCH" --no-commit

#chmod +x "$GIT_PATH"/*.sh
chmod +x "$GIT_PATH"/\*/*.sh