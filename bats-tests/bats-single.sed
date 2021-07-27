#!/usr/bin/env -S sed -n -f

1,/^\@test/ {x; 1d; p;}
/^\@test \"TEST_CASE\" {/,/^}/ p;
