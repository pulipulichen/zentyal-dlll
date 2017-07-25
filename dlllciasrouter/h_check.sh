cd ~/zentyal-dlll/dlllciasrouter
#perl -c src/EBox/*.pm
#perl -c src/EBox/*/Model/*.pm
#perl -c src/EBox/*/Composite/*.pm

#FILES="src/EBox/*.pm
#src/EBox/*/Model/*.pm
#src/EBox/*/Composite/*.pm"
#for f in $FILES
#do
#	perl -c $f
#done

echo "[h_check.sh] Start check pm files' syntax"

find src/EBox/dlllciasrouter/Model/*.pm -mtime -0.02 -exec perl -c {} \;
find src/EBox/dlllciasrouter/Composite/*.pm -mtime -0.02 -exec perl -c {} \;
find src/EBox/*.pm -mtime -0.02 -exec perl -c {} \;