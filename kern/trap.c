/*
 * Processor trap handling.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the MIT Exokernel and JOS.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/mmu.h>
#include <inc/x86.h>
#include <inc/assert.h>
#include <inc/stdlib.h>
#include <kern/cpu.h>
#include <kern/trap.h>
#include <kern/console.h>
#include <kern/init.h>

// Interrupt descriptor table.  Must be built at run time because
// shifted function addresses can't be represented in relocation records.
static struct gatedesc idt[256];

// This "pseudo-descriptor" is needed only by the LIDT instruction,
// to specify both the size and address of th IDT at once.
static struct pseudodesc idt_pd = {
	sizeof(idt) - 1, (uint32_t) idt
};


static void
trap_init_idt(void)
{
	extern segdesc gdt[];
	extern void handler0();
	extern void handler3();
	extern void handler4();
	extern void handler5();
	extern void handler6();
	extern void handler7();
	extern void handler10();
	extern void handler11();
	extern void handler12();
	extern void handler13();
	extern void handler14();
	extern void handler16();
	extern void handler17();
	extern void handler19();

	SETGATE(idt[0],1,0x8,&handler0,0);
	SETGATE(idt[3],1,0x8,&handler3,3);	
	SETGATE(idt[4],1,0x8,&handler4,3);	
	SETGATE(idt[5],1,0x8,&handler5,0);
	SETGATE(idt[6],1,0x8,&handler6,0);
	SETGATE(idt[7],1,0x8,&handler7,0);
	SETGATE(idt[10],1,0x8,&handler10,0);
	SETGATE(idt[11],1,0x8,&handler11,0);
	SETGATE(idt[12],1,0x8,&handler12,0);
	SETGATE(idt[13],1,0x8,&handler13,0);
	SETGATE(idt[14],1,0x8,&handler14,0);
	SETGATE(idt[16],1,0x8,&handler16,0);
	SETGATE(idt[17],1,0x8,&handler17,0);
	SETGATE(idt[19],1,0x8,&handler19,0);

//	panic("trap_init() not implemented.");
}

void
trap_init(void)
{
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
		trap_init_idt();

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
		trap_check_kernel();
}

const char *trap_name(int trapno)
{
	static const char * const excnames[] = {
		"Divide error",
		"Debug",
		"Non-Maskable Interrupt",
		"Breakpoint",
		"Overflow",
		"BOUND Range Exceeded",
		"Invalid Opcode",
		"Device Not Available",
		"Double Fault",
		"Coprocessor Segment Overrun",
		"Invalid TSS",
		"Segment Not Present",
		"Stack Fault",
		"General Protection",
		"Page Fault",
		"(unknown trap)",
		"x87 FPU Floating-Point Error",
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	return "(unknown trap)";
}

void
trap_print_regs(pushregs *regs)
{
	cprintf("  edi  0x%08x\n", regs->reg_edi);
	cprintf("  esi  0x%08x\n", regs->reg_esi);
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
//	cprintf("  oesp 0x%08x\n", regs->reg_oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
	cprintf("  edx  0x%08x\n", regs->reg_edx);
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
	cprintf("  eax  0x%08x\n", regs->reg_eax);
}

void
trap_print(trapframe *tf)
{
	cprintf("TRAP frame at %p\n", tf);
	trap_print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trap_name(tf->tf_trapno));
	cprintf("  err  0x%08x\n", tf->tf_err);
	cprintf("  eip  0x%08x\n", tf->tf_eip);
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
	cprintf("  esp  0x%08x\n", tf->tf_esp);
	cprintf("  ss   0x----%04x\n", tf->tf_ss);
}

void gcc_noreturn
trap(trapframe *tf)
{
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
	if (c->recover)
		c->recover(tf, c->recoverdata);

	trap_print(tf);
	//panic("unhandled trap");
	trap_return0(tf);
}


// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
	trap_check_args *args = recoverdata;
	tf->tf_eip = (uint32_t) args->reip;	// Use recovery EIP on return
	args->trapno = tf->tf_trapno;		// Return trap number
	//cprintf("   %d    ",args->trapno);
	if (tf->tf_trapno==0)
	{cprintf("\nDivide by Zero error handled\n");trap_return2(tf);}
	else if(tf->tf_trapno==3)
	{cprintf("\nBreakPoint error handled\n");trap_return0(tf);}
	else if(tf->tf_trapno==4)
	{cprintf("\nOverflow error handled\n");trap_return0(tf);}
	else if(tf->tf_trapno==5)
	{cprintf("\nBound error handled\n");trap_return3(tf);}
	else if(tf->tf_trapno==6)
	{cprintf("\nInvalid opcode handled\n");trap_return2(tf);}
	else if(tf->tf_trapno==7)
	{cprintf("\nDevice not Availble handled\n");trap_return2(tf);}
	else if(tf->tf_trapno==10)
	{cprintf("\nInvalid TSS handled\n");trap_return2(tf);}
	else if(tf->tf_trapno==11)
	{cprintf("\nSegement Not present fault handled\n");trap_return2(tf);}
	else if(tf->tf_trapno==12)
	{cprintf("\nStack Segment Fault handled\n");trap_return2(tf);}
	else if(tf->tf_trapno==13)
	{cprintf("\nGeneral Segment fault handled\n");trap_return2(tf);}
	else if(tf->tf_trapno==14)
	{cprintf("\nPage Fault handled\n");trap_return2(tf);}
	else if(tf->tf_trapno==16)
	{cprintf("\nPage Point Error handled\n");trap_return2(tf);}
	else if(tf->tf_trapno==17)
	{cprintf("\nAlignment Check Fault handled\n");trap_return2(tf);}
	else if(tf->tf_trapno==19)
	{cprintf("\nSIMD Floating Point Exception handled\n");trap_return2(tf);}
	else trap_return0(tf);
}

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
	assert((read_cs() & 3) == 0);	// better be in kernel mode!

	cpu *c = cpu_cur();
	c->recover = trap_check_recover;
	trap_check(&c->recoverdata);
	c->recover = NULL;	// No more mr. nice-guy; traps are real again

	cprintf("trap_check_kernel() succeeded!\n");
}

// Check for correct handling of traps from user mode.
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
	assert((read_cs() & 3) == 3);	// better be in user mode!

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
	c->recover = trap_check_recover;
	trap_check(&c->recoverdata);
	c->recover = NULL;	// No more mr. nice-guy; traps are real again

	cprintf("trap_check_user() succeeded!\n");
}

void after_div0();
void after_breakpoint();
void after_overflow();
void after_bound();
void after_illegal();
void after_gpfault();
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
	volatile int cookie = 0xfeedface;
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
	assert(args.trapno == T_DIVIDE);
	
	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
		
	// Breakpoint trap
	args.reip = after_breakpoint;
	asm volatile("int3; after_breakpoint:");
	assert(args.trapno == T_BRKPT);
	
	// Overflow trap
	args.reip = after_overflow;
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
	assert(args.trapno == T_OFLOW);
	
	// Bounds trap
	args.reip = after_bound;
	int bounds[2] = { 1, 3 };
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
	assert(args.trapno == T_BOUND);

	// Illegal instruction trap
	args.reip = after_illegal;
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
	assert(args.trapno == T_ILLOP);

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
	assert(args.trapno == T_GPFLT);

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
		args.reip = after_priv;
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
		assert(args.trapno == T_GPFLT);
	}

	cprintf("end");
	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);

	*argsp = NULL;	// recovery mechanism not needed anymore
}

