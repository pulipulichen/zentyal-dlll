if [ -d "~/zentyal-dlll/dlllciasrouter" ]; then
  cd ~/zentyal-dlll/dlllciasrouter
fi

if [ -d "zentyal-dlll/dlllciasrouter" ]; then
  cd zentyal-dlll/dlllciasrouter
fi

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

echo "[h_check.sh] Check syntax Start"
echo "---------------------------------------"

find src/EBox/dlllciasrouter/Model/*.pm -mtime -0.02 -exec perl -c {} \;
find src/EBox/dlllciasrouter/Composite/*.pm -mtime -0.02 -exec perl -c {} \;
find src/EBox/*.pm -mtime -0.02 -exec perl -c {} \;