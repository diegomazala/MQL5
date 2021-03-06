<chart>
id=130652731570823993
symbol=WINJ19
period_type=0
period_size=5
tester=1
digits=0
tick_size=5.000000
position_time=1551198900
scale_fix=0
scale_fixed_min=97455.000000
scale_fixed_max=98545.000000
scale_fix11=0
scale_bar=0
scale_bar_val=1.000000
scale=16
mode=1
fore=0
grid=0
volume=0
scroll=0
shift=0
shift_size=17.878529
fixed_pos=0.000000
ohlc=1
one_click=0
one_click_btn=1
bidline=1
askline=0
lastline=1
days=1
descriptions=0
tradelines=1
window_left=0
window_top=0
window_right=793
window_bottom=799
window_type=1
floating=0
floating_left=331
floating_top=55
floating_right=1929
floating_bottom=694
floating_type=1
floating_toolbar=1
floating_tbstate=
background_color=0
foreground_color=16777215
barup_color=65280
bardown_color=255
bullcandle_color=65280
bearcandle_color=255
chartline_color=65280
volumes_color=3329330
grid_color=10061943
bidline_color=10061943
askline_color=255
lastline_color=49152
stops_color=255
windows_total=3

<window>
height=118.581340
objects=24

<indicator>
name=Main
path=
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1
</indicator>

<indicator>
name=Moving Average
path=
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1

<graph>
name=
draw=129
style=0
width=1
arrow=251
color=16776960
</graph>
period=3
method=0
</indicator>

<indicator>
name=Custom Indicator
path=Indicators\Examples\ZigzagColor.ex5
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=4
fixed_height=-1

<graph>
name=ZigzagColor
draw=15
style=0
width=1
arrow=251
color=16776960,55295
</graph>
<inputs>
ExtDepth=20
ExtDeviation=8
ExtBackstep=3
</inputs>
</indicator>

<indicator>
name=Bollinger Bands
path=
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1

<graph>
name=
draw=131
style=0
width=1
arrow=251
color=13828244
</graph>

<graph>
name=
draw=131
style=0
width=1
arrow=251
color=13828244
</graph>

<graph>
name=
draw=131
style=0
width=1
arrow=251
color=13828244
</graph>
period=8
deviation=2.000000
</indicator>
<object>
type=31
name=autotrade #2 buy 100.00 WDOH19 at 3738.000
color=11296515
selectable=0
date1=1549875600
value1=3738.000000
</object>

<object>
type=32
name=autotrade #3 sell 100.00 WDOH19 at 3737.500
descr=sl 3737.500
color=1918177
selectable=0
date1=1549875620
value1=3737.500000
</object>

<object>
type=32
name=autotrade #4 sell 100.00 WDOH19 at 3760.500
color=1918177
selectable=0
date1=1549908000
value1=3760.500000
</object>

<object>
type=31
name=autotrade #5 buy 100.00 WDOH19 at 3760.500
descr=tp 3760.500
color=11296515
selectable=0
date1=1549908020
value1=3760.500000
</object>

<object>
type=31
name=autotrade #6 buy 100.00 WDOH19 at 3725.000
color=11296515
selectable=0
date1=1550052000
value1=3725.000000
</object>

<object>
type=32
name=autotrade #7 sell 100.00 WDOH19 at 3724.500
descr=sl 3724.500
color=1918177
selectable=0
date1=1550052020
value1=3724.500000
</object>

<object>
type=32
name=autotrade #8 sell 100.00 WDOH19 at 3765.000
color=1918177
selectable=0
date1=1550152800
value1=3765.000000
</object>

<object>
type=31
name=autotrade #9 buy 100.00 WDOH19 at 3765.500
descr=sl 3765.500
color=11296515
selectable=0
date1=1550152820
value1=3765.500000
</object>

<object>
type=2
name=autotrade #2 -> #3
descr=3738.000 -> 3737.500
color=11296515
style=2
selectable=0
date1=1549875600
date2=1549875620
value1=3738.000000
value2=3737.500000
</object>

<object>
type=2
name=autotrade #4 -> #5
descr=3760.500 -> 3760.500
color=1918177
style=2
selectable=0
date1=1549908000
date2=1549908020
value1=3760.500000
value2=3760.500000
</object>

<object>
type=2
name=autotrade #6 -> #7
descr=3725.000 -> 3724.500
color=11296515
style=2
selectable=0
date1=1550052000
date2=1550052020
value1=3725.000000
value2=3724.500000
</object>

<object>
type=2
name=autotrade #8 -> #9
descr=3765.000 -> 3765.500
color=1918177
style=2
selectable=0
date1=1550152800
date2=1550152820
value1=3765.000000
value2=3765.500000
</object>

