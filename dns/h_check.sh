cd ~/zentyal-dlll/dns
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

find src/EBox/DNS/Model/*.pm -mtime -0.02 -exec perl -c {} \;
find src/EBox/DNS/Composite/*.pm -mtime -0.02 -exec perl -c {} \;
find src/EBox/*.pm -mtime -0.02 -exec perl -c {} \;