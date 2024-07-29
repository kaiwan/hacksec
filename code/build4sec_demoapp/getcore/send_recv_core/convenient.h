/*
 * convenient.h
 *
 * A few convenience macros and routines..
 * Mostly for kernel-space usage, some for user-space as well.
 *
 * Author: Kaiwan N Billimoria <kaiwan@kaiwantech.com>
 * (c) Kaiwan NB, kaiwanTECH
 * Dual MIT/GPL.
 */
#ifndef __CONVENIENT_H__
#define __CONVENIENT_H__

#include <asm/param.h>		/* HZ */
#include <linux/sched.h>

#ifdef __KERNEL__
#include <linux/ratelimit.h>

/* 
   *** Note: PLEASE READ this documentation: ***

    We can reduce the load, and increase readability, by using the trace_printk
    instead of printk. To see the o/p do:
     # cat /sys/kernel/debug/tracing/trace

     If we insist on using the regular printk, lets at least rate-limit it.
	 For the programmers' convenience, this too is programatically controlled 
	  (by an integer var USE_RATELIMITING [default: On]).

 	*** Kernel module authors Note: ***
	To use the trace_printk(), pl #define the symbol USE_FTRACE_PRINT in your Makefile:
	EXTRA_CFLAGS += -DUSE_FTRACE_PRINT
	If you do not do this, we will use the usual printk() .

	To view :
	  printk's       : dmesg
      trace_printk's : cat /sys/kernel/debug/tracing/trace

	 Default: printk
 */
// keep this defined to use the FTRACE-style trace_printk(), else will use regular printk()
//#define USE_FTRACE_PRINT
#undef USE_FTRACE_PRINT

#ifdef USE_FTRACE_PRINT
#define DBGPRINT(string, args...) \
     trace_printk(string, ##args);
#else
#define DBGPRINT(string, args...) do {                             \
     int USE_RATELIMITING=0;                                       \
	 if (USE_RATELIMITING) {                                   \
	   printk_ratelimited (KERN_INFO pr_fmt(string), ##args);  \
	 }                                                         \
	 else                                                      \
           pr_info(pr_fmt(string), ##args);                        \
} while (0)
#endif
#endif				/* end ifdef __KERNEL__ at the top */

/*------------------------ MSG, QP ------------------------------------*/
#ifdef DEBUG
#ifdef __KERNEL__
#define MSG(string, args...) do {                                     \
	DBGPRINT("%s:%d : " string, __FUNCTION__, __LINE__, ##args);  \
} while (0)
#else
#define MSG(string, args...) do {                                           \
	fprintf(stderr, "%s:%d : " string, __FUNCTION__, __LINE__, ##args); \
} while (0)
#endif

#ifdef __KERNEL__
#define MSG_SHORT(string, args...) do {  \
	DBGPRINT(string, ##args);        \
} while (0)
#else
#define MSG_SHORT(string, args...) do {  \
	fprintf(stderr, string, ##args); \
} while (0)
#endif

// QP = Quick Print
#define QP MSG("\n")

#ifdef __KERNEL__
#define QPDS do {     \
	MSG("\n");    \
	dump_stack(); \
} while(0)
#endif

#ifdef __KERNEL__
#define HexDump(from_addr, len) \
 	    print_hex_dump_bytes (" ", DUMP_PREFIX_ADDRESS, from_addr, len);
#endif
#else				/* #ifdef DEBUG */
#define MSG(string, args...)
#define MSG_SHORT(string, args...)
#define QP
#define QPDS
#endif

#ifdef __KERNEL__
/*------------------------ PRINT_CTX ---------------------------------*/
/* 
 An interesting way to print the context info:
 If USE_FTRACE_PRINT is On, it implies we'll use trace_printk(), else the vanilla
 printk(). 
 If we are using trace_printk(), we will automatically get output in the ftrace 
 latency format (see below):

 * The Ftrace 'latency-format' :
                       _-----=> irqs-off          [d]
                      / _----=> need-resched      [N]
                     | / _---=> hardirq/softirq   [H|h|s]   H=>both h && s
                     || / _--=> preempt-depth     [#]
                     ||| /                      
 CPU  TASK/PID       ||||  DURATION                  FUNCTION CALLS 
 |     |    |        ||||   |   |                     |   |   |   | 

 However, if we're _not_ using ftrace trace_printk(), then we'll _emulate_ the same
 with the printk() !
 (Of course, without the 'Duration' and 'Function Calls' fields).
 */
#include <linux/sched.h>
#include <linux/interrupt.h>

#ifndef USE_FTRACE_PRINT	// 'normal' printk(), lets emulate ftrace latency format
#define PRINT_CTX() do {                                                                     \
	char sep='|', intr='.';                                                              \
	                                                                                     \
   if (in_interrupt()) {                                                                     \
      if (in_irq() && in_softirq())                                                          \
	    intr='H';                                                                        \
	  else if (in_irq())                                                                 \
	    intr='h';                                                                        \
	  else if (in_softirq())                                                             \
	    intr='s';                                                                        \
	}                                                                                    \
   else                                                                                      \
	intr='.';                                                                            \
	                                                                                     \
	DBGPRINT(                                                                            \
	"PRINT_CTX:: [%03d]%c%s%c:%d   %c "                                                  \
	"%c%c%c%u "                                                                          \
	"\n"                                                                                 \
	, smp_processor_id(),                                                                \
    (!current->mm?'[':' '), current->comm, (!current->mm?']':' '), current->pid, sep,        \
	(irqs_disabled()?'d':'.'),                                                           \
	(need_resched()?'N':'.'),                                                            \
	intr,                                                                                \
	(preempt_count() && 0xff)                                                            \
	);                                                                                   \
} while (0)
#else				// using ftrace trace_prink() internally
#define PRINT_CTX() do {                                                                     \
	DBGPRINT("PRINT_CTX:: [cpu %02d]%s:%d\n", smp_processor_id(), __func__,              \
			current->pid);                                                       \
	if (!in_interrupt()) {                                                               \
  		DBGPRINT(" in process context:%c%s%c:%d\n",                                  \
		    (!current->mm?'[':' '), current->comm, (!current->mm?']':' '),           \
				current->pid);                                               \
	} else {                                                                             \
        DBGPRINT(" in interrupt context: in_interrupt:%3s. in_irq:%3s. in_softirq:%3s. "     \
		"in_serving_softirq:%3s. preempt_count=0x%x\n",                              \
          (in_interrupt()?"yes":"no"), (in_irq()?"yes":"no"), (in_softirq()?"yes":"no"),     \
          (in_serving_softirq()?"yes":"no"), (preempt_count() && 0xff));                     \
	}                                                                                    \
} while (0)
#endif
#endif

