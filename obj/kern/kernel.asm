
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

00100000 <start-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		start
start:
	movw	$0x1234,0x472			# warm boot BIOS flag
  100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
  100006:	00 00                	add    %al,(%eax)
  100008:	fb                   	sti    
  100009:	4f                   	dec    %edi
  10000a:	52                   	push   %edx
  10000b:	e4 66                	in     $0x66,%al

0010000c <start>:
  10000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
  100013:	34 12 

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
  100015:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(cpu_boot+4096),%esp
  10001a:	bc 00 70 10 00       	mov    $0x107000,%esp

	# now to C code
	call	init
  10001f:	e8 6f 00 00 00       	call   100093 <init>

00100024 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
  100024:	eb fe                	jmp    100024 <spin>
  100026:	90                   	nop
  100027:	90                   	nop

00100028 <cpu_cur>:


// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100028:	55                   	push   %ebp
  100029:	89 e5                	mov    %esp,%ebp
  10002b:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10002e:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100031:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100034:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100037:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10003a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10003f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100042:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100045:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  10004b:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100050:	74 24                	je     100076 <cpu_cur+0x4e>
  100052:	c7 44 24 0c 40 39 10 	movl   $0x103940,0xc(%esp)
  100059:	00 
  10005a:	c7 44 24 08 56 39 10 	movl   $0x103956,0x8(%esp)
  100061:	00 
  100062:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  100069:	00 
  10006a:	c7 04 24 6b 39 10 00 	movl   $0x10396b,(%esp)
  100071:	e8 22 03 00 00       	call   100398 <debug_panic>
	return c;
  100076:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100079:	c9                   	leave  
  10007a:	c3                   	ret    

0010007b <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10007b:	55                   	push   %ebp
  10007c:	89 e5                	mov    %esp,%ebp
  10007e:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100081:	e8 a2 ff ff ff       	call   100028 <cpu_cur>
  100086:	3d 00 60 10 00       	cmp    $0x106000,%eax
  10008b:	0f 94 c0             	sete   %al
  10008e:	0f b6 c0             	movzbl %al,%eax
}
  100091:	c9                   	leave  
  100092:	c3                   	ret    

00100093 <init>:
// Called first from entry.S on the bootstrap processor,
// and later from boot/bootother.S on all other processors.
// As a rule, "init" functions in PIOS are called once on EACH processor.
void
init(void)
{
  100093:	55                   	push   %ebp
  100094:	89 e5                	mov    %esp,%ebp
  100096:	83 ec 18             	sub    $0x18,%esp
	extern char start[], edata[], end[];

	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program,
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
  100099:	e8 dd ff ff ff       	call   10007b <cpu_onboot>
  10009e:	85 c0                	test   %eax,%eax
  1000a0:	74 28                	je     1000ca <init+0x37>
		memset(edata, 0, end - edata);
  1000a2:	ba 84 8f 10 00       	mov    $0x108f84,%edx
  1000a7:	b8 30 75 10 00       	mov    $0x107530,%eax
  1000ac:	89 d1                	mov    %edx,%ecx
  1000ae:	29 c1                	sub    %eax,%ecx
  1000b0:	89 c8                	mov    %ecx,%eax
  1000b2:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000bd:	00 
  1000be:	c7 04 24 30 75 10 00 	movl   $0x107530,(%esp)
  1000c5:	e8 a8 32 00 00       	call   103372 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000ca:	e8 2e 02 00 00       	call   1002fd <cons_init>

	// Lab 1: test cprintf and debug_trace
	cprintf("1234 decimal is %o octal!\n", 1234);
  1000cf:	c7 44 24 04 d2 04 00 	movl   $0x4d2,0x4(%esp)
  1000d6:	00 
  1000d7:	c7 04 24 78 39 10 00 	movl   $0x103978,(%esp)
  1000de:	e8 4e 30 00 00       	call   103131 <cprintf>
	debug_check();
  1000e3:	e8 42 05 00 00       	call   10062a <debug_check>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000e8:	e8 92 10 00 00       	call   10117f <cpu_init>
	trap_init();	
  1000ed:	e8 02 19 00 00       	call   1019f4 <trap_init>
	
	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  1000f2:	e8 15 08 00 00       	call   10090c <mem_init>
	// Lab 1: change this so it enters user() in user mode,
	// running on the user_stack declared above,
	// instead of just calling user() directly.
	//cprintf("%d",(int *)&user_stack);
	
	asm volatile ( "movw %0,%%ds"::"r"(CPU_GDT_UDATA|3) );
  1000f7:	b8 23 00 00 00       	mov    $0x23,%eax
  1000fc:	8e d8                	mov    %eax,%ds
	asm volatile ( "movw %0,%%es"::"r"(CPU_GDT_UDATA|3) );
  1000fe:	b8 23 00 00 00       	mov    $0x23,%eax
  100103:	8e c0                	mov    %eax,%es
	asm volatile ( "movw %0,%%fs"::"r"(CPU_GDT_UDATA|3) );
  100105:	b8 23 00 00 00       	mov    $0x23,%eax
  10010a:	8e e0                	mov    %eax,%fs
	asm volatile ( "movw %0,%%gs"::"r"(CPU_GDT_UDATA|3) );
  10010c:	b8 23 00 00 00       	mov    $0x23,%eax
  100111:	8e e8                	mov    %eax,%gs
	asm volatile ( "pushl %0"::"r"(CPU_GDT_UDATA|3) );
  100113:	b8 23 00 00 00       	mov    $0x23,%eax
  100118:	50                   	push   %eax
	asm volatile ( "pushl %0"::"r"( &user_stack[sizeof(user_stack)]) );
  100119:	b8 40 85 10 00       	mov    $0x108540,%eax
  10011e:	50                   	push   %eax
	asm volatile ( "pushfl":: );
  10011f:	9c                   	pushf  
	asm ( "movl %eax,(%esp)");
  100120:	89 04 24             	mov    %eax,(%esp)
	asm ( "popl %ecx" );
  100123:	59                   	pop    %ecx
	asm volatile ( "orl %0,%%eax"::"r"(FL_IOPL_3));
  100124:	b8 00 30 00 00       	mov    $0x3000,%eax
  100129:	09 c0                	or     %eax,%eax
	asm ( "pushl %eax"); 
  10012b:	50                   	push   %eax
	asm volatile ( "pushl %0"::"r"(CPU_GDT_UCODE|3) );
  10012c:	b8 1b 00 00 00       	mov    $0x1b,%eax
  100131:	50                   	push   %eax
	asm volatile ( "pushl %0"::"r"(&user) );
  100132:	b8 40 01 10 00       	mov    $0x100140,%eax
  100137:	50                   	push   %eax
	asm ("iret");
  100138:	cf                   	iret   
	user();
  100139:	e8 02 00 00 00       	call   100140 <user>
}
  10013e:	c9                   	leave  
  10013f:	c3                   	ret    

00100140 <user>:
// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  100140:	55                   	push   %ebp
  100141:	89 e5                	mov    %esp,%ebp
  100143:	83 ec 28             	sub    $0x28,%esp
	cprintf("in user()\n");
  100146:	c7 04 24 93 39 10 00 	movl   $0x103993,(%esp)
  10014d:	e8 df 2f 00 00       	call   103131 <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100152:	89 65 f0             	mov    %esp,-0x10(%ebp)
        return esp;
  100155:	8b 45 f0             	mov    -0x10(%ebp),%eax
	assert(read_esp() > (uint32_t) &user_stack[0]);
  100158:	89 c2                	mov    %eax,%edx
  10015a:	b8 40 75 10 00       	mov    $0x107540,%eax
  10015f:	39 c2                	cmp    %eax,%edx
  100161:	77 24                	ja     100187 <user+0x47>
  100163:	c7 44 24 0c a0 39 10 	movl   $0x1039a0,0xc(%esp)
  10016a:	00 
  10016b:	c7 44 24 08 56 39 10 	movl   $0x103956,0x8(%esp)
  100172:	00 
  100173:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
  10017a:	00 
  10017b:	c7 04 24 c7 39 10 00 	movl   $0x1039c7,(%esp)
  100182:	e8 11 02 00 00       	call   100398 <debug_panic>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100187:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10018a:	8b 45 f4             	mov    -0xc(%ebp),%eax

	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  10018d:	89 c2                	mov    %eax,%edx
  10018f:	b8 40 85 10 00       	mov    $0x108540,%eax
  100194:	39 c2                	cmp    %eax,%edx
  100196:	72 24                	jb     1001bc <user+0x7c>
  100198:	c7 44 24 0c d4 39 10 	movl   $0x1039d4,0xc(%esp)
  10019f:	00 
  1001a0:	c7 44 24 08 56 39 10 	movl   $0x103956,0x8(%esp)
  1001a7:	00 
  1001a8:	c7 44 24 04 61 00 00 	movl   $0x61,0x4(%esp)
  1001af:	00 
  1001b0:	c7 04 24 c7 39 10 00 	movl   $0x1039c7,(%esp)
  1001b7:	e8 dc 01 00 00       	call   100398 <debug_panic>

	// Check that we're in user mode and can handle traps from there.

	trap_check_user();
  1001bc:	e8 03 1d 00 00       	call   101ec4 <trap_check_user>
	done();
  1001c1:	e8 00 00 00 00       	call   1001c6 <done>

001001c6 <done>:
}

void gcc_noreturn
done()
{
  1001c6:	55                   	push   %ebp
  1001c7:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  1001c9:	eb fe                	jmp    1001c9 <done+0x3>
  1001cb:	90                   	nop

001001cc <cpu_cur>:


// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1001cc:	55                   	push   %ebp
  1001cd:	89 e5                	mov    %esp,%ebp
  1001cf:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1001d2:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1001d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1001d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1001db:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1001de:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1001e3:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1001e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1001e9:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  1001ef:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1001f4:	74 24                	je     10021a <cpu_cur+0x4e>
  1001f6:	c7 44 24 0c 0c 3a 10 	movl   $0x103a0c,0xc(%esp)
  1001fd:	00 
  1001fe:	c7 44 24 08 22 3a 10 	movl   $0x103a22,0x8(%esp)
  100205:	00 
  100206:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  10020d:	00 
  10020e:	c7 04 24 37 3a 10 00 	movl   $0x103a37,(%esp)
  100215:	e8 7e 01 00 00       	call   100398 <debug_panic>
	return c;
  10021a:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10021d:	c9                   	leave  
  10021e:	c3                   	ret    

0010021f <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10021f:	55                   	push   %ebp
  100220:	89 e5                	mov    %esp,%ebp
  100222:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100225:	e8 a2 ff ff ff       	call   1001cc <cpu_cur>
  10022a:	3d 00 60 10 00       	cmp    $0x106000,%eax
  10022f:	0f 94 c0             	sete   %al
  100232:	0f b6 c0             	movzbl %al,%eax
}
  100235:	c9                   	leave  
  100236:	c3                   	ret    

00100237 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  100237:	55                   	push   %ebp
  100238:	89 e5                	mov    %esp,%ebp
  10023a:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = (*proc)()) != -1) {
  10023d:	eb 35                	jmp    100274 <cons_intr+0x3d>
		if (c == 0)
  10023f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100243:	74 2e                	je     100273 <cons_intr+0x3c>
			continue;
		cons.buf[cons.wpos++] = c;
  100245:	a1 44 87 10 00       	mov    0x108744,%eax
  10024a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10024d:	88 90 40 85 10 00    	mov    %dl,0x108540(%eax)
  100253:	83 c0 01             	add    $0x1,%eax
  100256:	a3 44 87 10 00       	mov    %eax,0x108744
		if (cons.wpos == CONSBUFSIZE)
  10025b:	a1 44 87 10 00       	mov    0x108744,%eax
  100260:	3d 00 02 00 00       	cmp    $0x200,%eax
  100265:	75 0d                	jne    100274 <cons_intr+0x3d>
			cons.wpos = 0;
  100267:	c7 05 44 87 10 00 00 	movl   $0x0,0x108744
  10026e:	00 00 00 
  100271:	eb 01                	jmp    100274 <cons_intr+0x3d>
{
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
  100273:	90                   	nop
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
  100274:	8b 45 08             	mov    0x8(%ebp),%eax
  100277:	ff d0                	call   *%eax
  100279:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10027c:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  100280:	75 bd                	jne    10023f <cons_intr+0x8>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
  100282:	c9                   	leave  
  100283:	c3                   	ret    

00100284 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  100284:	55                   	push   %ebp
  100285:	89 e5                	mov    %esp,%ebp
  100287:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  10028a:	e8 dd 24 00 00       	call   10276c <serial_intr>
	kbd_intr();
  10028f:	e8 32 24 00 00       	call   1026c6 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  100294:	8b 15 40 87 10 00    	mov    0x108740,%edx
  10029a:	a1 44 87 10 00       	mov    0x108744,%eax
  10029f:	39 c2                	cmp    %eax,%edx
  1002a1:	74 35                	je     1002d8 <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  1002a3:	a1 40 87 10 00       	mov    0x108740,%eax
  1002a8:	0f b6 90 40 85 10 00 	movzbl 0x108540(%eax),%edx
  1002af:	0f b6 d2             	movzbl %dl,%edx
  1002b2:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1002b5:	83 c0 01             	add    $0x1,%eax
  1002b8:	a3 40 87 10 00       	mov    %eax,0x108740
		if (cons.rpos == CONSBUFSIZE)
  1002bd:	a1 40 87 10 00       	mov    0x108740,%eax
  1002c2:	3d 00 02 00 00       	cmp    $0x200,%eax
  1002c7:	75 0a                	jne    1002d3 <cons_getc+0x4f>
			cons.rpos = 0;
  1002c9:	c7 05 40 87 10 00 00 	movl   $0x0,0x108740
  1002d0:	00 00 00 
		return c;
  1002d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1002d6:	eb 05                	jmp    1002dd <cons_getc+0x59>
	}
	return 0;
  1002d8:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1002dd:	c9                   	leave  
  1002de:	c3                   	ret    

001002df <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  1002df:	55                   	push   %ebp
  1002e0:	89 e5                	mov    %esp,%ebp
  1002e2:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
  1002e5:	8b 45 08             	mov    0x8(%ebp),%eax
  1002e8:	89 04 24             	mov    %eax,(%esp)
  1002eb:	e8 99 24 00 00       	call   102789 <serial_putc>
	video_putc(c);
  1002f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1002f3:	89 04 24             	mov    %eax,(%esp)
  1002f6:	e8 29 20 00 00       	call   102324 <video_putc>
}
  1002fb:	c9                   	leave  
  1002fc:	c3                   	ret    

001002fd <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  1002fd:	55                   	push   %ebp
  1002fe:	89 e5                	mov    %esp,%ebp
  100300:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100303:	e8 17 ff ff ff       	call   10021f <cpu_onboot>
  100308:	85 c0                	test   %eax,%eax
  10030a:	74 36                	je     100342 <cons_init+0x45>
		return;

	video_init();
  10030c:	e8 47 1f 00 00       	call   102258 <video_init>
	kbd_init();
  100311:	e8 c4 23 00 00       	call   1026da <kbd_init>
	serial_init();
  100316:	e8 d3 24 00 00       	call   1027ee <serial_init>

	if (!serial_exists)
  10031b:	a1 80 8f 10 00       	mov    0x108f80,%eax
  100320:	85 c0                	test   %eax,%eax
  100322:	75 1f                	jne    100343 <cons_init+0x46>
		warn("Serial port does not exist!\n");
  100324:	c7 44 24 08 44 3a 10 	movl   $0x103a44,0x8(%esp)
  10032b:	00 
  10032c:	c7 44 24 04 6b 00 00 	movl   $0x6b,0x4(%esp)
  100333:	00 
  100334:	c7 04 24 61 3a 10 00 	movl   $0x103a61,(%esp)
  10033b:	e8 12 01 00 00       	call   100452 <debug_warn>
  100340:	eb 01                	jmp    100343 <cons_init+0x46>
// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100342:	90                   	nop
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}
  100343:	c9                   	leave  
  100344:	c3                   	ret    

00100345 <cputs>:


// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  100345:	55                   	push   %ebp
  100346:	89 e5                	mov    %esp,%ebp
  100348:	83 ec 28             	sub    $0x28,%esp
	//LAB1 if (read_cs() & 3)
	//LAB1 	return ;//LAB1 sys_cputs(str);	// use syscall from user mode

	char ch;
	while (*str)
  10034b:	eb 15                	jmp    100362 <cputs+0x1d>
		cons_putc(*str++);
  10034d:	8b 45 08             	mov    0x8(%ebp),%eax
  100350:	0f b6 00             	movzbl (%eax),%eax
  100353:	0f be c0             	movsbl %al,%eax
  100356:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10035a:	89 04 24             	mov    %eax,(%esp)
  10035d:	e8 7d ff ff ff       	call   1002df <cons_putc>
{
	//LAB1 if (read_cs() & 3)
	//LAB1 	return ;//LAB1 sys_cputs(str);	// use syscall from user mode

	char ch;
	while (*str)
  100362:	8b 45 08             	mov    0x8(%ebp),%eax
  100365:	0f b6 00             	movzbl (%eax),%eax
  100368:	84 c0                	test   %al,%al
  10036a:	75 e1                	jne    10034d <cputs+0x8>
		cons_putc(*str++);
}
  10036c:	c9                   	leave  
  10036d:	c3                   	ret    

0010036e <cons_io>:

// Synchronize the root process's console special files
// with the actual console I/O device.
bool
cons_io(void)
{
  10036e:	55                   	push   %ebp
  10036f:	89 e5                	mov    %esp,%ebp
  100371:	83 ec 18             	sub    $0x18,%esp
	// Lab 4: your console I/O code here.
	warn("cons_io() not implemented");
  100374:	c7 44 24 08 70 3a 10 	movl   $0x103a70,0x8(%esp)
  10037b:	00 
  10037c:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
  100383:	00 
  100384:	c7 04 24 61 3a 10 00 	movl   $0x103a61,(%esp)
  10038b:	e8 c2 00 00 00       	call   100452 <debug_warn>
	return 0;	// 0 indicates no I/O done
  100390:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100395:	c9                   	leave  
  100396:	c3                   	ret    
  100397:	90                   	nop

00100398 <debug_panic>:

// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  100398:	55                   	push   %ebp
  100399:	89 e5                	mov    %esp,%ebp
  10039b:	83 ec 58             	sub    $0x58,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10039e:	8c 4d f2             	mov    %cs,-0xe(%ebp)
        return cs;
  1003a1:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  1003a5:	0f b7 c0             	movzwl %ax,%eax
  1003a8:	83 e0 03             	and    $0x3,%eax
  1003ab:	85 c0                	test   %eax,%eax
  1003ad:	75 16                	jne    1003c5 <debug_panic+0x2d>
		if (panicstr)
  1003af:	a1 48 87 10 00       	mov    0x108748,%eax
  1003b4:	85 c0                	test   %eax,%eax
  1003b6:	74 05                	je     1003bd <debug_panic+0x25>
			goto dead;
  1003b8:	e9 93 00 00 00       	jmp    100450 <debug_panic+0xb8>
		panicstr = fmt;
  1003bd:	8b 45 10             	mov    0x10(%ebp),%eax
  1003c0:	a3 48 87 10 00       	mov    %eax,0x108748
	}

	// First print the requested message
	va_start(ap, fmt);
  1003c5:	8d 45 10             	lea    0x10(%ebp),%eax
  1003c8:	83 c0 04             	add    $0x4,%eax
  1003cb:	89 45 e8             	mov    %eax,-0x18(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  1003ce:	8b 45 0c             	mov    0xc(%ebp),%eax
  1003d1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1003d5:	8b 45 08             	mov    0x8(%ebp),%eax
  1003d8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1003dc:	c7 04 24 8c 3a 10 00 	movl   $0x103a8c,(%esp)
  1003e3:	e8 49 2d 00 00       	call   103131 <cprintf>
	vcprintf(fmt, ap);
  1003e8:	8b 45 10             	mov    0x10(%ebp),%eax
  1003eb:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1003ee:	89 54 24 04          	mov    %edx,0x4(%esp)
  1003f2:	89 04 24             	mov    %eax,(%esp)
  1003f5:	e8 ce 2c 00 00       	call   1030c8 <vcprintf>
	cprintf("\n");
  1003fa:	c7 04 24 a4 3a 10 00 	movl   $0x103aa4,(%esp)
  100401:	e8 2b 2d 00 00       	call   103131 <cprintf>

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  100406:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  100409:	8b 45 f4             	mov    -0xc(%ebp),%eax
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  10040c:	8d 55 c0             	lea    -0x40(%ebp),%edx
  10040f:	89 54 24 04          	mov    %edx,0x4(%esp)
  100413:	89 04 24             	mov    %eax,(%esp)
  100416:	e8 80 00 00 00       	call   10049b <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  10041b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100422:	eb 1b                	jmp    10043f <debug_panic+0xa7>
		cprintf("  from %08x\n", eips[i]);
  100424:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100427:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  10042b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10042f:	c7 04 24 a6 3a 10 00 	movl   $0x103aa6,(%esp)
  100436:	e8 f6 2c 00 00       	call   103131 <cprintf>
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  10043b:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  10043f:	83 7d ec 09          	cmpl   $0x9,-0x14(%ebp)
  100443:	7f 0b                	jg     100450 <debug_panic+0xb8>
  100445:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100448:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  10044c:	85 c0                	test   %eax,%eax
  10044e:	75 d4                	jne    100424 <debug_panic+0x8c>
		cprintf("  from %08x\n", eips[i]);

dead:
	while (1) ;	// just spin
  100450:	eb fe                	jmp    100450 <debug_panic+0xb8>

00100452 <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  100452:	55                   	push   %ebp
  100453:	89 e5                	mov    %esp,%ebp
  100455:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  100458:	8d 45 10             	lea    0x10(%ebp),%eax
  10045b:	83 c0 04             	add    $0x4,%eax
  10045e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  100461:	8b 45 0c             	mov    0xc(%ebp),%eax
  100464:	89 44 24 08          	mov    %eax,0x8(%esp)
  100468:	8b 45 08             	mov    0x8(%ebp),%eax
  10046b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10046f:	c7 04 24 b3 3a 10 00 	movl   $0x103ab3,(%esp)
  100476:	e8 b6 2c 00 00       	call   103131 <cprintf>
	vcprintf(fmt, ap);
  10047b:	8b 45 10             	mov    0x10(%ebp),%eax
  10047e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100481:	89 54 24 04          	mov    %edx,0x4(%esp)
  100485:	89 04 24             	mov    %eax,(%esp)
  100488:	e8 3b 2c 00 00       	call   1030c8 <vcprintf>
	cprintf("\n");
  10048d:	c7 04 24 a4 3a 10 00 	movl   $0x103aa4,(%esp)
  100494:	e8 98 2c 00 00       	call   103131 <cprintf>
	va_end(ap);
}
  100499:	c9                   	leave  
  10049a:	c3                   	ret    

0010049b <debug_trace>:

// Record the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  10049b:	55                   	push   %ebp
  10049c:	89 e5                	mov    %esp,%ebp
  10049e:	56                   	push   %esi
  10049f:	53                   	push   %ebx
  1004a0:	83 ec 30             	sub    $0x30,%esp
	int i=-1;
  1004a3:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
	//panic("debug_trace not implemented");
	while(*(uint32_t *)ebp!=0 && i<10)
  1004aa:	eb 64                	jmp    100510 <debug_trace+0x75>
	{
	cprintf("ebp:%x  eip:%x  args: %x %x %x \n",*(uint32_t *)ebp,*(uint32_t *)(ebp+4), *(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16));
  1004ac:	8b 45 08             	mov    0x8(%ebp),%eax
  1004af:	83 c0 10             	add    $0x10,%eax
  1004b2:	8b 30                	mov    (%eax),%esi
  1004b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1004b7:	83 c0 0c             	add    $0xc,%eax
  1004ba:	8b 18                	mov    (%eax),%ebx
  1004bc:	8b 45 08             	mov    0x8(%ebp),%eax
  1004bf:	83 c0 08             	add    $0x8,%eax
  1004c2:	8b 08                	mov    (%eax),%ecx
  1004c4:	8b 45 08             	mov    0x8(%ebp),%eax
  1004c7:	83 c0 04             	add    $0x4,%eax
  1004ca:	8b 10                	mov    (%eax),%edx
  1004cc:	8b 45 08             	mov    0x8(%ebp),%eax
  1004cf:	8b 00                	mov    (%eax),%eax
  1004d1:	89 74 24 14          	mov    %esi,0x14(%esp)
  1004d5:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  1004d9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  1004dd:	89 54 24 08          	mov    %edx,0x8(%esp)
  1004e1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004e5:	c7 04 24 d0 3a 10 00 	movl   $0x103ad0,(%esp)
  1004ec:	e8 40 2c 00 00       	call   103131 <cprintf>
	eips[++i]=*((uint32_t *)(ebp +4));
  1004f1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1004f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1004f8:	c1 e0 02             	shl    $0x2,%eax
  1004fb:	03 45 0c             	add    0xc(%ebp),%eax
  1004fe:	8b 55 08             	mov    0x8(%ebp),%edx
  100501:	83 c2 04             	add    $0x4,%edx
  100504:	8b 12                	mov    (%edx),%edx
  100506:	89 10                	mov    %edx,(%eax)
	ebp=*(uint32_t *)ebp;
  100508:	8b 45 08             	mov    0x8(%ebp),%eax
  10050b:	8b 00                	mov    (%eax),%eax
  10050d:	89 45 08             	mov    %eax,0x8(%ebp)
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
	int i=-1;
	//panic("debug_trace not implemented");
	while(*(uint32_t *)ebp!=0 && i<10)
  100510:	8b 45 08             	mov    0x8(%ebp),%eax
  100513:	8b 00                	mov    (%eax),%eax
  100515:	85 c0                	test   %eax,%eax
  100517:	74 06                	je     10051f <debug_trace+0x84>
  100519:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  10051d:	7e 8d                	jle    1004ac <debug_trace+0x11>
	{
	cprintf("ebp:%x  eip:%x  args: %x %x %x \n",*(uint32_t *)ebp,*(uint32_t *)(ebp+4), *(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16));
	eips[++i]=*((uint32_t *)(ebp +4));
	ebp=*(uint32_t *)ebp;
	}
	cprintf("ebp:%x  eip: %x  args: %x %x %x \n",*(uint32_t *)ebp,*(uint32_t *)(ebp+4), *(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16));
  10051f:	8b 45 08             	mov    0x8(%ebp),%eax
  100522:	83 c0 10             	add    $0x10,%eax
  100525:	8b 30                	mov    (%eax),%esi
  100527:	8b 45 08             	mov    0x8(%ebp),%eax
  10052a:	83 c0 0c             	add    $0xc,%eax
  10052d:	8b 18                	mov    (%eax),%ebx
  10052f:	8b 45 08             	mov    0x8(%ebp),%eax
  100532:	83 c0 08             	add    $0x8,%eax
  100535:	8b 08                	mov    (%eax),%ecx
  100537:	8b 45 08             	mov    0x8(%ebp),%eax
  10053a:	83 c0 04             	add    $0x4,%eax
  10053d:	8b 10                	mov    (%eax),%edx
  10053f:	8b 45 08             	mov    0x8(%ebp),%eax
  100542:	8b 00                	mov    (%eax),%eax
  100544:	89 74 24 14          	mov    %esi,0x14(%esp)
  100548:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  10054c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  100550:	89 54 24 08          	mov    %edx,0x8(%esp)
  100554:	89 44 24 04          	mov    %eax,0x4(%esp)
  100558:	c7 04 24 f4 3a 10 00 	movl   $0x103af4,(%esp)
  10055f:	e8 cd 2b 00 00       	call   103131 <cprintf>
	eips[++i]=*((uint32_t *)(ebp+4));
  100564:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100568:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10056b:	c1 e0 02             	shl    $0x2,%eax
  10056e:	03 45 0c             	add    0xc(%ebp),%eax
  100571:	8b 55 08             	mov    0x8(%ebp),%edx
  100574:	83 c2 04             	add    $0x4,%edx
  100577:	8b 12                	mov    (%edx),%edx
  100579:	89 10                	mov    %edx,(%eax)
	while(i<10)
  10057b:	eb 13                	jmp    100590 <debug_trace+0xf5>
	{	
	eips[++i]=0;
  10057d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100581:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100584:	c1 e0 02             	shl    $0x2,%eax
  100587:	03 45 0c             	add    0xc(%ebp),%eax
  10058a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	eips[++i]=*((uint32_t *)(ebp +4));
	ebp=*(uint32_t *)ebp;
	}
	cprintf("ebp:%x  eip: %x  args: %x %x %x \n",*(uint32_t *)ebp,*(uint32_t *)(ebp+4), *(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16));
	eips[++i]=*((uint32_t *)(ebp+4));
	while(i<10)
  100590:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  100594:	7e e7                	jle    10057d <debug_trace+0xe2>
	{	
	eips[++i]=0;
	}
		
}
  100596:	83 c4 30             	add    $0x30,%esp
  100599:	5b                   	pop    %ebx
  10059a:	5e                   	pop    %esi
  10059b:	5d                   	pop    %ebp
  10059c:	c3                   	ret    

0010059d <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  10059d:	55                   	push   %ebp
  10059e:	89 e5                	mov    %esp,%ebp
  1005a0:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1005a3:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  1005a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1005a9:	8b 55 0c             	mov    0xc(%ebp),%edx
  1005ac:	89 54 24 04          	mov    %edx,0x4(%esp)
  1005b0:	89 04 24             	mov    %eax,(%esp)
  1005b3:	e8 e3 fe ff ff       	call   10049b <debug_trace>
  1005b8:	c9                   	leave  
  1005b9:	c3                   	ret    

001005ba <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  1005ba:	55                   	push   %ebp
  1005bb:	89 e5                	mov    %esp,%ebp
  1005bd:	83 ec 18             	sub    $0x18,%esp
  1005c0:	8b 45 08             	mov    0x8(%ebp),%eax
  1005c3:	83 e0 02             	and    $0x2,%eax
  1005c6:	85 c0                	test   %eax,%eax
  1005c8:	74 14                	je     1005de <f2+0x24>
  1005ca:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005cd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1005d4:	89 04 24             	mov    %eax,(%esp)
  1005d7:	e8 c1 ff ff ff       	call   10059d <f3>
  1005dc:	eb 12                	jmp    1005f0 <f2+0x36>
  1005de:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005e1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005e5:	8b 45 08             	mov    0x8(%ebp),%eax
  1005e8:	89 04 24             	mov    %eax,(%esp)
  1005eb:	e8 ad ff ff ff       	call   10059d <f3>
  1005f0:	c9                   	leave  
  1005f1:	c3                   	ret    

001005f2 <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  1005f2:	55                   	push   %ebp
  1005f3:	89 e5                	mov    %esp,%ebp
  1005f5:	83 ec 18             	sub    $0x18,%esp
  1005f8:	8b 45 08             	mov    0x8(%ebp),%eax
  1005fb:	83 e0 01             	and    $0x1,%eax
  1005fe:	84 c0                	test   %al,%al
  100600:	74 14                	je     100616 <f1+0x24>
  100602:	8b 45 0c             	mov    0xc(%ebp),%eax
  100605:	89 44 24 04          	mov    %eax,0x4(%esp)
  100609:	8b 45 08             	mov    0x8(%ebp),%eax
  10060c:	89 04 24             	mov    %eax,(%esp)
  10060f:	e8 a6 ff ff ff       	call   1005ba <f2>
  100614:	eb 12                	jmp    100628 <f1+0x36>
  100616:	8b 45 0c             	mov    0xc(%ebp),%eax
  100619:	89 44 24 04          	mov    %eax,0x4(%esp)
  10061d:	8b 45 08             	mov    0x8(%ebp),%eax
  100620:	89 04 24             	mov    %eax,(%esp)
  100623:	e8 92 ff ff ff       	call   1005ba <f2>
  100628:	c9                   	leave  
  100629:	c3                   	ret    

