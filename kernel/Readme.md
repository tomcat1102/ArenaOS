# 如何用Python测试kernel timer是否准确？
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;今天我提交了3个commit，一个处理键盘输入中断，一个读取CMOS用于确定开机时间，最后一个设置timer中断。
前面几个commit还好，关键是最有一个有点难。虽然设置时间中断不难本身，但如何确定时间中断是否就是10ms有点棘手。这个间隔对于OS十分重要（否则会影响后面的任务运行，各种时间调度）。
具体地，我设置硬件timer每隔0.01(10ms)发送一个中断信号，这个间隔相当于OS的heartbeat，系统按照这个频率运行。

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;接着测试，我发现用GDB调试时，给timer_interrupt打断点，先break在continue，没问题，但我不知道这个期间时间过了多少、是否是10ms。
而且一次continue太短，于是我测试了continue 10000次 (这个应该运行10000 * 10ms = 100s)，并同时用手机计时，结束时发现运行了100s多一点。
心里有点高兴，应该没错。  
  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;不过这肯定有误差，而且太不严谨，于是想在输入continue 10000之前，先获得一个start时间，结束后再获得一个end时间，
两者之差便是运行时间，但输命令也会耗时间（至少获得end时间需要一定的敲键盘的时间）。于是我想把命令都写在一起，类似 get_start; continue 10000; get_end
不过发现gdb竟然不支持。我查了查，发现可以gdb定义函数，于是就自己摸索着些写了个python的gdb自定义函数。

`define test_100s`  
`break timer_interrupt`  
`continue`  
`python import time`  
`python start = time.time()`  
`continue 10000`  
`python print (time.time() - start)`  
`end`  
  
 然后`(gdb)> test_100s`，就开始呼呼的跑



&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;这样就可以得出10000次时间中断到底经历了多久，最后结果是102.6499729156....考虑到gdb断点自身也对时间有影响而且os运行在qemu中，这个结果还不错哦。
即使是最坏情况，10ms的间隔平均最多也会3%的时间误差。
# 总结
其实不用python也行，用date命令也行，只是感觉还是python方便些。总得来说，其实我GDB调试的时间要比写(copy)代码的时间多得多，因为各种难以理解的Bug都可能发生，
而且好多次一个Bug都能卡住我一天，还有些不是bug的bug，各种编译问题，几次都不想写了，觉得这些对于了解OS够多了。不过还好最后都解决了，继续努力吧~
