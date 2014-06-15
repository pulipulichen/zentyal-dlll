cd ~/dlllciasrouter
#perl -c src/EBox/*.pm
#perl -c src/EBox/*/Model/*.pm
#perl -c src/EBox/*/Composite/*.pm

FILES="src/EBox/*.pm
src/EBox/*/Model/*.pm
src/EBox/*/Composite/*.pm"
for f in $FILES
do
	perl -c $f
done