0010062a <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  10062a:	55                   	push   %ebp
  10062b:	89 e5                	mov    %esp,%ebp
  10062d:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  100633:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10063a:	eb 29                	jmp    100665 <debug_check+0x3b>
		f1(i, eips[i]);
  10063c:	8d 8d 50 ff ff ff    	lea    -0xb0(%ebp),%ecx
  100642:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100645:	89 d0                	mov    %edx,%eax
  100647:	c1 e0 02             	shl    $0x2,%eax
  10064a:	01 d0                	add    %edx,%eax
  10064c:	c1 e0 03             	shl    $0x3,%eax
  10064f:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  100652:	89 44 24 04          	mov    %eax,0x4(%esp)
  100656:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100659:	89 04 24             	mov    %eax,(%esp)
  10065c:	e8 91 ff ff ff       	call   1005f2 <f1>
{
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  100661:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100665:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
  100669:	7e d1                	jle    10063c <debug_check+0x12>
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  10066b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100672:	e9 bc 00 00 00       	jmp    100733 <debug_check+0x109>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100677:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10067e:	e9 a2 00 00 00       	jmp    100725 <debug_check+0xfb>
			assert((eips[r][i] != 0) == (i < 5));
  100683:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100686:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  100689:	89 d0                	mov    %edx,%eax
  10068b:	c1 e0 02             	shl    $0x2,%eax
  10068e:	01 d0                	add    %edx,%eax
  100690:	01 c0                	add    %eax,%eax
  100692:	01 c8                	add    %ecx,%eax
  100694:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  10069b:	85 c0                	test   %eax,%eax
  10069d:	0f 95 c2             	setne  %dl
  1006a0:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
  1006a4:	0f 9e c0             	setle  %al
  1006a7:	31 d0                	xor    %edx,%eax
  1006a9:	84 c0                	test   %al,%al
  1006ab:	74 24                	je     1006d1 <debug_check+0xa7>
  1006ad:	c7 44 24 0c 16 3b 10 	movl   $0x103b16,0xc(%esp)
  1006b4:	00 
  1006b5:	c7 44 24 08 33 3b 10 	movl   $0x103b33,0x8(%esp)
  1006bc:	00 
  1006bd:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
  1006c4:	00 
  1006c5:	c7 04 24 48 3b 10 00 	movl   $0x103b48,(%esp)
  1006cc:	e8 c7 fc ff ff       	call   100398 <debug_panic>
			if (i >= 2)
  1006d1:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
  1006d5:	7e 4a                	jle    100721 <debug_check+0xf7>
				assert(eips[r][i] == eips[0][i]);
  1006d7:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1006da:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  1006dd:	89 d0                	mov    %edx,%eax
  1006df:	c1 e0 02             	shl    $0x2,%eax
  1006e2:	01 d0                	add    %edx,%eax
  1006e4:	01 c0                	add    %eax,%eax
  1006e6:	01 c8                	add    %ecx,%eax
  1006e8:	8b 94 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%edx
  1006ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1006f2:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  1006f9:	39 c2                	cmp    %eax,%edx
  1006fb:	74 24                	je     100721 <debug_check+0xf7>
  1006fd:	c7 44 24 0c 55 3b 10 	movl   $0x103b55,0xc(%esp)
  100704:	00 
  100705:	c7 44 24 08 33 3b 10 	movl   $0x103b33,0x8(%esp)
  10070c:	00 
  10070d:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
  100714:	00 
  100715:	c7 04 24 48 3b 10 00 	movl   $0x103b48,(%esp)
  10071c:	e8 77 fc ff ff       	call   100398 <debug_panic>
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100721:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100725:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  100729:	0f 8e 54 ff ff ff    	jle    100683 <debug_check+0x59>
	// produce several related backtraces...
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  10072f:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  100733:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
  100737:	0f 8e 3a ff ff ff    	jle    100677 <debug_check+0x4d>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
			assert((eips[r][i] != 0) == (i < 5));
			if (i >= 2)
				assert(eips[r][i] == eips[0][i]);
		}
	assert(eips[0][0] == eips[1][0]);
  10073d:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
  100743:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  100749:	39 c2                	cmp    %eax,%edx
  10074b:	74 24                	je     100771 <debug_check+0x147>
  10074d:	c7 44 24 0c 6e 3b 10 	movl   $0x103b6e,0xc(%esp)
  100754:	00 
  100755:	c7 44 24 08 33 3b 10 	movl   $0x103b33,0x8(%esp)
  10075c:	00 
  10075d:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
  100764:	00 
  100765:	c7 04 24 48 3b 10 00 	movl   $0x103b48,(%esp)
  10076c:	e8 27 fc ff ff       	call   100398 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  100771:	8b 55 a0             	mov    -0x60(%ebp),%edx
  100774:	8b 45 c8             	mov    -0x38(%ebp),%eax
  100777:	39 c2                	cmp    %eax,%edx
  100779:	74 24                	je     10079f <debug_check+0x175>
  10077b:	c7 44 24 0c 87 3b 10 	movl   $0x103b87,0xc(%esp)
  100782:	00 
  100783:	c7 44 24 08 33 3b 10 	movl   $0x103b33,0x8(%esp)
  10078a:	00 
  10078b:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
  100792:	00 
  100793:	c7 04 24 48 3b 10 00 	movl   $0x103b48,(%esp)
  10079a:	e8 f9 fb ff ff       	call   100398 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  10079f:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  1007a5:	8b 45 a0             	mov    -0x60(%ebp),%eax
  1007a8:	39 c2                	cmp    %eax,%edx
  1007aa:	75 24                	jne    1007d0 <debug_check+0x1a6>
  1007ac:	c7 44 24 0c a0 3b 10 	movl   $0x103ba0,0xc(%esp)
  1007b3:	00 
  1007b4:	c7 44 24 08 33 3b 10 	movl   $0x103b33,0x8(%esp)
  1007bb:	00 
  1007bc:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  1007c3:	00 
  1007c4:	c7 04 24 48 3b 10 00 	movl   $0x103b48,(%esp)
  1007cb:	e8 c8 fb ff ff       	call   100398 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  1007d0:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  1007d6:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  1007d9:	39 c2                	cmp    %eax,%edx
  1007db:	74 24                	je     100801 <debug_check+0x1d7>
  1007dd:	c7 44 24 0c b9 3b 10 	movl   $0x103bb9,0xc(%esp)
  1007e4:	00 
  1007e5:	c7 44 24 08 33 3b 10 	movl   $0x103b33,0x8(%esp)
  1007ec:	00 
  1007ed:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
  1007f4:	00 
  1007f5:	c7 04 24 48 3b 10 00 	movl   $0x103b48,(%esp)
  1007fc:	e8 97 fb ff ff       	call   100398 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  100801:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  100807:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10080a:	39 c2                	cmp    %eax,%edx
  10080c:	74 24                	je     100832 <debug_check+0x208>
  10080e:	c7 44 24 0c d2 3b 10 	movl   $0x103bd2,0xc(%esp)
  100815:	00 
  100816:	c7 44 24 08 33 3b 10 	movl   $0x103b33,0x8(%esp)
  10081d:	00 
  10081e:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  100825:	00 
  100826:	c7 04 24 48 3b 10 00 	movl   $0x103b48,(%esp)
  10082d:	e8 66 fb ff ff       	call   100398 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  100832:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100838:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  10083e:	39 c2                	cmp    %eax,%edx
  100840:	75 24                	jne    100866 <debug_check+0x23c>
  100842:	c7 44 24 0c eb 3b 10 	movl   $0x103beb,0xc(%esp)
  100849:	00 
  10084a:	c7 44 24 08 33 3b 10 	movl   $0x103b33,0x8(%esp)
  100851:	00 
  100852:	c7 44 24 04 76 00 00 	movl   $0x76,0x4(%esp)
  100859:	00 
  10085a:	c7 04 24 48 3b 10 00 	movl   $0x103b48,(%esp)
  100861:	e8 32 fb ff ff       	call   100398 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  100866:	c7 04 24 04 3c 10 00 	movl   $0x103c04,(%esp)
  10086d:	e8 bf 28 00 00       	call   103131 <cprintf>
}
  100872:	c9                   	leave  
  100873:	c3                   	ret    

00100874 <lockadd>:
}

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  100874:	55                   	push   %ebp
  100875:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  100877:	8b 45 08             	mov    0x8(%ebp),%eax
  10087a:	8b 55 0c             	mov    0xc(%ebp),%edx
  10087d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  100880:	f0 01 10             	lock add %edx,(%eax)
}
  100883:	5d                   	pop    %ebp
  100884:	c3                   	ret    

00100885 <lockaddz>:

// Atomically add incr to *addr and return true if the result is zero.
static inline uint8_t
lockaddz(volatile int32_t *addr, int32_t incr)
{
  100885:	55                   	push   %ebp
  100886:	89 e5                	mov    %esp,%ebp
  100888:	83 ec 10             	sub    $0x10,%esp
	uint8_t zero;
	asm volatile("lock; addl %2,%0; setzb %1"
  10088b:	8b 45 08             	mov    0x8(%ebp),%eax
  10088e:	8b 55 0c             	mov    0xc(%ebp),%edx
  100891:	8b 4d 08             	mov    0x8(%ebp),%ecx
  100894:	f0 01 10             	lock add %edx,(%eax)
  100897:	0f 94 45 ff          	sete   -0x1(%ebp)
		: "+m" (*addr), "=rm" (zero)
		: "r" (incr)
		: "cc");
	return zero;
  10089b:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
  10089f:	c9                   	leave  
  1008a0:	c3                   	ret    

001008a1 <cpu_cur>:


// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1008a1:	55                   	push   %ebp
  1008a2:	89 e5                	mov    %esp,%ebp
  1008a4:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1008a7:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1008aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1008ad:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1008b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1008b3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1008b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1008bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1008be:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  1008c4:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1008c9:	74 24                	je     1008ef <cpu_cur+0x4e>
  1008cb:	c7 44 24 0c 20 3c 10 	movl   $0x103c20,0xc(%esp)
  1008d2:	00 
  1008d3:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  1008da:	00 
  1008db:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  1008e2:	00 
  1008e3:	c7 04 24 4b 3c 10 00 	movl   $0x103c4b,(%esp)
  1008ea:	e8 a9 fa ff ff       	call   100398 <debug_panic>
	return c;
  1008ef:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1008f2:	c9                   	leave  
  1008f3:	c3                   	ret    

001008f4 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1008f4:	55                   	push   %ebp
  1008f5:	89 e5                	mov    %esp,%ebp
  1008f7:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1008fa:	e8 a2 ff ff ff       	call   1008a1 <cpu_cur>
  1008ff:	3d 00 60 10 00       	cmp    $0x106000,%eax
  100904:	0f 94 c0             	sete   %al
  100907:	0f b6 c0             	movzbl %al,%eax
}
  10090a:	c9                   	leave  
  10090b:	c3                   	ret    

0010090c <mem_init>:

void mem_check(void);

void
mem_init(void)
{
  10090c:	55                   	push   %ebp
  10090d:	89 e5                	mov    %esp,%ebp
  10090f:	83 ec 38             	sub    $0x38,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100912:	e8 dd ff ff ff       	call   1008f4 <cpu_onboot>
  100917:	85 c0                	test   %eax,%eax
  100919:	0f 84 44 01 00 00    	je     100a63 <mem_init+0x157>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  10091f:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100926:	e8 c8 1f 00 00       	call   1028f3 <nvram_read16>
  10092b:	c1 e0 0a             	shl    $0xa,%eax
  10092e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100931:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100934:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100939:	89 45 e0             	mov    %eax,-0x20(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  10093c:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  100943:	e8 ab 1f 00 00       	call   1028f3 <nvram_read16>
  100948:	c1 e0 0a             	shl    $0xa,%eax
  10094b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10094e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100951:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100956:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  100959:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10095c:	05 00 00 10 00       	add    $0x100000,%eax
  100961:	a3 78 8f 10 00       	mov    %eax,0x108f78

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  100966:	a1 78 8f 10 00       	mov    0x108f78,%eax
  10096b:	c1 e8 0c             	shr    $0xc,%eax
  10096e:	a3 74 8f 10 00       	mov    %eax,0x108f74

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  100973:	a1 78 8f 10 00       	mov    0x108f78,%eax
  100978:	c1 e8 0a             	shr    $0xa,%eax
  10097b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10097f:	c7 04 24 58 3c 10 00 	movl   $0x103c58,(%esp)
  100986:	e8 a6 27 00 00       	call   103131 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
		(int)(basemem/1024), (int)(extmem/1024));
  10098b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10098e:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100991:	89 c2                	mov    %eax,%edx
		(int)(basemem/1024), (int)(extmem/1024));
  100993:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100996:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100999:	89 54 24 08          	mov    %edx,0x8(%esp)
  10099d:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009a1:	c7 04 24 79 3c 10 00 	movl   $0x103c79,(%esp)
  1009a8:	e8 84 27 00 00       	call   103131 <cprintf>
		(int)(basemem/1024), (int)(extmem/1024));

	
	mem_pageinfo = 	(pageinfo*)(end+1);
  1009ad:	b8 85 8f 10 00       	mov    $0x108f85,%eax
  1009b2:	a3 7c 8f 10 00       	mov    %eax,0x108f7c
	//  5) Then extended memory [MEM_EXT, ...).
	//     Some of it is in use, some is free.
	//     Which pages hold the kernel and the pageinfo array?
	//     (See the comment on the start[] and end[] symbols above.)
	// Change the code to reflect this.
	pageinfo **freetail = &mem_freelist;
  1009b7:	c7 45 e8 70 8f 10 00 	movl   $0x108f70,-0x18(%ebp)
	int i;
	
	for (i = 2; i < mem_npage; i++)
  1009be:	c7 45 ec 02 00 00 00 	movl   $0x2,-0x14(%ebp)
  1009c5:	eb 7c                	jmp    100a43 <mem_init+0x137>
	 {
		// A free page has no references to it.
	//cprintf("\n\n %d  %d %d %d %d \n\n",(int)mem_ph2pi(MEM_IO),(int)mem_ph2pi((int)start),(int)mem_ph2pi(MEM_EXT),(int)mem_ph2pi((int)end),((int)mem_ph2pi((int)mem_max)));
		if ((i<(int)mem_ph2pi(MEM_IO)) ||
  1009c7:	81 7d ec 9f 00 00 00 	cmpl   $0x9f,-0x14(%ebp)
  1009ce:	7e 38                	jle    100a08 <mem_init+0xfc>
				((i>(int)mem_ph2pi((int)(end+mem_npage*sizeof(pageinfo)))) && (i<(int)mem_ph2pi((int)mem_max))))
  1009d0:	a1 74 8f 10 00       	mov    0x108f74,%eax
  1009d5:	c1 e0 03             	shl    $0x3,%eax
  1009d8:	05 84 8f 10 00       	add    $0x108f84,%eax
  1009dd:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
  1009e3:	85 c0                	test   %eax,%eax
  1009e5:	0f 48 c2             	cmovs  %edx,%eax
  1009e8:	c1 f8 0c             	sar    $0xc,%eax
	
	for (i = 2; i < mem_npage; i++)
	 {
		// A free page has no references to it.
	//cprintf("\n\n %d  %d %d %d %d \n\n",(int)mem_ph2pi(MEM_IO),(int)mem_ph2pi((int)start),(int)mem_ph2pi(MEM_EXT),(int)mem_ph2pi((int)end),((int)mem_ph2pi((int)mem_max)));
		if ((i<(int)mem_ph2pi(MEM_IO)) ||
  1009eb:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1009ee:	7d 4f                	jge    100a3f <mem_init+0x133>
				((i>(int)mem_ph2pi((int)(end+mem_npage*sizeof(pageinfo)))) && (i<(int)mem_ph2pi((int)mem_max))))
  1009f0:	a1 78 8f 10 00       	mov    0x108f78,%eax
  1009f5:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
  1009fb:	85 c0                	test   %eax,%eax
  1009fd:	0f 48 c2             	cmovs  %edx,%eax
  100a00:	c1 f8 0c             	sar    $0xc,%eax
	
	for (i = 2; i < mem_npage; i++)
	 {
		// A free page has no references to it.
	//cprintf("\n\n %d  %d %d %d %d \n\n",(int)mem_ph2pi(MEM_IO),(int)mem_ph2pi((int)start),(int)mem_ph2pi(MEM_EXT),(int)mem_ph2pi((int)end),((int)mem_ph2pi((int)mem_max)));
		if ((i<(int)mem_ph2pi(MEM_IO)) ||
  100a03:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  100a06:	7e 37                	jle    100a3f <mem_init+0x133>
				((i>(int)mem_ph2pi((int)(end+mem_npage*sizeof(pageinfo)))) && (i<(int)mem_ph2pi((int)mem_max))))
			{
			mem_pageinfo[i].refcount = 0;
  100a08:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100a0d:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100a10:	c1 e2 03             	shl    $0x3,%edx
  100a13:	01 d0                	add    %edx,%eax
  100a15:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
			// Add the page to the end of the free list.
			*freetail = &mem_pageinfo[i];
  100a1c:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100a21:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100a24:	c1 e2 03             	shl    $0x3,%edx
  100a27:	8d 14 10             	lea    (%eax,%edx,1),%edx
  100a2a:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100a2d:	89 10                	mov    %edx,(%eax)
			freetail = &mem_pageinfo[i].free_next;
  100a2f:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100a34:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100a37:	c1 e2 03             	shl    $0x3,%edx
  100a3a:	01 d0                	add    %edx,%eax
  100a3c:	89 45 e8             	mov    %eax,-0x18(%ebp)
	//     (See the comment on the start[] and end[] symbols above.)
	// Change the code to reflect this.
	pageinfo **freetail = &mem_freelist;
	int i;
	
	for (i = 2; i < mem_npage; i++)
  100a3f:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  100a43:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100a46:	a1 74 8f 10 00       	mov    0x108f74,%eax
  100a4b:	39 c2                	cmp    %eax,%edx
  100a4d:	0f 82 74 ff ff ff    	jb     1009c7 <mem_init+0xbb>
			freetail = &mem_pageinfo[i].free_next;
			
			}
	
	}
	*freetail = NULL;	// null-terminate the freelist
  100a53:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100a56:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
  100a5c:	e8 f5 01 00 00       	call   100c56 <mem_check>
  100a61:	eb 01                	jmp    100a64 <mem_init+0x158>

void
mem_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100a63:	90                   	nop
	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  100a64:	c9                   	leave  
  100a65:	c3                   	ret    

00100a66 <mem_alloc>:
//
// Hint: pi->refs should not be incremented 
// Hint: be sure to use proper mutual exclusion for multiprocessor operation.
pageinfo *
mem_alloc(void)
{
  100a66:	55                   	push   %ebp
  100a67:	89 e5                	mov    %esp,%ebp
  100a69:	83 ec 10             	sub    $0x10,%esp
	// Fill this function in.
	//panic("mem_alloc not implemented.");
	pageinfo* s = mem_freelist;
  100a6c:	a1 70 8f 10 00       	mov    0x108f70,%eax
  100a71:	89 45 fc             	mov    %eax,-0x4(%ebp)
	
	if (mem_freelist==0)
  100a74:	a1 70 8f 10 00       	mov    0x108f70,%eax
  100a79:	85 c0                	test   %eax,%eax
  100a7b:	75 07                	jne    100a84 <mem_alloc+0x1e>
	return NULL;
  100a7d:	b8 00 00 00 00       	mov    $0x0,%eax
  100a82:	eb 0f                	jmp    100a93 <mem_alloc+0x2d>
	else 
	{
	mem_freelist = mem_freelist[0].free_next;
  100a84:	a1 70 8f 10 00       	mov    0x108f70,%eax
  100a89:	8b 00                	mov    (%eax),%eax
  100a8b:	a3 70 8f 10 00       	mov    %eax,0x108f70
	return s;
  100a90:	8b 45 fc             	mov    -0x4(%ebp),%eax
	}
}
  100a93:	c9                   	leave  
  100a94:	c3                   	ret    

00100a95 <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  100a95:	55                   	push   %ebp
  100a96:	89 e5                	mov    %esp,%ebp
	pi[0].free_next = mem_freelist;
  100a98:	8b 15 70 8f 10 00    	mov    0x108f70,%edx
  100a9e:	8b 45 08             	mov    0x8(%ebp),%eax
  100aa1:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  100aa3:	8b 45 08             	mov    0x8(%ebp),%eax
  100aa6:	a3 70 8f 10 00       	mov    %eax,0x108f70
	// Fill this function in.
	//panic("mem_free not implemented.");
}
  100aab:	5d                   	pop    %ebp
  100aac:	c3                   	ret    

00100aad <mem_incref>:

// Atomically increment the reference count on a page.
void
mem_incref(pageinfo *pi)
{
  100aad:	55                   	push   %ebp
  100aae:	89 e5                	mov    %esp,%ebp
  100ab0:	83 ec 18             	sub    $0x18,%esp
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  100ab3:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100ab8:	83 c0 08             	add    $0x8,%eax
  100abb:	3b 45 08             	cmp    0x8(%ebp),%eax
  100abe:	73 15                	jae    100ad5 <mem_incref+0x28>
  100ac0:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100ac5:	8b 15 74 8f 10 00    	mov    0x108f74,%edx
  100acb:	c1 e2 03             	shl    $0x3,%edx
  100ace:	01 d0                	add    %edx,%eax
  100ad0:	3b 45 08             	cmp    0x8(%ebp),%eax
  100ad3:	77 24                	ja     100af9 <mem_incref+0x4c>
  100ad5:	c7 44 24 0c 98 3c 10 	movl   $0x103c98,0xc(%esp)
  100adc:	00 
  100add:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100ae4:	00 
  100ae5:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  100aec:	00 
  100aed:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100af4:	e8 9f f8 ff ff       	call   100398 <debug_panic>
	//LAB1 assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  100af9:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100afe:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  100b03:	c1 ea 0c             	shr    $0xc,%edx
  100b06:	c1 e2 03             	shl    $0x3,%edx
  100b09:	01 d0                	add    %edx,%eax
  100b0b:	3b 45 08             	cmp    0x8(%ebp),%eax
  100b0e:	77 3b                	ja     100b4b <mem_incref+0x9e>
  100b10:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100b15:	ba 83 8f 10 00       	mov    $0x108f83,%edx
  100b1a:	c1 ea 0c             	shr    $0xc,%edx
  100b1d:	c1 e2 03             	shl    $0x3,%edx
  100b20:	01 d0                	add    %edx,%eax
  100b22:	3b 45 08             	cmp    0x8(%ebp),%eax
  100b25:	72 24                	jb     100b4b <mem_incref+0x9e>
  100b27:	c7 44 24 0c dc 3c 10 	movl   $0x103cdc,0xc(%esp)
  100b2e:	00 
  100b2f:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100b36:	00 
  100b37:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
  100b3e:	00 
  100b3f:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100b46:	e8 4d f8 ff ff       	call   100398 <debug_panic>

	lockadd(&pi->refcount, 1);
  100b4b:	8b 45 08             	mov    0x8(%ebp),%eax
  100b4e:	83 c0 04             	add    $0x4,%eax
  100b51:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  100b58:	00 
  100b59:	89 04 24             	mov    %eax,(%esp)
  100b5c:	e8 13 fd ff ff       	call   100874 <lockadd>
}
  100b61:	c9                   	leave  
  100b62:	c3                   	ret    

00100b63 <mem_decref>:

// Atomically decrement the reference count on a page,
// freeing the page if there are no more refs.
void
mem_decref(pageinfo* pi)
{
  100b63:	55                   	push   %ebp
  100b64:	89 e5                	mov    %esp,%ebp
  100b66:	83 ec 18             	sub    $0x18,%esp
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  100b69:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100b6e:	83 c0 08             	add    $0x8,%eax
  100b71:	3b 45 08             	cmp    0x8(%ebp),%eax
  100b74:	73 15                	jae    100b8b <mem_decref+0x28>
  100b76:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100b7b:	8b 15 74 8f 10 00    	mov    0x108f74,%edx
  100b81:	c1 e2 03             	shl    $0x3,%edx
  100b84:	01 d0                	add    %edx,%eax
  100b86:	3b 45 08             	cmp    0x8(%ebp),%eax
  100b89:	77 24                	ja     100baf <mem_decref+0x4c>
  100b8b:	c7 44 24 0c 98 3c 10 	movl   $0x103c98,0xc(%esp)
  100b92:	00 
  100b93:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100b9a:	00 
  100b9b:	c7 44 24 04 a9 00 00 	movl   $0xa9,0x4(%esp)
  100ba2:	00 
  100ba3:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100baa:	e8 e9 f7 ff ff       	call   100398 <debug_panic>
	//LAB1 assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  100baf:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100bb4:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  100bb9:	c1 ea 0c             	shr    $0xc,%edx
  100bbc:	c1 e2 03             	shl    $0x3,%edx
  100bbf:	01 d0                	add    %edx,%eax
  100bc1:	3b 45 08             	cmp    0x8(%ebp),%eax
  100bc4:	77 3b                	ja     100c01 <mem_decref+0x9e>
  100bc6:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100bcb:	ba 83 8f 10 00       	mov    $0x108f83,%edx
  100bd0:	c1 ea 0c             	shr    $0xc,%edx
  100bd3:	c1 e2 03             	shl    $0x3,%edx
  100bd6:	01 d0                	add    %edx,%eax
  100bd8:	3b 45 08             	cmp    0x8(%ebp),%eax
  100bdb:	72 24                	jb     100c01 <mem_decref+0x9e>
  100bdd:	c7 44 24 0c dc 3c 10 	movl   $0x103cdc,0xc(%esp)
  100be4:	00 
  100be5:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100bec:	00 
  100bed:	c7 44 24 04 ab 00 00 	movl   $0xab,0x4(%esp)
  100bf4:	00 
  100bf5:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100bfc:	e8 97 f7 ff ff       	call   100398 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  100c01:	8b 45 08             	mov    0x8(%ebp),%eax
  100c04:	83 c0 04             	add    $0x4,%eax
  100c07:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  100c0e:	ff 
  100c0f:	89 04 24             	mov    %eax,(%esp)
  100c12:	e8 6e fc ff ff       	call   100885 <lockaddz>
  100c17:	84 c0                	test   %al,%al
  100c19:	74 0b                	je     100c26 <mem_decref+0xc3>
			mem_free(pi);
  100c1b:	8b 45 08             	mov    0x8(%ebp),%eax
  100c1e:	89 04 24             	mov    %eax,(%esp)
  100c21:	e8 6f fe ff ff       	call   100a95 <mem_free>
	assert(pi->refcount >= 0);
  100c26:	8b 45 08             	mov    0x8(%ebp),%eax
  100c29:	8b 40 04             	mov    0x4(%eax),%eax
  100c2c:	85 c0                	test   %eax,%eax
  100c2e:	79 24                	jns    100c54 <mem_decref+0xf1>
  100c30:	c7 44 24 0c 0d 3d 10 	movl   $0x103d0d,0xc(%esp)
  100c37:	00 
  100c38:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100c3f:	00 
  100c40:	c7 44 24 04 af 00 00 	movl   $0xaf,0x4(%esp)
  100c47:	00 
  100c48:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100c4f:	e8 44 f7 ff ff       	call   100398 <debug_panic>
}
  100c54:	c9                   	leave  
  100c55:	c3                   	ret    

00100c56 <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  100c56:	55                   	push   %ebp
  100c57:	89 e5                	mov    %esp,%ebp
  100c59:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100c5c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100c63:	a1 70 8f 10 00       	mov    0x108f70,%eax
  100c68:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100c6b:	eb 38                	jmp    100ca5 <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100c6d:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100c70:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100c75:	89 d1                	mov    %edx,%ecx
  100c77:	29 c1                	sub    %eax,%ecx
  100c79:	89 c8                	mov    %ecx,%eax
  100c7b:	c1 f8 03             	sar    $0x3,%eax
  100c7e:	c1 e0 0c             	shl    $0xc,%eax
  100c81:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100c88:	00 
  100c89:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100c90:	00 
  100c91:	89 04 24             	mov    %eax,(%esp)
  100c94:	e8 d9 26 00 00       	call   103372 <memset>
		freepages++;
  100c99:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100c9d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100ca0:	8b 00                	mov    (%eax),%eax
  100ca2:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100ca5:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  100ca9:	75 c2                	jne    100c6d <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100cab:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100cae:	89 44 24 04          	mov    %eax,0x4(%esp)
  100cb2:	c7 04 24 1f 3d 10 00 	movl   $0x103d1f,(%esp)
  100cb9:	e8 73 24 00 00       	call   103131 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100cbe:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100cc1:	a1 74 8f 10 00       	mov    0x108f74,%eax
  100cc6:	39 c2                	cmp    %eax,%edx
  100cc8:	72 24                	jb     100cee <mem_check+0x98>
  100cca:	c7 44 24 0c 39 3d 10 	movl   $0x103d39,0xc(%esp)
  100cd1:	00 
  100cd2:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100cd9:	00 
  100cda:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
  100ce1:	00 
  100ce2:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100ce9:	e8 aa f6 ff ff       	call   100398 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100cee:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100cf5:	7f 24                	jg     100d1b <mem_check+0xc5>
  100cf7:	c7 44 24 0c 4f 3d 10 	movl   $0x103d4f,0xc(%esp)
  100cfe:	00 
  100cff:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100d06:	00 
  100d07:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
  100d0e:	00 
  100d0f:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100d16:	e8 7d f6 ff ff       	call   100398 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  100d1b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100d22:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d25:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100d28:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100d2b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100d2e:	e8 33 fd ff ff       	call   100a66 <mem_alloc>
  100d33:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100d36:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100d3a:	75 24                	jne    100d60 <mem_check+0x10a>
  100d3c:	c7 44 24 0c 61 3d 10 	movl   $0x103d61,0xc(%esp)
  100d43:	00 
  100d44:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100d4b:	00 
  100d4c:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
  100d53:	00 
  100d54:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100d5b:	e8 38 f6 ff ff       	call   100398 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100d60:	e8 01 fd ff ff       	call   100a66 <mem_alloc>
  100d65:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100d68:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d6c:	75 24                	jne    100d92 <mem_check+0x13c>
  100d6e:	c7 44 24 0c 6a 3d 10 	movl   $0x103d6a,0xc(%esp)
  100d75:	00 
  100d76:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100d7d:	00 
  100d7e:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
  100d85:	00 
  100d86:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100d8d:	e8 06 f6 ff ff       	call   100398 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100d92:	e8 cf fc ff ff       	call   100a66 <mem_alloc>
  100d97:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100d9a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100d9e:	75 24                	jne    100dc4 <mem_check+0x16e>
  100da0:	c7 44 24 0c 73 3d 10 	movl   $0x103d73,0xc(%esp)
  100da7:	00 
  100da8:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100daf:	00 
  100db0:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  100db7:	00 
  100db8:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100dbf:	e8 d4 f5 ff ff       	call   100398 <debug_panic>

	assert(pp0);
  100dc4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100dc8:	75 24                	jne    100dee <mem_check+0x198>
  100dca:	c7 44 24 0c 7c 3d 10 	movl   $0x103d7c,0xc(%esp)
  100dd1:	00 
  100dd2:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100dd9:	00 
  100dda:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  100de1:	00 
  100de2:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100de9:	e8 aa f5 ff ff       	call   100398 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100dee:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100df2:	74 08                	je     100dfc <mem_check+0x1a6>
  100df4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100df7:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100dfa:	75 24                	jne    100e20 <mem_check+0x1ca>
  100dfc:	c7 44 24 0c 80 3d 10 	movl   $0x103d80,0xc(%esp)
  100e03:	00 
  100e04:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100e0b:	00 
  100e0c:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
  100e13:	00 
  100e14:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100e1b:	e8 78 f5 ff ff       	call   100398 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100e20:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100e24:	74 10                	je     100e36 <mem_check+0x1e0>
  100e26:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100e29:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100e2c:	74 08                	je     100e36 <mem_check+0x1e0>
  100e2e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100e31:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100e34:	75 24                	jne    100e5a <mem_check+0x204>
  100e36:	c7 44 24 0c 94 3d 10 	movl   $0x103d94,0xc(%esp)
  100e3d:	00 
  100e3e:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100e45:	00 
  100e46:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  100e4d:	00 
  100e4e:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100e55:	e8 3e f5 ff ff       	call   100398 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100e5a:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100e5d:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100e62:	89 d1                	mov    %edx,%ecx
  100e64:	29 c1                	sub    %eax,%ecx
  100e66:	89 c8                	mov    %ecx,%eax
  100e68:	c1 f8 03             	sar    $0x3,%eax
  100e6b:	c1 e0 0c             	shl    $0xc,%eax
  100e6e:	8b 15 74 8f 10 00    	mov    0x108f74,%edx
  100e74:	c1 e2 0c             	shl    $0xc,%edx
  100e77:	39 d0                	cmp    %edx,%eax
  100e79:	72 24                	jb     100e9f <mem_check+0x249>
  100e7b:	c7 44 24 0c b4 3d 10 	movl   $0x103db4,0xc(%esp)
  100e82:	00 
  100e83:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100e8a:	00 
  100e8b:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  100e92:	00 
  100e93:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100e9a:	e8 f9 f4 ff ff       	call   100398 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100e9f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100ea2:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100ea7:	89 d1                	mov    %edx,%ecx
  100ea9:	29 c1                	sub    %eax,%ecx
  100eab:	89 c8                	mov    %ecx,%eax
  100ead:	c1 f8 03             	sar    $0x3,%eax
  100eb0:	c1 e0 0c             	shl    $0xc,%eax
  100eb3:	8b 15 74 8f 10 00    	mov    0x108f74,%edx
  100eb9:	c1 e2 0c             	shl    $0xc,%edx
  100ebc:	39 d0                	cmp    %edx,%eax
  100ebe:	72 24                	jb     100ee4 <mem_check+0x28e>
  100ec0:	c7 44 24 0c dc 3d 10 	movl   $0x103ddc,0xc(%esp)
  100ec7:	00 
  100ec8:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100ecf:	00 
  100ed0:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
  100ed7:	00 
  100ed8:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100edf:	e8 b4 f4 ff ff       	call   100398 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100ee4:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100ee7:	a1 7c 8f 10 00       	mov    0x108f7c,%eax
  100eec:	89 d1                	mov    %edx,%ecx
  100eee:	29 c1                	sub    %eax,%ecx
  100ef0:	89 c8                	mov    %ecx,%eax
  100ef2:	c1 f8 03             	sar    $0x3,%eax
  100ef5:	c1 e0 0c             	shl    $0xc,%eax
  100ef8:	8b 15 74 8f 10 00    	mov    0x108f74,%edx
  100efe:	c1 e2 0c             	shl    $0xc,%edx
  100f01:	39 d0                	cmp    %edx,%eax
  100f03:	72 24                	jb     100f29 <mem_check+0x2d3>
  100f05:	c7 44 24 0c 04 3e 10 	movl   $0x103e04,0xc(%esp)
  100f0c:	00 
  100f0d:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100f14:	00 
  100f15:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  100f1c:	00 
  100f1d:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100f24:	e8 6f f4 ff ff       	call   100398 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100f29:	a1 70 8f 10 00       	mov    0x108f70,%eax
  100f2e:	89 45 ec             	mov    %eax,-0x14(%ebp)
	mem_freelist = 0;
  100f31:	c7 05 70 8f 10 00 00 	movl   $0x0,0x108f70
  100f38:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100f3b:	e8 26 fb ff ff       	call   100a66 <mem_alloc>
  100f40:	85 c0                	test   %eax,%eax
  100f42:	74 24                	je     100f68 <mem_check+0x312>
  100f44:	c7 44 24 0c 2a 3e 10 	movl   $0x103e2a,0xc(%esp)
  100f4b:	00 
  100f4c:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100f53:	00 
  100f54:	c7 44 24 04 db 00 00 	movl   $0xdb,0x4(%esp)
  100f5b:	00 
  100f5c:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100f63:	e8 30 f4 ff ff       	call   100398 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  100f68:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100f6b:	89 04 24             	mov    %eax,(%esp)
  100f6e:	e8 22 fb ff ff       	call   100a95 <mem_free>
        mem_free(pp1);
  100f73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100f76:	89 04 24             	mov    %eax,(%esp)
  100f79:	e8 17 fb ff ff       	call   100a95 <mem_free>
        mem_free(pp2);
  100f7e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100f81:	89 04 24             	mov    %eax,(%esp)
  100f84:	e8 0c fb ff ff       	call   100a95 <mem_free>
	pp0 = pp1 = pp2 = 0;
  100f89:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100f90:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100f93:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100f96:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100f99:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100f9c:	e8 c5 fa ff ff       	call   100a66 <mem_alloc>
  100fa1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100fa4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100fa8:	75 24                	jne    100fce <mem_check+0x378>
  100faa:	c7 44 24 0c 61 3d 10 	movl   $0x103d61,0xc(%esp)
  100fb1:	00 
  100fb2:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100fb9:	00 
  100fba:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  100fc1:	00 
  100fc2:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100fc9:	e8 ca f3 ff ff       	call   100398 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100fce:	e8 93 fa ff ff       	call   100a66 <mem_alloc>
  100fd3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100fd6:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100fda:	75 24                	jne    101000 <mem_check+0x3aa>
  100fdc:	c7 44 24 0c 6a 3d 10 	movl   $0x103d6a,0xc(%esp)
  100fe3:	00 
  100fe4:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  100feb:	00 
  100fec:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  100ff3:	00 
  100ff4:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  100ffb:	e8 98 f3 ff ff       	call   100398 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  101000:	e8 61 fa ff ff       	call   100a66 <mem_alloc>
  101005:	89 45 e8             	mov    %eax,-0x18(%ebp)
  101008:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  10100c:	75 24                	jne    101032 <mem_check+0x3dc>
  10100e:	c7 44 24 0c 73 3d 10 	movl   $0x103d73,0xc(%esp)
  101015:	00 
  101016:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  10101d:	00 
  10101e:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  101025:	00 
  101026:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  10102d:	e8 66 f3 ff ff       	call   100398 <debug_panic>
	assert(pp0);
  101032:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  101036:	75 24                	jne    10105c <mem_check+0x406>
  101038:	c7 44 24 0c 7c 3d 10 	movl   $0x103d7c,0xc(%esp)
  10103f:	00 
  101040:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  101047:	00 
  101048:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
  10104f:	00 
  101050:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  101057:	e8 3c f3 ff ff       	call   100398 <debug_panic>
	assert(pp1 && pp1 != pp0);
  10105c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  101060:	74 08                	je     10106a <mem_check+0x414>
  101062:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101065:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  101068:	75 24                	jne    10108e <mem_check+0x438>
  10106a:	c7 44 24 0c 80 3d 10 	movl   $0x103d80,0xc(%esp)
  101071:	00 
  101072:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  101079:	00 
  10107a:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
  101081:	00 
  101082:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  101089:	e8 0a f3 ff ff       	call   100398 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  10108e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  101092:	74 10                	je     1010a4 <mem_check+0x44e>
  101094:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101097:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  10109a:	74 08                	je     1010a4 <mem_check+0x44e>
  10109c:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10109f:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  1010a2:	75 24                	jne    1010c8 <mem_check+0x472>
  1010a4:	c7 44 24 0c 94 3d 10 	movl   $0x103d94,0xc(%esp)
  1010ab:	00 
  1010ac:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  1010b3:	00 
  1010b4:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  1010bb:	00 
  1010bc:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  1010c3:	e8 d0 f2 ff ff       	call   100398 <debug_panic>
	assert(mem_alloc() == 0);
  1010c8:	e8 99 f9 ff ff       	call   100a66 <mem_alloc>
  1010cd:	85 c0                	test   %eax,%eax
  1010cf:	74 24                	je     1010f5 <mem_check+0x49f>
  1010d1:	c7 44 24 0c 2a 3e 10 	movl   $0x103e2a,0xc(%esp)
  1010d8:	00 
  1010d9:	c7 44 24 08 36 3c 10 	movl   $0x103c36,0x8(%esp)
  1010e0:	00 
  1010e1:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  1010e8:	00 
  1010e9:	c7 04 24 cf 3c 10 00 	movl   $0x103ccf,(%esp)
  1010f0:	e8 a3 f2 ff ff       	call   100398 <debug_panic>

	// give free list back
	mem_freelist = fl;
  1010f5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1010f8:	a3 70 8f 10 00       	mov    %eax,0x108f70

	// free the pages we took
	mem_free(pp0);
  1010fd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101100:	89 04 24             	mov    %eax,(%esp)
  101103:	e8 8d f9 ff ff       	call   100a95 <mem_free>
	mem_free(pp1);
  101108:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10110b:	89 04 24             	mov    %eax,(%esp)
  10110e:	e8 82 f9 ff ff       	call   100a95 <mem_free>
	mem_free(pp2);
  101113:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101116:	89 04 24             	mov    %eax,(%esp)
  101119:	e8 77 f9 ff ff       	call   100a95 <mem_free>

	cprintf("mem_check() succeeded!\n");
  10111e:	c7 04 24 3b 3e 10 00 	movl   $0x103e3b,(%esp)
  101125:	e8 07 20 00 00       	call   103131 <cprintf>
}
  10112a:	c9                   	leave  
  10112b:	c3                   	ret    