/*------------------------ assert ---------------------------------------
 * Hey you, careful! 
 * Using assertions is great *but* pl be aware of traps & pitfalls:
 * http://blog.regehr.org/archives/1096
 *
 * The closest equivalent perhaps, to assert() in the kernel are the BUG() 
 * or BUG_ON() and WARN() or WARN_ON() macros. Using BUG*() is _only_ for those
 * cases where recovery is impossible. WARN*() is usally considered a better
 * option. Pl see <asm-generic/bug.h> for details.
 *
 * Here, we just trivially emit a noisy [trace_]printk() to "warn" the dev/user.
 */
#ifdef __KERNEL__
#define assert(expr) do {                                               \
 if (!(expr)) {                                                         \
  DBGPRINT("********** Assertion [%s] failed! : %s:%s:%d **********\n", \
   #expr, __FILE__, __func__, __LINE__);                                \
 }                                                                      \
} while(0)
#endif

#if 0
/*------------------------ DELAY_LOOP --------------------------------*/
static inline void beep(int what)
{
#ifdef __KERNEL__
	DBGPRINT("%c", (char)what);
#else
	char buf=(char)what;
	(void)write(STDOUT_FILENO, &buf, 1);
#endif
}

/* 
 * DELAY_LOOP macro
 * @val : ASCII value to print
 * @loop_count : times to loop around
 */
#define DELAY_LOOP(val,loop_count)                                             \
{                                                                              \
	int c=0, m;                                                            \
	unsigned int for_index,inner_index;                                    \
	                                                                       \
	for(for_index=0;for_index<loop_count;for_index++) {                    \
		beep((val));                                                   \
		c++;                                                           \
		for(inner_index=0;inner_index<HZ*1000*8;inner_index++)         \
			for(m=0;m<50;m++);                                     \
		}                                                              \
	/*printf("c=%d\n",c);*/                                                \
}
#endif
/*------------------------------------------------------------------------*/

#ifdef __KERNEL__
/*------------ DELAY_SEC -------------------------*
 * Delays execution for n seconds.
 * MUST be called from process context.
 *------------------------------------------------*/
#define DELAY_SEC(val)                                  \
{                                                       \
	if (!in_interrupt()) {	                        \
		set_current_state (TASK_INTERRUPTIBLE); \
		schedule_timeout (val * HZ);            \
	}	                                        \
}
#endif

#endif
