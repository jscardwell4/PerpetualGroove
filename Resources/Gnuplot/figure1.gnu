set term qt persist size 447, 447
unset xtics
unset ytics
set margin 10, 10, 10, 10
unset key
set xrange [0:447]
set yrange [0:447]


set object 1 rectangle from graph 0, graph 0 to graph 447, graph 447 back
set object 1 rectangle fc rgb "#555350" fillstyle solid 1.0 border rgb "#555350"

set arrow 1 from 206.87, 143.281 to 286.157, 21 fc rgb "#3C3A39"
set object 2 circle at 206.87, 143.281 size 21
set object 2 circle fc rgb "#AE6140" fillstyle solid 1.0 border rgb "#555350"
set object 3 circle at 286.157, 21 size 21 
set object 3 circle fc rgb "#AE6140" fillstyle solid 1.0 border rgb "#555350"
set object 4 circle at 426, 236.501 size 21 
set object 4 circle fc rgb "#AE6140" fillstyle solid 1.0 border rgb "#555350"
set arrow 2 from 286.157, 21 to 426, 236.501  fc rgb "#3C3A39"
set object 5 circle at 303.034, 426 size 21 
set object 5 circle fc rgb "#AE6140" fillstyle solid 1.0 border rgb "#555350"
set arrow 3 from 426, 236.501 to 303.034, 426 fc rgb "#3C3A39"
set object 6 circle at 40.225, 21 size 21 
set object 6 circle fc rgb "#AE6140" fillstyle solid 1.0 border rgb "#555350"
set arrow 4 from 303.034, 426 to 40.225, 21 fc rgb "#3C3A39"

set label 1 "003:3.054" at 206.87, 143.281 center textcolor rgb "#E2D8C9" front
set label 2 "004:1.161" at 286.157, 21 center textcolor rgb "#E2D8C9" front
set label 3 "005:1.161" at 426, 236.501 center textcolor rgb "#E2D8C9" front
set label 4 "006:3.203" at 303.034, 426 center textcolor rgb "#E2D8C9" front
set label 5 "009:1.331" at 40.225, 21 center textcolor rgb "#E2D8C9" front

filter(min, max, value) = value>=min && value<=max ? value : 1/0
_f(x) = (-223.415 / 144.976) * (x - 206.87) + 143.281
f(x) = filter(21, 143.281, _f(x))
plot 1/0