0010112c <cpu_cur>:


// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10112c:	55                   	push   %ebp
  10112d:	89 e5                	mov    %esp,%ebp
  10112f:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101132:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  101135:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101138:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10113b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10113e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101143:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  101146:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101149:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  10114f:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101154:	74 24                	je     10117a <cpu_cur+0x4e>
  101156:	c7 44 24 0c 53 3e 10 	movl   $0x103e53,0xc(%esp)
  10115d:	00 
  10115e:	c7 44 24 08 69 3e 10 	movl   $0x103e69,0x8(%esp)
  101165:	00 
  101166:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  10116d:	00 
  10116e:	c7 04 24 7e 3e 10 00 	movl   $0x103e7e,(%esp)
  101175:	e8 1e f2 ff ff       	call   100398 <debug_panic>
	return c;
  10117a:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10117d:	c9                   	leave  
  10117e:	c3                   	ret    

0010117f <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  10117f:	55                   	push   %ebp
  101180:	89 e5                	mov    %esp,%ebp
  101182:	53                   	push   %ebx
  101183:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  101186:	e8 a1 ff ff ff       	call   10112c <cpu_cur>
  10118b:	89 45 f0             	mov    %eax,-0x10(%ebp)

	//setting up TSS
	c->tss.ts_esp0 = (uintptr_t) &c->kstackhi;
  10118e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101191:	05 00 10 00 00       	add    $0x1000,%eax
  101196:	89 c2                	mov    %eax,%edx
  101198:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10119b:	89 50 34             	mov    %edx,0x34(%eax)
	c->tss.ts_ss0 =CPU_GDT_KDATA;
  10119e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011a1:	66 c7 40 38 10 00    	movw   $0x10,0x38(%eax)
	c->gdt[CPU_GDT_TSS>>3] = SEGDESC32(STS_T32A,(uintptr_t)&c->tss,sizeof(taskstate),0);
  1011a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011aa:	83 c0 30             	add    $0x30,%eax
  1011ad:	89 c3                	mov    %eax,%ebx
  1011af:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011b2:	83 c0 30             	add    $0x30,%eax
  1011b5:	c1 e8 10             	shr    $0x10,%eax
  1011b8:	89 c1                	mov    %eax,%ecx
  1011ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011bd:	83 c0 30             	add    $0x30,%eax
  1011c0:	c1 e8 18             	shr    $0x18,%eax
  1011c3:	89 c2                	mov    %eax,%edx
  1011c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011c8:	66 c7 40 28 00 00    	movw   $0x0,0x28(%eax)
  1011ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011d1:	66 89 58 2a          	mov    %bx,0x2a(%eax)
  1011d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011d8:	88 48 2c             	mov    %cl,0x2c(%eax)
  1011db:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011de:	0f b6 48 2d          	movzbl 0x2d(%eax),%ecx
  1011e2:	83 e1 f0             	and    $0xfffffff0,%ecx
  1011e5:	83 c9 09             	or     $0x9,%ecx
  1011e8:	88 48 2d             	mov    %cl,0x2d(%eax)
  1011eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011ee:	0f b6 48 2d          	movzbl 0x2d(%eax),%ecx
  1011f2:	83 c9 10             	or     $0x10,%ecx
  1011f5:	88 48 2d             	mov    %cl,0x2d(%eax)
  1011f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011fb:	0f b6 48 2d          	movzbl 0x2d(%eax),%ecx
  1011ff:	83 e1 9f             	and    $0xffffff9f,%ecx
  101202:	88 48 2d             	mov    %cl,0x2d(%eax)
  101205:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101208:	0f b6 48 2d          	movzbl 0x2d(%eax),%ecx
  10120c:	83 c9 80             	or     $0xffffff80,%ecx
  10120f:	88 48 2d             	mov    %cl,0x2d(%eax)
  101212:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101215:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
  101219:	83 e1 f0             	and    $0xfffffff0,%ecx
  10121c:	88 48 2e             	mov    %cl,0x2e(%eax)
  10121f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101222:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
  101226:	83 e1 ef             	and    $0xffffffef,%ecx
  101229:	88 48 2e             	mov    %cl,0x2e(%eax)
  10122c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10122f:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
  101233:	83 e1 df             	and    $0xffffffdf,%ecx
  101236:	88 48 2e             	mov    %cl,0x2e(%eax)
  101239:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10123c:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
  101240:	83 c9 40             	or     $0x40,%ecx
  101243:	88 48 2e             	mov    %cl,0x2e(%eax)
  101246:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101249:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
  10124d:	83 c9 80             	or     $0xffffff80,%ecx
  101250:	88 48 2e             	mov    %cl,0x2e(%eax)
  101253:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101256:	88 50 2f             	mov    %dl,0x2f(%eax)
	c->gdt[CPU_GDT_TSS>>3].sd_s = 0;
  101259:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10125c:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
  101260:	83 e2 ef             	and    $0xffffffef,%edx
  101263:	88 50 2d             	mov    %dl,0x2d(%eax)
	
	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  101266:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101269:	66 c7 45 ea 2f 00    	movw   $0x2f,-0x16(%ebp)
  10126f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  101272:	0f 01 55 ea          	lgdtl  -0x16(%ebp)

	

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  101276:	b8 23 00 00 00       	mov    $0x23,%eax
  10127b:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  10127d:	b8 23 00 00 00       	mov    $0x23,%eax
  101282:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  101284:	b8 10 00 00 00       	mov    $0x10,%eax
  101289:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  10128b:	b8 10 00 00 00       	mov    $0x10,%eax
  101290:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  101292:	b8 10 00 00 00       	mov    $0x10,%eax
  101297:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  101299:	ea a0 12 10 00 08 00 	ljmp   $0x8,$0x1012a0

	
	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  1012a0:	b8 00 00 00 00       	mov    $0x0,%eax
  1012a5:	0f 00 d0             	lldt   %ax
  1012a8:	66 c7 45 f6 28 00    	movw   $0x28,-0xa(%ebp)
}

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  1012ae:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  1012b2:	0f 00 d8             	ltr    %ax
	//__asm __volatile("ltr %0" : : "r" (CPU_GDT_TSS));
	ltr(CPU_GDT_TSS);
}
  1012b5:	83 c4 14             	add    $0x14,%esp
  1012b8:	5b                   	pop    %ebx
  1012b9:	5d                   	pop    %ebp
  1012ba:	c3                   	ret    
  1012bb:	90                   	nop

001012bc <cpu_cur>:


// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1012bc:	55                   	push   %ebp
  1012bd:	89 e5                	mov    %esp,%ebp
  1012bf:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1012c2:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1012c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1012c8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1012cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012ce:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1012d3:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1012d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1012d9:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  1012df:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1012e4:	74 24                	je     10130a <cpu_cur+0x4e>
  1012e6:	c7 44 24 0c a0 3e 10 	movl   $0x103ea0,0xc(%esp)
  1012ed:	00 
  1012ee:	c7 44 24 08 b6 3e 10 	movl   $0x103eb6,0x8(%esp)
  1012f5:	00 
  1012f6:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  1012fd:	00 
  1012fe:	c7 04 24 cb 3e 10 00 	movl   $0x103ecb,(%esp)
  101305:	e8 8e f0 ff ff       	call   100398 <debug_panic>
	return c;
  10130a:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10130d:	c9                   	leave  
  10130e:	c3                   	ret    

0010130f <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10130f:	55                   	push   %ebp
  101310:	89 e5                	mov    %esp,%ebp
  101312:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  101315:	e8 a2 ff ff ff       	call   1012bc <cpu_cur>
  10131a:	3d 00 60 10 00       	cmp    $0x106000,%eax
  10131f:	0f 94 c0             	sete   %al
  101322:	0f b6 c0             	movzbl %al,%eax
}
  101325:	c9                   	leave  
  101326:	c3                   	ret    

00101327 <trap_init_idt>:
};


static void
trap_init_idt(void)
{
  101327:	55                   	push   %ebp
  101328:	89 e5                	mov    %esp,%ebp
	extern void handler14();
	extern void handler16();
	extern void handler17();
	extern void handler19();

	SETGATE(idt[0],1,0x8,&handler0,0);
  10132a:	b8 80 21 10 00       	mov    $0x102180,%eax
  10132f:	66 a3 60 87 10 00    	mov    %ax,0x108760
  101335:	66 c7 05 62 87 10 00 	movw   $0x8,0x108762
  10133c:	08 00 
  10133e:	0f b6 05 64 87 10 00 	movzbl 0x108764,%eax
  101345:	83 e0 e0             	and    $0xffffffe0,%eax
  101348:	a2 64 87 10 00       	mov    %al,0x108764
  10134d:	0f b6 05 64 87 10 00 	movzbl 0x108764,%eax
  101354:	83 e0 1f             	and    $0x1f,%eax
  101357:	a2 64 87 10 00       	mov    %al,0x108764
  10135c:	0f b6 05 65 87 10 00 	movzbl 0x108765,%eax
  101363:	83 c8 0f             	or     $0xf,%eax
  101366:	a2 65 87 10 00       	mov    %al,0x108765
  10136b:	0f b6 05 65 87 10 00 	movzbl 0x108765,%eax
  101372:	83 e0 ef             	and    $0xffffffef,%eax
  101375:	a2 65 87 10 00       	mov    %al,0x108765
  10137a:	0f b6 05 65 87 10 00 	movzbl 0x108765,%eax
  101381:	83 e0 9f             	and    $0xffffff9f,%eax
  101384:	a2 65 87 10 00       	mov    %al,0x108765
  101389:	0f b6 05 65 87 10 00 	movzbl 0x108765,%eax
  101390:	83 c8 80             	or     $0xffffff80,%eax
  101393:	a2 65 87 10 00       	mov    %al,0x108765
  101398:	b8 80 21 10 00       	mov    $0x102180,%eax
  10139d:	c1 e8 10             	shr    $0x10,%eax
  1013a0:	66 a3 66 87 10 00    	mov    %ax,0x108766
	SETGATE(idt[3],1,0x8,&handler3,3);	
  1013a6:	b8 86 21 10 00       	mov    $0x102186,%eax
  1013ab:	66 a3 78 87 10 00    	mov    %ax,0x108778
  1013b1:	66 c7 05 7a 87 10 00 	movw   $0x8,0x10877a
  1013b8:	08 00 
  1013ba:	0f b6 05 7c 87 10 00 	movzbl 0x10877c,%eax
  1013c1:	83 e0 e0             	and    $0xffffffe0,%eax
  1013c4:	a2 7c 87 10 00       	mov    %al,0x10877c
  1013c9:	0f b6 05 7c 87 10 00 	movzbl 0x10877c,%eax
  1013d0:	83 e0 1f             	and    $0x1f,%eax
  1013d3:	a2 7c 87 10 00       	mov    %al,0x10877c
  1013d8:	0f b6 05 7d 87 10 00 	movzbl 0x10877d,%eax
  1013df:	83 c8 0f             	or     $0xf,%eax
  1013e2:	a2 7d 87 10 00       	mov    %al,0x10877d
  1013e7:	0f b6 05 7d 87 10 00 	movzbl 0x10877d,%eax
  1013ee:	83 e0 ef             	and    $0xffffffef,%eax
  1013f1:	a2 7d 87 10 00       	mov    %al,0x10877d
  1013f6:	0f b6 05 7d 87 10 00 	movzbl 0x10877d,%eax
  1013fd:	83 c8 60             	or     $0x60,%eax
  101400:	a2 7d 87 10 00       	mov    %al,0x10877d
  101405:	0f b6 05 7d 87 10 00 	movzbl 0x10877d,%eax
  10140c:	83 c8 80             	or     $0xffffff80,%eax
  10140f:	a2 7d 87 10 00       	mov    %al,0x10877d
  101414:	b8 86 21 10 00       	mov    $0x102186,%eax
  101419:	c1 e8 10             	shr    $0x10,%eax
  10141c:	66 a3 7e 87 10 00    	mov    %ax,0x10877e
	SETGATE(idt[4],1,0x8,&handler4,3);	
  101422:	b8 8c 21 10 00       	mov    $0x10218c,%eax
  101427:	66 a3 80 87 10 00    	mov    %ax,0x108780
  10142d:	66 c7 05 82 87 10 00 	movw   $0x8,0x108782
  101434:	08 00 
  101436:	0f b6 05 84 87 10 00 	movzbl 0x108784,%eax
  10143d:	83 e0 e0             	and    $0xffffffe0,%eax
  101440:	a2 84 87 10 00       	mov    %al,0x108784
  101445:	0f b6 05 84 87 10 00 	movzbl 0x108784,%eax
  10144c:	83 e0 1f             	and    $0x1f,%eax
  10144f:	a2 84 87 10 00       	mov    %al,0x108784
  101454:	0f b6 05 85 87 10 00 	movzbl 0x108785,%eax
  10145b:	83 c8 0f             	or     $0xf,%eax
  10145e:	a2 85 87 10 00       	mov    %al,0x108785
  101463:	0f b6 05 85 87 10 00 	movzbl 0x108785,%eax
  10146a:	83 e0 ef             	and    $0xffffffef,%eax
  10146d:	a2 85 87 10 00       	mov    %al,0x108785
  101472:	0f b6 05 85 87 10 00 	movzbl 0x108785,%eax
  101479:	83 c8 60             	or     $0x60,%eax
  10147c:	a2 85 87 10 00       	mov    %al,0x108785
  101481:	0f b6 05 85 87 10 00 	movzbl 0x108785,%eax
  101488:	83 c8 80             	or     $0xffffff80,%eax
  10148b:	a2 85 87 10 00       	mov    %al,0x108785
  101490:	b8 8c 21 10 00       	mov    $0x10218c,%eax
  101495:	c1 e8 10             	shr    $0x10,%eax
  101498:	66 a3 86 87 10 00    	mov    %ax,0x108786
	SETGATE(idt[5],1,0x8,&handler5,0);
  10149e:	b8 92 21 10 00       	mov    $0x102192,%eax
  1014a3:	66 a3 88 87 10 00    	mov    %ax,0x108788
  1014a9:	66 c7 05 8a 87 10 00 	movw   $0x8,0x10878a
  1014b0:	08 00 
  1014b2:	0f b6 05 8c 87 10 00 	movzbl 0x10878c,%eax
  1014b9:	83 e0 e0             	and    $0xffffffe0,%eax
  1014bc:	a2 8c 87 10 00       	mov    %al,0x10878c
  1014c1:	0f b6 05 8c 87 10 00 	movzbl 0x10878c,%eax
  1014c8:	83 e0 1f             	and    $0x1f,%eax
  1014cb:	a2 8c 87 10 00       	mov    %al,0x10878c
  1014d0:	0f b6 05 8d 87 10 00 	movzbl 0x10878d,%eax
  1014d7:	83 c8 0f             	or     $0xf,%eax
  1014da:	a2 8d 87 10 00       	mov    %al,0x10878d
  1014df:	0f b6 05 8d 87 10 00 	movzbl 0x10878d,%eax
  1014e6:	83 e0 ef             	and    $0xffffffef,%eax
  1014e9:	a2 8d 87 10 00       	mov    %al,0x10878d
  1014ee:	0f b6 05 8d 87 10 00 	movzbl 0x10878d,%eax
  1014f5:	83 e0 9f             	and    $0xffffff9f,%eax
  1014f8:	a2 8d 87 10 00       	mov    %al,0x10878d
  1014fd:	0f b6 05 8d 87 10 00 	movzbl 0x10878d,%eax
  101504:	83 c8 80             	or     $0xffffff80,%eax
  101507:	a2 8d 87 10 00       	mov    %al,0x10878d
  10150c:	b8 92 21 10 00       	mov    $0x102192,%eax
  101511:	c1 e8 10             	shr    $0x10,%eax
  101514:	66 a3 8e 87 10 00    	mov    %ax,0x10878e
	SETGATE(idt[6],1,0x8,&handler6,0);
  10151a:	b8 98 21 10 00       	mov    $0x102198,%eax
  10151f:	66 a3 90 87 10 00    	mov    %ax,0x108790
  101525:	66 c7 05 92 87 10 00 	movw   $0x8,0x108792
  10152c:	08 00 
  10152e:	0f b6 05 94 87 10 00 	movzbl 0x108794,%eax
  101535:	83 e0 e0             	and    $0xffffffe0,%eax
  101538:	a2 94 87 10 00       	mov    %al,0x108794
  10153d:	0f b6 05 94 87 10 00 	movzbl 0x108794,%eax
  101544:	83 e0 1f             	and    $0x1f,%eax
  101547:	a2 94 87 10 00       	mov    %al,0x108794
  10154c:	0f b6 05 95 87 10 00 	movzbl 0x108795,%eax
  101553:	83 c8 0f             	or     $0xf,%eax
  101556:	a2 95 87 10 00       	mov    %al,0x108795
  10155b:	0f b6 05 95 87 10 00 	movzbl 0x108795,%eax
  101562:	83 e0 ef             	and    $0xffffffef,%eax
  101565:	a2 95 87 10 00       	mov    %al,0x108795
  10156a:	0f b6 05 95 87 10 00 	movzbl 0x108795,%eax
  101571:	83 e0 9f             	and    $0xffffff9f,%eax
  101574:	a2 95 87 10 00       	mov    %al,0x108795
  101579:	0f b6 05 95 87 10 00 	movzbl 0x108795,%eax
  101580:	83 c8 80             	or     $0xffffff80,%eax
  101583:	a2 95 87 10 00       	mov    %al,0x108795
  101588:	b8 98 21 10 00       	mov    $0x102198,%eax
  10158d:	c1 e8 10             	shr    $0x10,%eax
  101590:	66 a3 96 87 10 00    	mov    %ax,0x108796
	SETGATE(idt[7],1,0x8,&handler7,0);
  101596:	b8 9e 21 10 00       	mov    $0x10219e,%eax
  10159b:	66 a3 98 87 10 00    	mov    %ax,0x108798
  1015a1:	66 c7 05 9a 87 10 00 	movw   $0x8,0x10879a
  1015a8:	08 00 
  1015aa:	0f b6 05 9c 87 10 00 	movzbl 0x10879c,%eax
  1015b1:	83 e0 e0             	and    $0xffffffe0,%eax
  1015b4:	a2 9c 87 10 00       	mov    %al,0x10879c
  1015b9:	0f b6 05 9c 87 10 00 	movzbl 0x10879c,%eax
  1015c0:	83 e0 1f             	and    $0x1f,%eax
  1015c3:	a2 9c 87 10 00       	mov    %al,0x10879c
  1015c8:	0f b6 05 9d 87 10 00 	movzbl 0x10879d,%eax
  1015cf:	83 c8 0f             	or     $0xf,%eax
  1015d2:	a2 9d 87 10 00       	mov    %al,0x10879d
  1015d7:	0f b6 05 9d 87 10 00 	movzbl 0x10879d,%eax
  1015de:	83 e0 ef             	and    $0xffffffef,%eax
  1015e1:	a2 9d 87 10 00       	mov    %al,0x10879d
  1015e6:	0f b6 05 9d 87 10 00 	movzbl 0x10879d,%eax
  1015ed:	83 e0 9f             	and    $0xffffff9f,%eax
  1015f0:	a2 9d 87 10 00       	mov    %al,0x10879d
  1015f5:	0f b6 05 9d 87 10 00 	movzbl 0x10879d,%eax
  1015fc:	83 c8 80             	or     $0xffffff80,%eax
  1015ff:	a2 9d 87 10 00       	mov    %al,0x10879d
  101604:	b8 9e 21 10 00       	mov    $0x10219e,%eax
  101609:	c1 e8 10             	shr    $0x10,%eax
  10160c:	66 a3 9e 87 10 00    	mov    %ax,0x10879e
	SETGATE(idt[10],1,0x8,&handler10,0);
  101612:	b8 a4 21 10 00       	mov    $0x1021a4,%eax
  101617:	66 a3 b0 87 10 00    	mov    %ax,0x1087b0
  10161d:	66 c7 05 b2 87 10 00 	movw   $0x8,0x1087b2
  101624:	08 00 
  101626:	0f b6 05 b4 87 10 00 	movzbl 0x1087b4,%eax
  10162d:	83 e0 e0             	and    $0xffffffe0,%eax
  101630:	a2 b4 87 10 00       	mov    %al,0x1087b4
  101635:	0f b6 05 b4 87 10 00 	movzbl 0x1087b4,%eax
  10163c:	83 e0 1f             	and    $0x1f,%eax
  10163f:	a2 b4 87 10 00       	mov    %al,0x1087b4
  101644:	0f b6 05 b5 87 10 00 	movzbl 0x1087b5,%eax
  10164b:	83 c8 0f             	or     $0xf,%eax
  10164e:	a2 b5 87 10 00       	mov    %al,0x1087b5
  101653:	0f b6 05 b5 87 10 00 	movzbl 0x1087b5,%eax
  10165a:	83 e0 ef             	and    $0xffffffef,%eax
  10165d:	a2 b5 87 10 00       	mov    %al,0x1087b5
  101662:	0f b6 05 b5 87 10 00 	movzbl 0x1087b5,%eax
  101669:	83 e0 9f             	and    $0xffffff9f,%eax
  10166c:	a2 b5 87 10 00       	mov    %al,0x1087b5
  101671:	0f b6 05 b5 87 10 00 	movzbl 0x1087b5,%eax
  101678:	83 c8 80             	or     $0xffffff80,%eax
  10167b:	a2 b5 87 10 00       	mov    %al,0x1087b5
  101680:	b8 a4 21 10 00       	mov    $0x1021a4,%eax
  101685:	c1 e8 10             	shr    $0x10,%eax
  101688:	66 a3 b6 87 10 00    	mov    %ax,0x1087b6
	SETGATE(idt[11],1,0x8,&handler11,0);
  10168e:	b8 a8 21 10 00       	mov    $0x1021a8,%eax
  101693:	66 a3 b8 87 10 00    	mov    %ax,0x1087b8
  101699:	66 c7 05 ba 87 10 00 	movw   $0x8,0x1087ba
  1016a0:	08 00 
  1016a2:	0f b6 05 bc 87 10 00 	movzbl 0x1087bc,%eax
  1016a9:	83 e0 e0             	and    $0xffffffe0,%eax
  1016ac:	a2 bc 87 10 00       	mov    %al,0x1087bc
  1016b1:	0f b6 05 bc 87 10 00 	movzbl 0x1087bc,%eax
  1016b8:	83 e0 1f             	and    $0x1f,%eax
  1016bb:	a2 bc 87 10 00       	mov    %al,0x1087bc
  1016c0:	0f b6 05 bd 87 10 00 	movzbl 0x1087bd,%eax
  1016c7:	83 c8 0f             	or     $0xf,%eax
  1016ca:	a2 bd 87 10 00       	mov    %al,0x1087bd
  1016cf:	0f b6 05 bd 87 10 00 	movzbl 0x1087bd,%eax
  1016d6:	83 e0 ef             	and    $0xffffffef,%eax
  1016d9:	a2 bd 87 10 00       	mov    %al,0x1087bd
  1016de:	0f b6 05 bd 87 10 00 	movzbl 0x1087bd,%eax
  1016e5:	83 e0 9f             	and    $0xffffff9f,%eax
  1016e8:	a2 bd 87 10 00       	mov    %al,0x1087bd
  1016ed:	0f b6 05 bd 87 10 00 	movzbl 0x1087bd,%eax
  1016f4:	83 c8 80             	or     $0xffffff80,%eax
  1016f7:	a2 bd 87 10 00       	mov    %al,0x1087bd
  1016fc:	b8 a8 21 10 00       	mov    $0x1021a8,%eax
  101701:	c1 e8 10             	shr    $0x10,%eax
  101704:	66 a3 be 87 10 00    	mov    %ax,0x1087be
	SETGATE(idt[12],1,0x8,&handler12,0);
  10170a:	b8 ac 21 10 00       	mov    $0x1021ac,%eax
  10170f:	66 a3 c0 87 10 00    	mov    %ax,0x1087c0
  101715:	66 c7 05 c2 87 10 00 	movw   $0x8,0x1087c2
  10171c:	08 00 
  10171e:	0f b6 05 c4 87 10 00 	movzbl 0x1087c4,%eax
  101725:	83 e0 e0             	and    $0xffffffe0,%eax
  101728:	a2 c4 87 10 00       	mov    %al,0x1087c4
  10172d:	0f b6 05 c4 87 10 00 	movzbl 0x1087c4,%eax
  101734:	83 e0 1f             	and    $0x1f,%eax
  101737:	a2 c4 87 10 00       	mov    %al,0x1087c4
  10173c:	0f b6 05 c5 87 10 00 	movzbl 0x1087c5,%eax
  101743:	83 c8 0f             	or     $0xf,%eax
  101746:	a2 c5 87 10 00       	mov    %al,0x1087c5
  10174b:	0f b6 05 c5 87 10 00 	movzbl 0x1087c5,%eax
  101752:	83 e0 ef             	and    $0xffffffef,%eax
  101755:	a2 c5 87 10 00       	mov    %al,0x1087c5
  10175a:	0f b6 05 c5 87 10 00 	movzbl 0x1087c5,%eax
  101761:	83 e0 9f             	and    $0xffffff9f,%eax
  101764:	a2 c5 87 10 00       	mov    %al,0x1087c5
  101769:	0f b6 05 c5 87 10 00 	movzbl 0x1087c5,%eax
  101770:	83 c8 80             	or     $0xffffff80,%eax
  101773:	a2 c5 87 10 00       	mov    %al,0x1087c5
  101778:	b8 ac 21 10 00       	mov    $0x1021ac,%eax
  10177d:	c1 e8 10             	shr    $0x10,%eax
  101780:	66 a3 c6 87 10 00    	mov    %ax,0x1087c6
	SETGATE(idt[13],1,0x8,&handler13,0);
  101786:	b8 b0 21 10 00       	mov    $0x1021b0,%eax
  10178b:	66 a3 c8 87 10 00    	mov    %ax,0x1087c8
  101791:	66 c7 05 ca 87 10 00 	movw   $0x8,0x1087ca
  101798:	08 00 
  10179a:	0f b6 05 cc 87 10 00 	movzbl 0x1087cc,%eax
  1017a1:	83 e0 e0             	and    $0xffffffe0,%eax
  1017a4:	a2 cc 87 10 00       	mov    %al,0x1087cc
  1017a9:	0f b6 05 cc 87 10 00 	movzbl 0x1087cc,%eax
  1017b0:	83 e0 1f             	and    $0x1f,%eax
  1017b3:	a2 cc 87 10 00       	mov    %al,0x1087cc
  1017b8:	0f b6 05 cd 87 10 00 	movzbl 0x1087cd,%eax
  1017bf:	83 c8 0f             	or     $0xf,%eax
  1017c2:	a2 cd 87 10 00       	mov    %al,0x1087cd
  1017c7:	0f b6 05 cd 87 10 00 	movzbl 0x1087cd,%eax
  1017ce:	83 e0 ef             	and    $0xffffffef,%eax
  1017d1:	a2 cd 87 10 00       	mov    %al,0x1087cd
  1017d6:	0f b6 05 cd 87 10 00 	movzbl 0x1087cd,%eax
  1017dd:	83 e0 9f             	and    $0xffffff9f,%eax
  1017e0:	a2 cd 87 10 00       	mov    %al,0x1087cd
  1017e5:	0f b6 05 cd 87 10 00 	movzbl 0x1087cd,%eax
  1017ec:	83 c8 80             	or     $0xffffff80,%eax
  1017ef:	a2 cd 87 10 00       	mov    %al,0x1087cd
  1017f4:	b8 b0 21 10 00       	mov    $0x1021b0,%eax
  1017f9:	c1 e8 10             	shr    $0x10,%eax
  1017fc:	66 a3 ce 87 10 00    	mov    %ax,0x1087ce
	SETGATE(idt[14],1,0x8,&handler14,0);
  101802:	b8 b4 21 10 00       	mov    $0x1021b4,%eax
  101807:	66 a3 d0 87 10 00    	mov    %ax,0x1087d0
  10180d:	66 c7 05 d2 87 10 00 	movw   $0x8,0x1087d2
  101814:	08 00 
  101816:	0f b6 05 d4 87 10 00 	movzbl 0x1087d4,%eax
  10181d:	83 e0 e0             	and    $0xffffffe0,%eax
  101820:	a2 d4 87 10 00       	mov    %al,0x1087d4
  101825:	0f b6 05 d4 87 10 00 	movzbl 0x1087d4,%eax
  10182c:	83 e0 1f             	and    $0x1f,%eax
  10182f:	a2 d4 87 10 00       	mov    %al,0x1087d4
  101834:	0f b6 05 d5 87 10 00 	movzbl 0x1087d5,%eax
  10183b:	83 c8 0f             	or     $0xf,%eax
  10183e:	a2 d5 87 10 00       	mov    %al,0x1087d5
  101843:	0f b6 05 d5 87 10 00 	movzbl 0x1087d5,%eax
  10184a:	83 e0 ef             	and    $0xffffffef,%eax
  10184d:	a2 d5 87 10 00       	mov    %al,0x1087d5
  101852:	0f b6 05 d5 87 10 00 	movzbl 0x1087d5,%eax
  101859:	83 e0 9f             	and    $0xffffff9f,%eax
  10185c:	a2 d5 87 10 00       	mov    %al,0x1087d5
  101861:	0f b6 05 d5 87 10 00 	movzbl 0x1087d5,%eax
  101868:	83 c8 80             	or     $0xffffff80,%eax
  10186b:	a2 d5 87 10 00       	mov    %al,0x1087d5
  101870:	b8 b4 21 10 00       	mov    $0x1021b4,%eax
  101875:	c1 e8 10             	shr    $0x10,%eax
  101878:	66 a3 d6 87 10 00    	mov    %ax,0x1087d6
	SETGATE(idt[16],1,0x8,&handler16,0);
  10187e:	b8 b8 21 10 00       	mov    $0x1021b8,%eax
  101883:	66 a3 e0 87 10 00    	mov    %ax,0x1087e0
  101889:	66 c7 05 e2 87 10 00 	movw   $0x8,0x1087e2
  101890:	08 00 
  101892:	0f b6 05 e4 87 10 00 	movzbl 0x1087e4,%eax
  101899:	83 e0 e0             	and    $0xffffffe0,%eax
  10189c:	a2 e4 87 10 00       	mov    %al,0x1087e4
  1018a1:	0f b6 05 e4 87 10 00 	movzbl 0x1087e4,%eax
  1018a8:	83 e0 1f             	and    $0x1f,%eax
  1018ab:	a2 e4 87 10 00       	mov    %al,0x1087e4
  1018b0:	0f b6 05 e5 87 10 00 	movzbl 0x1087e5,%eax
  1018b7:	83 c8 0f             	or     $0xf,%eax
  1018ba:	a2 e5 87 10 00       	mov    %al,0x1087e5
  1018bf:	0f b6 05 e5 87 10 00 	movzbl 0x1087e5,%eax
  1018c6:	83 e0 ef             	and    $0xffffffef,%eax
  1018c9:	a2 e5 87 10 00       	mov    %al,0x1087e5
  1018ce:	0f b6 05 e5 87 10 00 	movzbl 0x1087e5,%eax
  1018d5:	83 e0 9f             	and    $0xffffff9f,%eax
  1018d8:	a2 e5 87 10 00       	mov    %al,0x1087e5
  1018dd:	0f b6 05 e5 87 10 00 	movzbl 0x1087e5,%eax
  1018e4:	83 c8 80             	or     $0xffffff80,%eax
  1018e7:	a2 e5 87 10 00       	mov    %al,0x1087e5
  1018ec:	b8 b8 21 10 00       	mov    $0x1021b8,%eax
  1018f1:	c1 e8 10             	shr    $0x10,%eax
  1018f4:	66 a3 e6 87 10 00    	mov    %ax,0x1087e6
	SETGATE(idt[17],1,0x8,&handler17,0);
  1018fa:	b8 be 21 10 00       	mov    $0x1021be,%eax
  1018ff:	66 a3 e8 87 10 00    	mov    %ax,0x1087e8
  101905:	66 c7 05 ea 87 10 00 	movw   $0x8,0x1087ea
  10190c:	08 00 
  10190e:	0f b6 05 ec 87 10 00 	movzbl 0x1087ec,%eax
  101915:	83 e0 e0             	and    $0xffffffe0,%eax
  101918:	a2 ec 87 10 00       	mov    %al,0x1087ec
  10191d:	0f b6 05 ec 87 10 00 	movzbl 0x1087ec,%eax
  101924:	83 e0 1f             	and    $0x1f,%eax
  101927:	a2 ec 87 10 00       	mov    %al,0x1087ec
  10192c:	0f b6 05 ed 87 10 00 	movzbl 0x1087ed,%eax
  101933:	83 c8 0f             	or     $0xf,%eax
  101936:	a2 ed 87 10 00       	mov    %al,0x1087ed
  10193b:	0f b6 05 ed 87 10 00 	movzbl 0x1087ed,%eax
  101942:	83 e0 ef             	and    $0xffffffef,%eax
  101945:	a2 ed 87 10 00       	mov    %al,0x1087ed
  10194a:	0f b6 05 ed 87 10 00 	movzbl 0x1087ed,%eax
  101951:	83 e0 9f             	and    $0xffffff9f,%eax
  101954:	a2 ed 87 10 00       	mov    %al,0x1087ed
  101959:	0f b6 05 ed 87 10 00 	movzbl 0x1087ed,%eax
  101960:	83 c8 80             	or     $0xffffff80,%eax
  101963:	a2 ed 87 10 00       	mov    %al,0x1087ed
  101968:	b8 be 21 10 00       	mov    $0x1021be,%eax
  10196d:	c1 e8 10             	shr    $0x10,%eax
  101970:	66 a3 ee 87 10 00    	mov    %ax,0x1087ee
	SETGATE(idt[19],1,0x8,&handler19,0);
  101976:	b8 c2 21 10 00       	mov    $0x1021c2,%eax
  10197b:	66 a3 f8 87 10 00    	mov    %ax,0x1087f8
  101981:	66 c7 05 fa 87 10 00 	movw   $0x8,0x1087fa
  101988:	08 00 
  10198a:	0f b6 05 fc 87 10 00 	movzbl 0x1087fc,%eax
  101991:	83 e0 e0             	and    $0xffffffe0,%eax
  101994:	a2 fc 87 10 00       	mov    %al,0x1087fc
  101999:	0f b6 05 fc 87 10 00 	movzbl 0x1087fc,%eax
  1019a0:	83 e0 1f             	and    $0x1f,%eax
  1019a3:	a2 fc 87 10 00       	mov    %al,0x1087fc
  1019a8:	0f b6 05 fd 87 10 00 	movzbl 0x1087fd,%eax
  1019af:	83 c8 0f             	or     $0xf,%eax
  1019b2:	a2 fd 87 10 00       	mov    %al,0x1087fd
  1019b7:	0f b6 05 fd 87 10 00 	movzbl 0x1087fd,%eax
  1019be:	83 e0 ef             	and    $0xffffffef,%eax
  1019c1:	a2 fd 87 10 00       	mov    %al,0x1087fd
  1019c6:	0f b6 05 fd 87 10 00 	movzbl 0x1087fd,%eax
  1019cd:	83 e0 9f             	and    $0xffffff9f,%eax
  1019d0:	a2 fd 87 10 00       	mov    %al,0x1087fd
  1019d5:	0f b6 05 fd 87 10 00 	movzbl 0x1087fd,%eax
  1019dc:	83 c8 80             	or     $0xffffff80,%eax
  1019df:	a2 fd 87 10 00       	mov    %al,0x1087fd
  1019e4:	b8 c2 21 10 00       	mov    $0x1021c2,%eax
  1019e9:	c1 e8 10             	shr    $0x10,%eax
  1019ec:	66 a3 fe 87 10 00    	mov    %ax,0x1087fe

//	panic("trap_init() not implemented.");
}
  1019f2:	5d                   	pop    %ebp
  1019f3:	c3                   	ret    

