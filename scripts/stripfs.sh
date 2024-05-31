
# TODO: set arch specific -strip

find ./root -type f | xargs file 2>/dev/null | grep "LSB executable"     | cut -f 1 -d : | xargs i686-linux-gnu-strip --strip-all      2>/dev/null || true
find ./root -type f | xargs file 2>/dev/null | grep "shared object"      | cut -f 1 -d : | xargs i686-linux-gnu-strip --strip-unneeded 2>/dev/null || true
find ./root -type f | xargs file 2>/dev/null | grep "current ar archive" | cut -f 1 -d : | xargs i686-linux-gnu-strip --strip-debug	   2>/dev/null || true
