/*
 * Trap handler entry and exit code, written in assembly language.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the MIT Exokernel and JOS.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/mmu.h>
#include <inc/trap.h>

#include <kern/cpu.h>



/* The TRAPHANDLER macro defines a globally-visible function for handling
 * a trap.  It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 */ 
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(handler0,0);
TRAPHANDLER_NOEC(handler3,3);
TRAPHANDLER_NOEC(handler4,4);
TRAPHANDLER_NOEC(handler5,5);
TRAPHANDLER_NOEC(handler6,6);
TRAPHANDLER_NOEC(handler7,7);
TRAPHANDLER(handler10,10);
TRAPHANDLER(handler11,11);
TRAPHANDLER(handler12,12);
TRAPHANDLER(handler13,13);
TRAPHANDLER(handler14,14);
TRAPHANDLER_NOEC(handler16,16);
TRAPHANDLER(handler17,17);
TRAPHANDLER_NOEC(handler19,19);

/*
 * Lab 1: Your code here for _alltraps
 */


_alltraps:
	pushl 16(%esp)
	pushl %cs
	pushl 16(%esp)
	pushl 16(%esp)
	pushl 16(%esp)
	pushl %ds
	pushl %es
	pushal
	pushl %esp
	call trap

//
// Trap return code.
// C code in the kernel will call this function to return from a trap,
// providing the 
// Restore the CPU state from a given trapframe struct
// and return from the trap using the processor's 'iret' instruction.
// This function does not return to the caller,
// since the new CPU state this function loads
// replaces the caller's stack pointer and other registers.
//
.globl	trap_return2
.type	trap_return2,@function
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return2:
/*
 * Lab 1: Your code here for trap_return
 */
	movl 4(%esp),%esp
	popal
	popl %es
	popl %ds

	addl $28,%esp 	//pop trap_n0
	popl %ecx
	addl $2,%ecx
	pushl %ecx
	movl $0,%ecx
	iret


.globl	trap_return0
.type	trap_return0,@function
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return0:
	movl 4(%esp),%esp
	popal
	popl %es
	popl %ds

	addl $28,%esp 	//pop trap_n0
	iret

.globl	trap_return3
.type	trap_return3,@function
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return3:
	movl 4(%esp),%esp
	popal
	popl %es
	popl %ds

	addl $28,%esp 	//pop trap_n0
	popl %ecx
	addl $3,%ecx
	pushl %ecx
	movl $0,%ecx
	iret

.globl	trap_return1
.type	trap_return1,@function
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return1:
	movl 4(%esp),%esp
	popal
	popl %es
	popl %ds

	addl $28,%esp 	//pop trap_n0
	popl %ecx
	addl $1,%ecx
	pushl %ecx
	movl $0,%ecx
	iret

1:	jmp	1b		// just spin