001019f4 <trap_init>:

void
trap_init(void)
{
  1019f4:	55                   	push   %ebp
  1019f5:	89 e5                	mov    %esp,%ebp
  1019f7:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  1019fa:	e8 10 f9 ff ff       	call   10130f <cpu_onboot>
  1019ff:	85 c0                	test   %eax,%eax
  101a01:	74 05                	je     101a08 <trap_init+0x14>
		trap_init_idt();
  101a03:	e8 1f f9 ff ff       	call   101327 <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  101a08:	0f 01 1d 00 70 10 00 	lidtl  0x107000

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  101a0f:	e8 fb f8 ff ff       	call   10130f <cpu_onboot>
  101a14:	85 c0                	test   %eax,%eax
  101a16:	74 05                	je     101a1d <trap_init+0x29>
		trap_check_kernel();
  101a18:	e8 2c 04 00 00       	call   101e49 <trap_check_kernel>
}
  101a1d:	c9                   	leave  
  101a1e:	c3                   	ret    

00101a1f <trap_name>:

const char *trap_name(int trapno)
{
  101a1f:	55                   	push   %ebp
  101a20:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  101a22:	8b 45 08             	mov    0x8(%ebp),%eax
  101a25:	83 f8 13             	cmp    $0x13,%eax
  101a28:	77 0c                	ja     101a36 <trap_name+0x17>
		return excnames[trapno];
  101a2a:	8b 45 08             	mov    0x8(%ebp),%eax
  101a2d:	8b 04 85 00 44 10 00 	mov    0x104400(,%eax,4),%eax
  101a34:	eb 05                	jmp    101a3b <trap_name+0x1c>
	return "(unknown trap)";
  101a36:	b8 d8 3e 10 00       	mov    $0x103ed8,%eax
}
  101a3b:	5d                   	pop    %ebp
  101a3c:	c3                   	ret    

00101a3d <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  101a3d:	55                   	push   %ebp
  101a3e:	89 e5                	mov    %esp,%ebp
  101a40:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->reg_edi);
  101a43:	8b 45 08             	mov    0x8(%ebp),%eax
  101a46:	8b 00                	mov    (%eax),%eax
  101a48:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a4c:	c7 04 24 e7 3e 10 00 	movl   $0x103ee7,(%esp)
  101a53:	e8 d9 16 00 00       	call   103131 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
  101a58:	8b 45 08             	mov    0x8(%ebp),%eax
  101a5b:	8b 40 04             	mov    0x4(%eax),%eax
  101a5e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a62:	c7 04 24 f6 3e 10 00 	movl   $0x103ef6,(%esp)
  101a69:	e8 c3 16 00 00       	call   103131 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
  101a6e:	8b 45 08             	mov    0x8(%ebp),%eax
  101a71:	8b 40 08             	mov    0x8(%eax),%eax
  101a74:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a78:	c7 04 24 05 3f 10 00 	movl   $0x103f05,(%esp)
  101a7f:	e8 ad 16 00 00       	call   103131 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->reg_oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
  101a84:	8b 45 08             	mov    0x8(%ebp),%eax
  101a87:	8b 40 10             	mov    0x10(%eax),%eax
  101a8a:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a8e:	c7 04 24 14 3f 10 00 	movl   $0x103f14,(%esp)
  101a95:	e8 97 16 00 00       	call   103131 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
  101a9a:	8b 45 08             	mov    0x8(%ebp),%eax
  101a9d:	8b 40 14             	mov    0x14(%eax),%eax
  101aa0:	89 44 24 04          	mov    %eax,0x4(%esp)
  101aa4:	c7 04 24 23 3f 10 00 	movl   $0x103f23,(%esp)
  101aab:	e8 81 16 00 00       	call   103131 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
  101ab0:	8b 45 08             	mov    0x8(%ebp),%eax
  101ab3:	8b 40 18             	mov    0x18(%eax),%eax
  101ab6:	89 44 24 04          	mov    %eax,0x4(%esp)
  101aba:	c7 04 24 32 3f 10 00 	movl   $0x103f32,(%esp)
  101ac1:	e8 6b 16 00 00       	call   103131 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
  101ac6:	8b 45 08             	mov    0x8(%ebp),%eax
  101ac9:	8b 40 1c             	mov    0x1c(%eax),%eax
  101acc:	89 44 24 04          	mov    %eax,0x4(%esp)
  101ad0:	c7 04 24 41 3f 10 00 	movl   $0x103f41,(%esp)
  101ad7:	e8 55 16 00 00       	call   103131 <cprintf>
}
  101adc:	c9                   	leave  
  101add:	c3                   	ret    

00101ade <trap_print>:

void
trap_print(trapframe *tf)
{
  101ade:	55                   	push   %ebp
  101adf:	89 e5                	mov    %esp,%ebp
  101ae1:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  101ae4:	8b 45 08             	mov    0x8(%ebp),%eax
  101ae7:	89 44 24 04          	mov    %eax,0x4(%esp)
  101aeb:	c7 04 24 50 3f 10 00 	movl   $0x103f50,(%esp)
  101af2:	e8 3a 16 00 00       	call   103131 <cprintf>
	trap_print_regs(&tf->tf_regs);
  101af7:	8b 45 08             	mov    0x8(%ebp),%eax
  101afa:	89 04 24             	mov    %eax,(%esp)
  101afd:	e8 3b ff ff ff       	call   101a3d <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
  101b02:	8b 45 08             	mov    0x8(%ebp),%eax
  101b05:	0f b7 40 20          	movzwl 0x20(%eax),%eax
  101b09:	0f b7 c0             	movzwl %ax,%eax
  101b0c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b10:	c7 04 24 62 3f 10 00 	movl   $0x103f62,(%esp)
  101b17:	e8 15 16 00 00       	call   103131 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
  101b1c:	8b 45 08             	mov    0x8(%ebp),%eax
  101b1f:	0f b7 40 24          	movzwl 0x24(%eax),%eax
  101b23:	0f b7 c0             	movzwl %ax,%eax
  101b26:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b2a:	c7 04 24 75 3f 10 00 	movl   $0x103f75,(%esp)
  101b31:	e8 fb 15 00 00       	call   103131 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trap_name(tf->tf_trapno));
  101b36:	8b 45 08             	mov    0x8(%ebp),%eax
  101b39:	8b 40 28             	mov    0x28(%eax),%eax
  101b3c:	89 04 24             	mov    %eax,(%esp)
  101b3f:	e8 db fe ff ff       	call   101a1f <trap_name>
  101b44:	8b 55 08             	mov    0x8(%ebp),%edx
  101b47:	8b 52 28             	mov    0x28(%edx),%edx
  101b4a:	89 44 24 08          	mov    %eax,0x8(%esp)
  101b4e:	89 54 24 04          	mov    %edx,0x4(%esp)
  101b52:	c7 04 24 88 3f 10 00 	movl   $0x103f88,(%esp)
  101b59:	e8 d3 15 00 00       	call   103131 <cprintf>
	cprintf("  err  0x%08x\n", tf->tf_err);
  101b5e:	8b 45 08             	mov    0x8(%ebp),%eax
  101b61:	8b 40 2c             	mov    0x2c(%eax),%eax
  101b64:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b68:	c7 04 24 9a 3f 10 00 	movl   $0x103f9a,(%esp)
  101b6f:	e8 bd 15 00 00       	call   103131 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
  101b74:	8b 45 08             	mov    0x8(%ebp),%eax
  101b77:	8b 40 30             	mov    0x30(%eax),%eax
  101b7a:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b7e:	c7 04 24 a9 3f 10 00 	movl   $0x103fa9,(%esp)
  101b85:	e8 a7 15 00 00       	call   103131 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
  101b8a:	8b 45 08             	mov    0x8(%ebp),%eax
  101b8d:	0f b7 40 34          	movzwl 0x34(%eax),%eax
  101b91:	0f b7 c0             	movzwl %ax,%eax
  101b94:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b98:	c7 04 24 b8 3f 10 00 	movl   $0x103fb8,(%esp)
  101b9f:	e8 8d 15 00 00       	call   103131 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
  101ba4:	8b 45 08             	mov    0x8(%ebp),%eax
  101ba7:	8b 40 38             	mov    0x38(%eax),%eax
  101baa:	89 44 24 04          	mov    %eax,0x4(%esp)
  101bae:	c7 04 24 cb 3f 10 00 	movl   $0x103fcb,(%esp)
  101bb5:	e8 77 15 00 00       	call   103131 <cprintf>
	cprintf("  esp  0x%08x\n", tf->tf_esp);
  101bba:	8b 45 08             	mov    0x8(%ebp),%eax
  101bbd:	8b 40 3c             	mov    0x3c(%eax),%eax
  101bc0:	89 44 24 04          	mov    %eax,0x4(%esp)
  101bc4:	c7 04 24 da 3f 10 00 	movl   $0x103fda,(%esp)
  101bcb:	e8 61 15 00 00       	call   103131 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->tf_ss);
  101bd0:	8b 45 08             	mov    0x8(%ebp),%eax
  101bd3:	0f b7 40 40          	movzwl 0x40(%eax),%eax
  101bd7:	0f b7 c0             	movzwl %ax,%eax
  101bda:	89 44 24 04          	mov    %eax,0x4(%esp)
  101bde:	c7 04 24 e9 3f 10 00 	movl   $0x103fe9,(%esp)
  101be5:	e8 47 15 00 00       	call   103131 <cprintf>
}
  101bea:	c9                   	leave  
  101beb:	c3                   	ret    

00101bec <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  101bec:	55                   	push   %ebp
  101bed:	89 e5                	mov    %esp,%ebp
  101bef:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  101bf2:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  101bf3:	e8 c4 f6 ff ff       	call   1012bc <cpu_cur>
  101bf8:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  101bfb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101bfe:	8b 80 98 00 00 00    	mov    0x98(%eax),%eax
  101c04:	85 c0                	test   %eax,%eax
  101c06:	74 1e                	je     101c26 <trap+0x3a>
		c->recover(tf, c->recoverdata);
  101c08:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c0b:	8b 90 98 00 00 00    	mov    0x98(%eax),%edx
  101c11:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c14:	8b 80 9c 00 00 00    	mov    0x9c(%eax),%eax
  101c1a:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c1e:	8b 45 08             	mov    0x8(%ebp),%eax
  101c21:	89 04 24             	mov    %eax,(%esp)
  101c24:	ff d2                	call   *%edx

	trap_print(tf);
  101c26:	8b 45 08             	mov    0x8(%ebp),%eax
  101c29:	89 04 24             	mov    %eax,(%esp)
  101c2c:	e8 ad fe ff ff       	call   101ade <trap_print>
	//panic("unhandled trap");
	trap_return0(tf);
  101c31:	8b 45 08             	mov    0x8(%ebp),%eax
  101c34:	89 04 24             	mov    %eax,(%esp)
  101c37:	e8 d4 05 00 00       	call   102210 <trap_return0>

00101c3c <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  101c3c:	55                   	push   %ebp
  101c3d:	89 e5                	mov    %esp,%ebp
  101c3f:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  101c42:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c45:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->tf_eip = (uint32_t) args->reip;	// Use recovery EIP on return
  101c48:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c4b:	8b 00                	mov    (%eax),%eax
  101c4d:	89 c2                	mov    %eax,%edx
  101c4f:	8b 45 08             	mov    0x8(%ebp),%eax
  101c52:	89 50 30             	mov    %edx,0x30(%eax)
	args->trapno = tf->tf_trapno;		// Return trap number
  101c55:	8b 45 08             	mov    0x8(%ebp),%eax
  101c58:	8b 40 28             	mov    0x28(%eax),%eax
  101c5b:	89 c2                	mov    %eax,%edx
  101c5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c60:	89 50 04             	mov    %edx,0x4(%eax)
	//cprintf("   %d    ",args->trapno);
	if (tf->tf_trapno==0)
  101c63:	8b 45 08             	mov    0x8(%ebp),%eax
  101c66:	8b 40 28             	mov    0x28(%eax),%eax
  101c69:	85 c0                	test   %eax,%eax
  101c6b:	75 17                	jne    101c84 <trap_check_recover+0x48>
	{cprintf("\nDivide by Zero error handled\n");trap_return2(tf);}
  101c6d:	c7 04 24 fc 3f 10 00 	movl   $0x103ffc,(%esp)
  101c74:	e8 b8 14 00 00       	call   103131 <cprintf>
  101c79:	8b 45 08             	mov    0x8(%ebp),%eax
  101c7c:	89 04 24             	mov    %eax,(%esp)
  101c7f:	e8 6c 05 00 00       	call   1021f0 <trap_return2>
	else if(tf->tf_trapno==3)
  101c84:	8b 45 08             	mov    0x8(%ebp),%eax
  101c87:	8b 40 28             	mov    0x28(%eax),%eax
  101c8a:	83 f8 03             	cmp    $0x3,%eax
  101c8d:	75 17                	jne    101ca6 <trap_check_recover+0x6a>
	{cprintf("\nBreakPoint error handled\n");trap_return0(tf);}
  101c8f:	c7 04 24 1b 40 10 00 	movl   $0x10401b,(%esp)
  101c96:	e8 96 14 00 00       	call   103131 <cprintf>
  101c9b:	8b 45 08             	mov    0x8(%ebp),%eax
  101c9e:	89 04 24             	mov    %eax,(%esp)
  101ca1:	e8 6a 05 00 00       	call   102210 <trap_return0>
	else if(tf->tf_trapno==4)
  101ca6:	8b 45 08             	mov    0x8(%ebp),%eax
  101ca9:	8b 40 28             	mov    0x28(%eax),%eax
  101cac:	83 f8 04             	cmp    $0x4,%eax
  101caf:	75 17                	jne    101cc8 <trap_check_recover+0x8c>
	{cprintf("\nOverflow error handled\n");trap_return0(tf);}
  101cb1:	c7 04 24 36 40 10 00 	movl   $0x104036,(%esp)
  101cb8:	e8 74 14 00 00       	call   103131 <cprintf>
  101cbd:	8b 45 08             	mov    0x8(%ebp),%eax
  101cc0:	89 04 24             	mov    %eax,(%esp)
  101cc3:	e8 48 05 00 00       	call   102210 <trap_return0>
	else if(tf->tf_trapno==5)
  101cc8:	8b 45 08             	mov    0x8(%ebp),%eax
  101ccb:	8b 40 28             	mov    0x28(%eax),%eax
  101cce:	83 f8 05             	cmp    $0x5,%eax
  101cd1:	75 17                	jne    101cea <trap_check_recover+0xae>
	{cprintf("\nBound error handled\n");trap_return3(tf);}
  101cd3:	c7 04 24 4f 40 10 00 	movl   $0x10404f,(%esp)
  101cda:	e8 52 14 00 00       	call   103131 <cprintf>
  101cdf:	8b 45 08             	mov    0x8(%ebp),%eax
  101ce2:	89 04 24             	mov    %eax,(%esp)
  101ce5:	e8 36 05 00 00       	call   102220 <trap_return3>
	else if(tf->tf_trapno==6)
  101cea:	8b 45 08             	mov    0x8(%ebp),%eax
  101ced:	8b 40 28             	mov    0x28(%eax),%eax
  101cf0:	83 f8 06             	cmp    $0x6,%eax
  101cf3:	75 17                	jne    101d0c <trap_check_recover+0xd0>
	{cprintf("\nInvalid opcode handled\n");trap_return2(tf);}
  101cf5:	c7 04 24 65 40 10 00 	movl   $0x104065,(%esp)
  101cfc:	e8 30 14 00 00       	call   103131 <cprintf>
  101d01:	8b 45 08             	mov    0x8(%ebp),%eax
  101d04:	89 04 24             	mov    %eax,(%esp)
  101d07:	e8 e4 04 00 00       	call   1021f0 <trap_return2>
	else if(tf->tf_trapno==7)
  101d0c:	8b 45 08             	mov    0x8(%ebp),%eax
  101d0f:	8b 40 28             	mov    0x28(%eax),%eax
  101d12:	83 f8 07             	cmp    $0x7,%eax
  101d15:	75 17                	jne    101d2e <trap_check_recover+0xf2>
	{cprintf("\nDevice not Availble handled\n");trap_return2(tf);}
  101d17:	c7 04 24 7e 40 10 00 	movl   $0x10407e,(%esp)
  101d1e:	e8 0e 14 00 00       	call   103131 <cprintf>
  101d23:	8b 45 08             	mov    0x8(%ebp),%eax
  101d26:	89 04 24             	mov    %eax,(%esp)
  101d29:	e8 c2 04 00 00       	call   1021f0 <trap_return2>
	else if(tf->tf_trapno==10)
  101d2e:	8b 45 08             	mov    0x8(%ebp),%eax
  101d31:	8b 40 28             	mov    0x28(%eax),%eax
  101d34:	83 f8 0a             	cmp    $0xa,%eax
  101d37:	75 17                	jne    101d50 <trap_check_recover+0x114>
	{cprintf("\nInvalid TSS handled\n");trap_return2(tf);}
  101d39:	c7 04 24 9c 40 10 00 	movl   $0x10409c,(%esp)
  101d40:	e8 ec 13 00 00       	call   103131 <cprintf>
  101d45:	8b 45 08             	mov    0x8(%ebp),%eax
  101d48:	89 04 24             	mov    %eax,(%esp)
  101d4b:	e8 a0 04 00 00       	call   1021f0 <trap_return2>
	else if(tf->tf_trapno==11)
  101d50:	8b 45 08             	mov    0x8(%ebp),%eax
  101d53:	8b 40 28             	mov    0x28(%eax),%eax
  101d56:	83 f8 0b             	cmp    $0xb,%eax
  101d59:	75 17                	jne    101d72 <trap_check_recover+0x136>
	{cprintf("\nSegement Not present fault handled\n");trap_return2(tf);}
  101d5b:	c7 04 24 b4 40 10 00 	movl   $0x1040b4,(%esp)
  101d62:	e8 ca 13 00 00       	call   103131 <cprintf>
  101d67:	8b 45 08             	mov    0x8(%ebp),%eax
  101d6a:	89 04 24             	mov    %eax,(%esp)
  101d6d:	e8 7e 04 00 00       	call   1021f0 <trap_return2>
	else if(tf->tf_trapno==12)
  101d72:	8b 45 08             	mov    0x8(%ebp),%eax
  101d75:	8b 40 28             	mov    0x28(%eax),%eax
  101d78:	83 f8 0c             	cmp    $0xc,%eax
  101d7b:	75 17                	jne    101d94 <trap_check_recover+0x158>
	{cprintf("\nStack Segment Fault handled\n");trap_return2(tf);}
  101d7d:	c7 04 24 d9 40 10 00 	movl   $0x1040d9,(%esp)
  101d84:	e8 a8 13 00 00       	call   103131 <cprintf>
  101d89:	8b 45 08             	mov    0x8(%ebp),%eax
  101d8c:	89 04 24             	mov    %eax,(%esp)
  101d8f:	e8 5c 04 00 00       	call   1021f0 <trap_return2>
	else if(tf->tf_trapno==13)
  101d94:	8b 45 08             	mov    0x8(%ebp),%eax
  101d97:	8b 40 28             	mov    0x28(%eax),%eax
  101d9a:	83 f8 0d             	cmp    $0xd,%eax
  101d9d:	75 17                	jne    101db6 <trap_check_recover+0x17a>
	{cprintf("\nGeneral Segment fault handled\n");trap_return2(tf);}
  101d9f:	c7 04 24 f8 40 10 00 	movl   $0x1040f8,(%esp)
  101da6:	e8 86 13 00 00       	call   103131 <cprintf>
  101dab:	8b 45 08             	mov    0x8(%ebp),%eax
  101dae:	89 04 24             	mov    %eax,(%esp)
  101db1:	e8 3a 04 00 00       	call   1021f0 <trap_return2>
	else if(tf->tf_trapno==14)
  101db6:	8b 45 08             	mov    0x8(%ebp),%eax
  101db9:	8b 40 28             	mov    0x28(%eax),%eax
  101dbc:	83 f8 0e             	cmp    $0xe,%eax
  101dbf:	75 17                	jne    101dd8 <trap_check_recover+0x19c>
	{cprintf("\nPage Fault handled\n");trap_return2(tf);}
  101dc1:	c7 04 24 18 41 10 00 	movl   $0x104118,(%esp)
  101dc8:	e8 64 13 00 00       	call   103131 <cprintf>
  101dcd:	8b 45 08             	mov    0x8(%ebp),%eax
  101dd0:	89 04 24             	mov    %eax,(%esp)
  101dd3:	e8 18 04 00 00       	call   1021f0 <trap_return2>
	else if(tf->tf_trapno==16)
  101dd8:	8b 45 08             	mov    0x8(%ebp),%eax
  101ddb:	8b 40 28             	mov    0x28(%eax),%eax
  101dde:	83 f8 10             	cmp    $0x10,%eax
  101de1:	75 17                	jne    101dfa <trap_check_recover+0x1be>
	{cprintf("\nPage Point Error handled\n");trap_return2(tf);}
  101de3:	c7 04 24 2d 41 10 00 	movl   $0x10412d,(%esp)
  101dea:	e8 42 13 00 00       	call   103131 <cprintf>
  101def:	8b 45 08             	mov    0x8(%ebp),%eax
  101df2:	89 04 24             	mov    %eax,(%esp)
  101df5:	e8 f6 03 00 00       	call   1021f0 <trap_return2>
	else if(tf->tf_trapno==17)
  101dfa:	8b 45 08             	mov    0x8(%ebp),%eax
  101dfd:	8b 40 28             	mov    0x28(%eax),%eax
  101e00:	83 f8 11             	cmp    $0x11,%eax
  101e03:	75 17                	jne    101e1c <trap_check_recover+0x1e0>
	{cprintf("\nAlignment Check Fault handled\n");trap_return2(tf);}
  101e05:	c7 04 24 48 41 10 00 	movl   $0x104148,(%esp)
  101e0c:	e8 20 13 00 00       	call   103131 <cprintf>
  101e11:	8b 45 08             	mov    0x8(%ebp),%eax
  101e14:	89 04 24             	mov    %eax,(%esp)
  101e17:	e8 d4 03 00 00       	call   1021f0 <trap_return2>
	else if(tf->tf_trapno==19)
  101e1c:	8b 45 08             	mov    0x8(%ebp),%eax
  101e1f:	8b 40 28             	mov    0x28(%eax),%eax
  101e22:	83 f8 13             	cmp    $0x13,%eax
  101e25:	75 17                	jne    101e3e <trap_check_recover+0x202>
	{cprintf("\nSIMD Floating Point Exception handled\n");trap_return2(tf);}
  101e27:	c7 04 24 68 41 10 00 	movl   $0x104168,(%esp)
  101e2e:	e8 fe 12 00 00       	call   103131 <cprintf>
  101e33:	8b 45 08             	mov    0x8(%ebp),%eax
  101e36:	89 04 24             	mov    %eax,(%esp)
  101e39:	e8 b2 03 00 00       	call   1021f0 <trap_return2>
	else trap_return0(tf);
  101e3e:	8b 45 08             	mov    0x8(%ebp),%eax
  101e41:	89 04 24             	mov    %eax,(%esp)
  101e44:	e8 c7 03 00 00       	call   102210 <trap_return0>