<object>
type=31
name=autotrade #2 buy 50.00 WINJ19 at 97810
color=11296515
selectable=0
date1=1550570400
value1=97810.000000
</object>

<object>
type=32
name=autotrade #3 sell 50.00 WINJ19 at 98810
descr=tp 98810
color=1918177
selectable=0
date1=1550579360
value1=98810.000000
</object>

<object>
type=32
name=autotrade #4 sell 50.00 WINJ19 at 98430
color=1918177
selectable=0
date1=1550664000
value1=98430.000000
</object>

<object>
type=31
name=autotrade #5 buy 50.00 WINJ19 at 98470
descr=sl 98470
color=11296515
selectable=0
date1=1550675620
value1=98470.000000
</object>

<object>
type=2
name=autotrade #2 -> #3
descr=97810 -> 98810
color=11296515
style=2
selectable=0
date1=1550570400
date2=1550579360
value1=97810.000000
value2=98810.000000
</object>

<object>
type=2
name=autotrade #4 -> #5
descr=98430 -> 98470
color=1918177
style=2
selectable=0
date1=1550664000
date2=1550675620
value1=98430.000000
value2=98470.000000
</object>

<object>
type=32
name=autotrade #2 sell 100.00 WINJ19 at 98550
color=1918177
selectable=0
date1=1551189960
value1=98550.000000
</object>

<object>
type=31
name=autotrade #3 buy 100.00 WINJ19 at 98575
descr=sl 98575
color=11296515
selectable=0
date1=1551190360
value1=98575.000000
</object>

<object>
type=31
name=autotrade #4 buy 100.00 WINJ19 at 98305
color=11296515
selectable=0
date1=1551198960
value1=98305.000000
</object>

<object>
type=32
name=autotrade #5 sell 100.00 WINJ19 at 98435
descr=sl 98435
color=1918177
selectable=0
date1=1551200680
value1=98435.000000
</object>

<object>
type=2
name=autotrade #2 -> #3
descr=98550 -> 98575
color=1918177
style=2
selectable=0
date1=1551189960
date2=1551190360
value1=98550.000000
value2=98575.000000
</object>

<object>
type=2
name=autotrade #4 -> #5
descr=98305 -> 98435
color=11296515
style=2
selectable=0
date1=1551198960
date2=1551200680
value1=98305.000000
value2=98435.000000
</object>

</window>

<window>
height=50.000000
objects=0

<indicator>
name=Custom Indicator
path=Indicators\Examples\DidiIndex.ex5
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=1.000100
scale_fix_min=0
scale_fix_min_val=0.992180
scale_fix_max=0
scale_fix_max_val=1.008020
expertmode=0
fixed_height=-1

<graph>
name=Fast Line
draw=1
style=0
width=1
arrow=251
color=16776960
</graph>

<graph>
name=Mean Line
draw=1
style=0
width=1
arrow=251
color=16777215
</graph>

<graph>
name=Slow Line
draw=1
style=0
width=1
arrow=251
color=55295
</graph>
<inputs>
Timeframe=0
Method=0
AppliedPrice=1
Shift=0
FastPeriod=3
MeanPeriod=8
SlowPeriod=20
</inputs>
</indicator>
</window>

<window>
height=50.000000
objects=0

<indicator>
name=Custom Indicator
path=Indicators\Examples\ADX.ex5
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=-2.971000
scale_fix_max=0
scale_fix_max_val=71.125000
expertmode=0
fixed_height=-1

<graph>
name=ADX(8)
draw=1
style=0
width=2
arrow=251
color=16777215
</graph>

<graph>
name=+DI
draw=1
style=2
width=2
arrow=251
color=16776960
</graph>

<graph>
name=-DI
draw=1
style=2
width=2
arrow=251
color=55295
</graph>

<level>
level=32.000000
style=2
color=12632256
width=1
descr=
</level>
<inputs>
InpPeriodADX=8
</inputs>
</indicator>

<indicator>
name=Custom Indicator
path=Indicators\Examples\ADXW.ex5
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=-2.490850
scale_fix_max=0
scale_fix_max_val=67.685850
expertmode=4
fixed_height=-1

<graph>
name=ADX Wilder(8)
draw=1
style=0
width=1
arrow=251
color=11119017
</graph>

<graph>
name=+DI
draw=1
style=2
width=1
arrow=251
color=16776960
</graph>

<graph>
name=-DI
draw=1
style=2
width=1
arrow=251
color=65535
</graph>
<inputs>
InpPeriodADXW=8
</inputs>
</indicator>
</window>
</chart>