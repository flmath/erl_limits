%%% @author Mathias Green <flmath@fedora>

%%% @copyright (C) 2022, Mathias Green
%%% Created : 25 Nov 2022 by Mathias Green <flmath@fedora>
%%% Todays show is sponsored by function phash2(Term).


-module(erl_limits).
-export([process_test/0,
	 process_test_heap_link/0,
	 process_opt_test/0,
	 exponential_process/2,
	 process_test_no_limit/0]).

-export([printable_range/0]).


process_opt_test() ->
    WS = erlang:system_info(wordsize),
    SNAME = catch init:get_argument(sname),
    T = erlang:memory(total),
    P = erlang:memory(processes),
    S = erlang:memory(system),
    U = erlang:memory(processes_used),
    Ports = erlang:ports(),
    {WS, {T, P, S, U}, SNAME,Ports}.


process_test() ->
    spawn(?MODULE, exponential_process, [100, self()]),    
    R1 = receive_message(),
    %% erlang:process_display(self(), backtrace),
    R1.


%%https://www.erlang.org/doc/efficiency_guide/advanced.html

%% erlang:system_info(wordsize) * 8 bit architecture
%%Small integer 	1 word.
%%On 32-bit architectures: -134217729 < i < 134217728 (28 bits).
%% Large integer 	3..N words.
%%On 64-bit architectures: -576460752303423489 < i < 576460752303423488 (60 bits).


%%Processes
%%5The maximum number of simultaneously alive Erlang processes is by default 262,144.
%%5This limit can be configured at startup.
%%For more information, see the +P command-line flag in the erl(1) manual page in ERTS.

process_test_heap_link() ->
    WS = erlang:system_info(wordsize),
    %IntStepSize = 2 + power(2, 8*WS-4),
    process_flag(trap_exit, true),

    spawn(?MODULE, exponential_process, [1, self()]),  
  
    [_, _, _, {heap_size, HZ}] = receive_message(),   
    R1 = receive_message(),


    spawn_opt(?MODULE, exponential_process,
	      [1, self()], [link, {max_heap_size, 234 }]),
    R2 = receive_message(),
    R3 = receive_message(),
    R4 = receive_message(),
 
    spawn_opt(?MODULE, exponential_process,
	      [7*4*WS, self()], [link,  {min_heap_size, 10 }, {max_heap_size, 233 }]), %erl +hmax
    R5 = receive_message(),
    R6 = receive_message(),
    R7 = receive_message(),

    {R1, HZ,  R2, R3, R4, R5, R6, R7 }.


%% erl_limits:process_test_heap_link().
%% {2,233,
%%  [{current_function,{erl_limits,print_proces_info,1}},
%%   {stack_size,6},
%%   {total_heap_size,233},
%%   {heap_size,233}],
%%  2,
%%  {'EXIT',<0.210.0>,normal},
%%  [{current_function,{erl_limits,print_proces_info,1}},
%%   {stack_size,6},
%%   {total_heap_size,233},
%%   {heap_size,233}],
%%  26959946667150639794667015087019630673637144422540572481103610249216,
%%  {'EXIT',<0.211.0>,normal}}
%% =ERROR REPORT==== 26-Nov-2022::15:12:22.262509 ===
%%      Process:            <0.211.0> 
%%      Context:            maximum heap size reached
%%      Max Heap Size:      233
%%      Total Heap Size:    261
%%      Kill:               true
%%      Error Logger:       true
%%      Message Queue Len:  0
%%      GC Info:            [{old_heap_block_size,0},
%%                           {heap_block_size,466},
%%                           {mbuf_size,0},
%%                           {recent_size,0},
%%                           {stack_size,203},
%%                           {old_heap_size,0},
%%                           {heap_size,28},
%%                           {bin_vheap_size,0},
%%                           {bin_vheap_block_size,46422},
%%                           {bin_old_vheap_size,0},
%%                           {bin_old_vheap_block_size,46422}]

process_test_no_limit() ->
    process_flag(trap_exit, true),

    Proc =  erlang:system_info(process_limit), %erl +P

    [spawn_link(?MODULE, exponential_process, [1, self()]) ||
	_ <- lists:seq(1, Proc+21)],
    receive
	M = {'EXIT',_,_ } -> io:format("~p~n",[M])
    end.
	    
  
%% ** exception error: a system limit has been reached
%%      in function  spawn_link/3
%%         called as spawn_link(erl_limits,exponential_process,[1,<0.503.8>])



exponential_process(P, Pid) ->
    print_proces_info(Pid),
    BigNum  = power(2, P),
    Pid ! BigNum.

power(B,1) -> B;
power(B,P) ->
    B * power(B,P-1).    

receive_message()->  
    receive
	Message -> Message
    after 
	5000 -> too_long	 
    end.	

print_proces_info(Pid) ->
    PI = erlang:process_info(self(),
			     [current_function,
			      stack_size,
			      total_heap_size,
			      heap_size
			     ]),
    Pid ! PI,
    timer:sleep(1600).

printable_range() -> io:printable_range(). 


%term_to_iovec(Term)