00101e49 <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  101e49:	55                   	push   %ebp
  101e4a:	89 e5                	mov    %esp,%ebp
  101e4c:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101e4f:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  101e52:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  101e56:	0f b7 c0             	movzwl %ax,%eax
  101e59:	83 e0 03             	and    $0x3,%eax
  101e5c:	85 c0                	test   %eax,%eax
  101e5e:	74 24                	je     101e84 <trap_check_kernel+0x3b>
  101e60:	c7 44 24 0c 90 41 10 	movl   $0x104190,0xc(%esp)
  101e67:	00 
  101e68:	c7 44 24 08 b6 3e 10 	movl   $0x103eb6,0x8(%esp)
  101e6f:	00 
  101e70:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  101e77:	00 
  101e78:	c7 04 24 a5 41 10 00 	movl   $0x1041a5,(%esp)
  101e7f:	e8 14 e5 ff ff       	call   100398 <debug_panic>

	cpu *c = cpu_cur();
  101e84:	e8 33 f4 ff ff       	call   1012bc <cpu_cur>
  101e89:	89 45 f0             	mov    %eax,-0x10(%ebp)
	c->recover = trap_check_recover;
  101e8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101e8f:	c7 80 98 00 00 00 3c 	movl   $0x101c3c,0x98(%eax)
  101e96:	1c 10 00 
	trap_check(&c->recoverdata);
  101e99:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101e9c:	05 9c 00 00 00       	add    $0x9c,%eax
  101ea1:	89 04 24             	mov    %eax,(%esp)
  101ea4:	e8 96 00 00 00       	call   101f3f <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101ea9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101eac:	c7 80 98 00 00 00 00 	movl   $0x0,0x98(%eax)
  101eb3:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  101eb6:	c7 04 24 b4 41 10 00 	movl   $0x1041b4,(%esp)
  101ebd:	e8 6f 12 00 00       	call   103131 <cprintf>
}
  101ec2:	c9                   	leave  
  101ec3:	c3                   	ret    

00101ec4 <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  101ec4:	55                   	push   %ebp
  101ec5:	89 e5                	mov    %esp,%ebp
  101ec7:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101eca:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  101ecd:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  101ed1:	0f b7 c0             	movzwl %ax,%eax
  101ed4:	83 e0 03             	and    $0x3,%eax
  101ed7:	83 f8 03             	cmp    $0x3,%eax
  101eda:	74 24                	je     101f00 <trap_check_user+0x3c>
  101edc:	c7 44 24 0c d4 41 10 	movl   $0x1041d4,0xc(%esp)
  101ee3:	00 
  101ee4:	c7 44 24 08 b6 3e 10 	movl   $0x103eb6,0x8(%esp)
  101eeb:	00 
  101eec:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
  101ef3:	00 
  101ef4:	c7 04 24 a5 41 10 00 	movl   $0x1041a5,(%esp)
  101efb:	e8 98 e4 ff ff       	call   100398 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  101f00:	c7 45 f0 00 60 10 00 	movl   $0x106000,-0x10(%ebp)
	c->recover = trap_check_recover;
  101f07:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101f0a:	c7 80 98 00 00 00 3c 	movl   $0x101c3c,0x98(%eax)
  101f11:	1c 10 00 
	trap_check(&c->recoverdata);
  101f14:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101f17:	05 9c 00 00 00       	add    $0x9c,%eax
  101f1c:	89 04 24             	mov    %eax,(%esp)
  101f1f:	e8 1b 00 00 00       	call   101f3f <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101f24:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101f27:	c7 80 98 00 00 00 00 	movl   $0x0,0x98(%eax)
  101f2e:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  101f31:	c7 04 24 e9 41 10 00 	movl   $0x1041e9,(%esp)
  101f38:	e8 f4 11 00 00       	call   103131 <cprintf>
}
  101f3d:	c9                   	leave  
  101f3e:	c3                   	ret    

00101f3f <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  101f3f:	55                   	push   %ebp
  101f40:	89 e5                	mov    %esp,%ebp
  101f42:	57                   	push   %edi
  101f43:	56                   	push   %esi
  101f44:	53                   	push   %ebx
  101f45:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  101f48:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  101f4f:	8b 45 08             	mov    0x8(%ebp),%eax
  101f52:	8d 55 d8             	lea    -0x28(%ebp),%edx
  101f55:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  101f57:	c7 45 d8 65 1f 10 00 	movl   $0x101f65,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  101f5e:	b8 00 00 00 00       	mov    $0x0,%eax
  101f63:	f7 f0                	div    %eax

00101f65 <after_div0>:
	assert(args.trapno == T_DIVIDE);
  101f65:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101f68:	85 c0                	test   %eax,%eax
  101f6a:	74 24                	je     101f90 <after_div0+0x2b>
  101f6c:	c7 44 24 0c 07 42 10 	movl   $0x104207,0xc(%esp)
  101f73:	00 
  101f74:	c7 44 24 08 b6 3e 10 	movl   $0x103eb6,0x8(%esp)
  101f7b:	00 
  101f7c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  101f83:	00 
  101f84:	c7 04 24 a5 41 10 00 	movl   $0x1041a5,(%esp)
  101f8b:	e8 08 e4 ff ff       	call   100398 <debug_panic>
	
	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  101f90:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101f93:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101f98:	74 24                	je     101fbe <after_div0+0x59>
  101f9a:	c7 44 24 0c 1f 42 10 	movl   $0x10421f,0xc(%esp)
  101fa1:	00 
  101fa2:	c7 44 24 08 b6 3e 10 	movl   $0x103eb6,0x8(%esp)
  101fa9:	00 
  101faa:	c7 44 24 04 04 01 00 	movl   $0x104,0x4(%esp)
  101fb1:	00 
  101fb2:	c7 04 24 a5 41 10 00 	movl   $0x1041a5,(%esp)
  101fb9:	e8 da e3 ff ff       	call   100398 <debug_panic>
		
	// Breakpoint trap
	args.reip = after_breakpoint;
  101fbe:	c7 45 d8 c6 1f 10 00 	movl   $0x101fc6,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  101fc5:	cc                   	int3   

00101fc6 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  101fc6:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101fc9:	83 f8 03             	cmp    $0x3,%eax
  101fcc:	74 24                	je     101ff2 <after_breakpoint+0x2c>
  101fce:	c7 44 24 0c 34 42 10 	movl   $0x104234,0xc(%esp)
  101fd5:	00 
  101fd6:	c7 44 24 08 b6 3e 10 	movl   $0x103eb6,0x8(%esp)
  101fdd:	00 
  101fde:	c7 44 24 04 09 01 00 	movl   $0x109,0x4(%esp)
  101fe5:	00 
  101fe6:	c7 04 24 a5 41 10 00 	movl   $0x1041a5,(%esp)
  101fed:	e8 a6 e3 ff ff       	call   100398 <debug_panic>
	
	// Overflow trap
	args.reip = after_overflow;
  101ff2:	c7 45 d8 01 20 10 00 	movl   $0x102001,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101ff9:	b8 00 00 00 70       	mov    $0x70000000,%eax
  101ffe:	01 c0                	add    %eax,%eax
  102000:	ce                   	into   

00102001 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  102001:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102004:	83 f8 04             	cmp    $0x4,%eax
  102007:	74 24                	je     10202d <after_overflow+0x2c>
  102009:	c7 44 24 0c 4b 42 10 	movl   $0x10424b,0xc(%esp)
  102010:	00 
  102011:	c7 44 24 08 b6 3e 10 	movl   $0x103eb6,0x8(%esp)
  102018:	00 
  102019:	c7 44 24 04 0e 01 00 	movl   $0x10e,0x4(%esp)
  102020:	00 
  102021:	c7 04 24 a5 41 10 00 	movl   $0x1041a5,(%esp)
  102028:	e8 6b e3 ff ff       	call   100398 <debug_panic>
	
	// Bounds trap
	args.reip = after_bound;
  10202d:	c7 45 d8 4a 20 10 00 	movl   $0x10204a,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  102034:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  10203b:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  102042:	b8 00 00 00 00       	mov    $0x0,%eax
  102047:	62 45 d0             	bound  %eax,-0x30(%ebp)

0010204a <after_bound>:
	assert(args.trapno == T_BOUND);
  10204a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10204d:	83 f8 05             	cmp    $0x5,%eax
  102050:	74 24                	je     102076 <after_bound+0x2c>
  102052:	c7 44 24 0c 62 42 10 	movl   $0x104262,0xc(%esp)
  102059:	00 
  10205a:	c7 44 24 08 b6 3e 10 	movl   $0x103eb6,0x8(%esp)
  102061:	00 
  102062:	c7 44 24 04 14 01 00 	movl   $0x114,0x4(%esp)
  102069:	00 
  10206a:	c7 04 24 a5 41 10 00 	movl   $0x1041a5,(%esp)
  102071:	e8 22 e3 ff ff       	call   100398 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  102076:	c7 45 d8 7f 20 10 00 	movl   $0x10207f,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  10207d:	0f 0b                	ud2    

0010207f <after_illegal>:
	assert(args.trapno == T_ILLOP);
  10207f:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102082:	83 f8 06             	cmp    $0x6,%eax
  102085:	74 24                	je     1020ab <after_illegal+0x2c>
  102087:	c7 44 24 0c 79 42 10 	movl   $0x104279,0xc(%esp)
  10208e:	00 
  10208f:	c7 44 24 08 b6 3e 10 	movl   $0x103eb6,0x8(%esp)
  102096:	00 
  102097:	c7 44 24 04 19 01 00 	movl   $0x119,0x4(%esp)
  10209e:	00 
  10209f:	c7 04 24 a5 41 10 00 	movl   $0x1041a5,(%esp)
  1020a6:	e8 ed e2 ff ff       	call   100398 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  1020ab:	c7 45 d8 b9 20 10 00 	movl   $0x1020b9,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  1020b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1020b7:	8e e0                	mov    %eax,%fs

001020b9 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  1020b9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1020bc:	83 f8 0d             	cmp    $0xd,%eax
  1020bf:	74 24                	je     1020e5 <after_gpfault+0x2c>
  1020c1:	c7 44 24 0c 90 42 10 	movl   $0x104290,0xc(%esp)
  1020c8:	00 
  1020c9:	c7 44 24 08 b6 3e 10 	movl   $0x103eb6,0x8(%esp)
  1020d0:	00 
  1020d1:	c7 44 24 04 1e 01 00 	movl   $0x11e,0x4(%esp)
  1020d8:	00 
  1020d9:	c7 04 24 a5 41 10 00 	movl   $0x1041a5,(%esp)
  1020e0:	e8 b3 e2 ff ff       	call   100398 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1020e5:	8c 4d e6             	mov    %cs,-0x1a(%ebp)
        return cs;
  1020e8:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  1020ec:	0f b7 c0             	movzwl %ax,%eax
  1020ef:	83 e0 03             	and    $0x3,%eax
  1020f2:	85 c0                	test   %eax,%eax
  1020f4:	74 3a                	je     102130 <after_priv+0x2c>
		args.reip = after_priv;
  1020f6:	c7 45 d8 04 21 10 00 	movl   $0x102104,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  1020fd:	0f 01 1d 00 70 10 00 	lidtl  0x107000

00102104 <after_priv>:
		assert(args.trapno == T_GPFLT);
  102104:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102107:	83 f8 0d             	cmp    $0xd,%eax
  10210a:	74 24                	je     102130 <after_priv+0x2c>
  10210c:	c7 44 24 0c 90 42 10 	movl   $0x104290,0xc(%esp)
  102113:	00 
  102114:	c7 44 24 08 b6 3e 10 	movl   $0x103eb6,0x8(%esp)
  10211b:	00 
  10211c:	c7 44 24 04 24 01 00 	movl   $0x124,0x4(%esp)
  102123:	00 
  102124:	c7 04 24 a5 41 10 00 	movl   $0x1041a5,(%esp)
  10212b:	e8 68 e2 ff ff       	call   100398 <debug_panic>
	}

	cprintf("end");
  102130:	c7 04 24 a7 42 10 00 	movl   $0x1042a7,(%esp)
  102137:	e8 f5 0f 00 00       	call   103131 <cprintf>
	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  10213c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10213f:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  102144:	74 24                	je     10216a <after_priv+0x66>
  102146:	c7 44 24 0c 1f 42 10 	movl   $0x10421f,0xc(%esp)
  10214d:	00 
  10214e:	c7 44 24 08 b6 3e 10 	movl   $0x103eb6,0x8(%esp)
  102155:	00 
  102156:	c7 44 24 04 29 01 00 	movl   $0x129,0x4(%esp)
  10215d:	00 
  10215e:	c7 04 24 a5 41 10 00 	movl   $0x1041a5,(%esp)
  102165:	e8 2e e2 ff ff       	call   100398 <debug_panic>

	*argsp = NULL;	// recovery mechanism not needed anymore
  10216a:	8b 45 08             	mov    0x8(%ebp),%eax
  10216d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  102173:	83 c4 3c             	add    $0x3c,%esp
  102176:	5b                   	pop    %ebx
  102177:	5e                   	pop    %esi
  102178:	5f                   	pop    %edi
  102179:	5d                   	pop    %ebp
  10217a:	c3                   	ret    
  10217b:	90                   	nop
  10217c:	90                   	nop
  10217d:	90                   	nop
  10217e:	90                   	nop
  10217f:	90                   	nop

00102180 <handler0>:
.text

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(handler0,0);
  102180:	6a 00                	push   $0x0
  102182:	6a 00                	push   $0x0
  102184:	eb 42                	jmp    1021c8 <_alltraps>

00102186 <handler3>:
TRAPHANDLER_NOEC(handler3,3);
  102186:	6a 00                	push   $0x0
  102188:	6a 03                	push   $0x3
  10218a:	eb 3c                	jmp    1021c8 <_alltraps>

0010218c <handler4>:
TRAPHANDLER_NOEC(handler4,4);
  10218c:	6a 00                	push   $0x0
  10218e:	6a 04                	push   $0x4
  102190:	eb 36                	jmp    1021c8 <_alltraps>

00102192 <handler5>:
TRAPHANDLER_NOEC(handler5,5);
  102192:	6a 00                	push   $0x0
  102194:	6a 05                	push   $0x5
  102196:	eb 30                	jmp    1021c8 <_alltraps>

00102198 <handler6>:
TRAPHANDLER_NOEC(handler6,6);
  102198:	6a 00                	push   $0x0
  10219a:	6a 06                	push   $0x6
  10219c:	eb 2a                	jmp    1021c8 <_alltraps>

0010219e <handler7>:
TRAPHANDLER_NOEC(handler7,7);
  10219e:	6a 00                	push   $0x0
  1021a0:	6a 07                	push   $0x7
  1021a2:	eb 24                	jmp    1021c8 <_alltraps>

001021a4 <handler10>:
TRAPHANDLER(handler10,10);
  1021a4:	6a 0a                	push   $0xa
  1021a6:	eb 20                	jmp    1021c8 <_alltraps>

001021a8 <handler11>:
TRAPHANDLER(handler11,11);
  1021a8:	6a 0b                	push   $0xb
  1021aa:	eb 1c                	jmp    1021c8 <_alltraps>

001021ac <handler12>:
TRAPHANDLER(handler12,12);
  1021ac:	6a 0c                	push   $0xc
  1021ae:	eb 18                	jmp    1021c8 <_alltraps>

001021b0 <handler13>:
TRAPHANDLER(handler13,13);
  1021b0:	6a 0d                	push   $0xd
  1021b2:	eb 14                	jmp    1021c8 <_alltraps>

001021b4 <handler14>:
TRAPHANDLER(handler14,14);
  1021b4:	6a 0e                	push   $0xe
  1021b6:	eb 10                	jmp    1021c8 <_alltraps>

001021b8 <handler16>:
TRAPHANDLER_NOEC(handler16,16);
  1021b8:	6a 00                	push   $0x0
  1021ba:	6a 10                	push   $0x10
  1021bc:	eb 0a                	jmp    1021c8 <_alltraps>

001021be <handler17>:
TRAPHANDLER(handler17,17);
  1021be:	6a 11                	push   $0x11
  1021c0:	eb 06                	jmp    1021c8 <_alltraps>

001021c2 <handler19>:
TRAPHANDLER_NOEC(handler19,19);
  1021c2:	6a 00                	push   $0x0
  1021c4:	6a 13                	push   $0x13
  1021c6:	eb 00                	jmp    1021c8 <_alltraps>

001021c8 <_alltraps>:
 * Lab 1: Your code here for _alltraps
 */


_alltraps:
	pushl 16(%esp)
  1021c8:	ff 74 24 10          	pushl  0x10(%esp)
	pushl %cs
  1021cc:	0e                   	push   %cs
	pushl 16(%esp)
  1021cd:	ff 74 24 10          	pushl  0x10(%esp)
	pushl 16(%esp)
  1021d1:	ff 74 24 10          	pushl  0x10(%esp)
	pushl 16(%esp)
  1021d5:	ff 74 24 10          	pushl  0x10(%esp)
	pushl %ds
  1021d9:	1e                   	push   %ds
	pushl %es
  1021da:	06                   	push   %es
	pushal
  1021db:	60                   	pusha  
	pushl %esp
  1021dc:	54                   	push   %esp
	call trap
  1021dd:	e8 0a fa ff ff       	call   101bec <trap>
  1021e2:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  1021e9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001021f0 <trap_return2>:
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return2:
/*
 * Lab 1: Your code here for trap_return
 */
	movl 4(%esp),%esp
  1021f0:	8b 64 24 04          	mov    0x4(%esp),%esp
	popal
  1021f4:	61                   	popa   
	popl %es
  1021f5:	07                   	pop    %es
	popl %ds
  1021f6:	1f                   	pop    %ds

	addl $28,%esp 	//pop trap_n0
  1021f7:	83 c4 1c             	add    $0x1c,%esp
	popl %ecx
  1021fa:	59                   	pop    %ecx
	addl $2,%ecx
  1021fb:	83 c1 02             	add    $0x2,%ecx
	pushl %ecx
  1021fe:	51                   	push   %ecx
	movl $0,%ecx
  1021ff:	b9 00 00 00 00       	mov    $0x0,%ecx
	iret
  102204:	cf                   	iret   
  102205:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102209:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00102210 <trap_return0>:

.globl	trap_return0
.type	trap_return0,@function
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return0:
	movl 4(%esp),%esp
  102210:	8b 64 24 04          	mov    0x4(%esp),%esp
	popal
  102214:	61                   	popa   
	popl %es
  102215:	07                   	pop    %es
	popl %ds
  102216:	1f                   	pop    %ds

	addl $28,%esp 	//pop trap_n0
  102217:	83 c4 1c             	add    $0x1c,%esp
	iret
  10221a:	cf                   	iret   
  10221b:	90                   	nop
  10221c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

00102220 <trap_return3>:

.globl	trap_return3
.type	trap_return3,@function
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return3:
	movl 4(%esp),%esp
  102220:	8b 64 24 04          	mov    0x4(%esp),%esp
	popal
  102224:	61                   	popa   
	popl %es
  102225:	07                   	pop    %es
	popl %ds
  102226:	1f                   	pop    %ds

	addl $28,%esp 	//pop trap_n0
  102227:	83 c4 1c             	add    $0x1c,%esp
	popl %ecx
  10222a:	59                   	pop    %ecx
	addl $3,%ecx
  10222b:	83 c1 03             	add    $0x3,%ecx
	pushl %ecx
  10222e:	51                   	push   %ecx
	movl $0,%ecx
  10222f:	b9 00 00 00 00       	mov    $0x0,%ecx
	iret
  102234:	cf                   	iret   
  102235:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102239:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

00102240 <trap_return1>:

.globl	trap_return1
.type	trap_return1,@function
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return1:
	movl 4(%esp),%esp
  102240:	8b 64 24 04          	mov    0x4(%esp),%esp
	popal
  102244:	61                   	popa   
	popl %es
  102245:	07                   	pop    %es
	popl %ds
  102246:	1f                   	pop    %ds

	addl $28,%esp 	//pop trap_n0
  102247:	83 c4 1c             	add    $0x1c,%esp
	popl %ecx
  10224a:	59                   	pop    %ecx
	addl $1,%ecx
  10224b:	83 c1 01             	add    $0x1,%ecx
	pushl %ecx
  10224e:	51                   	push   %ecx
	movl $0,%ecx
  10224f:	b9 00 00 00 00       	mov    $0x0,%ecx
	iret
  102254:	cf                   	iret   

1:	jmp	1b		// just spin
  102255:	eb fe                	jmp    102255 <trap_return1+0x15>
  102257:	90                   	nop

00102258 <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  102258:	55                   	push   %ebp
  102259:	89 e5                	mov    %esp,%ebp
  10225b:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  10225e:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  102265:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102268:	0f b7 00             	movzwl (%eax),%eax
  10226b:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  10226f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102272:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  102277:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10227a:	0f b7 00             	movzwl (%eax),%eax
  10227d:	66 3d 5a a5          	cmp    $0xa55a,%ax
  102281:	74 13                	je     102296 <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  102283:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  10228a:	c7 05 60 8f 10 00 b4 	movl   $0x3b4,0x108f60
  102291:	03 00 00 
  102294:	eb 14                	jmp    1022aa <video_init+0x52>
	} else {
		*cp = was;
  102296:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102299:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  10229d:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  1022a0:	c7 05 60 8f 10 00 d4 	movl   $0x3d4,0x108f60
  1022a7:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  1022aa:	a1 60 8f 10 00       	mov    0x108f60,%eax
  1022af:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1022b2:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1022b6:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  1022ba:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1022bd:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  1022be:	a1 60 8f 10 00       	mov    0x108f60,%eax
  1022c3:	83 c0 01             	add    $0x1,%eax
  1022c6:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1022c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1022cc:	89 c2                	mov    %eax,%edx
  1022ce:	ec                   	in     (%dx),%al
  1022cf:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  1022d2:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  1022d6:	0f b6 c0             	movzbl %al,%eax
  1022d9:	c1 e0 08             	shl    $0x8,%eax
  1022dc:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  1022df:	a1 60 8f 10 00       	mov    0x108f60,%eax
  1022e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1022e7:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1022eb:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1022ef:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1022f2:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  1022f3:	a1 60 8f 10 00       	mov    0x108f60,%eax
  1022f8:	83 c0 01             	add    $0x1,%eax
  1022fb:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1022fe:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102301:	89 c2                	mov    %eax,%edx
  102303:	ec                   	in     (%dx),%al
  102304:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  102307:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  10230b:	0f b6 c0             	movzbl %al,%eax
  10230e:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  102311:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102314:	a3 64 8f 10 00       	mov    %eax,0x108f64
	crt_pos = pos;
  102319:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10231c:	66 a3 68 8f 10 00    	mov    %ax,0x108f68
}
  102322:	c9                   	leave  
  102323:	c3                   	ret    

00102324 <video_putc>:



void
video_putc(int c)
{
  102324:	55                   	push   %ebp
  102325:	89 e5                	mov    %esp,%ebp
  102327:	53                   	push   %ebx
  102328:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  10232b:	8b 45 08             	mov    0x8(%ebp),%eax
  10232e:	b0 00                	mov    $0x0,%al
  102330:	85 c0                	test   %eax,%eax
  102332:	75 07                	jne    10233b <video_putc+0x17>
		c |= 0x0700;
  102334:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  10233b:	8b 45 08             	mov    0x8(%ebp),%eax
  10233e:	25 ff 00 00 00       	and    $0xff,%eax
  102343:	83 f8 09             	cmp    $0x9,%eax
  102346:	0f 84 ae 00 00 00    	je     1023fa <video_putc+0xd6>
  10234c:	83 f8 09             	cmp    $0x9,%eax
  10234f:	7f 0a                	jg     10235b <video_putc+0x37>
  102351:	83 f8 08             	cmp    $0x8,%eax
  102354:	74 14                	je     10236a <video_putc+0x46>
  102356:	e9 dd 00 00 00       	jmp    102438 <video_putc+0x114>
  10235b:	83 f8 0a             	cmp    $0xa,%eax
  10235e:	74 4e                	je     1023ae <video_putc+0x8a>
  102360:	83 f8 0d             	cmp    $0xd,%eax
  102363:	74 59                	je     1023be <video_putc+0x9a>
  102365:	e9 ce 00 00 00       	jmp    102438 <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  10236a:	0f b7 05 68 8f 10 00 	movzwl 0x108f68,%eax
  102371:	66 85 c0             	test   %ax,%ax
  102374:	0f 84 e4 00 00 00    	je     10245e <video_putc+0x13a>
			crt_pos--;
  10237a:	0f b7 05 68 8f 10 00 	movzwl 0x108f68,%eax
  102381:	83 e8 01             	sub    $0x1,%eax
  102384:	66 a3 68 8f 10 00    	mov    %ax,0x108f68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  10238a:	a1 64 8f 10 00       	mov    0x108f64,%eax
  10238f:	0f b7 15 68 8f 10 00 	movzwl 0x108f68,%edx
  102396:	0f b7 d2             	movzwl %dx,%edx
  102399:	01 d2                	add    %edx,%edx
  10239b:	8d 14 10             	lea    (%eax,%edx,1),%edx
  10239e:	8b 45 08             	mov    0x8(%ebp),%eax
  1023a1:	b0 00                	mov    $0x0,%al
  1023a3:	83 c8 20             	or     $0x20,%eax
  1023a6:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  1023a9:	e9 b1 00 00 00       	jmp    10245f <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  1023ae:	0f b7 05 68 8f 10 00 	movzwl 0x108f68,%eax
  1023b5:	83 c0 50             	add    $0x50,%eax
  1023b8:	66 a3 68 8f 10 00    	mov    %ax,0x108f68
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  1023be:	0f b7 1d 68 8f 10 00 	movzwl 0x108f68,%ebx
  1023c5:	0f b7 0d 68 8f 10 00 	movzwl 0x108f68,%ecx
  1023cc:	0f b7 c1             	movzwl %cx,%eax
  1023cf:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  1023d5:	c1 e8 10             	shr    $0x10,%eax
  1023d8:	89 c2                	mov    %eax,%edx
  1023da:	66 c1 ea 06          	shr    $0x6,%dx
  1023de:	89 d0                	mov    %edx,%eax
  1023e0:	c1 e0 02             	shl    $0x2,%eax
  1023e3:	01 d0                	add    %edx,%eax
  1023e5:	c1 e0 04             	shl    $0x4,%eax
  1023e8:	89 ca                	mov    %ecx,%edx
  1023ea:	66 29 c2             	sub    %ax,%dx
  1023ed:	89 d8                	mov    %ebx,%eax
  1023ef:	66 29 d0             	sub    %dx,%ax
  1023f2:	66 a3 68 8f 10 00    	mov    %ax,0x108f68
		break;
  1023f8:	eb 65                	jmp    10245f <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  1023fa:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  102401:	e8 1e ff ff ff       	call   102324 <video_putc>
		video_putc(' ');
  102406:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10240d:	e8 12 ff ff ff       	call   102324 <video_putc>
		video_putc(' ');
  102412:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  102419:	e8 06 ff ff ff       	call   102324 <video_putc>
		video_putc(' ');
  10241e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  102425:	e8 fa fe ff ff       	call   102324 <video_putc>
		video_putc(' ');
  10242a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  102431:	e8 ee fe ff ff       	call   102324 <video_putc>
		break;
  102436:	eb 27                	jmp    10245f <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  102438:	8b 15 64 8f 10 00    	mov    0x108f64,%edx
  10243e:	0f b7 05 68 8f 10 00 	movzwl 0x108f68,%eax
  102445:	0f b7 c8             	movzwl %ax,%ecx
  102448:	01 c9                	add    %ecx,%ecx
  10244a:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  10244d:	8b 55 08             	mov    0x8(%ebp),%edx
  102450:	66 89 11             	mov    %dx,(%ecx)
  102453:	83 c0 01             	add    $0x1,%eax
  102456:	66 a3 68 8f 10 00    	mov    %ax,0x108f68
  10245c:	eb 01                	jmp    10245f <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  10245e:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  10245f:	0f b7 05 68 8f 10 00 	movzwl 0x108f68,%eax
  102466:	66 3d cf 07          	cmp    $0x7cf,%ax
  10246a:	76 5b                	jbe    1024c7 <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  10246c:	a1 64 8f 10 00       	mov    0x108f64,%eax
  102471:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  102477:	a1 64 8f 10 00       	mov    0x108f64,%eax
  10247c:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  102483:	00 
  102484:	89 54 24 04          	mov    %edx,0x4(%esp)
  102488:	89 04 24             	mov    %eax,(%esp)
  10248b:	e8 56 0f 00 00       	call   1033e6 <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  102490:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  102497:	eb 15                	jmp    1024ae <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  102499:	a1 64 8f 10 00       	mov    0x108f64,%eax
  10249e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1024a1:	01 d2                	add    %edx,%edx
  1024a3:	01 d0                	add    %edx,%eax
  1024a5:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  1024aa:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  1024ae:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  1024b5:	7e e2                	jle    102499 <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  1024b7:	0f b7 05 68 8f 10 00 	movzwl 0x108f68,%eax
  1024be:	83 e8 50             	sub    $0x50,%eax
  1024c1:	66 a3 68 8f 10 00    	mov    %ax,0x108f68
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  1024c7:	a1 60 8f 10 00       	mov    0x108f60,%eax
  1024cc:	89 45 dc             	mov    %eax,-0x24(%ebp)
  1024cf:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1024d3:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  1024d7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1024da:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  1024db:	0f b7 05 68 8f 10 00 	movzwl 0x108f68,%eax
  1024e2:	66 c1 e8 08          	shr    $0x8,%ax
  1024e6:	0f b6 c0             	movzbl %al,%eax
  1024e9:	8b 15 60 8f 10 00    	mov    0x108f60,%edx
  1024ef:	83 c2 01             	add    $0x1,%edx
  1024f2:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  1024f5:	88 45 e3             	mov    %al,-0x1d(%ebp)
  1024f8:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1024fc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1024ff:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  102500:	a1 60 8f 10 00       	mov    0x108f60,%eax
  102505:	89 45 ec             	mov    %eax,-0x14(%ebp)
  102508:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  10250c:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  102510:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102513:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  102514:	0f b7 05 68 8f 10 00 	movzwl 0x108f68,%eax
  10251b:	0f b6 c0             	movzbl %al,%eax
  10251e:	8b 15 60 8f 10 00    	mov    0x108f60,%edx
  102524:	83 c2 01             	add    $0x1,%edx
  102527:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10252a:	88 45 f3             	mov    %al,-0xd(%ebp)
  10252d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  102531:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102534:	ee                   	out    %al,(%dx)
}
  102535:	83 c4 44             	add    $0x44,%esp
  102538:	5b                   	pop    %ebx
  102539:	5d                   	pop    %ebp
  10253a:	c3                   	ret    
  10253b:	90                   	nop

0010253c <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  10253c:	55                   	push   %ebp
  10253d:	89 e5                	mov    %esp,%ebp
  10253f:	83 ec 38             	sub    $0x38,%esp
  102542:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  102549:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10254c:	89 c2                	mov    %eax,%edx
  10254e:	ec                   	in     (%dx),%al
  10254f:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  102552:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  102556:	0f b6 c0             	movzbl %al,%eax
  102559:	83 e0 01             	and    $0x1,%eax
  10255c:	85 c0                	test   %eax,%eax
  10255e:	75 0a                	jne    10256a <kbd_proc_data+0x2e>
		return -1;
  102560:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  102565:	e9 5a 01 00 00       	jmp    1026c4 <kbd_proc_data+0x188>
  10256a:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  102571:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102574:	89 c2                	mov    %eax,%edx
  102576:	ec                   	in     (%dx),%al
  102577:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  10257a:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  10257e:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  102581:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  102585:	75 17                	jne    10259e <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  102587:	a1 6c 8f 10 00       	mov    0x108f6c,%eax
  10258c:	83 c8 40             	or     $0x40,%eax
  10258f:	a3 6c 8f 10 00       	mov    %eax,0x108f6c
		return 0;
  102594:	b8 00 00 00 00       	mov    $0x0,%eax
  102599:	e9 26 01 00 00       	jmp    1026c4 <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  10259e:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1025a2:	84 c0                	test   %al,%al
  1025a4:	79 47                	jns    1025ed <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  1025a6:	a1 6c 8f 10 00       	mov    0x108f6c,%eax
  1025ab:	83 e0 40             	and    $0x40,%eax
  1025ae:	85 c0                	test   %eax,%eax
  1025b0:	75 09                	jne    1025bb <kbd_proc_data+0x7f>
  1025b2:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1025b6:	83 e0 7f             	and    $0x7f,%eax
  1025b9:	eb 04                	jmp    1025bf <kbd_proc_data+0x83>
  1025bb:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1025bf:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  1025c2:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1025c6:	0f b6 80 20 70 10 00 	movzbl 0x107020(%eax),%eax
  1025cd:	83 c8 40             	or     $0x40,%eax
  1025d0:	0f b6 c0             	movzbl %al,%eax
  1025d3:	f7 d0                	not    %eax
  1025d5:	89 c2                	mov    %eax,%edx
  1025d7:	a1 6c 8f 10 00       	mov    0x108f6c,%eax
  1025dc:	21 d0                	and    %edx,%eax
  1025de:	a3 6c 8f 10 00       	mov    %eax,0x108f6c
		return 0;
  1025e3:	b8 00 00 00 00       	mov    $0x0,%eax
  1025e8:	e9 d7 00 00 00       	jmp    1026c4 <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  1025ed:	a1 6c 8f 10 00       	mov    0x108f6c,%eax
  1025f2:	83 e0 40             	and    $0x40,%eax
  1025f5:	85 c0                	test   %eax,%eax
  1025f7:	74 11                	je     10260a <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  1025f9:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  1025fd:	a1 6c 8f 10 00       	mov    0x108f6c,%eax
  102602:	83 e0 bf             	and    $0xffffffbf,%eax
  102605:	a3 6c 8f 10 00       	mov    %eax,0x108f6c
	}

	shift |= shiftcode[data];
  10260a:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10260e:	0f b6 80 20 70 10 00 	movzbl 0x107020(%eax),%eax
  102615:	0f b6 d0             	movzbl %al,%edx
  102618:	a1 6c 8f 10 00       	mov    0x108f6c,%eax
  10261d:	09 d0                	or     %edx,%eax
  10261f:	a3 6c 8f 10 00       	mov    %eax,0x108f6c
	shift ^= togglecode[data];
  102624:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  102628:	0f b6 80 20 71 10 00 	movzbl 0x107120(%eax),%eax
  10262f:	0f b6 d0             	movzbl %al,%edx
  102632:	a1 6c 8f 10 00       	mov    0x108f6c,%eax
  102637:	31 d0                	xor    %edx,%eax
  102639:	a3 6c 8f 10 00       	mov    %eax,0x108f6c

	c = charcode[shift & (CTL | SHIFT)][data];
  10263e:	a1 6c 8f 10 00       	mov    0x108f6c,%eax
  102643:	83 e0 03             	and    $0x3,%eax
  102646:	8b 14 85 20 75 10 00 	mov    0x107520(,%eax,4),%edx
  10264d:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  102651:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102654:	0f b6 00             	movzbl (%eax),%eax
  102657:	0f b6 c0             	movzbl %al,%eax
  10265a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  10265d:	a1 6c 8f 10 00       	mov    0x108f6c,%eax
  102662:	83 e0 08             	and    $0x8,%eax
  102665:	85 c0                	test   %eax,%eax
  102667:	74 22                	je     10268b <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  102669:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  10266d:	7e 0c                	jle    10267b <kbd_proc_data+0x13f>
  10266f:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  102673:	7f 06                	jg     10267b <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  102675:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  102679:	eb 10                	jmp    10268b <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  10267b:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  10267f:	7e 0a                	jle    10268b <kbd_proc_data+0x14f>
  102681:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  102685:	7f 04                	jg     10268b <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  102687:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  10268b:	a1 6c 8f 10 00       	mov    0x108f6c,%eax
  102690:	f7 d0                	not    %eax
  102692:	83 e0 06             	and    $0x6,%eax
  102695:	85 c0                	test   %eax,%eax
  102697:	75 28                	jne    1026c1 <kbd_proc_data+0x185>
  102699:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  1026a0:	75 1f                	jne    1026c1 <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  1026a2:	c7 04 24 50 44 10 00 	movl   $0x104450,(%esp)
  1026a9:	e8 83 0a 00 00       	call   103131 <cprintf>
  1026ae:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  1026b5:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1026b9:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1026bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1026c0:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  1026c1:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  1026c4:	c9                   	leave  
  1026c5:	c3                   	ret    

001026c6 <kbd_intr>:

void
kbd_intr(void)
{
  1026c6:	55                   	push   %ebp
  1026c7:	89 e5                	mov    %esp,%ebp
  1026c9:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  1026cc:	c7 04 24 3c 25 10 00 	movl   $0x10253c,(%esp)
  1026d3:	e8 5f db ff ff       	call   100237 <cons_intr>
}
  1026d8:	c9                   	leave  
  1026d9:	c3                   	ret    

001026da <kbd_init>:

void
kbd_init(void)
{
  1026da:	55                   	push   %ebp
  1026db:	89 e5                	mov    %esp,%ebp
}
  1026dd:	5d                   	pop    %ebp
  1026de:	c3                   	ret    
  1026df:	90                   	nop

001026e0 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  1026e0:	55                   	push   %ebp
  1026e1:	89 e5                	mov    %esp,%ebp
  1026e3:	83 ec 20             	sub    $0x20,%esp
  1026e6:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1026ed:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1026f0:	89 c2                	mov    %eax,%edx
  1026f2:	ec                   	in     (%dx),%al
  1026f3:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  1026f6:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1026fd:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102700:	89 c2                	mov    %eax,%edx
  102702:	ec                   	in     (%dx),%al
  102703:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  102706:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10270d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102710:	89 c2                	mov    %eax,%edx
  102712:	ec                   	in     (%dx),%al
  102713:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  102716:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10271d:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102720:	89 c2                	mov    %eax,%edx
  102722:	ec                   	in     (%dx),%al
  102723:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  102726:	c9                   	leave  
  102727:	c3                   	ret    

00102728 <serial_proc_data>:

static int
serial_proc_data(void)
{
  102728:	55                   	push   %ebp
  102729:	89 e5                	mov    %esp,%ebp
  10272b:	83 ec 10             	sub    $0x10,%esp
  10272e:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  102735:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102738:	89 c2                	mov    %eax,%edx
  10273a:	ec                   	in     (%dx),%al
  10273b:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  10273e:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  102742:	0f b6 c0             	movzbl %al,%eax
  102745:	83 e0 01             	and    $0x1,%eax
  102748:	85 c0                	test   %eax,%eax
  10274a:	75 07                	jne    102753 <serial_proc_data+0x2b>
		return -1;
  10274c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  102751:	eb 17                	jmp    10276a <serial_proc_data+0x42>
  102753:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10275a:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10275d:	89 c2                	mov    %eax,%edx
  10275f:	ec                   	in     (%dx),%al
  102760:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  102763:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  102767:	0f b6 c0             	movzbl %al,%eax
}
  10276a:	c9                   	leave  
  10276b:	c3                   	ret    

0010276c <serial_intr>:

void
serial_intr(void)
{
  10276c:	55                   	push   %ebp
  10276d:	89 e5                	mov    %esp,%ebp
  10276f:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  102772:	a1 80 8f 10 00       	mov    0x108f80,%eax
  102777:	85 c0                	test   %eax,%eax
  102779:	74 0c                	je     102787 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  10277b:	c7 04 24 28 27 10 00 	movl   $0x102728,(%esp)
  102782:	e8 b0 da ff ff       	call   100237 <cons_intr>
}
  102787:	c9                   	leave  
  102788:	c3                   	ret    

00102789 <serial_putc>:

void
serial_putc(int c)
{
  102789:	55                   	push   %ebp
  10278a:	89 e5                	mov    %esp,%ebp
  10278c:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  10278f:	a1 80 8f 10 00       	mov    0x108f80,%eax
  102794:	85 c0                	test   %eax,%eax
  102796:	74 53                	je     1027eb <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  102798:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  10279f:	eb 09                	jmp    1027aa <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  1027a1:	e8 3a ff ff ff       	call   1026e0 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  1027a6:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  1027aa:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1027b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1027b4:	89 c2                	mov    %eax,%edx
  1027b6:	ec                   	in     (%dx),%al
  1027b7:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  1027ba:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  1027be:	0f b6 c0             	movzbl %al,%eax
  1027c1:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  1027c4:	85 c0                	test   %eax,%eax
  1027c6:	75 09                	jne    1027d1 <serial_putc+0x48>
  1027c8:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  1027cf:	7e d0                	jle    1027a1 <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  1027d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1027d4:	0f b6 c0             	movzbl %al,%eax
  1027d7:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  1027de:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1027e1:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  1027e5:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1027e8:	ee                   	out    %al,(%dx)
  1027e9:	eb 01                	jmp    1027ec <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  1027eb:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  1027ec:	c9                   	leave  
  1027ed:	c3                   	ret    

001027ee <serial_init>:

void
serial_init(void)
{
  1027ee:	55                   	push   %ebp
  1027ef:	89 e5                	mov    %esp,%ebp
  1027f1:	83 ec 50             	sub    $0x50,%esp
  1027f4:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  1027fb:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  1027ff:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  102803:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  102806:	ee                   	out    %al,(%dx)
  102807:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  10280e:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  102812:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  102816:	8b 55 bc             	mov    -0x44(%ebp),%edx
  102819:	ee                   	out    %al,(%dx)
  10281a:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  102821:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  102825:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  102829:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  10282c:	ee                   	out    %al,(%dx)
  10282d:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  102834:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  102838:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  10283c:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10283f:	ee                   	out    %al,(%dx)
  102840:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  102847:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  10284b:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  10284f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  102852:	ee                   	out    %al,(%dx)
  102853:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  10285a:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  10285e:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  102862:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102865:	ee                   	out    %al,(%dx)
  102866:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  10286d:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  102871:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  102875:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  102878:	ee                   	out    %al,(%dx)
  102879:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  102880:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102883:	89 c2                	mov    %eax,%edx
  102885:	ec                   	in     (%dx),%al
  102886:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  102889:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  10288d:	3c ff                	cmp    $0xff,%al
  10288f:	0f 95 c0             	setne  %al
  102892:	0f b6 c0             	movzbl %al,%eax
  102895:	a3 80 8f 10 00       	mov    %eax,0x108f80
  10289a:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1028a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1028a4:	89 c2                	mov    %eax,%edx
  1028a6:	ec                   	in     (%dx),%al
  1028a7:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  1028aa:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1028b1:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1028b4:	89 c2                	mov    %eax,%edx
  1028b6:	ec                   	in     (%dx),%al
  1028b7:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  1028ba:	c9                   	leave  
  1028bb:	c3                   	ret    

001028bc <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  1028bc:	55                   	push   %ebp
  1028bd:	89 e5                	mov    %esp,%ebp
  1028bf:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  1028c2:	8b 45 08             	mov    0x8(%ebp),%eax
  1028c5:	0f b6 c0             	movzbl %al,%eax
  1028c8:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  1028cf:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1028d2:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1028d6:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1028d9:	ee                   	out    %al,(%dx)
  1028da:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1028e1:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1028e4:	89 c2                	mov    %eax,%edx
  1028e6:	ec                   	in     (%dx),%al
  1028e7:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  1028ea:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  1028ee:	0f b6 c0             	movzbl %al,%eax
}
  1028f1:	c9                   	leave  
  1028f2:	c3                   	ret    

001028f3 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  1028f3:	55                   	push   %ebp
  1028f4:	89 e5                	mov    %esp,%ebp
  1028f6:	53                   	push   %ebx
  1028f7:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  1028fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1028fd:	89 04 24             	mov    %eax,(%esp)
  102900:	e8 b7 ff ff ff       	call   1028bc <nvram_read>
  102905:	89 c3                	mov    %eax,%ebx
  102907:	8b 45 08             	mov    0x8(%ebp),%eax
  10290a:	83 c0 01             	add    $0x1,%eax
  10290d:	89 04 24             	mov    %eax,(%esp)
  102910:	e8 a7 ff ff ff       	call   1028bc <nvram_read>
  102915:	c1 e0 08             	shl    $0x8,%eax
  102918:	09 d8                	or     %ebx,%eax
}
  10291a:	83 c4 04             	add    $0x4,%esp
  10291d:	5b                   	pop    %ebx
  10291e:	5d                   	pop    %ebp
  10291f:	c3                   	ret    

00102920 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  102920:	55                   	push   %ebp
  102921:	89 e5                	mov    %esp,%ebp
  102923:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  102926:	8b 45 08             	mov    0x8(%ebp),%eax
  102929:	0f b6 c0             	movzbl %al,%eax
  10292c:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  102933:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102936:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10293a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10293d:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  10293e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102941:	0f b6 c0             	movzbl %al,%eax
  102944:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  10294b:	88 45 fb             	mov    %al,-0x5(%ebp)
  10294e:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  102952:	8b 55 fc             	mov    -0x4(%ebp),%edx
  102955:	ee                   	out    %al,(%dx)
}
  102956:	c9                   	leave  
  102957:	c3                   	ret    

00102958 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  102958:	55                   	push   %ebp
  102959:	89 e5                	mov    %esp,%ebp
  10295b:	53                   	push   %ebx
  10295c:	83 ec 34             	sub    $0x34,%esp
  10295f:	8b 45 10             	mov    0x10(%ebp),%eax
  102962:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102965:	8b 45 14             	mov    0x14(%ebp),%eax
  102968:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  10296b:	8b 45 18             	mov    0x18(%ebp),%eax
  10296e:	ba 00 00 00 00       	mov    $0x0,%edx
  102973:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  102976:	77 72                	ja     1029ea <printnum+0x92>
  102978:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  10297b:	72 05                	jb     102982 <printnum+0x2a>
  10297d:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102980:	77 68                	ja     1029ea <printnum+0x92>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  102982:	8b 45 1c             	mov    0x1c(%ebp),%eax
  102985:	8d 58 ff             	lea    -0x1(%eax),%ebx
  102988:	8b 45 18             	mov    0x18(%ebp),%eax
  10298b:	ba 00 00 00 00       	mov    $0x0,%edx
  102990:	89 44 24 08          	mov    %eax,0x8(%esp)
  102994:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102998:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10299b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10299e:	89 04 24             	mov    %eax,(%esp)
  1029a1:	89 54 24 04          	mov    %edx,0x4(%esp)
  1029a5:	e8 26 0d 00 00       	call   1036d0 <__udivdi3>
  1029aa:	8b 4d 20             	mov    0x20(%ebp),%ecx
  1029ad:	89 4c 24 18          	mov    %ecx,0x18(%esp)
  1029b1:	89 5c 24 14          	mov    %ebx,0x14(%esp)
  1029b5:	8b 4d 18             	mov    0x18(%ebp),%ecx
  1029b8:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  1029bc:	89 44 24 08          	mov    %eax,0x8(%esp)
  1029c0:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1029c4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1029c7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1029cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1029ce:	89 04 24             	mov    %eax,(%esp)
  1029d1:	e8 82 ff ff ff       	call   102958 <printnum>
  1029d6:	eb 1c                	jmp    1029f4 <printnum+0x9c>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  1029d8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1029db:	89 44 24 04          	mov    %eax,0x4(%esp)
  1029df:	8b 45 20             	mov    0x20(%ebp),%eax
  1029e2:	89 04 24             	mov    %eax,(%esp)
  1029e5:	8b 45 08             	mov    0x8(%ebp),%eax
  1029e8:	ff d0                	call   *%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  1029ea:	83 6d 1c 01          	subl   $0x1,0x1c(%ebp)
  1029ee:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
  1029f2:	7f e4                	jg     1029d8 <printnum+0x80>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  1029f4:	8b 4d 18             	mov    0x18(%ebp),%ecx
  1029f7:	bb 00 00 00 00       	mov    $0x0,%ebx
  1029fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1029ff:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102a02:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  102a06:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  102a0a:	89 04 24             	mov    %eax,(%esp)
  102a0d:	89 54 24 04          	mov    %edx,0x4(%esp)
  102a11:	e8 ea 0d 00 00       	call   103800 <__umoddi3>
  102a16:	05 5c 44 10 00       	add    $0x10445c,%eax
  102a1b:	0f b6 00             	movzbl (%eax),%eax
  102a1e:	0f be c0             	movsbl %al,%eax
  102a21:	8b 55 0c             	mov    0xc(%ebp),%edx
  102a24:	89 54 24 04          	mov    %edx,0x4(%esp)
  102a28:	89 04 24             	mov    %eax,(%esp)
  102a2b:	8b 45 08             	mov    0x8(%ebp),%eax
  102a2e:	ff d0                	call   *%eax
}
  102a30:	83 c4 34             	add    $0x34,%esp
  102a33:	5b                   	pop    %ebx
  102a34:	5d                   	pop    %ebp
  102a35:	c3                   	ret    

00102a36 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  102a36:	55                   	push   %ebp
  102a37:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  102a39:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  102a3d:	7e 1c                	jle    102a5b <getuint+0x25>
		return va_arg(*ap, unsigned long long);
  102a3f:	8b 45 08             	mov    0x8(%ebp),%eax
  102a42:	8b 00                	mov    (%eax),%eax
  102a44:	8d 50 08             	lea    0x8(%eax),%edx
  102a47:	8b 45 08             	mov    0x8(%ebp),%eax
  102a4a:	89 10                	mov    %edx,(%eax)
  102a4c:	8b 45 08             	mov    0x8(%ebp),%eax
  102a4f:	8b 00                	mov    (%eax),%eax
  102a51:	83 e8 08             	sub    $0x8,%eax
  102a54:	8b 50 04             	mov    0x4(%eax),%edx
  102a57:	8b 00                	mov    (%eax),%eax
  102a59:	eb 40                	jmp    102a9b <getuint+0x65>
	else if (lflag)
  102a5b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  102a5f:	74 1e                	je     102a7f <getuint+0x49>
		return va_arg(*ap, unsigned long);
  102a61:	8b 45 08             	mov    0x8(%ebp),%eax
  102a64:	8b 00                	mov    (%eax),%eax
  102a66:	8d 50 04             	lea    0x4(%eax),%edx
  102a69:	8b 45 08             	mov    0x8(%ebp),%eax
  102a6c:	89 10                	mov    %edx,(%eax)
  102a6e:	8b 45 08             	mov    0x8(%ebp),%eax
  102a71:	8b 00                	mov    (%eax),%eax
  102a73:	83 e8 04             	sub    $0x4,%eax
  102a76:	8b 00                	mov    (%eax),%eax
  102a78:	ba 00 00 00 00       	mov    $0x0,%edx
  102a7d:	eb 1c                	jmp    102a9b <getuint+0x65>
	else
		return va_arg(*ap, unsigned int);
  102a7f:	8b 45 08             	mov    0x8(%ebp),%eax
  102a82:	8b 00                	mov    (%eax),%eax
  102a84:	8d 50 04             	lea    0x4(%eax),%edx
  102a87:	8b 45 08             	mov    0x8(%ebp),%eax
  102a8a:	89 10                	mov    %edx,(%eax)
  102a8c:	8b 45 08             	mov    0x8(%ebp),%eax
  102a8f:	8b 00                	mov    (%eax),%eax
  102a91:	83 e8 04             	sub    $0x4,%eax
  102a94:	8b 00                	mov    (%eax),%eax
  102a96:	ba 00 00 00 00       	mov    $0x0,%edx
}
  102a9b:	5d                   	pop    %ebp
  102a9c:	c3                   	ret    

00102a9d <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  102a9d:	55                   	push   %ebp
  102a9e:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  102aa0:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  102aa4:	7e 1c                	jle    102ac2 <getint+0x25>
		return va_arg(*ap, long long);
  102aa6:	8b 45 08             	mov    0x8(%ebp),%eax
  102aa9:	8b 00                	mov    (%eax),%eax
  102aab:	8d 50 08             	lea    0x8(%eax),%edx
  102aae:	8b 45 08             	mov    0x8(%ebp),%eax
  102ab1:	89 10                	mov    %edx,(%eax)
  102ab3:	8b 45 08             	mov    0x8(%ebp),%eax
  102ab6:	8b 00                	mov    (%eax),%eax
  102ab8:	83 e8 08             	sub    $0x8,%eax
  102abb:	8b 50 04             	mov    0x4(%eax),%edx
  102abe:	8b 00                	mov    (%eax),%eax
  102ac0:	eb 40                	jmp    102b02 <getint+0x65>
	else if (lflag)
  102ac2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  102ac6:	74 1e                	je     102ae6 <getint+0x49>
		return va_arg(*ap, long);
  102ac8:	8b 45 08             	mov    0x8(%ebp),%eax
  102acb:	8b 00                	mov    (%eax),%eax
  102acd:	8d 50 04             	lea    0x4(%eax),%edx
  102ad0:	8b 45 08             	mov    0x8(%ebp),%eax
  102ad3:	89 10                	mov    %edx,(%eax)
  102ad5:	8b 45 08             	mov    0x8(%ebp),%eax
  102ad8:	8b 00                	mov    (%eax),%eax
  102ada:	83 e8 04             	sub    $0x4,%eax
  102add:	8b 00                	mov    (%eax),%eax
  102adf:	89 c2                	mov    %eax,%edx
  102ae1:	c1 fa 1f             	sar    $0x1f,%edx
  102ae4:	eb 1c                	jmp    102b02 <getint+0x65>
	else
		return va_arg(*ap, int);
  102ae6:	8b 45 08             	mov    0x8(%ebp),%eax
  102ae9:	8b 00                	mov    (%eax),%eax
  102aeb:	8d 50 04             	lea    0x4(%eax),%edx
  102aee:	8b 45 08             	mov    0x8(%ebp),%eax
  102af1:	89 10                	mov    %edx,(%eax)
  102af3:	8b 45 08             	mov    0x8(%ebp),%eax
  102af6:	8b 00                	mov    (%eax),%eax
  102af8:	83 e8 04             	sub    $0x4,%eax
  102afb:	8b 00                	mov    (%eax),%eax
  102afd:	89 c2                	mov    %eax,%edx
  102aff:	c1 fa 1f             	sar    $0x1f,%edx
}
  102b02:	5d                   	pop    %ebp
  102b03:	c3                   	ret    

00102b04 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  102b04:	55                   	push   %ebp
  102b05:	89 e5                	mov    %esp,%ebp
  102b07:	56                   	push   %esi
  102b08:	53                   	push   %ebx
  102b09:	83 ec 40             	sub    $0x40,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  102b0c:	eb 17                	jmp    102b25 <vprintfmt+0x21>
			if (ch == '\0')
  102b0e:	85 db                	test   %ebx,%ebx
  102b10:	0f 84 8f 03 00 00    	je     102ea5 <vprintfmt+0x3a1>
				return;
			putch(ch, putdat);
  102b16:	8b 45 0c             	mov    0xc(%ebp),%eax
  102b19:	89 44 24 04          	mov    %eax,0x4(%esp)
  102b1d:	89 1c 24             	mov    %ebx,(%esp)
  102b20:	8b 45 08             	mov    0x8(%ebp),%eax
  102b23:	ff d0                	call   *%eax
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  102b25:	8b 45 10             	mov    0x10(%ebp),%eax
  102b28:	0f b6 00             	movzbl (%eax),%eax
  102b2b:	0f b6 d8             	movzbl %al,%ebx
  102b2e:	83 fb 25             	cmp    $0x25,%ebx
  102b31:	0f 95 c0             	setne  %al
  102b34:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  102b38:	84 c0                	test   %al,%al
  102b3a:	75 d2                	jne    102b0e <vprintfmt+0xa>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
  102b3c:	c6 45 f7 20          	movb   $0x20,-0x9(%ebp)
		width = -1;
  102b40:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,-0x18(%ebp)
		precision = -1;
  102b47:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
		lflag = 0;
  102b4e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		altflag = 0;
  102b55:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  102b5c:	eb 04                	jmp    102b62 <vprintfmt+0x5e>
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
			goto reswitch;
  102b5e:	90                   	nop
  102b5f:	eb 01                	jmp    102b62 <vprintfmt+0x5e>
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
			goto reswitch;
  102b61:	90                   	nop
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  102b62:	8b 45 10             	mov    0x10(%ebp),%eax
  102b65:	0f b6 00             	movzbl (%eax),%eax
  102b68:	0f b6 d8             	movzbl %al,%ebx
  102b6b:	89 d8                	mov    %ebx,%eax
  102b6d:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  102b71:	83 e8 23             	sub    $0x23,%eax
  102b74:	83 f8 55             	cmp    $0x55,%eax
  102b77:	0f 87 f8 02 00 00    	ja     102e75 <vprintfmt+0x371>
  102b7d:	8b 04 85 74 44 10 00 	mov    0x104474(,%eax,4),%eax
  102b84:	ff e0                	jmp    *%eax

		// flag to pad on the right
		case '-':
			padc = '-';
  102b86:	c6 45 f7 2d          	movb   $0x2d,-0x9(%ebp)
			goto reswitch;
  102b8a:	eb d6                	jmp    102b62 <vprintfmt+0x5e>
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  102b8c:	c6 45 f7 30          	movb   $0x30,-0x9(%ebp)
			goto reswitch;
  102b90:	eb d0                	jmp    102b62 <vprintfmt+0x5e>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  102b92:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
				precision = precision * 10 + ch - '0';
  102b99:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102b9c:	89 d0                	mov    %edx,%eax
  102b9e:	c1 e0 02             	shl    $0x2,%eax
  102ba1:	01 d0                	add    %edx,%eax
  102ba3:	01 c0                	add    %eax,%eax
  102ba5:	01 d8                	add    %ebx,%eax
  102ba7:	83 e8 30             	sub    $0x30,%eax
  102baa:	89 45 ec             	mov    %eax,-0x14(%ebp)
				ch = *fmt;
  102bad:	8b 45 10             	mov    0x10(%ebp),%eax
  102bb0:	0f b6 00             	movzbl (%eax),%eax
  102bb3:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  102bb6:	83 fb 2f             	cmp    $0x2f,%ebx
  102bb9:	7e 43                	jle    102bfe <vprintfmt+0xfa>
  102bbb:	83 fb 39             	cmp    $0x39,%ebx
  102bbe:	7f 41                	jg     102c01 <vprintfmt+0xfd>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  102bc0:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  102bc4:	eb d3                	jmp    102b99 <vprintfmt+0x95>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  102bc6:	8b 45 14             	mov    0x14(%ebp),%eax
  102bc9:	83 c0 04             	add    $0x4,%eax
  102bcc:	89 45 14             	mov    %eax,0x14(%ebp)
  102bcf:	8b 45 14             	mov    0x14(%ebp),%eax
  102bd2:	83 e8 04             	sub    $0x4,%eax
  102bd5:	8b 00                	mov    (%eax),%eax
  102bd7:	89 45 ec             	mov    %eax,-0x14(%ebp)
			goto process_precision;
  102bda:	eb 26                	jmp    102c02 <vprintfmt+0xfe>

		case '.':
			if (width < 0)
  102bdc:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  102be0:	0f 89 78 ff ff ff    	jns    102b5e <vprintfmt+0x5a>
				width = 0;
  102be6:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
			goto reswitch;
  102bed:	e9 70 ff ff ff       	jmp    102b62 <vprintfmt+0x5e>

		case '#':
			altflag = 1;
  102bf2:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
			goto reswitch;
  102bf9:	e9 64 ff ff ff       	jmp    102b62 <vprintfmt+0x5e>
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto process_precision;
  102bfe:	90                   	nop
  102bff:	eb 01                	jmp    102c02 <vprintfmt+0xfe>
  102c01:	90                   	nop
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  102c02:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  102c06:	0f 89 55 ff ff ff    	jns    102b61 <vprintfmt+0x5d>
				width = precision, precision = -1;
  102c0c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102c0f:	89 45 e8             	mov    %eax,-0x18(%ebp)
  102c12:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
			goto reswitch;
  102c19:	e9 44 ff ff ff       	jmp    102b62 <vprintfmt+0x5e>

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  102c1e:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
			goto reswitch;
  102c22:	e9 3b ff ff ff       	jmp    102b62 <vprintfmt+0x5e>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  102c27:	8b 45 14             	mov    0x14(%ebp),%eax
  102c2a:	83 c0 04             	add    $0x4,%eax
  102c2d:	89 45 14             	mov    %eax,0x14(%ebp)
  102c30:	8b 45 14             	mov    0x14(%ebp),%eax
  102c33:	83 e8 04             	sub    $0x4,%eax
  102c36:	8b 00                	mov    (%eax),%eax
  102c38:	8b 55 0c             	mov    0xc(%ebp),%edx
  102c3b:	89 54 24 04          	mov    %edx,0x4(%esp)
  102c3f:	89 04 24             	mov    %eax,(%esp)
  102c42:	8b 45 08             	mov    0x8(%ebp),%eax
  102c45:	ff d0                	call   *%eax
			break;
  102c47:	e9 53 02 00 00       	jmp    102e9f <vprintfmt+0x39b>

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  102c4c:	8b 45 14             	mov    0x14(%ebp),%eax
  102c4f:	83 c0 04             	add    $0x4,%eax
  102c52:	89 45 14             	mov    %eax,0x14(%ebp)
  102c55:	8b 45 14             	mov    0x14(%ebp),%eax
  102c58:	83 e8 04             	sub    $0x4,%eax
  102c5b:	8b 30                	mov    (%eax),%esi
  102c5d:	85 f6                	test   %esi,%esi
  102c5f:	75 05                	jne    102c66 <vprintfmt+0x162>
				p = "(null)";
  102c61:	be 6d 44 10 00       	mov    $0x10446d,%esi
			if (width > 0 && padc != '-')
  102c66:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  102c6a:	7e 73                	jle    102cdf <vprintfmt+0x1db>
  102c6c:	80 7d f7 2d          	cmpb   $0x2d,-0x9(%ebp)
  102c70:	74 70                	je     102ce2 <vprintfmt+0x1de>
				for (width -= strnlen(p, precision); width > 0; width--)
  102c72:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102c75:	89 44 24 04          	mov    %eax,0x4(%esp)
  102c79:	89 34 24             	mov    %esi,(%esp)
  102c7c:	e8 01 05 00 00       	call   103182 <strnlen>
  102c81:	29 45 e8             	sub    %eax,-0x18(%ebp)
  102c84:	eb 17                	jmp    102c9d <vprintfmt+0x199>
					putch(padc, putdat);
  102c86:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  102c8a:	8b 55 0c             	mov    0xc(%ebp),%edx
  102c8d:	89 54 24 04          	mov    %edx,0x4(%esp)
  102c91:	89 04 24             	mov    %eax,(%esp)
  102c94:	8b 45 08             	mov    0x8(%ebp),%eax
  102c97:	ff d0                	call   *%eax
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  102c99:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
  102c9d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  102ca1:	7f e3                	jg     102c86 <vprintfmt+0x182>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  102ca3:	eb 3e                	jmp    102ce3 <vprintfmt+0x1df>
				if (altflag && (ch < ' ' || ch > '~'))
  102ca5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  102ca9:	74 1f                	je     102cca <vprintfmt+0x1c6>
  102cab:	83 fb 1f             	cmp    $0x1f,%ebx
  102cae:	7e 05                	jle    102cb5 <vprintfmt+0x1b1>
  102cb0:	83 fb 7e             	cmp    $0x7e,%ebx
  102cb3:	7e 15                	jle    102cca <vprintfmt+0x1c6>
					putch('?', putdat);
  102cb5:	8b 45 0c             	mov    0xc(%ebp),%eax
  102cb8:	89 44 24 04          	mov    %eax,0x4(%esp)
  102cbc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  102cc3:	8b 45 08             	mov    0x8(%ebp),%eax
  102cc6:	ff d0                	call   *%eax
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  102cc8:	eb 0f                	jmp    102cd9 <vprintfmt+0x1d5>
					putch('?', putdat);
				else
					putch(ch, putdat);
  102cca:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ccd:	89 44 24 04          	mov    %eax,0x4(%esp)
  102cd1:	89 1c 24             	mov    %ebx,(%esp)
  102cd4:	8b 45 08             	mov    0x8(%ebp),%eax
  102cd7:	ff d0                	call   *%eax
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  102cd9:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
  102cdd:	eb 04                	jmp    102ce3 <vprintfmt+0x1df>
  102cdf:	90                   	nop
  102ce0:	eb 01                	jmp    102ce3 <vprintfmt+0x1df>
  102ce2:	90                   	nop
  102ce3:	0f b6 06             	movzbl (%esi),%eax
  102ce6:	0f be d8             	movsbl %al,%ebx
  102ce9:	85 db                	test   %ebx,%ebx
  102ceb:	0f 95 c0             	setne  %al
  102cee:	83 c6 01             	add    $0x1,%esi
  102cf1:	84 c0                	test   %al,%al
  102cf3:	74 29                	je     102d1e <vprintfmt+0x21a>
  102cf5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  102cf9:	78 aa                	js     102ca5 <vprintfmt+0x1a1>
  102cfb:	83 6d ec 01          	subl   $0x1,-0x14(%ebp)
  102cff:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  102d03:	79 a0                	jns    102ca5 <vprintfmt+0x1a1>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  102d05:	eb 17                	jmp    102d1e <vprintfmt+0x21a>
				putch(' ', putdat);
  102d07:	8b 45 0c             	mov    0xc(%ebp),%eax
  102d0a:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d0e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  102d15:	8b 45 08             	mov    0x8(%ebp),%eax
  102d18:	ff d0                	call   *%eax
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  102d1a:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
  102d1e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  102d22:	7f e3                	jg     102d07 <vprintfmt+0x203>
				putch(' ', putdat);
			break;
  102d24:	e9 76 01 00 00       	jmp    102e9f <vprintfmt+0x39b>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  102d29:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102d2c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d30:	8d 45 14             	lea    0x14(%ebp),%eax
  102d33:	89 04 24             	mov    %eax,(%esp)
  102d36:	e8 62 fd ff ff       	call   102a9d <getint>
  102d3b:	89 45 d8             	mov    %eax,-0x28(%ebp)
  102d3e:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
  102d41:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102d44:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102d47:	85 d2                	test   %edx,%edx
  102d49:	79 26                	jns    102d71 <vprintfmt+0x26d>
				putch('-', putdat);
  102d4b:	8b 45 0c             	mov    0xc(%ebp),%eax
  102d4e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d52:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  102d59:	8b 45 08             	mov    0x8(%ebp),%eax
  102d5c:	ff d0                	call   *%eax
				num = -(long long) num;
  102d5e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102d61:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102d64:	f7 d8                	neg    %eax
  102d66:	83 d2 00             	adc    $0x0,%edx
  102d69:	f7 da                	neg    %edx
  102d6b:	89 45 d8             	mov    %eax,-0x28(%ebp)
  102d6e:	89 55 dc             	mov    %edx,-0x24(%ebp)
			}
			base = 10;
  102d71:	c7 45 e0 0a 00 00 00 	movl   $0xa,-0x20(%ebp)
			goto number;
  102d78:	e9 af 00 00 00       	jmp    102e2c <vprintfmt+0x328>

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  102d7d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102d80:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d84:	8d 45 14             	lea    0x14(%ebp),%eax
  102d87:	89 04 24             	mov    %eax,(%esp)
  102d8a:	e8 a7 fc ff ff       	call   102a36 <getuint>
  102d8f:	89 45 d8             	mov    %eax,-0x28(%ebp)
  102d92:	89 55 dc             	mov    %edx,-0x24(%ebp)
			base = 10;
  102d95:	c7 45 e0 0a 00 00 00 	movl   $0xa,-0x20(%ebp)
			goto number;
  102d9c:	e9 8b 00 00 00       	jmp    102e2c <vprintfmt+0x328>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag); 	//putch('X', putdat);
  102da1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102da4:	89 44 24 04          	mov    %eax,0x4(%esp)
  102da8:	8d 45 14             	lea    0x14(%ebp),%eax
  102dab:	89 04 24             	mov    %eax,(%esp)
  102dae:	e8 83 fc ff ff       	call   102a36 <getuint>
  102db3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  102db6:	89 55 dc             	mov    %edx,-0x24(%ebp)
			base = 8 ;			//putch('X', putdat);
  102db9:	c7 45 e0 08 00 00 00 	movl   $0x8,-0x20(%ebp)
			goto number;			//putch('X', putdat);
  102dc0:	eb 6a                	jmp    102e2c <vprintfmt+0x328>
							//break;

		// pointer
		case 'p':
			putch('0', putdat);
  102dc2:	8b 45 0c             	mov    0xc(%ebp),%eax
  102dc5:	89 44 24 04          	mov    %eax,0x4(%esp)
  102dc9:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  102dd0:	8b 45 08             	mov    0x8(%ebp),%eax
  102dd3:	ff d0                	call   *%eax
			putch('x', putdat);
  102dd5:	8b 45 0c             	mov    0xc(%ebp),%eax
  102dd8:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ddc:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  102de3:	8b 45 08             	mov    0x8(%ebp),%eax
  102de6:	ff d0                	call   *%eax
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  102de8:	8b 45 14             	mov    0x14(%ebp),%eax
  102deb:	83 c0 04             	add    $0x4,%eax
  102dee:	89 45 14             	mov    %eax,0x14(%ebp)
  102df1:	8b 45 14             	mov    0x14(%ebp),%eax
  102df4:	83 e8 04             	sub    $0x4,%eax
  102df7:	8b 00                	mov    (%eax),%eax

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  102df9:	ba 00 00 00 00       	mov    $0x0,%edx
  102dfe:	89 45 d8             	mov    %eax,-0x28(%ebp)
  102e01:	89 55 dc             	mov    %edx,-0x24(%ebp)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  102e04:	c7 45 e0 10 00 00 00 	movl   $0x10,-0x20(%ebp)
			goto number;
  102e0b:	eb 1f                	jmp    102e2c <vprintfmt+0x328>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  102e0d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102e10:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e14:	8d 45 14             	lea    0x14(%ebp),%eax
  102e17:	89 04 24             	mov    %eax,(%esp)
  102e1a:	e8 17 fc ff ff       	call   102a36 <getuint>
  102e1f:	89 45 d8             	mov    %eax,-0x28(%ebp)
  102e22:	89 55 dc             	mov    %edx,-0x24(%ebp)
			base = 16;
  102e25:	c7 45 e0 10 00 00 00 	movl   $0x10,-0x20(%ebp)
		number:
			printnum(putch, putdat, num, base, width, padc);
  102e2c:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
  102e30:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102e33:	89 54 24 18          	mov    %edx,0x18(%esp)
  102e37:	8b 55 e8             	mov    -0x18(%ebp),%edx
  102e3a:	89 54 24 14          	mov    %edx,0x14(%esp)
  102e3e:	89 44 24 10          	mov    %eax,0x10(%esp)
  102e42:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102e45:	8b 55 dc             	mov    -0x24(%ebp),%edx
  102e48:	89 44 24 08          	mov    %eax,0x8(%esp)
  102e4c:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102e50:	8b 45 0c             	mov    0xc(%ebp),%eax
  102e53:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e57:	8b 45 08             	mov    0x8(%ebp),%eax
  102e5a:	89 04 24             	mov    %eax,(%esp)
  102e5d:	e8 f6 fa ff ff       	call   102958 <printnum>
			break;
  102e62:	eb 3b                	jmp    102e9f <vprintfmt+0x39b>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  102e64:	8b 45 0c             	mov    0xc(%ebp),%eax
  102e67:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e6b:	89 1c 24             	mov    %ebx,(%esp)
  102e6e:	8b 45 08             	mov    0x8(%ebp),%eax
  102e71:	ff d0                	call   *%eax
			break;
  102e73:	eb 2a                	jmp    102e9f <vprintfmt+0x39b>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  102e75:	8b 45 0c             	mov    0xc(%ebp),%eax
  102e78:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e7c:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  102e83:	8b 45 08             	mov    0x8(%ebp),%eax
  102e86:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  102e88:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102e8c:	eb 04                	jmp    102e92 <vprintfmt+0x38e>
  102e8e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102e92:	8b 45 10             	mov    0x10(%ebp),%eax
  102e95:	83 e8 01             	sub    $0x1,%eax
  102e98:	0f b6 00             	movzbl (%eax),%eax
  102e9b:	3c 25                	cmp    $0x25,%al
  102e9d:	75 ef                	jne    102e8e <vprintfmt+0x38a>
				/* do nothing */;
			break;
		}
	}
  102e9f:	90                   	nop
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  102ea0:	e9 80 fc ff ff       	jmp    102b25 <vprintfmt+0x21>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  102ea5:	83 c4 40             	add    $0x40,%esp
  102ea8:	5b                   	pop    %ebx
  102ea9:	5e                   	pop    %esi
  102eaa:	5d                   	pop    %ebp
  102eab:	c3                   	ret    

00102eac <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  102eac:	55                   	push   %ebp
  102ead:	89 e5                	mov    %esp,%ebp
  102eaf:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  102eb2:	8d 45 10             	lea    0x10(%ebp),%eax
  102eb5:	83 c0 04             	add    $0x4,%eax
  102eb8:	89 45 f4             	mov    %eax,-0xc(%ebp)
	vprintfmt(putch, putdat, fmt, ap);
  102ebb:	8b 45 10             	mov    0x10(%ebp),%eax
  102ebe:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102ec1:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102ec5:	89 44 24 08          	mov    %eax,0x8(%esp)
  102ec9:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ecc:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ed0:	8b 45 08             	mov    0x8(%ebp),%eax
  102ed3:	89 04 24             	mov    %eax,(%esp)
  102ed6:	e8 29 fc ff ff       	call   102b04 <vprintfmt>
	va_end(ap);
}
  102edb:	c9                   	leave  
  102edc:	c3                   	ret    

00102edd <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  102edd:	55                   	push   %ebp
  102ede:	89 e5                	mov    %esp,%ebp
	b->cnt++;
  102ee0:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ee3:	8b 40 08             	mov    0x8(%eax),%eax
  102ee6:	8d 50 01             	lea    0x1(%eax),%edx
  102ee9:	8b 45 0c             	mov    0xc(%ebp),%eax
  102eec:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
  102eef:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ef2:	8b 10                	mov    (%eax),%edx
  102ef4:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ef7:	8b 40 04             	mov    0x4(%eax),%eax
  102efa:	39 c2                	cmp    %eax,%edx
  102efc:	73 12                	jae    102f10 <sprintputch+0x33>
		*b->buf++ = ch;
  102efe:	8b 45 0c             	mov    0xc(%ebp),%eax
  102f01:	8b 00                	mov    (%eax),%eax
  102f03:	8b 55 08             	mov    0x8(%ebp),%edx
  102f06:	88 10                	mov    %dl,(%eax)
  102f08:	8d 50 01             	lea    0x1(%eax),%edx
  102f0b:	8b 45 0c             	mov    0xc(%ebp),%eax
  102f0e:	89 10                	mov    %edx,(%eax)
}
  102f10:	5d                   	pop    %ebp
  102f11:	c3                   	ret    

00102f12 <vsprintf>:

int
vsprintf(char *buf, const char *fmt, va_list ap)
{
  102f12:	55                   	push   %ebp
  102f13:	89 e5                	mov    %esp,%ebp
  102f15:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL);
  102f18:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102f1c:	75 24                	jne    102f42 <vsprintf+0x30>
  102f1e:	c7 44 24 0c cc 45 10 	movl   $0x1045cc,0xc(%esp)
  102f25:	00 
  102f26:	c7 44 24 08 d8 45 10 	movl   $0x1045d8,0x8(%esp)
  102f2d:	00 
  102f2e:	c7 44 24 04 05 01 00 	movl   $0x105,0x4(%esp)
  102f35:	00 
  102f36:	c7 04 24 ed 45 10 00 	movl   $0x1045ed,(%esp)
  102f3d:	e8 56 d4 ff ff       	call   100398 <debug_panic>
	struct sprintbuf b = {buf, (char*)(intptr_t)~0, 0};
  102f42:	8b 45 08             	mov    0x8(%ebp),%eax
  102f45:	89 45 ec             	mov    %eax,-0x14(%ebp)
  102f48:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
  102f4f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  102f56:	b8 dd 2e 10 00       	mov    $0x102edd,%eax
  102f5b:	8b 55 10             	mov    0x10(%ebp),%edx
  102f5e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102f62:	8b 55 0c             	mov    0xc(%ebp),%edx
  102f65:	89 54 24 08          	mov    %edx,0x8(%esp)
  102f69:	8d 55 ec             	lea    -0x14(%ebp),%edx
  102f6c:	89 54 24 04          	mov    %edx,0x4(%esp)
  102f70:	89 04 24             	mov    %eax,(%esp)
  102f73:	e8 8c fb ff ff       	call   102b04 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  102f78:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102f7b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  102f7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  102f81:	c9                   	leave  
  102f82:	c3                   	ret    

00102f83 <sprintf>:

int
sprintf(char *buf, const char *fmt, ...)
{
  102f83:	55                   	push   %ebp
  102f84:	89 e5                	mov    %esp,%ebp
  102f86:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  102f89:	8d 45 0c             	lea    0xc(%ebp),%eax
  102f8c:	83 c0 04             	add    $0x4,%eax
  102f8f:	89 45 f0             	mov    %eax,-0x10(%ebp)
	rc = vsprintf(buf, fmt, ap);
  102f92:	8b 45 0c             	mov    0xc(%ebp),%eax
  102f95:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102f98:	89 54 24 08          	mov    %edx,0x8(%esp)
  102f9c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102fa0:	8b 45 08             	mov    0x8(%ebp),%eax
  102fa3:	89 04 24             	mov    %eax,(%esp)
  102fa6:	e8 67 ff ff ff       	call   102f12 <vsprintf>
  102fab:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return rc;
  102fae:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  102fb1:	c9                   	leave  
  102fb2:	c3                   	ret    

00102fb3 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  102fb3:	55                   	push   %ebp
  102fb4:	89 e5                	mov    %esp,%ebp
  102fb6:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL && n > 0);
  102fb9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102fbd:	74 06                	je     102fc5 <vsnprintf+0x12>
  102fbf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  102fc3:	7f 24                	jg     102fe9 <vsnprintf+0x36>
  102fc5:	c7 44 24 0c fc 45 10 	movl   $0x1045fc,0xc(%esp)
  102fcc:	00 
  102fcd:	c7 44 24 08 d8 45 10 	movl   $0x1045d8,0x8(%esp)
  102fd4:	00 
  102fd5:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
  102fdc:	00 
  102fdd:	c7 04 24 ed 45 10 00 	movl   $0x1045ed,(%esp)
  102fe4:	e8 af d3 ff ff       	call   100398 <debug_panic>
	struct sprintbuf b = {buf, buf+n-1, 0};
  102fe9:	8b 45 0c             	mov    0xc(%ebp),%eax
  102fec:	83 e8 01             	sub    $0x1,%eax
  102fef:	03 45 08             	add    0x8(%ebp),%eax
  102ff2:	8b 55 08             	mov    0x8(%ebp),%edx
  102ff5:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102ff8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102ffb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  103002:	b8 dd 2e 10 00       	mov    $0x102edd,%eax
  103007:	8b 55 14             	mov    0x14(%ebp),%edx
  10300a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10300e:	8b 55 10             	mov    0x10(%ebp),%edx
  103011:	89 54 24 08          	mov    %edx,0x8(%esp)
  103015:	8d 55 ec             	lea    -0x14(%ebp),%edx
  103018:	89 54 24 04          	mov    %edx,0x4(%esp)
  10301c:	89 04 24             	mov    %eax,(%esp)
  10301f:	e8 e0 fa ff ff       	call   102b04 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  103024:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103027:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  10302a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  10302d:	c9                   	leave  
  10302e:	c3                   	ret    

0010302f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  10302f:	55                   	push   %ebp
  103030:	89 e5                	mov    %esp,%ebp
  103032:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  103035:	8d 45 10             	lea    0x10(%ebp),%eax
  103038:	83 c0 04             	add    $0x4,%eax
  10303b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
  10303e:	8b 45 10             	mov    0x10(%ebp),%eax
  103041:	8b 55 f0             	mov    -0x10(%ebp),%edx
  103044:	89 54 24 0c          	mov    %edx,0xc(%esp)
  103048:	89 44 24 08          	mov    %eax,0x8(%esp)
  10304c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10304f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103053:	8b 45 08             	mov    0x8(%ebp),%eax
  103056:	89 04 24             	mov    %eax,(%esp)
  103059:	e8 55 ff ff ff       	call   102fb3 <vsnprintf>
  10305e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return rc;
  103061:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  103064:	c9                   	leave  
  103065:	c3                   	ret    
  103066:	90                   	nop
  103067:	90                   	nop

00103068 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  103068:	55                   	push   %ebp
  103069:	89 e5                	mov    %esp,%ebp
  10306b:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  10306e:	8b 45 0c             	mov    0xc(%ebp),%eax
  103071:	8b 00                	mov    (%eax),%eax
  103073:	8b 55 08             	mov    0x8(%ebp),%edx
  103076:	89 d1                	mov    %edx,%ecx
  103078:	8b 55 0c             	mov    0xc(%ebp),%edx
  10307b:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  10307f:	8d 50 01             	lea    0x1(%eax),%edx
  103082:	8b 45 0c             	mov    0xc(%ebp),%eax
  103085:	89 10                	mov    %edx,(%eax)
	if (b->idx == SYS_CPUTS_MAX-1) {
  103087:	8b 45 0c             	mov    0xc(%ebp),%eax
  10308a:	8b 00                	mov    (%eax),%eax
  10308c:	3d ff 00 00 00       	cmp    $0xff,%eax
  103091:	75 24                	jne    1030b7 <putch+0x4f>
		b->buf[b->idx] = 0;
  103093:	8b 45 0c             	mov    0xc(%ebp),%eax
  103096:	8b 00                	mov    (%eax),%eax
  103098:	8b 55 0c             	mov    0xc(%ebp),%edx
  10309b:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  1030a0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1030a3:	83 c0 08             	add    $0x8,%eax
  1030a6:	89 04 24             	mov    %eax,(%esp)
  1030a9:	e8 97 d2 ff ff       	call   100345 <cputs>
		b->idx = 0;
  1030ae:	8b 45 0c             	mov    0xc(%ebp),%eax
  1030b1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  1030b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1030ba:	8b 40 04             	mov    0x4(%eax),%eax
  1030bd:	8d 50 01             	lea    0x1(%eax),%edx
  1030c0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1030c3:	89 50 04             	mov    %edx,0x4(%eax)
}
  1030c6:	c9                   	leave  
  1030c7:	c3                   	ret    

001030c8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  1030c8:	55                   	push   %ebp
  1030c9:	89 e5                	mov    %esp,%ebp
  1030cb:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  1030d1:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  1030d8:	00 00 00 
	b.cnt = 0;
  1030db:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  1030e2:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  1030e5:	b8 68 30 10 00       	mov    $0x103068,%eax
  1030ea:	8b 55 0c             	mov    0xc(%ebp),%edx
  1030ed:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1030f1:	8b 55 08             	mov    0x8(%ebp),%edx
  1030f4:	89 54 24 08          	mov    %edx,0x8(%esp)
  1030f8:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  1030fe:	89 54 24 04          	mov    %edx,0x4(%esp)
  103102:	89 04 24             	mov    %eax,(%esp)
  103105:	e8 fa f9 ff ff       	call   102b04 <vprintfmt>

	b.buf[b.idx] = 0;
  10310a:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  103110:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  103117:	00 
	cputs(b.buf);
  103118:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  10311e:	83 c0 08             	add    $0x8,%eax
  103121:	89 04 24             	mov    %eax,(%esp)
  103124:	e8 1c d2 ff ff       	call   100345 <cputs>

	return b.cnt;
  103129:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  10312f:	c9                   	leave  
  103130:	c3                   	ret    

00103131 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  103131:	55                   	push   %ebp
  103132:	89 e5                	mov    %esp,%ebp
  103134:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  103137:	8d 45 08             	lea    0x8(%ebp),%eax
  10313a:	83 c0 04             	add    $0x4,%eax
  10313d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  103140:	8b 45 08             	mov    0x8(%ebp),%eax
  103143:	8b 55 f0             	mov    -0x10(%ebp),%edx
  103146:	89 54 24 04          	mov    %edx,0x4(%esp)
  10314a:	89 04 24             	mov    %eax,(%esp)
  10314d:	e8 76 ff ff ff       	call   1030c8 <vcprintf>
  103152:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  103155:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  103158:	c9                   	leave  
  103159:	c3                   	ret    
  10315a:	90                   	nop
  10315b:	90                   	nop

0010315c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  10315c:	55                   	push   %ebp
  10315d:	89 e5                	mov    %esp,%ebp
  10315f:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  103162:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  103169:	eb 08                	jmp    103173 <strlen+0x17>
		n++;
  10316b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  10316f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  103173:	8b 45 08             	mov    0x8(%ebp),%eax
  103176:	0f b6 00             	movzbl (%eax),%eax
  103179:	84 c0                	test   %al,%al
  10317b:	75 ee                	jne    10316b <strlen+0xf>
		n++;
	return n;
  10317d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  103180:	c9                   	leave  
  103181:	c3                   	ret    

00103182 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  103182:	55                   	push   %ebp
  103183:	89 e5                	mov    %esp,%ebp
  103185:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  103188:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  10318f:	eb 0c                	jmp    10319d <strnlen+0x1b>
		n++;
  103191:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  103195:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  103199:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
  10319d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  1031a1:	74 0a                	je     1031ad <strnlen+0x2b>
  1031a3:	8b 45 08             	mov    0x8(%ebp),%eax
  1031a6:	0f b6 00             	movzbl (%eax),%eax
  1031a9:	84 c0                	test   %al,%al
  1031ab:	75 e4                	jne    103191 <strnlen+0xf>
		n++;
	return n;
  1031ad:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1031b0:	c9                   	leave  
  1031b1:	c3                   	ret    

001031b2 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  1031b2:	55                   	push   %ebp
  1031b3:	89 e5                	mov    %esp,%ebp
  1031b5:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  1031b8:	8b 45 08             	mov    0x8(%ebp),%eax
  1031bb:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  1031be:	8b 45 0c             	mov    0xc(%ebp),%eax
  1031c1:	0f b6 10             	movzbl (%eax),%edx
  1031c4:	8b 45 08             	mov    0x8(%ebp),%eax
  1031c7:	88 10                	mov    %dl,(%eax)
  1031c9:	8b 45 08             	mov    0x8(%ebp),%eax
  1031cc:	0f b6 00             	movzbl (%eax),%eax
  1031cf:	84 c0                	test   %al,%al
  1031d1:	0f 95 c0             	setne  %al
  1031d4:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1031d8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  1031dc:	84 c0                	test   %al,%al
  1031de:	75 de                	jne    1031be <strcpy+0xc>
		/* do nothing */;
	return ret;
  1031e0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1031e3:	c9                   	leave  
  1031e4:	c3                   	ret    

001031e5 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  1031e5:	55                   	push   %ebp
  1031e6:	89 e5                	mov    %esp,%ebp
  1031e8:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  1031eb:	8b 45 08             	mov    0x8(%ebp),%eax
  1031ee:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  1031f1:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  1031f8:	eb 21                	jmp    10321b <strncpy+0x36>
		*dst++ = *src;
  1031fa:	8b 45 0c             	mov    0xc(%ebp),%eax
  1031fd:	0f b6 10             	movzbl (%eax),%edx
  103200:	8b 45 08             	mov    0x8(%ebp),%eax
  103203:	88 10                	mov    %dl,(%eax)
  103205:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  103209:	8b 45 0c             	mov    0xc(%ebp),%eax
  10320c:	0f b6 00             	movzbl (%eax),%eax
  10320f:	84 c0                	test   %al,%al
  103211:	74 04                	je     103217 <strncpy+0x32>
			src++;
  103213:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  103217:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  10321b:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10321e:	3b 45 10             	cmp    0x10(%ebp),%eax
  103221:	72 d7                	jb     1031fa <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  103223:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  103226:	c9                   	leave  
  103227:	c3                   	ret    

00103228 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  103228:	55                   	push   %ebp
  103229:	89 e5                	mov    %esp,%ebp
  10322b:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  10322e:	8b 45 08             	mov    0x8(%ebp),%eax
  103231:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  103234:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  103238:	74 2f                	je     103269 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  10323a:	eb 13                	jmp    10324f <strlcpy+0x27>
			*dst++ = *src++;
  10323c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10323f:	0f b6 10             	movzbl (%eax),%edx
  103242:	8b 45 08             	mov    0x8(%ebp),%eax
  103245:	88 10                	mov    %dl,(%eax)
  103247:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10324b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  10324f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  103253:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  103257:	74 0a                	je     103263 <strlcpy+0x3b>
  103259:	8b 45 0c             	mov    0xc(%ebp),%eax
  10325c:	0f b6 00             	movzbl (%eax),%eax
  10325f:	84 c0                	test   %al,%al
  103261:	75 d9                	jne    10323c <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  103263:	8b 45 08             	mov    0x8(%ebp),%eax
  103266:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  103269:	8b 55 08             	mov    0x8(%ebp),%edx
  10326c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10326f:	89 d1                	mov    %edx,%ecx
  103271:	29 c1                	sub    %eax,%ecx
  103273:	89 c8                	mov    %ecx,%eax
}
  103275:	c9                   	leave  
  103276:	c3                   	ret    

00103277 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  103277:	55                   	push   %ebp
  103278:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  10327a:	eb 08                	jmp    103284 <strcmp+0xd>
		p++, q++;
  10327c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  103280:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  103284:	8b 45 08             	mov    0x8(%ebp),%eax
  103287:	0f b6 00             	movzbl (%eax),%eax
  10328a:	84 c0                	test   %al,%al
  10328c:	74 10                	je     10329e <strcmp+0x27>
  10328e:	8b 45 08             	mov    0x8(%ebp),%eax
  103291:	0f b6 10             	movzbl (%eax),%edx
  103294:	8b 45 0c             	mov    0xc(%ebp),%eax
  103297:	0f b6 00             	movzbl (%eax),%eax
  10329a:	38 c2                	cmp    %al,%dl
  10329c:	74 de                	je     10327c <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  10329e:	8b 45 08             	mov    0x8(%ebp),%eax
  1032a1:	0f b6 00             	movzbl (%eax),%eax
  1032a4:	0f b6 d0             	movzbl %al,%edx
  1032a7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1032aa:	0f b6 00             	movzbl (%eax),%eax
  1032ad:	0f b6 c0             	movzbl %al,%eax
  1032b0:	89 d1                	mov    %edx,%ecx
  1032b2:	29 c1                	sub    %eax,%ecx
  1032b4:	89 c8                	mov    %ecx,%eax
}
  1032b6:	5d                   	pop    %ebp
  1032b7:	c3                   	ret    

001032b8 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  1032b8:	55                   	push   %ebp
  1032b9:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  1032bb:	eb 0c                	jmp    1032c9 <strncmp+0x11>
		n--, p++, q++;
  1032bd:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1032c1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1032c5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  1032c9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1032cd:	74 1a                	je     1032e9 <strncmp+0x31>
  1032cf:	8b 45 08             	mov    0x8(%ebp),%eax
  1032d2:	0f b6 00             	movzbl (%eax),%eax
  1032d5:	84 c0                	test   %al,%al
  1032d7:	74 10                	je     1032e9 <strncmp+0x31>
  1032d9:	8b 45 08             	mov    0x8(%ebp),%eax
  1032dc:	0f b6 10             	movzbl (%eax),%edx
  1032df:	8b 45 0c             	mov    0xc(%ebp),%eax
  1032e2:	0f b6 00             	movzbl (%eax),%eax
  1032e5:	38 c2                	cmp    %al,%dl
  1032e7:	74 d4                	je     1032bd <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  1032e9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1032ed:	75 07                	jne    1032f6 <strncmp+0x3e>
		return 0;
  1032ef:	b8 00 00 00 00       	mov    $0x0,%eax
  1032f4:	eb 18                	jmp    10330e <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  1032f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1032f9:	0f b6 00             	movzbl (%eax),%eax
  1032fc:	0f b6 d0             	movzbl %al,%edx
  1032ff:	8b 45 0c             	mov    0xc(%ebp),%eax
  103302:	0f b6 00             	movzbl (%eax),%eax
  103305:	0f b6 c0             	movzbl %al,%eax
  103308:	89 d1                	mov    %edx,%ecx
  10330a:	29 c1                	sub    %eax,%ecx
  10330c:	89 c8                	mov    %ecx,%eax
}
  10330e:	5d                   	pop    %ebp
  10330f:	c3                   	ret    

00103310 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  103310:	55                   	push   %ebp
  103311:	89 e5                	mov    %esp,%ebp
  103313:	83 ec 04             	sub    $0x4,%esp
  103316:	8b 45 0c             	mov    0xc(%ebp),%eax
  103319:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
  10331c:	eb 14                	jmp    103332 <strchr+0x22>
		if (*s == c)
  10331e:	8b 45 08             	mov    0x8(%ebp),%eax
  103321:	0f b6 00             	movzbl (%eax),%eax
  103324:	3a 45 fc             	cmp    -0x4(%ebp),%al
  103327:	75 05                	jne    10332e <strchr+0x1e>
			return (char *) s;
  103329:	8b 45 08             	mov    0x8(%ebp),%eax
  10332c:	eb 13                	jmp    103341 <strchr+0x31>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  10332e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  103332:	8b 45 08             	mov    0x8(%ebp),%eax
  103335:	0f b6 00             	movzbl (%eax),%eax
  103338:	84 c0                	test   %al,%al
  10333a:	75 e2                	jne    10331e <strchr+0xe>
		if (*s == c)
			return (char *) s;
	return 0;
  10333c:	b8 00 00 00 00       	mov    $0x0,%eax
}
  103341:	c9                   	leave  
  103342:	c3                   	ret    

00103343 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  103343:	55                   	push   %ebp
  103344:	89 e5                	mov    %esp,%ebp
  103346:	83 ec 04             	sub    $0x4,%esp
  103349:	8b 45 0c             	mov    0xc(%ebp),%eax
  10334c:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
  10334f:	eb 0f                	jmp    103360 <strfind+0x1d>
		if (*s == c)
  103351:	8b 45 08             	mov    0x8(%ebp),%eax
  103354:	0f b6 00             	movzbl (%eax),%eax
  103357:	3a 45 fc             	cmp    -0x4(%ebp),%al
  10335a:	74 10                	je     10336c <strfind+0x29>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  10335c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  103360:	8b 45 08             	mov    0x8(%ebp),%eax
  103363:	0f b6 00             	movzbl (%eax),%eax
  103366:	84 c0                	test   %al,%al
  103368:	75 e7                	jne    103351 <strfind+0xe>
  10336a:	eb 01                	jmp    10336d <strfind+0x2a>
		if (*s == c)
			break;
  10336c:	90                   	nop
	return (char *) s;
  10336d:	8b 45 08             	mov    0x8(%ebp),%eax
}
  103370:	c9                   	leave  
  103371:	c3                   	ret    

00103372 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  103372:	55                   	push   %ebp
  103373:	89 e5                	mov    %esp,%ebp
  103375:	57                   	push   %edi
  103376:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  103379:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10337d:	75 05                	jne    103384 <memset+0x12>
		return v;
  10337f:	8b 45 08             	mov    0x8(%ebp),%eax
  103382:	eb 5c                	jmp    1033e0 <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  103384:	8b 45 08             	mov    0x8(%ebp),%eax
  103387:	83 e0 03             	and    $0x3,%eax
  10338a:	85 c0                	test   %eax,%eax
  10338c:	75 41                	jne    1033cf <memset+0x5d>
  10338e:	8b 45 10             	mov    0x10(%ebp),%eax
  103391:	83 e0 03             	and    $0x3,%eax
  103394:	85 c0                	test   %eax,%eax
  103396:	75 37                	jne    1033cf <memset+0x5d>
		c &= 0xFF;
  103398:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  10339f:	8b 45 0c             	mov    0xc(%ebp),%eax
  1033a2:	89 c2                	mov    %eax,%edx
  1033a4:	c1 e2 18             	shl    $0x18,%edx
  1033a7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1033aa:	c1 e0 10             	shl    $0x10,%eax
  1033ad:	09 c2                	or     %eax,%edx
  1033af:	8b 45 0c             	mov    0xc(%ebp),%eax
  1033b2:	c1 e0 08             	shl    $0x8,%eax
  1033b5:	09 d0                	or     %edx,%eax
  1033b7:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  1033ba:	8b 45 10             	mov    0x10(%ebp),%eax
  1033bd:	89 c1                	mov    %eax,%ecx
  1033bf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  1033c2:	8b 55 08             	mov    0x8(%ebp),%edx
  1033c5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1033c8:	89 d7                	mov    %edx,%edi
  1033ca:	fc                   	cld    
  1033cb:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  1033cd:	eb 0e                	jmp    1033dd <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  1033cf:	8b 55 08             	mov    0x8(%ebp),%edx
  1033d2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1033d5:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1033d8:	89 d7                	mov    %edx,%edi
  1033da:	fc                   	cld    
  1033db:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  1033dd:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1033e0:	83 c4 10             	add    $0x10,%esp
  1033e3:	5f                   	pop    %edi
  1033e4:	5d                   	pop    %ebp
  1033e5:	c3                   	ret    

001033e6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  1033e6:	55                   	push   %ebp
  1033e7:	89 e5                	mov    %esp,%ebp
  1033e9:	57                   	push   %edi
  1033ea:	56                   	push   %esi
  1033eb:	53                   	push   %ebx
  1033ec:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  1033ef:	8b 45 0c             	mov    0xc(%ebp),%eax
  1033f2:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  1033f5:	8b 45 08             	mov    0x8(%ebp),%eax
  1033f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  1033fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1033fe:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  103401:	73 6e                	jae    103471 <memmove+0x8b>
  103403:	8b 45 10             	mov    0x10(%ebp),%eax
  103406:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103409:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10340c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10340f:	76 60                	jbe    103471 <memmove+0x8b>
		s += n;
  103411:	8b 45 10             	mov    0x10(%ebp),%eax
  103414:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  103417:	8b 45 10             	mov    0x10(%ebp),%eax
  10341a:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10341d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103420:	83 e0 03             	and    $0x3,%eax
  103423:	85 c0                	test   %eax,%eax
  103425:	75 2f                	jne    103456 <memmove+0x70>
  103427:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10342a:	83 e0 03             	and    $0x3,%eax
  10342d:	85 c0                	test   %eax,%eax
  10342f:	75 25                	jne    103456 <memmove+0x70>
  103431:	8b 45 10             	mov    0x10(%ebp),%eax
  103434:	83 e0 03             	and    $0x3,%eax
  103437:	85 c0                	test   %eax,%eax
  103439:	75 1b                	jne    103456 <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  10343b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10343e:	83 e8 04             	sub    $0x4,%eax
  103441:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103444:	83 ea 04             	sub    $0x4,%edx
  103447:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10344a:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  10344d:	89 c7                	mov    %eax,%edi
  10344f:	89 d6                	mov    %edx,%esi
  103451:	fd                   	std    
  103452:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  103454:	eb 18                	jmp    10346e <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  103456:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103459:	8d 50 ff             	lea    -0x1(%eax),%edx
  10345c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10345f:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  103462:	8b 45 10             	mov    0x10(%ebp),%eax
  103465:	89 d7                	mov    %edx,%edi
  103467:	89 de                	mov    %ebx,%esi
  103469:	89 c1                	mov    %eax,%ecx
  10346b:	fd                   	std    
  10346c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  10346e:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  10346f:	eb 45                	jmp    1034b6 <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  103471:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103474:	83 e0 03             	and    $0x3,%eax
  103477:	85 c0                	test   %eax,%eax
  103479:	75 2b                	jne    1034a6 <memmove+0xc0>
  10347b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10347e:	83 e0 03             	and    $0x3,%eax
  103481:	85 c0                	test   %eax,%eax
  103483:	75 21                	jne    1034a6 <memmove+0xc0>
  103485:	8b 45 10             	mov    0x10(%ebp),%eax
  103488:	83 e0 03             	and    $0x3,%eax
  10348b:	85 c0                	test   %eax,%eax
  10348d:	75 17                	jne    1034a6 <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  10348f:	8b 45 10             	mov    0x10(%ebp),%eax
  103492:	89 c1                	mov    %eax,%ecx
  103494:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  103497:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10349a:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10349d:	89 c7                	mov    %eax,%edi
  10349f:	89 d6                	mov    %edx,%esi
  1034a1:	fc                   	cld    
  1034a2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1034a4:	eb 10                	jmp    1034b6 <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  1034a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1034a9:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1034ac:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1034af:	89 c7                	mov    %eax,%edi
  1034b1:	89 d6                	mov    %edx,%esi
  1034b3:	fc                   	cld    
  1034b4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  1034b6:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1034b9:	83 c4 10             	add    $0x10,%esp
  1034bc:	5b                   	pop    %ebx
  1034bd:	5e                   	pop    %esi
  1034be:	5f                   	pop    %edi
  1034bf:	5d                   	pop    %ebp
  1034c0:	c3                   	ret    

001034c1 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  1034c1:	55                   	push   %ebp
  1034c2:	89 e5                	mov    %esp,%ebp
  1034c4:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  1034c7:	8b 45 10             	mov    0x10(%ebp),%eax
  1034ca:	89 44 24 08          	mov    %eax,0x8(%esp)
  1034ce:	8b 45 0c             	mov    0xc(%ebp),%eax
  1034d1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1034d5:	8b 45 08             	mov    0x8(%ebp),%eax
  1034d8:	89 04 24             	mov    %eax,(%esp)
  1034db:	e8 06 ff ff ff       	call   1033e6 <memmove>
}
  1034e0:	c9                   	leave  
  1034e1:	c3                   	ret    

001034e2 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  1034e2:	55                   	push   %ebp
  1034e3:	89 e5                	mov    %esp,%ebp
  1034e5:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  1034e8:	8b 45 08             	mov    0x8(%ebp),%eax
  1034eb:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  1034ee:	8b 45 0c             	mov    0xc(%ebp),%eax
  1034f1:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  1034f4:	eb 32                	jmp    103528 <memcmp+0x46>
		if (*s1 != *s2)
  1034f6:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1034f9:	0f b6 10             	movzbl (%eax),%edx
  1034fc:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1034ff:	0f b6 00             	movzbl (%eax),%eax
  103502:	38 c2                	cmp    %al,%dl
  103504:	74 1a                	je     103520 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  103506:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103509:	0f b6 00             	movzbl (%eax),%eax
  10350c:	0f b6 d0             	movzbl %al,%edx
  10350f:	8b 45 fc             	mov    -0x4(%ebp),%eax
  103512:	0f b6 00             	movzbl (%eax),%eax
  103515:	0f b6 c0             	movzbl %al,%eax
  103518:	89 d1                	mov    %edx,%ecx
  10351a:	29 c1                	sub    %eax,%ecx
  10351c:	89 c8                	mov    %ecx,%eax
  10351e:	eb 1c                	jmp    10353c <memcmp+0x5a>
		s1++, s2++;
  103520:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  103524:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  103528:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10352c:	0f 95 c0             	setne  %al
  10352f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  103533:	84 c0                	test   %al,%al
  103535:	75 bf                	jne    1034f6 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  103537:	b8 00 00 00 00       	mov    $0x0,%eax
}
  10353c:	c9                   	leave  
  10353d:	c3                   	ret    

0010353e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  10353e:	55                   	push   %ebp
  10353f:	89 e5                	mov    %esp,%ebp
  103541:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  103544:	8b 45 10             	mov    0x10(%ebp),%eax
  103547:	8b 55 08             	mov    0x8(%ebp),%edx
  10354a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10354d:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  103550:	eb 11                	jmp    103563 <memfind+0x25>
		if (*(const unsigned char *) s == (unsigned char) c)
  103552:	8b 45 08             	mov    0x8(%ebp),%eax
  103555:	0f b6 10             	movzbl (%eax),%edx
  103558:	8b 45 0c             	mov    0xc(%ebp),%eax
  10355b:	38 c2                	cmp    %al,%dl
  10355d:	74 0e                	je     10356d <memfind+0x2f>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  10355f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  103563:	8b 45 08             	mov    0x8(%ebp),%eax
  103566:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  103569:	72 e7                	jb     103552 <memfind+0x14>
  10356b:	eb 01                	jmp    10356e <memfind+0x30>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
  10356d:	90                   	nop
	return (void *) s;
  10356e:	8b 45 08             	mov    0x8(%ebp),%eax
}
  103571:	c9                   	leave  
  103572:	c3                   	ret    

00103573 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  103573:	55                   	push   %ebp
  103574:	89 e5                	mov    %esp,%ebp
  103576:	83 ec 10             	sub    $0x10,%esp
	int neg = 0;
  103579:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	long val = 0;
  103580:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  103587:	eb 04                	jmp    10358d <strtol+0x1a>
		s++;
  103589:	83 45 08 01          	addl   $0x1,0x8(%ebp)
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  10358d:	8b 45 08             	mov    0x8(%ebp),%eax
  103590:	0f b6 00             	movzbl (%eax),%eax
  103593:	3c 20                	cmp    $0x20,%al
  103595:	74 f2                	je     103589 <strtol+0x16>
  103597:	8b 45 08             	mov    0x8(%ebp),%eax
  10359a:	0f b6 00             	movzbl (%eax),%eax
  10359d:	3c 09                	cmp    $0x9,%al
  10359f:	74 e8                	je     103589 <strtol+0x16>
		s++;

	// plus/minus sign
	if (*s == '+')
  1035a1:	8b 45 08             	mov    0x8(%ebp),%eax
  1035a4:	0f b6 00             	movzbl (%eax),%eax
  1035a7:	3c 2b                	cmp    $0x2b,%al
  1035a9:	75 06                	jne    1035b1 <strtol+0x3e>
		s++;
  1035ab:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1035af:	eb 15                	jmp    1035c6 <strtol+0x53>
	else if (*s == '-')
  1035b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1035b4:	0f b6 00             	movzbl (%eax),%eax
  1035b7:	3c 2d                	cmp    $0x2d,%al
  1035b9:	75 0b                	jne    1035c6 <strtol+0x53>
		s++, neg = 1;
  1035bb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1035bf:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  1035c6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1035ca:	74 06                	je     1035d2 <strtol+0x5f>
  1035cc:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
  1035d0:	75 24                	jne    1035f6 <strtol+0x83>
  1035d2:	8b 45 08             	mov    0x8(%ebp),%eax
  1035d5:	0f b6 00             	movzbl (%eax),%eax
  1035d8:	3c 30                	cmp    $0x30,%al
  1035da:	75 1a                	jne    1035f6 <strtol+0x83>
  1035dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1035df:	83 c0 01             	add    $0x1,%eax
  1035e2:	0f b6 00             	movzbl (%eax),%eax
  1035e5:	3c 78                	cmp    $0x78,%al
  1035e7:	75 0d                	jne    1035f6 <strtol+0x83>
		s += 2, base = 16;
  1035e9:	83 45 08 02          	addl   $0x2,0x8(%ebp)
  1035ed:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  1035f4:	eb 2a                	jmp    103620 <strtol+0xad>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  1035f6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1035fa:	75 17                	jne    103613 <strtol+0xa0>
  1035fc:	8b 45 08             	mov    0x8(%ebp),%eax
  1035ff:	0f b6 00             	movzbl (%eax),%eax
  103602:	3c 30                	cmp    $0x30,%al
  103604:	75 0d                	jne    103613 <strtol+0xa0>
		s++, base = 8;
  103606:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10360a:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  103611:	eb 0d                	jmp    103620 <strtol+0xad>
		s++, base = 8;
	else if (base == 0)
  103613:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  103617:	75 07                	jne    103620 <strtol+0xad>
		base = 10;
  103619:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  103620:	8b 45 08             	mov    0x8(%ebp),%eax
  103623:	0f b6 00             	movzbl (%eax),%eax
  103626:	3c 2f                	cmp    $0x2f,%al
  103628:	7e 1b                	jle    103645 <strtol+0xd2>
  10362a:	8b 45 08             	mov    0x8(%ebp),%eax
  10362d:	0f b6 00             	movzbl (%eax),%eax
  103630:	3c 39                	cmp    $0x39,%al
  103632:	7f 11                	jg     103645 <strtol+0xd2>
			dig = *s - '0';
  103634:	8b 45 08             	mov    0x8(%ebp),%eax
  103637:	0f b6 00             	movzbl (%eax),%eax
  10363a:	0f be c0             	movsbl %al,%eax
  10363d:	83 e8 30             	sub    $0x30,%eax
  103640:	89 45 fc             	mov    %eax,-0x4(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  103643:	eb 48                	jmp    10368d <strtol+0x11a>
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
  103645:	8b 45 08             	mov    0x8(%ebp),%eax
  103648:	0f b6 00             	movzbl (%eax),%eax
  10364b:	3c 60                	cmp    $0x60,%al
  10364d:	7e 1b                	jle    10366a <strtol+0xf7>
  10364f:	8b 45 08             	mov    0x8(%ebp),%eax
  103652:	0f b6 00             	movzbl (%eax),%eax
  103655:	3c 7a                	cmp    $0x7a,%al
  103657:	7f 11                	jg     10366a <strtol+0xf7>
			dig = *s - 'a' + 10;
  103659:	8b 45 08             	mov    0x8(%ebp),%eax
  10365c:	0f b6 00             	movzbl (%eax),%eax
  10365f:	0f be c0             	movsbl %al,%eax
  103662:	83 e8 57             	sub    $0x57,%eax
  103665:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
  103668:	eb 23                	jmp    10368d <strtol+0x11a>
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  10366a:	8b 45 08             	mov    0x8(%ebp),%eax
  10366d:	0f b6 00             	movzbl (%eax),%eax
  103670:	3c 40                	cmp    $0x40,%al
  103672:	7e 38                	jle    1036ac <strtol+0x139>
  103674:	8b 45 08             	mov    0x8(%ebp),%eax
  103677:	0f b6 00             	movzbl (%eax),%eax
  10367a:	3c 5a                	cmp    $0x5a,%al
  10367c:	7f 2e                	jg     1036ac <strtol+0x139>
			dig = *s - 'A' + 10;
  10367e:	8b 45 08             	mov    0x8(%ebp),%eax
  103681:	0f b6 00             	movzbl (%eax),%eax
  103684:	0f be c0             	movsbl %al,%eax
  103687:	83 e8 37             	sub    $0x37,%eax
  10368a:	89 45 fc             	mov    %eax,-0x4(%ebp)
		else
			break;
		if (dig >= base)
  10368d:	8b 45 fc             	mov    -0x4(%ebp),%eax
  103690:	3b 45 10             	cmp    0x10(%ebp),%eax
  103693:	7d 16                	jge    1036ab <strtol+0x138>
			break;
		s++, val = (val * base) + dig;
  103695:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  103699:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10369c:	0f af 45 10          	imul   0x10(%ebp),%eax
  1036a0:	03 45 fc             	add    -0x4(%ebp),%eax
  1036a3:	89 45 f8             	mov    %eax,-0x8(%ebp)
		// we don't properly detect overflow!
	}
  1036a6:	e9 75 ff ff ff       	jmp    103620 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
			break;
  1036ab:	90                   	nop
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  1036ac:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  1036b0:	74 08                	je     1036ba <strtol+0x147>
		*endptr = (char *) s;
  1036b2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1036b5:	8b 55 08             	mov    0x8(%ebp),%edx
  1036b8:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
  1036ba:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1036be:	74 07                	je     1036c7 <strtol+0x154>
  1036c0:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1036c3:	f7 d8                	neg    %eax
  1036c5:	eb 03                	jmp    1036ca <strtol+0x157>
  1036c7:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  1036ca:	c9                   	leave  
  1036cb:	c3                   	ret    
  1036cc:	90                   	nop
  1036cd:	90                   	nop
  1036ce:	90                   	nop
  1036cf:	90                   	nop

001036d0 <__udivdi3>:
  1036d0:	55                   	push   %ebp
  1036d1:	89 e5                	mov    %esp,%ebp
  1036d3:	57                   	push   %edi
  1036d4:	56                   	push   %esi
  1036d5:	83 ec 10             	sub    $0x10,%esp
  1036d8:	8b 45 14             	mov    0x14(%ebp),%eax
  1036db:	8b 55 08             	mov    0x8(%ebp),%edx
  1036de:	8b 75 10             	mov    0x10(%ebp),%esi
  1036e1:	8b 7d 0c             	mov    0xc(%ebp),%edi
  1036e4:	85 c0                	test   %eax,%eax
  1036e6:	89 55 f0             	mov    %edx,-0x10(%ebp)
  1036e9:	75 35                	jne    103720 <__udivdi3+0x50>
  1036eb:	39 fe                	cmp    %edi,%esi
  1036ed:	77 61                	ja     103750 <__udivdi3+0x80>
  1036ef:	85 f6                	test   %esi,%esi
  1036f1:	75 0b                	jne    1036fe <__udivdi3+0x2e>
  1036f3:	b8 01 00 00 00       	mov    $0x1,%eax
  1036f8:	31 d2                	xor    %edx,%edx
  1036fa:	f7 f6                	div    %esi
  1036fc:	89 c6                	mov    %eax,%esi
  1036fe:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  103701:	31 d2                	xor    %edx,%edx
  103703:	89 f8                	mov    %edi,%eax
  103705:	f7 f6                	div    %esi
  103707:	89 c7                	mov    %eax,%edi
  103709:	89 c8                	mov    %ecx,%eax
  10370b:	f7 f6                	div    %esi
  10370d:	89 c1                	mov    %eax,%ecx
  10370f:	89 fa                	mov    %edi,%edx
  103711:	89 c8                	mov    %ecx,%eax
  103713:	83 c4 10             	add    $0x10,%esp
  103716:	5e                   	pop    %esi
  103717:	5f                   	pop    %edi
  103718:	5d                   	pop    %ebp
  103719:	c3                   	ret    
  10371a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  103720:	39 f8                	cmp    %edi,%eax
  103722:	77 1c                	ja     103740 <__udivdi3+0x70>
  103724:	0f bd d0             	bsr    %eax,%edx
  103727:	83 f2 1f             	xor    $0x1f,%edx
  10372a:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10372d:	75 39                	jne    103768 <__udivdi3+0x98>
  10372f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  103732:	0f 86 a0 00 00 00    	jbe    1037d8 <__udivdi3+0x108>
  103738:	39 f8                	cmp    %edi,%eax
  10373a:	0f 82 98 00 00 00    	jb     1037d8 <__udivdi3+0x108>
  103740:	31 ff                	xor    %edi,%edi
  103742:	31 c9                	xor    %ecx,%ecx
  103744:	89 c8                	mov    %ecx,%eax
  103746:	89 fa                	mov    %edi,%edx
  103748:	83 c4 10             	add    $0x10,%esp
  10374b:	5e                   	pop    %esi
  10374c:	5f                   	pop    %edi
  10374d:	5d                   	pop    %ebp
  10374e:	c3                   	ret    
  10374f:	90                   	nop
  103750:	89 d1                	mov    %edx,%ecx
  103752:	89 fa                	mov    %edi,%edx
  103754:	89 c8                	mov    %ecx,%eax
  103756:	31 ff                	xor    %edi,%edi
  103758:	f7 f6                	div    %esi
  10375a:	89 c1                	mov    %eax,%ecx
  10375c:	89 fa                	mov    %edi,%edx
  10375e:	89 c8                	mov    %ecx,%eax
  103760:	83 c4 10             	add    $0x10,%esp
  103763:	5e                   	pop    %esi
  103764:	5f                   	pop    %edi
  103765:	5d                   	pop    %ebp
  103766:	c3                   	ret    
  103767:	90                   	nop
  103768:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  10376c:	89 f2                	mov    %esi,%edx
  10376e:	d3 e0                	shl    %cl,%eax
  103770:	89 45 ec             	mov    %eax,-0x14(%ebp)
  103773:	b8 20 00 00 00       	mov    $0x20,%eax
  103778:	2b 45 f4             	sub    -0xc(%ebp),%eax
  10377b:	89 c1                	mov    %eax,%ecx
  10377d:	d3 ea                	shr    %cl,%edx
  10377f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  103783:	0b 55 ec             	or     -0x14(%ebp),%edx
  103786:	d3 e6                	shl    %cl,%esi
  103788:	89 c1                	mov    %eax,%ecx
  10378a:	89 75 e8             	mov    %esi,-0x18(%ebp)
  10378d:	89 fe                	mov    %edi,%esi
  10378f:	d3 ee                	shr    %cl,%esi
  103791:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  103795:	89 55 ec             	mov    %edx,-0x14(%ebp)
  103798:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10379b:	d3 e7                	shl    %cl,%edi
  10379d:	89 c1                	mov    %eax,%ecx
  10379f:	d3 ea                	shr    %cl,%edx
  1037a1:	09 d7                	or     %edx,%edi
  1037a3:	89 f2                	mov    %esi,%edx
  1037a5:	89 f8                	mov    %edi,%eax
  1037a7:	f7 75 ec             	divl   -0x14(%ebp)
  1037aa:	89 d6                	mov    %edx,%esi
  1037ac:	89 c7                	mov    %eax,%edi
  1037ae:	f7 65 e8             	mull   -0x18(%ebp)
  1037b1:	39 d6                	cmp    %edx,%esi
  1037b3:	89 55 ec             	mov    %edx,-0x14(%ebp)
  1037b6:	72 30                	jb     1037e8 <__udivdi3+0x118>
  1037b8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1037bb:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  1037bf:	d3 e2                	shl    %cl,%edx
  1037c1:	39 c2                	cmp    %eax,%edx
  1037c3:	73 05                	jae    1037ca <__udivdi3+0xfa>
  1037c5:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  1037c8:	74 1e                	je     1037e8 <__udivdi3+0x118>
  1037ca:	89 f9                	mov    %edi,%ecx
  1037cc:	31 ff                	xor    %edi,%edi
  1037ce:	e9 71 ff ff ff       	jmp    103744 <__udivdi3+0x74>
  1037d3:	90                   	nop
  1037d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1037d8:	31 ff                	xor    %edi,%edi
  1037da:	b9 01 00 00 00       	mov    $0x1,%ecx
  1037df:	e9 60 ff ff ff       	jmp    103744 <__udivdi3+0x74>
  1037e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1037e8:	8d 4f ff             	lea    -0x1(%edi),%ecx
  1037eb:	31 ff                	xor    %edi,%edi
  1037ed:	89 c8                	mov    %ecx,%eax
  1037ef:	89 fa                	mov    %edi,%edx
  1037f1:	83 c4 10             	add    $0x10,%esp
  1037f4:	5e                   	pop    %esi
  1037f5:	5f                   	pop    %edi
  1037f6:	5d                   	pop    %ebp
  1037f7:	c3                   	ret    
  1037f8:	90                   	nop
  1037f9:	90                   	nop
  1037fa:	90                   	nop
  1037fb:	90                   	nop
  1037fc:	90                   	nop
  1037fd:	90                   	nop
  1037fe:	90                   	nop
  1037ff:	90                   	nop

00103800 <__umoddi3>:
  103800:	55                   	push   %ebp
  103801:	89 e5                	mov    %esp,%ebp
  103803:	57                   	push   %edi
  103804:	56                   	push   %esi
  103805:	83 ec 20             	sub    $0x20,%esp
  103808:	8b 55 14             	mov    0x14(%ebp),%edx
  10380b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10380e:	8b 7d 10             	mov    0x10(%ebp),%edi
  103811:	8b 75 0c             	mov    0xc(%ebp),%esi
  103814:	85 d2                	test   %edx,%edx
  103816:	89 c8                	mov    %ecx,%eax
  103818:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  10381b:	75 13                	jne    103830 <__umoddi3+0x30>
  10381d:	39 f7                	cmp    %esi,%edi
  10381f:	76 3f                	jbe    103860 <__umoddi3+0x60>
  103821:	89 f2                	mov    %esi,%edx
  103823:	f7 f7                	div    %edi
  103825:	89 d0                	mov    %edx,%eax
  103827:	31 d2                	xor    %edx,%edx
  103829:	83 c4 20             	add    $0x20,%esp
  10382c:	5e                   	pop    %esi
  10382d:	5f                   	pop    %edi
  10382e:	5d                   	pop    %ebp
  10382f:	c3                   	ret    
  103830:	39 f2                	cmp    %esi,%edx
  103832:	77 4c                	ja     103880 <__umoddi3+0x80>
  103834:	0f bd ca             	bsr    %edx,%ecx
  103837:	83 f1 1f             	xor    $0x1f,%ecx
  10383a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  10383d:	75 51                	jne    103890 <__umoddi3+0x90>
  10383f:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  103842:	0f 87 e0 00 00 00    	ja     103928 <__umoddi3+0x128>
  103848:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10384b:	29 f8                	sub    %edi,%eax
  10384d:	19 d6                	sbb    %edx,%esi
  10384f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  103852:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103855:	89 f2                	mov    %esi,%edx
  103857:	83 c4 20             	add    $0x20,%esp
  10385a:	5e                   	pop    %esi
  10385b:	5f                   	pop    %edi
  10385c:	5d                   	pop    %ebp
  10385d:	c3                   	ret    
  10385e:	66 90                	xchg   %ax,%ax
  103860:	85 ff                	test   %edi,%edi
  103862:	75 0b                	jne    10386f <__umoddi3+0x6f>
  103864:	b8 01 00 00 00       	mov    $0x1,%eax
  103869:	31 d2                	xor    %edx,%edx
  10386b:	f7 f7                	div    %edi
  10386d:	89 c7                	mov    %eax,%edi
  10386f:	89 f0                	mov    %esi,%eax
  103871:	31 d2                	xor    %edx,%edx
  103873:	f7 f7                	div    %edi
  103875:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103878:	f7 f7                	div    %edi
  10387a:	eb a9                	jmp    103825 <__umoddi3+0x25>
  10387c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103880:	89 c8                	mov    %ecx,%eax
  103882:	89 f2                	mov    %esi,%edx
  103884:	83 c4 20             	add    $0x20,%esp
  103887:	5e                   	pop    %esi
  103888:	5f                   	pop    %edi
  103889:	5d                   	pop    %ebp
  10388a:	c3                   	ret    
  10388b:	90                   	nop
  10388c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103890:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  103894:	d3 e2                	shl    %cl,%edx
  103896:	89 55 f4             	mov    %edx,-0xc(%ebp)
  103899:	ba 20 00 00 00       	mov    $0x20,%edx
  10389e:	2b 55 f0             	sub    -0x10(%ebp),%edx
  1038a1:	89 55 ec             	mov    %edx,-0x14(%ebp)
  1038a4:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  1038a8:	89 fa                	mov    %edi,%edx
  1038aa:	d3 ea                	shr    %cl,%edx
  1038ac:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1038b0:	0b 55 f4             	or     -0xc(%ebp),%edx
  1038b3:	d3 e7                	shl    %cl,%edi
  1038b5:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  1038b9:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1038bc:	89 f2                	mov    %esi,%edx
  1038be:	89 7d e8             	mov    %edi,-0x18(%ebp)
  1038c1:	89 c7                	mov    %eax,%edi
  1038c3:	d3 ea                	shr    %cl,%edx
  1038c5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1038c9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  1038cc:	89 c2                	mov    %eax,%edx
  1038ce:	d3 e6                	shl    %cl,%esi
  1038d0:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  1038d4:	d3 ea                	shr    %cl,%edx
  1038d6:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1038da:	09 d6                	or     %edx,%esi
  1038dc:	89 f0                	mov    %esi,%eax
  1038de:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  1038e1:	d3 e7                	shl    %cl,%edi
  1038e3:	89 f2                	mov    %esi,%edx
  1038e5:	f7 75 f4             	divl   -0xc(%ebp)
  1038e8:	89 d6                	mov    %edx,%esi
  1038ea:	f7 65 e8             	mull   -0x18(%ebp)
  1038ed:	39 d6                	cmp    %edx,%esi
  1038ef:	72 2b                	jb     10391c <__umoddi3+0x11c>
  1038f1:	39 c7                	cmp    %eax,%edi
  1038f3:	72 23                	jb     103918 <__umoddi3+0x118>
  1038f5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1038f9:	29 c7                	sub    %eax,%edi
  1038fb:	19 d6                	sbb    %edx,%esi
  1038fd:	89 f0                	mov    %esi,%eax
  1038ff:	89 f2                	mov    %esi,%edx
  103901:	d3 ef                	shr    %cl,%edi
  103903:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  103907:	d3 e0                	shl    %cl,%eax
  103909:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  10390d:	09 f8                	or     %edi,%eax
  10390f:	d3 ea                	shr    %cl,%edx
  103911:	83 c4 20             	add    $0x20,%esp
  103914:	5e                   	pop    %esi
  103915:	5f                   	pop    %edi
  103916:	5d                   	pop    %ebp
  103917:	c3                   	ret    
  103918:	39 d6                	cmp    %edx,%esi
  10391a:	75 d9                	jne    1038f5 <__umoddi3+0xf5>
  10391c:	2b 45 e8             	sub    -0x18(%ebp),%eax
  10391f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  103922:	eb d1                	jmp    1038f5 <__umoddi3+0xf5>
  103924:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  103928:	39 f2                	cmp    %esi,%edx
  10392a:	0f 82 18 ff ff ff    	jb     103848 <__umoddi3+0x48>
  103930:	e9 1d ff ff ff       	jmp    103852 <__umoddi3+0x52>
