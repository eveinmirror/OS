
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49260613          	addi	a2,a2,1170 # ffffffffc020d4e4 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	5b1030ef          	jal	ra,ffffffffc0203e12 <memset>
    dtb_init();
ffffffffc0200066:	4fa000ef          	jal	ra,ffffffffc0200560 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	484000ef          	jal	ra,ffffffffc02004ee <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	df258593          	addi	a1,a1,-526 # ffffffffc0203e60 <etext>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	e0a50513          	addi	a0,a0,-502 # ffffffffc0203e80 <etext+0x20>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	15a000ef          	jal	ra,ffffffffc02001dc <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	05c020ef          	jal	ra,ffffffffc02020e2 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	093000ef          	jal	ra,ffffffffc020091c <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	091000ef          	jal	ra,ffffffffc020091e <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	5c5020ef          	jal	ra,ffffffffc0202e56 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	53c030ef          	jal	ra,ffffffffc02035d2 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	41c000ef          	jal	ra,ffffffffc02004b6 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	073000ef          	jal	ra,ffffffffc0200910 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	77e030ef          	jal	ra,ffffffffc0203820 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00004517          	auipc	a0,0x4
ffffffffc02000c0:	dcc50513          	addi	a0,a0,-564 # ffffffffc0203e88 <etext+0x28>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	00009b97          	auipc	s7,0x9
ffffffffc02000d6:	f5eb8b93          	addi	s7,s7,-162 # ffffffffc0209030 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	0ee000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	0de000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	0cc000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	00009517          	auipc	a0,0x9
ffffffffc0200132:	f0250513          	addi	a0,a0,-254 # ffffffffc0209030 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	38e000ef          	jal	ra,ffffffffc02004f0 <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	067030ef          	jal	ra,ffffffffc02039ee <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc0208028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	031030ef          	jal	ra,ffffffffc02039ee <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a61d                	j	ffffffffc02004f0 <cons_putc>

ffffffffc02001cc <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc02001cc:	1141                	addi	sp,sp,-16
ffffffffc02001ce:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001d0:	354000ef          	jal	ra,ffffffffc0200524 <cons_getc>
ffffffffc02001d4:	dd75                	beqz	a0,ffffffffc02001d0 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d6:	60a2                	ld	ra,8(sp)
ffffffffc02001d8:	0141                	addi	sp,sp,16
ffffffffc02001da:	8082                	ret

ffffffffc02001dc <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02001dc:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001de:	00004517          	auipc	a0,0x4
ffffffffc02001e2:	cb250513          	addi	a0,a0,-846 # ffffffffc0203e90 <etext+0x30>
{
ffffffffc02001e6:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e8:	fadff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001ec:	00000597          	auipc	a1,0x0
ffffffffc02001f0:	e5e58593          	addi	a1,a1,-418 # ffffffffc020004a <kern_init>
ffffffffc02001f4:	00004517          	auipc	a0,0x4
ffffffffc02001f8:	cbc50513          	addi	a0,a0,-836 # ffffffffc0203eb0 <etext+0x50>
ffffffffc02001fc:	f99ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200200:	00004597          	auipc	a1,0x4
ffffffffc0200204:	c6058593          	addi	a1,a1,-928 # ffffffffc0203e60 <etext>
ffffffffc0200208:	00004517          	auipc	a0,0x4
ffffffffc020020c:	cc850513          	addi	a0,a0,-824 # ffffffffc0203ed0 <etext+0x70>
ffffffffc0200210:	f85ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200214:	00009597          	auipc	a1,0x9
ffffffffc0200218:	e1c58593          	addi	a1,a1,-484 # ffffffffc0209030 <buf>
ffffffffc020021c:	00004517          	auipc	a0,0x4
ffffffffc0200220:	cd450513          	addi	a0,a0,-812 # ffffffffc0203ef0 <etext+0x90>
ffffffffc0200224:	f71ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200228:	0000d597          	auipc	a1,0xd
ffffffffc020022c:	2bc58593          	addi	a1,a1,700 # ffffffffc020d4e4 <end>
ffffffffc0200230:	00004517          	auipc	a0,0x4
ffffffffc0200234:	ce050513          	addi	a0,a0,-800 # ffffffffc0203f10 <etext+0xb0>
ffffffffc0200238:	f5dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023c:	0000d597          	auipc	a1,0xd
ffffffffc0200240:	6a758593          	addi	a1,a1,1703 # ffffffffc020d8e3 <end+0x3ff>
ffffffffc0200244:	00000797          	auipc	a5,0x0
ffffffffc0200248:	e0678793          	addi	a5,a5,-506 # ffffffffc020004a <kern_init>
ffffffffc020024c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200250:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200254:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200256:	3ff5f593          	andi	a1,a1,1023
ffffffffc020025a:	95be                	add	a1,a1,a5
ffffffffc020025c:	85a9                	srai	a1,a1,0xa
ffffffffc020025e:	00004517          	auipc	a0,0x4
ffffffffc0200262:	cd250513          	addi	a0,a0,-814 # ffffffffc0203f30 <etext+0xd0>
}
ffffffffc0200266:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200268:	b735                	j	ffffffffc0200194 <cprintf>

ffffffffc020026a <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc020026a:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020026c:	00004617          	auipc	a2,0x4
ffffffffc0200270:	cf460613          	addi	a2,a2,-780 # ffffffffc0203f60 <etext+0x100>
ffffffffc0200274:	04900593          	li	a1,73
ffffffffc0200278:	00004517          	auipc	a0,0x4
ffffffffc020027c:	d0050513          	addi	a0,a0,-768 # ffffffffc0203f78 <etext+0x118>
{
ffffffffc0200280:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200282:	1d8000ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0200286 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200286:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200288:	00004617          	auipc	a2,0x4
ffffffffc020028c:	d0860613          	addi	a2,a2,-760 # ffffffffc0203f90 <etext+0x130>
ffffffffc0200290:	00004597          	auipc	a1,0x4
ffffffffc0200294:	d2058593          	addi	a1,a1,-736 # ffffffffc0203fb0 <etext+0x150>
ffffffffc0200298:	00004517          	auipc	a0,0x4
ffffffffc020029c:	d2050513          	addi	a0,a0,-736 # ffffffffc0203fb8 <etext+0x158>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002a0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a2:	ef3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002a6:	00004617          	auipc	a2,0x4
ffffffffc02002aa:	d2260613          	addi	a2,a2,-734 # ffffffffc0203fc8 <etext+0x168>
ffffffffc02002ae:	00004597          	auipc	a1,0x4
ffffffffc02002b2:	d4258593          	addi	a1,a1,-702 # ffffffffc0203ff0 <etext+0x190>
ffffffffc02002b6:	00004517          	auipc	a0,0x4
ffffffffc02002ba:	d0250513          	addi	a0,a0,-766 # ffffffffc0203fb8 <etext+0x158>
ffffffffc02002be:	ed7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002c2:	00004617          	auipc	a2,0x4
ffffffffc02002c6:	d3e60613          	addi	a2,a2,-706 # ffffffffc0204000 <etext+0x1a0>
ffffffffc02002ca:	00004597          	auipc	a1,0x4
ffffffffc02002ce:	d5658593          	addi	a1,a1,-682 # ffffffffc0204020 <etext+0x1c0>
ffffffffc02002d2:	00004517          	auipc	a0,0x4
ffffffffc02002d6:	ce650513          	addi	a0,a0,-794 # ffffffffc0203fb8 <etext+0x158>
ffffffffc02002da:	ebbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc02002de:	60a2                	ld	ra,8(sp)
ffffffffc02002e0:	4501                	li	a0,0
ffffffffc02002e2:	0141                	addi	sp,sp,16
ffffffffc02002e4:	8082                	ret

ffffffffc02002e6 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e6:	1141                	addi	sp,sp,-16
ffffffffc02002e8:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002ea:	ef3ff0ef          	jal	ra,ffffffffc02001dc <print_kerninfo>
    return 0;
}
ffffffffc02002ee:	60a2                	ld	ra,8(sp)
ffffffffc02002f0:	4501                	li	a0,0
ffffffffc02002f2:	0141                	addi	sp,sp,16
ffffffffc02002f4:	8082                	ret

ffffffffc02002f6 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002f6:	1141                	addi	sp,sp,-16
ffffffffc02002f8:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002fa:	f71ff0ef          	jal	ra,ffffffffc020026a <print_stackframe>
    return 0;
}
ffffffffc02002fe:	60a2                	ld	ra,8(sp)
ffffffffc0200300:	4501                	li	a0,0
ffffffffc0200302:	0141                	addi	sp,sp,16
ffffffffc0200304:	8082                	ret

ffffffffc0200306 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200306:	7115                	addi	sp,sp,-224
ffffffffc0200308:	ed5e                	sd	s7,152(sp)
ffffffffc020030a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020030c:	00004517          	auipc	a0,0x4
ffffffffc0200310:	d2450513          	addi	a0,a0,-732 # ffffffffc0204030 <etext+0x1d0>
kmonitor(struct trapframe *tf) {
ffffffffc0200314:	ed86                	sd	ra,216(sp)
ffffffffc0200316:	e9a2                	sd	s0,208(sp)
ffffffffc0200318:	e5a6                	sd	s1,200(sp)
ffffffffc020031a:	e1ca                	sd	s2,192(sp)
ffffffffc020031c:	fd4e                	sd	s3,184(sp)
ffffffffc020031e:	f952                	sd	s4,176(sp)
ffffffffc0200320:	f556                	sd	s5,168(sp)
ffffffffc0200322:	f15a                	sd	s6,160(sp)
ffffffffc0200324:	e962                	sd	s8,144(sp)
ffffffffc0200326:	e566                	sd	s9,136(sp)
ffffffffc0200328:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032a:	e6bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020032e:	00004517          	auipc	a0,0x4
ffffffffc0200332:	d2a50513          	addi	a0,a0,-726 # ffffffffc0204058 <etext+0x1f8>
ffffffffc0200336:	e5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL) {
ffffffffc020033a:	000b8563          	beqz	s7,ffffffffc0200344 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020033e:	855e                	mv	a0,s7
ffffffffc0200340:	7c6000ef          	jal	ra,ffffffffc0200b06 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200344:	4501                	li	a0,0
ffffffffc0200346:	4581                	li	a1,0
ffffffffc0200348:	4601                	li	a2,0
ffffffffc020034a:	48a1                	li	a7,8
ffffffffc020034c:	00000073          	ecall
ffffffffc0200350:	00004c17          	auipc	s8,0x4
ffffffffc0200354:	d78c0c13          	addi	s8,s8,-648 # ffffffffc02040c8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200358:	00004917          	auipc	s2,0x4
ffffffffc020035c:	d2890913          	addi	s2,s2,-728 # ffffffffc0204080 <etext+0x220>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200360:	00004497          	auipc	s1,0x4
ffffffffc0200364:	d2848493          	addi	s1,s1,-728 # ffffffffc0204088 <etext+0x228>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020036a:	00004b17          	auipc	s6,0x4
ffffffffc020036e:	d26b0b13          	addi	s6,s6,-730 # ffffffffc0204090 <etext+0x230>
        argv[argc ++] = buf;
ffffffffc0200372:	00004a17          	auipc	s4,0x4
ffffffffc0200376:	c3ea0a13          	addi	s4,s4,-962 # ffffffffc0203fb0 <etext+0x150>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020037a:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020037c:	854a                	mv	a0,s2
ffffffffc020037e:	d29ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc0200382:	842a                	mv	s0,a0
ffffffffc0200384:	dd65                	beqz	a0,ffffffffc020037c <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200386:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020038a:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038c:	e1bd                	bnez	a1,ffffffffc02003f2 <kmonitor+0xec>
    if (argc == 0) {
ffffffffc020038e:	fe0c87e3          	beqz	s9,ffffffffc020037c <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200392:	6582                	ld	a1,0(sp)
ffffffffc0200394:	00004d17          	auipc	s10,0x4
ffffffffc0200398:	d34d0d13          	addi	s10,s10,-716 # ffffffffc02040c8 <commands>
        argv[argc ++] = buf;
ffffffffc020039c:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039e:	4401                	li	s0,0
ffffffffc02003a0:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003a2:	217030ef          	jal	ra,ffffffffc0203db8 <strcmp>
ffffffffc02003a6:	c919                	beqz	a0,ffffffffc02003bc <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003a8:	2405                	addiw	s0,s0,1
ffffffffc02003aa:	0b540063          	beq	s0,s5,ffffffffc020044a <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ae:	000d3503          	ld	a0,0(s10)
ffffffffc02003b2:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003b6:	203030ef          	jal	ra,ffffffffc0203db8 <strcmp>
ffffffffc02003ba:	f57d                	bnez	a0,ffffffffc02003a8 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003bc:	00141793          	slli	a5,s0,0x1
ffffffffc02003c0:	97a2                	add	a5,a5,s0
ffffffffc02003c2:	078e                	slli	a5,a5,0x3
ffffffffc02003c4:	97e2                	add	a5,a5,s8
ffffffffc02003c6:	6b9c                	ld	a5,16(a5)
ffffffffc02003c8:	865e                	mv	a2,s7
ffffffffc02003ca:	002c                	addi	a1,sp,8
ffffffffc02003cc:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003d0:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003d2:	fa0555e3          	bgez	a0,ffffffffc020037c <kmonitor+0x76>
}
ffffffffc02003d6:	60ee                	ld	ra,216(sp)
ffffffffc02003d8:	644e                	ld	s0,208(sp)
ffffffffc02003da:	64ae                	ld	s1,200(sp)
ffffffffc02003dc:	690e                	ld	s2,192(sp)
ffffffffc02003de:	79ea                	ld	s3,184(sp)
ffffffffc02003e0:	7a4a                	ld	s4,176(sp)
ffffffffc02003e2:	7aaa                	ld	s5,168(sp)
ffffffffc02003e4:	7b0a                	ld	s6,160(sp)
ffffffffc02003e6:	6bea                	ld	s7,152(sp)
ffffffffc02003e8:	6c4a                	ld	s8,144(sp)
ffffffffc02003ea:	6caa                	ld	s9,136(sp)
ffffffffc02003ec:	6d0a                	ld	s10,128(sp)
ffffffffc02003ee:	612d                	addi	sp,sp,224
ffffffffc02003f0:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003f2:	8526                	mv	a0,s1
ffffffffc02003f4:	209030ef          	jal	ra,ffffffffc0203dfc <strchr>
ffffffffc02003f8:	c901                	beqz	a0,ffffffffc0200408 <kmonitor+0x102>
ffffffffc02003fa:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003fe:	00040023          	sb	zero,0(s0)
ffffffffc0200402:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200404:	d5c9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200406:	b7f5                	j	ffffffffc02003f2 <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200408:	00044783          	lbu	a5,0(s0)
ffffffffc020040c:	d3c9                	beqz	a5,ffffffffc020038e <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc020040e:	033c8963          	beq	s9,s3,ffffffffc0200440 <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc0200412:	003c9793          	slli	a5,s9,0x3
ffffffffc0200416:	0118                	addi	a4,sp,128
ffffffffc0200418:	97ba                	add	a5,a5,a4
ffffffffc020041a:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020041e:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200422:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200424:	e591                	bnez	a1,ffffffffc0200430 <kmonitor+0x12a>
ffffffffc0200426:	b7b5                	j	ffffffffc0200392 <kmonitor+0x8c>
ffffffffc0200428:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020042c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020042e:	d1a5                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200430:	8526                	mv	a0,s1
ffffffffc0200432:	1cb030ef          	jal	ra,ffffffffc0203dfc <strchr>
ffffffffc0200436:	d96d                	beqz	a0,ffffffffc0200428 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200438:	00044583          	lbu	a1,0(s0)
ffffffffc020043c:	d9a9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc020043e:	bf55                	j	ffffffffc02003f2 <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200440:	45c1                	li	a1,16
ffffffffc0200442:	855a                	mv	a0,s6
ffffffffc0200444:	d51ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200448:	b7e9                	j	ffffffffc0200412 <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020044a:	6582                	ld	a1,0(sp)
ffffffffc020044c:	00004517          	auipc	a0,0x4
ffffffffc0200450:	c6450513          	addi	a0,a0,-924 # ffffffffc02040b0 <etext+0x250>
ffffffffc0200454:	d41ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc0200458:	b715                	j	ffffffffc020037c <kmonitor+0x76>

ffffffffc020045a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020045a:	0000d317          	auipc	t1,0xd
ffffffffc020045e:	00e30313          	addi	t1,t1,14 # ffffffffc020d468 <is_panic>
ffffffffc0200462:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200466:	715d                	addi	sp,sp,-80
ffffffffc0200468:	ec06                	sd	ra,24(sp)
ffffffffc020046a:	e822                	sd	s0,16(sp)
ffffffffc020046c:	f436                	sd	a3,40(sp)
ffffffffc020046e:	f83a                	sd	a4,48(sp)
ffffffffc0200470:	fc3e                	sd	a5,56(sp)
ffffffffc0200472:	e0c2                	sd	a6,64(sp)
ffffffffc0200474:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200476:	020e1a63          	bnez	t3,ffffffffc02004aa <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020047a:	4785                	li	a5,1
ffffffffc020047c:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200480:	8432                	mv	s0,a2
ffffffffc0200482:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200484:	862e                	mv	a2,a1
ffffffffc0200486:	85aa                	mv	a1,a0
ffffffffc0200488:	00004517          	auipc	a0,0x4
ffffffffc020048c:	c8850513          	addi	a0,a0,-888 # ffffffffc0204110 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200490:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200492:	d03ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200496:	65a2                	ld	a1,8(sp)
ffffffffc0200498:	8522                	mv	a0,s0
ffffffffc020049a:	cdbff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020049e:	00005517          	auipc	a0,0x5
ffffffffc02004a2:	d1250513          	addi	a0,a0,-750 # ffffffffc02051b0 <default_pmm_manager+0x530>
ffffffffc02004a6:	cefff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02004aa:	46c000ef          	jal	ra,ffffffffc0200916 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004ae:	4501                	li	a0,0
ffffffffc02004b0:	e57ff0ef          	jal	ra,ffffffffc0200306 <kmonitor>
    while (1) {
ffffffffc02004b4:	bfed                	j	ffffffffc02004ae <__panic+0x54>

ffffffffc02004b6 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004b6:	67e1                	lui	a5,0x18
ffffffffc02004b8:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004bc:	0000d717          	auipc	a4,0xd
ffffffffc02004c0:	faf73e23          	sd	a5,-68(a4) # ffffffffc020d478 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004c4:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02004c8:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004ca:	953e                	add	a0,a0,a5
ffffffffc02004cc:	4601                	li	a2,0
ffffffffc02004ce:	4881                	li	a7,0
ffffffffc02004d0:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02004d4:	02000793          	li	a5,32
ffffffffc02004d8:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02004dc:	00004517          	auipc	a0,0x4
ffffffffc02004e0:	c5450513          	addi	a0,a0,-940 # ffffffffc0204130 <commands+0x68>
    ticks = 0;
ffffffffc02004e4:	0000d797          	auipc	a5,0xd
ffffffffc02004e8:	f807b623          	sd	zero,-116(a5) # ffffffffc020d470 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02004ec:	b165                	j	ffffffffc0200194 <cprintf>

ffffffffc02004ee <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02004ee:	8082                	ret

ffffffffc02004f0 <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004f0:	100027f3          	csrr	a5,sstatus
ffffffffc02004f4:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02004f6:	0ff57513          	zext.b	a0,a0
ffffffffc02004fa:	e799                	bnez	a5,ffffffffc0200508 <cons_putc+0x18>
ffffffffc02004fc:	4581                	li	a1,0
ffffffffc02004fe:	4601                	li	a2,0
ffffffffc0200500:	4885                	li	a7,1
ffffffffc0200502:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200506:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200508:	1101                	addi	sp,sp,-32
ffffffffc020050a:	ec06                	sd	ra,24(sp)
ffffffffc020050c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020050e:	408000ef          	jal	ra,ffffffffc0200916 <intr_disable>
ffffffffc0200512:	6522                	ld	a0,8(sp)
ffffffffc0200514:	4581                	li	a1,0
ffffffffc0200516:	4601                	li	a2,0
ffffffffc0200518:	4885                	li	a7,1
ffffffffc020051a:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc020051e:	60e2                	ld	ra,24(sp)
ffffffffc0200520:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200522:	a6fd                	j	ffffffffc0200910 <intr_enable>

ffffffffc0200524 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200524:	100027f3          	csrr	a5,sstatus
ffffffffc0200528:	8b89                	andi	a5,a5,2
ffffffffc020052a:	eb89                	bnez	a5,ffffffffc020053c <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc020052c:	4501                	li	a0,0
ffffffffc020052e:	4581                	li	a1,0
ffffffffc0200530:	4601                	li	a2,0
ffffffffc0200532:	4889                	li	a7,2
ffffffffc0200534:	00000073          	ecall
ffffffffc0200538:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc020053a:	8082                	ret
int cons_getc(void) {
ffffffffc020053c:	1101                	addi	sp,sp,-32
ffffffffc020053e:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200540:	3d6000ef          	jal	ra,ffffffffc0200916 <intr_disable>
ffffffffc0200544:	4501                	li	a0,0
ffffffffc0200546:	4581                	li	a1,0
ffffffffc0200548:	4601                	li	a2,0
ffffffffc020054a:	4889                	li	a7,2
ffffffffc020054c:	00000073          	ecall
ffffffffc0200550:	2501                	sext.w	a0,a0
ffffffffc0200552:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200554:	3bc000ef          	jal	ra,ffffffffc0200910 <intr_enable>
}
ffffffffc0200558:	60e2                	ld	ra,24(sp)
ffffffffc020055a:	6522                	ld	a0,8(sp)
ffffffffc020055c:	6105                	addi	sp,sp,32
ffffffffc020055e:	8082                	ret

ffffffffc0200560 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200560:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200562:	00004517          	auipc	a0,0x4
ffffffffc0200566:	bee50513          	addi	a0,a0,-1042 # ffffffffc0204150 <commands+0x88>
void dtb_init(void) {
ffffffffc020056a:	fc86                	sd	ra,120(sp)
ffffffffc020056c:	f8a2                	sd	s0,112(sp)
ffffffffc020056e:	e8d2                	sd	s4,80(sp)
ffffffffc0200570:	f4a6                	sd	s1,104(sp)
ffffffffc0200572:	f0ca                	sd	s2,96(sp)
ffffffffc0200574:	ecce                	sd	s3,88(sp)
ffffffffc0200576:	e4d6                	sd	s5,72(sp)
ffffffffc0200578:	e0da                	sd	s6,64(sp)
ffffffffc020057a:	fc5e                	sd	s7,56(sp)
ffffffffc020057c:	f862                	sd	s8,48(sp)
ffffffffc020057e:	f466                	sd	s9,40(sp)
ffffffffc0200580:	f06a                	sd	s10,32(sp)
ffffffffc0200582:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200584:	c11ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200588:	00009597          	auipc	a1,0x9
ffffffffc020058c:	a785b583          	ld	a1,-1416(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc0200590:	00004517          	auipc	a0,0x4
ffffffffc0200594:	bd050513          	addi	a0,a0,-1072 # ffffffffc0204160 <commands+0x98>
ffffffffc0200598:	bfdff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020059c:	00009417          	auipc	s0,0x9
ffffffffc02005a0:	a6c40413          	addi	s0,s0,-1428 # ffffffffc0209008 <boot_dtb>
ffffffffc02005a4:	600c                	ld	a1,0(s0)
ffffffffc02005a6:	00004517          	auipc	a0,0x4
ffffffffc02005aa:	bca50513          	addi	a0,a0,-1078 # ffffffffc0204170 <commands+0xa8>
ffffffffc02005ae:	be7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005b2:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005b6:	00004517          	auipc	a0,0x4
ffffffffc02005ba:	bd250513          	addi	a0,a0,-1070 # ffffffffc0204188 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02005be:	120a0463          	beqz	s4,ffffffffc02006e6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02005c2:	57f5                	li	a5,-3
ffffffffc02005c4:	07fa                	slli	a5,a5,0x1e
ffffffffc02005c6:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02005ca:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005cc:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005d0:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005d2:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02005d6:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005da:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005de:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005e2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005e8:	8ec9                	or	a3,a3,a0
ffffffffc02005ea:	0087979b          	slliw	a5,a5,0x8
ffffffffc02005ee:	1b7d                	addi	s6,s6,-1
ffffffffc02005f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02005f4:	8dd5                	or	a1,a1,a3
ffffffffc02005f6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02005f8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005fc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02005fe:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed2a09>
ffffffffc0200602:	10f59163          	bne	a1,a5,ffffffffc0200704 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200606:	471c                	lw	a5,8(a4)
ffffffffc0200608:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc020060a:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020060c:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200610:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200614:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200618:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020061c:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200620:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200624:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200628:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020062c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200630:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200634:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200636:	01146433          	or	s0,s0,a7
ffffffffc020063a:	0086969b          	slliw	a3,a3,0x8
ffffffffc020063e:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200642:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200644:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200648:	8c49                	or	s0,s0,a0
ffffffffc020064a:	0166f6b3          	and	a3,a3,s6
ffffffffc020064e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200652:	0167f7b3          	and	a5,a5,s6
ffffffffc0200656:	8c55                	or	s0,s0,a3
ffffffffc0200658:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020065c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020065e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200660:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200662:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200666:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200668:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020066e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200670:	00004917          	auipc	s2,0x4
ffffffffc0200674:	b6890913          	addi	s2,s2,-1176 # ffffffffc02041d8 <commands+0x110>
ffffffffc0200678:	49bd                	li	s3,15
        switch (token) {
ffffffffc020067a:	4d91                	li	s11,4
ffffffffc020067c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020067e:	00004497          	auipc	s1,0x4
ffffffffc0200682:	b5248493          	addi	s1,s1,-1198 # ffffffffc02041d0 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200686:	000a2703          	lw	a4,0(s4)
ffffffffc020068a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200692:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200696:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020069a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069e:	0107571b          	srliw	a4,a4,0x10
ffffffffc02006a2:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a4:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a8:	0087171b          	slliw	a4,a4,0x8
ffffffffc02006ac:	8fd5                	or	a5,a5,a3
ffffffffc02006ae:	00eb7733          	and	a4,s6,a4
ffffffffc02006b2:	8fd9                	or	a5,a5,a4
ffffffffc02006b4:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02006b6:	09778c63          	beq	a5,s7,ffffffffc020074e <dtb_init+0x1ee>
ffffffffc02006ba:	00fbea63          	bltu	s7,a5,ffffffffc02006ce <dtb_init+0x16e>
ffffffffc02006be:	07a78663          	beq	a5,s10,ffffffffc020072a <dtb_init+0x1ca>
ffffffffc02006c2:	4709                	li	a4,2
ffffffffc02006c4:	00e79763          	bne	a5,a4,ffffffffc02006d2 <dtb_init+0x172>
ffffffffc02006c8:	4c81                	li	s9,0
ffffffffc02006ca:	8a56                	mv	s4,s5
ffffffffc02006cc:	bf6d                	j	ffffffffc0200686 <dtb_init+0x126>
ffffffffc02006ce:	ffb78ee3          	beq	a5,s11,ffffffffc02006ca <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006d2:	00004517          	auipc	a0,0x4
ffffffffc02006d6:	b7e50513          	addi	a0,a0,-1154 # ffffffffc0204250 <commands+0x188>
ffffffffc02006da:	abbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006de:	00004517          	auipc	a0,0x4
ffffffffc02006e2:	baa50513          	addi	a0,a0,-1110 # ffffffffc0204288 <commands+0x1c0>
}
ffffffffc02006e6:	7446                	ld	s0,112(sp)
ffffffffc02006e8:	70e6                	ld	ra,120(sp)
ffffffffc02006ea:	74a6                	ld	s1,104(sp)
ffffffffc02006ec:	7906                	ld	s2,96(sp)
ffffffffc02006ee:	69e6                	ld	s3,88(sp)
ffffffffc02006f0:	6a46                	ld	s4,80(sp)
ffffffffc02006f2:	6aa6                	ld	s5,72(sp)
ffffffffc02006f4:	6b06                	ld	s6,64(sp)
ffffffffc02006f6:	7be2                	ld	s7,56(sp)
ffffffffc02006f8:	7c42                	ld	s8,48(sp)
ffffffffc02006fa:	7ca2                	ld	s9,40(sp)
ffffffffc02006fc:	7d02                	ld	s10,32(sp)
ffffffffc02006fe:	6de2                	ld	s11,24(sp)
ffffffffc0200700:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200702:	bc49                	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200704:	7446                	ld	s0,112(sp)
ffffffffc0200706:	70e6                	ld	ra,120(sp)
ffffffffc0200708:	74a6                	ld	s1,104(sp)
ffffffffc020070a:	7906                	ld	s2,96(sp)
ffffffffc020070c:	69e6                	ld	s3,88(sp)
ffffffffc020070e:	6a46                	ld	s4,80(sp)
ffffffffc0200710:	6aa6                	ld	s5,72(sp)
ffffffffc0200712:	6b06                	ld	s6,64(sp)
ffffffffc0200714:	7be2                	ld	s7,56(sp)
ffffffffc0200716:	7c42                	ld	s8,48(sp)
ffffffffc0200718:	7ca2                	ld	s9,40(sp)
ffffffffc020071a:	7d02                	ld	s10,32(sp)
ffffffffc020071c:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020071e:	00004517          	auipc	a0,0x4
ffffffffc0200722:	a8a50513          	addi	a0,a0,-1398 # ffffffffc02041a8 <commands+0xe0>
}
ffffffffc0200726:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200728:	b4b5                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc020072a:	8556                	mv	a0,s5
ffffffffc020072c:	644030ef          	jal	ra,ffffffffc0203d70 <strlen>
ffffffffc0200730:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200732:	4619                	li	a2,6
ffffffffc0200734:	85a6                	mv	a1,s1
ffffffffc0200736:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200738:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020073a:	69c030ef          	jal	ra,ffffffffc0203dd6 <strncmp>
ffffffffc020073e:	e111                	bnez	a0,ffffffffc0200742 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200740:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200742:	0a91                	addi	s5,s5,4
ffffffffc0200744:	9ad2                	add	s5,s5,s4
ffffffffc0200746:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020074a:	8a56                	mv	s4,s5
ffffffffc020074c:	bf2d                	j	ffffffffc0200686 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020074e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200752:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200756:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020075a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020075e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200762:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200766:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020076a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020076e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200772:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200776:	00eaeab3          	or	s5,s5,a4
ffffffffc020077a:	00fb77b3          	and	a5,s6,a5
ffffffffc020077e:	00faeab3          	or	s5,s5,a5
ffffffffc0200782:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200784:	000c9c63          	bnez	s9,ffffffffc020079c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200788:	1a82                	slli	s5,s5,0x20
ffffffffc020078a:	00368793          	addi	a5,a3,3
ffffffffc020078e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200792:	9abe                	add	s5,s5,a5
ffffffffc0200794:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200798:	8a56                	mv	s4,s5
ffffffffc020079a:	b5f5                	j	ffffffffc0200686 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020079c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007a0:	85ca                	mv	a1,s2
ffffffffc02007a2:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007a4:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a8:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ac:	0187971b          	slliw	a4,a5,0x18
ffffffffc02007b0:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007b4:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02007b8:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ba:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007be:	0087979b          	slliw	a5,a5,0x8
ffffffffc02007c2:	8d59                	or	a0,a0,a4
ffffffffc02007c4:	00fb77b3          	and	a5,s6,a5
ffffffffc02007c8:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007ca:	1502                	slli	a0,a0,0x20
ffffffffc02007cc:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ce:	9522                	add	a0,a0,s0
ffffffffc02007d0:	5e8030ef          	jal	ra,ffffffffc0203db8 <strcmp>
ffffffffc02007d4:	66a2                	ld	a3,8(sp)
ffffffffc02007d6:	f94d                	bnez	a0,ffffffffc0200788 <dtb_init+0x228>
ffffffffc02007d8:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200788 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007dc:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007e0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007e4:	00004517          	auipc	a0,0x4
ffffffffc02007e8:	9fc50513          	addi	a0,a0,-1540 # ffffffffc02041e0 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc02007ec:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02007f4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02007fc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200808:	0187d693          	srli	a3,a5,0x18
ffffffffc020080c:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200810:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200814:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200818:	0106561b          	srliw	a2,a2,0x10
ffffffffc020081c:	010f6f33          	or	t5,t5,a6
ffffffffc0200820:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200824:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200828:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020082c:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200830:	0186f6b3          	and	a3,a3,s8
ffffffffc0200834:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200838:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020083c:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200840:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200844:	8361                	srli	a4,a4,0x18
ffffffffc0200846:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020084a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020084e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200852:	00cb7633          	and	a2,s6,a2
ffffffffc0200856:	0088181b          	slliw	a6,a6,0x8
ffffffffc020085a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020085e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200862:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200866:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020086a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020086e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200872:	011b78b3          	and	a7,s6,a7
ffffffffc0200876:	005eeeb3          	or	t4,t4,t0
ffffffffc020087a:	00c6e733          	or	a4,a3,a2
ffffffffc020087e:	006c6c33          	or	s8,s8,t1
ffffffffc0200882:	010b76b3          	and	a3,s6,a6
ffffffffc0200886:	00bb7b33          	and	s6,s6,a1
ffffffffc020088a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020088e:	016c6b33          	or	s6,s8,s6
ffffffffc0200892:	01146433          	or	s0,s0,a7
ffffffffc0200896:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200898:	1702                	slli	a4,a4,0x20
ffffffffc020089a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020089c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020089e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008a0:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008a2:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008a6:	0167eb33          	or	s6,a5,s6
ffffffffc02008aa:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008ac:	8e9ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008b0:	85a2                	mv	a1,s0
ffffffffc02008b2:	00004517          	auipc	a0,0x4
ffffffffc02008b6:	94e50513          	addi	a0,a0,-1714 # ffffffffc0204200 <commands+0x138>
ffffffffc02008ba:	8dbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008be:	014b5613          	srli	a2,s6,0x14
ffffffffc02008c2:	85da                	mv	a1,s6
ffffffffc02008c4:	00004517          	auipc	a0,0x4
ffffffffc02008c8:	95450513          	addi	a0,a0,-1708 # ffffffffc0204218 <commands+0x150>
ffffffffc02008cc:	8c9ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008d0:	008b05b3          	add	a1,s6,s0
ffffffffc02008d4:	15fd                	addi	a1,a1,-1
ffffffffc02008d6:	00004517          	auipc	a0,0x4
ffffffffc02008da:	96250513          	addi	a0,a0,-1694 # ffffffffc0204238 <commands+0x170>
ffffffffc02008de:	8b7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02008e2:	00004517          	auipc	a0,0x4
ffffffffc02008e6:	9a650513          	addi	a0,a0,-1626 # ffffffffc0204288 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc02008ea:	0000d797          	auipc	a5,0xd
ffffffffc02008ee:	b887bb23          	sd	s0,-1130(a5) # ffffffffc020d480 <memory_base>
        memory_size = mem_size;
ffffffffc02008f2:	0000d797          	auipc	a5,0xd
ffffffffc02008f6:	b967bb23          	sd	s6,-1130(a5) # ffffffffc020d488 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02008fa:	b3f5                	j	ffffffffc02006e6 <dtb_init+0x186>

ffffffffc02008fc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02008fc:	0000d517          	auipc	a0,0xd
ffffffffc0200900:	b8453503          	ld	a0,-1148(a0) # ffffffffc020d480 <memory_base>
ffffffffc0200904:	8082                	ret

ffffffffc0200906 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200906:	0000d517          	auipc	a0,0xd
ffffffffc020090a:	b8253503          	ld	a0,-1150(a0) # ffffffffc020d488 <memory_size>
ffffffffc020090e:	8082                	ret

ffffffffc0200910 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200910:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200914:	8082                	ret

ffffffffc0200916 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200916:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020091a:	8082                	ret

ffffffffc020091c <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020091c:	8082                	ret

ffffffffc020091e <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020091e:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200922:	00000797          	auipc	a5,0x0
ffffffffc0200926:	38678793          	addi	a5,a5,902 # ffffffffc0200ca8 <__alltraps>
ffffffffc020092a:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020092e:	000407b7          	lui	a5,0x40
ffffffffc0200932:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200936:	8082                	ret

ffffffffc0200938 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200938:	610c                	ld	a1,0(a0)
{
ffffffffc020093a:	1141                	addi	sp,sp,-16
ffffffffc020093c:	e022                	sd	s0,0(sp)
ffffffffc020093e:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200940:	00004517          	auipc	a0,0x4
ffffffffc0200944:	96050513          	addi	a0,a0,-1696 # ffffffffc02042a0 <commands+0x1d8>
{
ffffffffc0200948:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020094a:	84bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020094e:	640c                	ld	a1,8(s0)
ffffffffc0200950:	00004517          	auipc	a0,0x4
ffffffffc0200954:	96850513          	addi	a0,a0,-1688 # ffffffffc02042b8 <commands+0x1f0>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020095c:	680c                	ld	a1,16(s0)
ffffffffc020095e:	00004517          	auipc	a0,0x4
ffffffffc0200962:	97250513          	addi	a0,a0,-1678 # ffffffffc02042d0 <commands+0x208>
ffffffffc0200966:	82fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020096a:	6c0c                	ld	a1,24(s0)
ffffffffc020096c:	00004517          	auipc	a0,0x4
ffffffffc0200970:	97c50513          	addi	a0,a0,-1668 # ffffffffc02042e8 <commands+0x220>
ffffffffc0200974:	821ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200978:	700c                	ld	a1,32(s0)
ffffffffc020097a:	00004517          	auipc	a0,0x4
ffffffffc020097e:	98650513          	addi	a0,a0,-1658 # ffffffffc0204300 <commands+0x238>
ffffffffc0200982:	813ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200986:	740c                	ld	a1,40(s0)
ffffffffc0200988:	00004517          	auipc	a0,0x4
ffffffffc020098c:	99050513          	addi	a0,a0,-1648 # ffffffffc0204318 <commands+0x250>
ffffffffc0200990:	805ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200994:	780c                	ld	a1,48(s0)
ffffffffc0200996:	00004517          	auipc	a0,0x4
ffffffffc020099a:	99a50513          	addi	a0,a0,-1638 # ffffffffc0204330 <commands+0x268>
ffffffffc020099e:	ff6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02009a2:	7c0c                	ld	a1,56(s0)
ffffffffc02009a4:	00004517          	auipc	a0,0x4
ffffffffc02009a8:	9a450513          	addi	a0,a0,-1628 # ffffffffc0204348 <commands+0x280>
ffffffffc02009ac:	fe8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02009b0:	602c                	ld	a1,64(s0)
ffffffffc02009b2:	00004517          	auipc	a0,0x4
ffffffffc02009b6:	9ae50513          	addi	a0,a0,-1618 # ffffffffc0204360 <commands+0x298>
ffffffffc02009ba:	fdaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009be:	642c                	ld	a1,72(s0)
ffffffffc02009c0:	00004517          	auipc	a0,0x4
ffffffffc02009c4:	9b850513          	addi	a0,a0,-1608 # ffffffffc0204378 <commands+0x2b0>
ffffffffc02009c8:	fccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009cc:	682c                	ld	a1,80(s0)
ffffffffc02009ce:	00004517          	auipc	a0,0x4
ffffffffc02009d2:	9c250513          	addi	a0,a0,-1598 # ffffffffc0204390 <commands+0x2c8>
ffffffffc02009d6:	fbeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009da:	6c2c                	ld	a1,88(s0)
ffffffffc02009dc:	00004517          	auipc	a0,0x4
ffffffffc02009e0:	9cc50513          	addi	a0,a0,-1588 # ffffffffc02043a8 <commands+0x2e0>
ffffffffc02009e4:	fb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009e8:	702c                	ld	a1,96(s0)
ffffffffc02009ea:	00004517          	auipc	a0,0x4
ffffffffc02009ee:	9d650513          	addi	a0,a0,-1578 # ffffffffc02043c0 <commands+0x2f8>
ffffffffc02009f2:	fa2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009f6:	742c                	ld	a1,104(s0)
ffffffffc02009f8:	00004517          	auipc	a0,0x4
ffffffffc02009fc:	9e050513          	addi	a0,a0,-1568 # ffffffffc02043d8 <commands+0x310>
ffffffffc0200a00:	f94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a04:	782c                	ld	a1,112(s0)
ffffffffc0200a06:	00004517          	auipc	a0,0x4
ffffffffc0200a0a:	9ea50513          	addi	a0,a0,-1558 # ffffffffc02043f0 <commands+0x328>
ffffffffc0200a0e:	f86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a12:	7c2c                	ld	a1,120(s0)
ffffffffc0200a14:	00004517          	auipc	a0,0x4
ffffffffc0200a18:	9f450513          	addi	a0,a0,-1548 # ffffffffc0204408 <commands+0x340>
ffffffffc0200a1c:	f78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a20:	604c                	ld	a1,128(s0)
ffffffffc0200a22:	00004517          	auipc	a0,0x4
ffffffffc0200a26:	9fe50513          	addi	a0,a0,-1538 # ffffffffc0204420 <commands+0x358>
ffffffffc0200a2a:	f6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a2e:	644c                	ld	a1,136(s0)
ffffffffc0200a30:	00004517          	auipc	a0,0x4
ffffffffc0200a34:	a0850513          	addi	a0,a0,-1528 # ffffffffc0204438 <commands+0x370>
ffffffffc0200a38:	f5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a3c:	684c                	ld	a1,144(s0)
ffffffffc0200a3e:	00004517          	auipc	a0,0x4
ffffffffc0200a42:	a1250513          	addi	a0,a0,-1518 # ffffffffc0204450 <commands+0x388>
ffffffffc0200a46:	f4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a4a:	6c4c                	ld	a1,152(s0)
ffffffffc0200a4c:	00004517          	auipc	a0,0x4
ffffffffc0200a50:	a1c50513          	addi	a0,a0,-1508 # ffffffffc0204468 <commands+0x3a0>
ffffffffc0200a54:	f40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a58:	704c                	ld	a1,160(s0)
ffffffffc0200a5a:	00004517          	auipc	a0,0x4
ffffffffc0200a5e:	a2650513          	addi	a0,a0,-1498 # ffffffffc0204480 <commands+0x3b8>
ffffffffc0200a62:	f32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a66:	744c                	ld	a1,168(s0)
ffffffffc0200a68:	00004517          	auipc	a0,0x4
ffffffffc0200a6c:	a3050513          	addi	a0,a0,-1488 # ffffffffc0204498 <commands+0x3d0>
ffffffffc0200a70:	f24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a74:	784c                	ld	a1,176(s0)
ffffffffc0200a76:	00004517          	auipc	a0,0x4
ffffffffc0200a7a:	a3a50513          	addi	a0,a0,-1478 # ffffffffc02044b0 <commands+0x3e8>
ffffffffc0200a7e:	f16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a82:	7c4c                	ld	a1,184(s0)
ffffffffc0200a84:	00004517          	auipc	a0,0x4
ffffffffc0200a88:	a4450513          	addi	a0,a0,-1468 # ffffffffc02044c8 <commands+0x400>
ffffffffc0200a8c:	f08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a90:	606c                	ld	a1,192(s0)
ffffffffc0200a92:	00004517          	auipc	a0,0x4
ffffffffc0200a96:	a4e50513          	addi	a0,a0,-1458 # ffffffffc02044e0 <commands+0x418>
ffffffffc0200a9a:	efaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a9e:	646c                	ld	a1,200(s0)
ffffffffc0200aa0:	00004517          	auipc	a0,0x4
ffffffffc0200aa4:	a5850513          	addi	a0,a0,-1448 # ffffffffc02044f8 <commands+0x430>
ffffffffc0200aa8:	eecff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200aac:	686c                	ld	a1,208(s0)
ffffffffc0200aae:	00004517          	auipc	a0,0x4
ffffffffc0200ab2:	a6250513          	addi	a0,a0,-1438 # ffffffffc0204510 <commands+0x448>
ffffffffc0200ab6:	edeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200aba:	6c6c                	ld	a1,216(s0)
ffffffffc0200abc:	00004517          	auipc	a0,0x4
ffffffffc0200ac0:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0204528 <commands+0x460>
ffffffffc0200ac4:	ed0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ac8:	706c                	ld	a1,224(s0)
ffffffffc0200aca:	00004517          	auipc	a0,0x4
ffffffffc0200ace:	a7650513          	addi	a0,a0,-1418 # ffffffffc0204540 <commands+0x478>
ffffffffc0200ad2:	ec2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200ad6:	746c                	ld	a1,232(s0)
ffffffffc0200ad8:	00004517          	auipc	a0,0x4
ffffffffc0200adc:	a8050513          	addi	a0,a0,-1408 # ffffffffc0204558 <commands+0x490>
ffffffffc0200ae0:	eb4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200ae4:	786c                	ld	a1,240(s0)
ffffffffc0200ae6:	00004517          	auipc	a0,0x4
ffffffffc0200aea:	a8a50513          	addi	a0,a0,-1398 # ffffffffc0204570 <commands+0x4a8>
ffffffffc0200aee:	ea6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200af2:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200af4:	6402                	ld	s0,0(sp)
ffffffffc0200af6:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200af8:	00004517          	auipc	a0,0x4
ffffffffc0200afc:	a9050513          	addi	a0,a0,-1392 # ffffffffc0204588 <commands+0x4c0>
}
ffffffffc0200b00:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b02:	e92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b06 <print_trapframe>:
{
ffffffffc0200b06:	1141                	addi	sp,sp,-16
ffffffffc0200b08:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b0a:	85aa                	mv	a1,a0
{
ffffffffc0200b0c:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b0e:	00004517          	auipc	a0,0x4
ffffffffc0200b12:	a9250513          	addi	a0,a0,-1390 # ffffffffc02045a0 <commands+0x4d8>
{
ffffffffc0200b16:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b18:	e7cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b1c:	8522                	mv	a0,s0
ffffffffc0200b1e:	e1bff0ef          	jal	ra,ffffffffc0200938 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b22:	10043583          	ld	a1,256(s0)
ffffffffc0200b26:	00004517          	auipc	a0,0x4
ffffffffc0200b2a:	a9250513          	addi	a0,a0,-1390 # ffffffffc02045b8 <commands+0x4f0>
ffffffffc0200b2e:	e66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b32:	10843583          	ld	a1,264(s0)
ffffffffc0200b36:	00004517          	auipc	a0,0x4
ffffffffc0200b3a:	a9a50513          	addi	a0,a0,-1382 # ffffffffc02045d0 <commands+0x508>
ffffffffc0200b3e:	e56ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b42:	11043583          	ld	a1,272(s0)
ffffffffc0200b46:	00004517          	auipc	a0,0x4
ffffffffc0200b4a:	aa250513          	addi	a0,a0,-1374 # ffffffffc02045e8 <commands+0x520>
ffffffffc0200b4e:	e46ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b52:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b56:	6402                	ld	s0,0(sp)
ffffffffc0200b58:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b5a:	00004517          	auipc	a0,0x4
ffffffffc0200b5e:	aa650513          	addi	a0,a0,-1370 # ffffffffc0204600 <commands+0x538>
}
ffffffffc0200b62:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b64:	e30ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b68 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200b68:	11853783          	ld	a5,280(a0)
ffffffffc0200b6c:	472d                	li	a4,11
ffffffffc0200b6e:	0786                	slli	a5,a5,0x1
ffffffffc0200b70:	8385                	srli	a5,a5,0x1
ffffffffc0200b72:	04f76a63          	bltu	a4,a5,ffffffffc0200bc6 <interrupt_handler+0x5e>
ffffffffc0200b76:	00004717          	auipc	a4,0x4
ffffffffc0200b7a:	b4270713          	addi	a4,a4,-1214 # ffffffffc02046b8 <commands+0x5f0>
ffffffffc0200b7e:	078a                	slli	a5,a5,0x2
ffffffffc0200b80:	97ba                	add	a5,a5,a4
ffffffffc0200b82:	439c                	lw	a5,0(a5)
ffffffffc0200b84:	97ba                	add	a5,a5,a4
ffffffffc0200b86:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200b88:	00004517          	auipc	a0,0x4
ffffffffc0200b8c:	af050513          	addi	a0,a0,-1296 # ffffffffc0204678 <commands+0x5b0>
ffffffffc0200b90:	e04ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200b94:	00004517          	auipc	a0,0x4
ffffffffc0200b98:	ac450513          	addi	a0,a0,-1340 # ffffffffc0204658 <commands+0x590>
ffffffffc0200b9c:	df8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200ba0:	00004517          	auipc	a0,0x4
ffffffffc0200ba4:	a7850513          	addi	a0,a0,-1416 # ffffffffc0204618 <commands+0x550>
ffffffffc0200ba8:	decff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200bac:	00004517          	auipc	a0,0x4
ffffffffc0200bb0:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0204638 <commands+0x570>
ffffffffc0200bb4:	de0ff06f          	j	ffffffffc0200194 <cprintf>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bb8:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bba:	00004517          	auipc	a0,0x4
ffffffffc0200bbe:	ade50513          	addi	a0,a0,-1314 # ffffffffc0204698 <commands+0x5d0>
ffffffffc0200bc2:	dd2ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200bc6:	b781                	j	ffffffffc0200b06 <print_trapframe>

ffffffffc0200bc8 <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200bc8:	11853783          	ld	a5,280(a0)
ffffffffc0200bcc:	473d                	li	a4,15
ffffffffc0200bce:	0cf76563          	bltu	a4,a5,ffffffffc0200c98 <exception_handler+0xd0>
ffffffffc0200bd2:	00004717          	auipc	a4,0x4
ffffffffc0200bd6:	cae70713          	addi	a4,a4,-850 # ffffffffc0204880 <commands+0x7b8>
ffffffffc0200bda:	078a                	slli	a5,a5,0x2
ffffffffc0200bdc:	97ba                	add	a5,a5,a4
ffffffffc0200bde:	439c                	lw	a5,0(a5)
ffffffffc0200be0:	97ba                	add	a5,a5,a4
ffffffffc0200be2:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200be4:	00004517          	auipc	a0,0x4
ffffffffc0200be8:	c8450513          	addi	a0,a0,-892 # ffffffffc0204868 <commands+0x7a0>
ffffffffc0200bec:	da8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200bf0:	00004517          	auipc	a0,0x4
ffffffffc0200bf4:	af850513          	addi	a0,a0,-1288 # ffffffffc02046e8 <commands+0x620>
ffffffffc0200bf8:	d9cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200bfc:	00004517          	auipc	a0,0x4
ffffffffc0200c00:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0204708 <commands+0x640>
ffffffffc0200c04:	d90ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200c08:	00004517          	auipc	a0,0x4
ffffffffc0200c0c:	b2050513          	addi	a0,a0,-1248 # ffffffffc0204728 <commands+0x660>
ffffffffc0200c10:	d84ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200c14:	00004517          	auipc	a0,0x4
ffffffffc0200c18:	b2c50513          	addi	a0,a0,-1236 # ffffffffc0204740 <commands+0x678>
ffffffffc0200c1c:	d78ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200c20:	00004517          	auipc	a0,0x4
ffffffffc0200c24:	b3050513          	addi	a0,a0,-1232 # ffffffffc0204750 <commands+0x688>
ffffffffc0200c28:	d6cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200c2c:	00004517          	auipc	a0,0x4
ffffffffc0200c30:	b4450513          	addi	a0,a0,-1212 # ffffffffc0204770 <commands+0x6a8>
ffffffffc0200c34:	d60ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200c38:	00004517          	auipc	a0,0x4
ffffffffc0200c3c:	b5050513          	addi	a0,a0,-1200 # ffffffffc0204788 <commands+0x6c0>
ffffffffc0200c40:	d54ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200c44:	00004517          	auipc	a0,0x4
ffffffffc0200c48:	b5c50513          	addi	a0,a0,-1188 # ffffffffc02047a0 <commands+0x6d8>
ffffffffc0200c4c:	d48ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200c50:	00004517          	auipc	a0,0x4
ffffffffc0200c54:	b6850513          	addi	a0,a0,-1176 # ffffffffc02047b8 <commands+0x6f0>
ffffffffc0200c58:	d3cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200c5c:	00004517          	auipc	a0,0x4
ffffffffc0200c60:	b7c50513          	addi	a0,a0,-1156 # ffffffffc02047d8 <commands+0x710>
ffffffffc0200c64:	d30ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200c68:	00004517          	auipc	a0,0x4
ffffffffc0200c6c:	b9050513          	addi	a0,a0,-1136 # ffffffffc02047f8 <commands+0x730>
ffffffffc0200c70:	d24ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200c74:	00004517          	auipc	a0,0x4
ffffffffc0200c78:	ba450513          	addi	a0,a0,-1116 # ffffffffc0204818 <commands+0x750>
ffffffffc0200c7c:	d18ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200c80:	00004517          	auipc	a0,0x4
ffffffffc0200c84:	bb850513          	addi	a0,a0,-1096 # ffffffffc0204838 <commands+0x770>
ffffffffc0200c88:	d0cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200c8c:	00004517          	auipc	a0,0x4
ffffffffc0200c90:	bc450513          	addi	a0,a0,-1084 # ffffffffc0204850 <commands+0x788>
ffffffffc0200c94:	d00ff06f          	j	ffffffffc0200194 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200c98:	b5bd                	j	ffffffffc0200b06 <print_trapframe>

ffffffffc0200c9a <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200c9a:	11853783          	ld	a5,280(a0)
ffffffffc0200c9e:	0007c363          	bltz	a5,ffffffffc0200ca4 <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200ca2:	b71d                	j	ffffffffc0200bc8 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200ca4:	b5d1                	j	ffffffffc0200b68 <interrupt_handler>
	...

ffffffffc0200ca8 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ca8:	14011073          	csrw	sscratch,sp
ffffffffc0200cac:	712d                	addi	sp,sp,-288
ffffffffc0200cae:	e406                	sd	ra,8(sp)
ffffffffc0200cb0:	ec0e                	sd	gp,24(sp)
ffffffffc0200cb2:	f012                	sd	tp,32(sp)
ffffffffc0200cb4:	f416                	sd	t0,40(sp)
ffffffffc0200cb6:	f81a                	sd	t1,48(sp)
ffffffffc0200cb8:	fc1e                	sd	t2,56(sp)
ffffffffc0200cba:	e0a2                	sd	s0,64(sp)
ffffffffc0200cbc:	e4a6                	sd	s1,72(sp)
ffffffffc0200cbe:	e8aa                	sd	a0,80(sp)
ffffffffc0200cc0:	ecae                	sd	a1,88(sp)
ffffffffc0200cc2:	f0b2                	sd	a2,96(sp)
ffffffffc0200cc4:	f4b6                	sd	a3,104(sp)
ffffffffc0200cc6:	f8ba                	sd	a4,112(sp)
ffffffffc0200cc8:	fcbe                	sd	a5,120(sp)
ffffffffc0200cca:	e142                	sd	a6,128(sp)
ffffffffc0200ccc:	e546                	sd	a7,136(sp)
ffffffffc0200cce:	e94a                	sd	s2,144(sp)
ffffffffc0200cd0:	ed4e                	sd	s3,152(sp)
ffffffffc0200cd2:	f152                	sd	s4,160(sp)
ffffffffc0200cd4:	f556                	sd	s5,168(sp)
ffffffffc0200cd6:	f95a                	sd	s6,176(sp)
ffffffffc0200cd8:	fd5e                	sd	s7,184(sp)
ffffffffc0200cda:	e1e2                	sd	s8,192(sp)
ffffffffc0200cdc:	e5e6                	sd	s9,200(sp)
ffffffffc0200cde:	e9ea                	sd	s10,208(sp)
ffffffffc0200ce0:	edee                	sd	s11,216(sp)
ffffffffc0200ce2:	f1f2                	sd	t3,224(sp)
ffffffffc0200ce4:	f5f6                	sd	t4,232(sp)
ffffffffc0200ce6:	f9fa                	sd	t5,240(sp)
ffffffffc0200ce8:	fdfe                	sd	t6,248(sp)
ffffffffc0200cea:	14002473          	csrr	s0,sscratch
ffffffffc0200cee:	100024f3          	csrr	s1,sstatus
ffffffffc0200cf2:	14102973          	csrr	s2,sepc
ffffffffc0200cf6:	143029f3          	csrr	s3,stval
ffffffffc0200cfa:	14202a73          	csrr	s4,scause
ffffffffc0200cfe:	e822                	sd	s0,16(sp)
ffffffffc0200d00:	e226                	sd	s1,256(sp)
ffffffffc0200d02:	e64a                	sd	s2,264(sp)
ffffffffc0200d04:	ea4e                	sd	s3,272(sp)
ffffffffc0200d06:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d08:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d0a:	f91ff0ef          	jal	ra,ffffffffc0200c9a <trap>

ffffffffc0200d0e <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d0e:	6492                	ld	s1,256(sp)
ffffffffc0200d10:	6932                	ld	s2,264(sp)
ffffffffc0200d12:	10049073          	csrw	sstatus,s1
ffffffffc0200d16:	14191073          	csrw	sepc,s2
ffffffffc0200d1a:	60a2                	ld	ra,8(sp)
ffffffffc0200d1c:	61e2                	ld	gp,24(sp)
ffffffffc0200d1e:	7202                	ld	tp,32(sp)
ffffffffc0200d20:	72a2                	ld	t0,40(sp)
ffffffffc0200d22:	7342                	ld	t1,48(sp)
ffffffffc0200d24:	73e2                	ld	t2,56(sp)
ffffffffc0200d26:	6406                	ld	s0,64(sp)
ffffffffc0200d28:	64a6                	ld	s1,72(sp)
ffffffffc0200d2a:	6546                	ld	a0,80(sp)
ffffffffc0200d2c:	65e6                	ld	a1,88(sp)
ffffffffc0200d2e:	7606                	ld	a2,96(sp)
ffffffffc0200d30:	76a6                	ld	a3,104(sp)
ffffffffc0200d32:	7746                	ld	a4,112(sp)
ffffffffc0200d34:	77e6                	ld	a5,120(sp)
ffffffffc0200d36:	680a                	ld	a6,128(sp)
ffffffffc0200d38:	68aa                	ld	a7,136(sp)
ffffffffc0200d3a:	694a                	ld	s2,144(sp)
ffffffffc0200d3c:	69ea                	ld	s3,152(sp)
ffffffffc0200d3e:	7a0a                	ld	s4,160(sp)
ffffffffc0200d40:	7aaa                	ld	s5,168(sp)
ffffffffc0200d42:	7b4a                	ld	s6,176(sp)
ffffffffc0200d44:	7bea                	ld	s7,184(sp)
ffffffffc0200d46:	6c0e                	ld	s8,192(sp)
ffffffffc0200d48:	6cae                	ld	s9,200(sp)
ffffffffc0200d4a:	6d4e                	ld	s10,208(sp)
ffffffffc0200d4c:	6dee                	ld	s11,216(sp)
ffffffffc0200d4e:	7e0e                	ld	t3,224(sp)
ffffffffc0200d50:	7eae                	ld	t4,232(sp)
ffffffffc0200d52:	7f4e                	ld	t5,240(sp)
ffffffffc0200d54:	7fee                	ld	t6,248(sp)
ffffffffc0200d56:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200d58:	10200073          	sret

ffffffffc0200d5c <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200d5c:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200d5e:	bf45                	j	ffffffffc0200d0e <__trapret>
	...

ffffffffc0200d62 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200d62:	00008797          	auipc	a5,0x8
ffffffffc0200d66:	6ce78793          	addi	a5,a5,1742 # ffffffffc0209430 <free_area>
ffffffffc0200d6a:	e79c                	sd	a5,8(a5)
ffffffffc0200d6c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200d6e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200d72:	8082                	ret

ffffffffc0200d74 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200d74:	00008517          	auipc	a0,0x8
ffffffffc0200d78:	6cc56503          	lwu	a0,1740(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200d7c:	8082                	ret

ffffffffc0200d7e <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200d7e:	715d                	addi	sp,sp,-80
ffffffffc0200d80:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200d82:	00008417          	auipc	s0,0x8
ffffffffc0200d86:	6ae40413          	addi	s0,s0,1710 # ffffffffc0209430 <free_area>
ffffffffc0200d8a:	641c                	ld	a5,8(s0)
ffffffffc0200d8c:	e486                	sd	ra,72(sp)
ffffffffc0200d8e:	fc26                	sd	s1,56(sp)
ffffffffc0200d90:	f84a                	sd	s2,48(sp)
ffffffffc0200d92:	f44e                	sd	s3,40(sp)
ffffffffc0200d94:	f052                	sd	s4,32(sp)
ffffffffc0200d96:	ec56                	sd	s5,24(sp)
ffffffffc0200d98:	e85a                	sd	s6,16(sp)
ffffffffc0200d9a:	e45e                	sd	s7,8(sp)
ffffffffc0200d9c:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d9e:	2a878d63          	beq	a5,s0,ffffffffc0201058 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200da2:	4481                	li	s1,0
ffffffffc0200da4:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200da6:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200daa:	8b09                	andi	a4,a4,2
ffffffffc0200dac:	2a070a63          	beqz	a4,ffffffffc0201060 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0200db0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200db4:	679c                	ld	a5,8(a5)
ffffffffc0200db6:	2905                	addiw	s2,s2,1
ffffffffc0200db8:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dba:	fe8796e3          	bne	a5,s0,ffffffffc0200da6 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200dbe:	89a6                	mv	s3,s1
ffffffffc0200dc0:	6db000ef          	jal	ra,ffffffffc0201c9a <nr_free_pages>
ffffffffc0200dc4:	6f351e63          	bne	a0,s3,ffffffffc02014c0 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200dc8:	4505                	li	a0,1
ffffffffc0200dca:	653000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200dce:	8aaa                	mv	s5,a0
ffffffffc0200dd0:	42050863          	beqz	a0,ffffffffc0201200 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200dd4:	4505                	li	a0,1
ffffffffc0200dd6:	647000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200dda:	89aa                	mv	s3,a0
ffffffffc0200ddc:	70050263          	beqz	a0,ffffffffc02014e0 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200de0:	4505                	li	a0,1
ffffffffc0200de2:	63b000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200de6:	8a2a                	mv	s4,a0
ffffffffc0200de8:	48050c63          	beqz	a0,ffffffffc0201280 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200dec:	293a8a63          	beq	s5,s3,ffffffffc0201080 <default_check+0x302>
ffffffffc0200df0:	28aa8863          	beq	s5,a0,ffffffffc0201080 <default_check+0x302>
ffffffffc0200df4:	28a98663          	beq	s3,a0,ffffffffc0201080 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200df8:	000aa783          	lw	a5,0(s5)
ffffffffc0200dfc:	2a079263          	bnez	a5,ffffffffc02010a0 <default_check+0x322>
ffffffffc0200e00:	0009a783          	lw	a5,0(s3)
ffffffffc0200e04:	28079e63          	bnez	a5,ffffffffc02010a0 <default_check+0x322>
ffffffffc0200e08:	411c                	lw	a5,0(a0)
ffffffffc0200e0a:	28079b63          	bnez	a5,ffffffffc02010a0 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200e0e:	0000c797          	auipc	a5,0xc
ffffffffc0200e12:	6a27b783          	ld	a5,1698(a5) # ffffffffc020d4b0 <pages>
ffffffffc0200e16:	40fa8733          	sub	a4,s5,a5
ffffffffc0200e1a:	00005617          	auipc	a2,0x5
ffffffffc0200e1e:	b7e63603          	ld	a2,-1154(a2) # ffffffffc0205998 <nbase>
ffffffffc0200e22:	8719                	srai	a4,a4,0x6
ffffffffc0200e24:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e26:	0000c697          	auipc	a3,0xc
ffffffffc0200e2a:	6826b683          	ld	a3,1666(a3) # ffffffffc020d4a8 <npage>
ffffffffc0200e2e:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e30:	0732                	slli	a4,a4,0xc
ffffffffc0200e32:	28d77763          	bgeu	a4,a3,ffffffffc02010c0 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200e36:	40f98733          	sub	a4,s3,a5
ffffffffc0200e3a:	8719                	srai	a4,a4,0x6
ffffffffc0200e3c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e3e:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e40:	4cd77063          	bgeu	a4,a3,ffffffffc0201300 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200e44:	40f507b3          	sub	a5,a0,a5
ffffffffc0200e48:	8799                	srai	a5,a5,0x6
ffffffffc0200e4a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e4c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e4e:	30d7f963          	bgeu	a5,a3,ffffffffc0201160 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200e52:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e54:	00043c03          	ld	s8,0(s0)
ffffffffc0200e58:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e5c:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200e60:	e400                	sd	s0,8(s0)
ffffffffc0200e62:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200e64:	00008797          	auipc	a5,0x8
ffffffffc0200e68:	5c07ae23          	sw	zero,1500(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e6c:	5b1000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200e70:	2c051863          	bnez	a0,ffffffffc0201140 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200e74:	4585                	li	a1,1
ffffffffc0200e76:	8556                	mv	a0,s5
ffffffffc0200e78:	5e3000ef          	jal	ra,ffffffffc0201c5a <free_pages>
    free_page(p1);
ffffffffc0200e7c:	4585                	li	a1,1
ffffffffc0200e7e:	854e                	mv	a0,s3
ffffffffc0200e80:	5db000ef          	jal	ra,ffffffffc0201c5a <free_pages>
    free_page(p2);
ffffffffc0200e84:	4585                	li	a1,1
ffffffffc0200e86:	8552                	mv	a0,s4
ffffffffc0200e88:	5d3000ef          	jal	ra,ffffffffc0201c5a <free_pages>
    assert(nr_free == 3);
ffffffffc0200e8c:	4818                	lw	a4,16(s0)
ffffffffc0200e8e:	478d                	li	a5,3
ffffffffc0200e90:	28f71863          	bne	a4,a5,ffffffffc0201120 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e94:	4505                	li	a0,1
ffffffffc0200e96:	587000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200e9a:	89aa                	mv	s3,a0
ffffffffc0200e9c:	26050263          	beqz	a0,ffffffffc0201100 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ea0:	4505                	li	a0,1
ffffffffc0200ea2:	57b000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200ea6:	8aaa                	mv	s5,a0
ffffffffc0200ea8:	3a050c63          	beqz	a0,ffffffffc0201260 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200eac:	4505                	li	a0,1
ffffffffc0200eae:	56f000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200eb2:	8a2a                	mv	s4,a0
ffffffffc0200eb4:	38050663          	beqz	a0,ffffffffc0201240 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200eb8:	4505                	li	a0,1
ffffffffc0200eba:	563000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200ebe:	36051163          	bnez	a0,ffffffffc0201220 <default_check+0x4a2>
    free_page(p0);
ffffffffc0200ec2:	4585                	li	a1,1
ffffffffc0200ec4:	854e                	mv	a0,s3
ffffffffc0200ec6:	595000ef          	jal	ra,ffffffffc0201c5a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200eca:	641c                	ld	a5,8(s0)
ffffffffc0200ecc:	20878a63          	beq	a5,s0,ffffffffc02010e0 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0200ed0:	4505                	li	a0,1
ffffffffc0200ed2:	54b000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200ed6:	30a99563          	bne	s3,a0,ffffffffc02011e0 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0200eda:	4505                	li	a0,1
ffffffffc0200edc:	541000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200ee0:	2e051063          	bnez	a0,ffffffffc02011c0 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0200ee4:	481c                	lw	a5,16(s0)
ffffffffc0200ee6:	2a079d63          	bnez	a5,ffffffffc02011a0 <default_check+0x422>
    free_page(p);
ffffffffc0200eea:	854e                	mv	a0,s3
ffffffffc0200eec:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200eee:	01843023          	sd	s8,0(s0)
ffffffffc0200ef2:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200ef6:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200efa:	561000ef          	jal	ra,ffffffffc0201c5a <free_pages>
    free_page(p1);
ffffffffc0200efe:	4585                	li	a1,1
ffffffffc0200f00:	8556                	mv	a0,s5
ffffffffc0200f02:	559000ef          	jal	ra,ffffffffc0201c5a <free_pages>
    free_page(p2);
ffffffffc0200f06:	4585                	li	a1,1
ffffffffc0200f08:	8552                	mv	a0,s4
ffffffffc0200f0a:	551000ef          	jal	ra,ffffffffc0201c5a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200f0e:	4515                	li	a0,5
ffffffffc0200f10:	50d000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200f14:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f16:	26050563          	beqz	a0,ffffffffc0201180 <default_check+0x402>
ffffffffc0200f1a:	651c                	ld	a5,8(a0)
ffffffffc0200f1c:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f1e:	8b85                	andi	a5,a5,1
ffffffffc0200f20:	54079063          	bnez	a5,ffffffffc0201460 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f24:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f26:	00043b03          	ld	s6,0(s0)
ffffffffc0200f2a:	00843a83          	ld	s5,8(s0)
ffffffffc0200f2e:	e000                	sd	s0,0(s0)
ffffffffc0200f30:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200f32:	4eb000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200f36:	50051563          	bnez	a0,ffffffffc0201440 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200f3a:	08098a13          	addi	s4,s3,128
ffffffffc0200f3e:	8552                	mv	a0,s4
ffffffffc0200f40:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200f42:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200f46:	00008797          	auipc	a5,0x8
ffffffffc0200f4a:	4e07ad23          	sw	zero,1274(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200f4e:	50d000ef          	jal	ra,ffffffffc0201c5a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f52:	4511                	li	a0,4
ffffffffc0200f54:	4c9000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200f58:	4c051463          	bnez	a0,ffffffffc0201420 <default_check+0x6a2>
ffffffffc0200f5c:	0889b783          	ld	a5,136(s3)
ffffffffc0200f60:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200f62:	8b85                	andi	a5,a5,1
ffffffffc0200f64:	48078e63          	beqz	a5,ffffffffc0201400 <default_check+0x682>
ffffffffc0200f68:	0909a703          	lw	a4,144(s3)
ffffffffc0200f6c:	478d                	li	a5,3
ffffffffc0200f6e:	48f71963          	bne	a4,a5,ffffffffc0201400 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200f72:	450d                	li	a0,3
ffffffffc0200f74:	4a9000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200f78:	8c2a                	mv	s8,a0
ffffffffc0200f7a:	46050363          	beqz	a0,ffffffffc02013e0 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0200f7e:	4505                	li	a0,1
ffffffffc0200f80:	49d000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200f84:	42051e63          	bnez	a0,ffffffffc02013c0 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0200f88:	418a1c63          	bne	s4,s8,ffffffffc02013a0 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200f8c:	4585                	li	a1,1
ffffffffc0200f8e:	854e                	mv	a0,s3
ffffffffc0200f90:	4cb000ef          	jal	ra,ffffffffc0201c5a <free_pages>
    free_pages(p1, 3);
ffffffffc0200f94:	458d                	li	a1,3
ffffffffc0200f96:	8552                	mv	a0,s4
ffffffffc0200f98:	4c3000ef          	jal	ra,ffffffffc0201c5a <free_pages>
ffffffffc0200f9c:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200fa0:	04098c13          	addi	s8,s3,64
ffffffffc0200fa4:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200fa6:	8b85                	andi	a5,a5,1
ffffffffc0200fa8:	3c078c63          	beqz	a5,ffffffffc0201380 <default_check+0x602>
ffffffffc0200fac:	0109a703          	lw	a4,16(s3)
ffffffffc0200fb0:	4785                	li	a5,1
ffffffffc0200fb2:	3cf71763          	bne	a4,a5,ffffffffc0201380 <default_check+0x602>
ffffffffc0200fb6:	008a3783          	ld	a5,8(s4)
ffffffffc0200fba:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200fbc:	8b85                	andi	a5,a5,1
ffffffffc0200fbe:	3a078163          	beqz	a5,ffffffffc0201360 <default_check+0x5e2>
ffffffffc0200fc2:	010a2703          	lw	a4,16(s4)
ffffffffc0200fc6:	478d                	li	a5,3
ffffffffc0200fc8:	38f71c63          	bne	a4,a5,ffffffffc0201360 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200fcc:	4505                	li	a0,1
ffffffffc0200fce:	44f000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200fd2:	36a99763          	bne	s3,a0,ffffffffc0201340 <default_check+0x5c2>
    free_page(p0);
ffffffffc0200fd6:	4585                	li	a1,1
ffffffffc0200fd8:	483000ef          	jal	ra,ffffffffc0201c5a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200fdc:	4509                	li	a0,2
ffffffffc0200fde:	43f000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200fe2:	32aa1f63          	bne	s4,a0,ffffffffc0201320 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0200fe6:	4589                	li	a1,2
ffffffffc0200fe8:	473000ef          	jal	ra,ffffffffc0201c5a <free_pages>
    free_page(p2);
ffffffffc0200fec:	4585                	li	a1,1
ffffffffc0200fee:	8562                	mv	a0,s8
ffffffffc0200ff0:	46b000ef          	jal	ra,ffffffffc0201c5a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200ff4:	4515                	li	a0,5
ffffffffc0200ff6:	427000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0200ffa:	89aa                	mv	s3,a0
ffffffffc0200ffc:	48050263          	beqz	a0,ffffffffc0201480 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201000:	4505                	li	a0,1
ffffffffc0201002:	41b000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
ffffffffc0201006:	2c051d63          	bnez	a0,ffffffffc02012e0 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc020100a:	481c                	lw	a5,16(s0)
ffffffffc020100c:	2a079a63          	bnez	a5,ffffffffc02012c0 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201010:	4595                	li	a1,5
ffffffffc0201012:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201014:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201018:	01643023          	sd	s6,0(s0)
ffffffffc020101c:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201020:	43b000ef          	jal	ra,ffffffffc0201c5a <free_pages>
    return listelm->next;
ffffffffc0201024:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201026:	00878963          	beq	a5,s0,ffffffffc0201038 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020102a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020102e:	679c                	ld	a5,8(a5)
ffffffffc0201030:	397d                	addiw	s2,s2,-1
ffffffffc0201032:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201034:	fe879be3          	bne	a5,s0,ffffffffc020102a <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201038:	26091463          	bnez	s2,ffffffffc02012a0 <default_check+0x522>
    assert(total == 0);
ffffffffc020103c:	46049263          	bnez	s1,ffffffffc02014a0 <default_check+0x722>
}
ffffffffc0201040:	60a6                	ld	ra,72(sp)
ffffffffc0201042:	6406                	ld	s0,64(sp)
ffffffffc0201044:	74e2                	ld	s1,56(sp)
ffffffffc0201046:	7942                	ld	s2,48(sp)
ffffffffc0201048:	79a2                	ld	s3,40(sp)
ffffffffc020104a:	7a02                	ld	s4,32(sp)
ffffffffc020104c:	6ae2                	ld	s5,24(sp)
ffffffffc020104e:	6b42                	ld	s6,16(sp)
ffffffffc0201050:	6ba2                	ld	s7,8(sp)
ffffffffc0201052:	6c02                	ld	s8,0(sp)
ffffffffc0201054:	6161                	addi	sp,sp,80
ffffffffc0201056:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201058:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020105a:	4481                	li	s1,0
ffffffffc020105c:	4901                	li	s2,0
ffffffffc020105e:	b38d                	j	ffffffffc0200dc0 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201060:	00004697          	auipc	a3,0x4
ffffffffc0201064:	86068693          	addi	a3,a3,-1952 # ffffffffc02048c0 <commands+0x7f8>
ffffffffc0201068:	00004617          	auipc	a2,0x4
ffffffffc020106c:	86860613          	addi	a2,a2,-1944 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201070:	0f000593          	li	a1,240
ffffffffc0201074:	00004517          	auipc	a0,0x4
ffffffffc0201078:	87450513          	addi	a0,a0,-1932 # ffffffffc02048e8 <commands+0x820>
ffffffffc020107c:	bdeff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201080:	00004697          	auipc	a3,0x4
ffffffffc0201084:	90068693          	addi	a3,a3,-1792 # ffffffffc0204980 <commands+0x8b8>
ffffffffc0201088:	00004617          	auipc	a2,0x4
ffffffffc020108c:	84860613          	addi	a2,a2,-1976 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201090:	0bd00593          	li	a1,189
ffffffffc0201094:	00004517          	auipc	a0,0x4
ffffffffc0201098:	85450513          	addi	a0,a0,-1964 # ffffffffc02048e8 <commands+0x820>
ffffffffc020109c:	bbeff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02010a0:	00004697          	auipc	a3,0x4
ffffffffc02010a4:	90868693          	addi	a3,a3,-1784 # ffffffffc02049a8 <commands+0x8e0>
ffffffffc02010a8:	00004617          	auipc	a2,0x4
ffffffffc02010ac:	82860613          	addi	a2,a2,-2008 # ffffffffc02048d0 <commands+0x808>
ffffffffc02010b0:	0be00593          	li	a1,190
ffffffffc02010b4:	00004517          	auipc	a0,0x4
ffffffffc02010b8:	83450513          	addi	a0,a0,-1996 # ffffffffc02048e8 <commands+0x820>
ffffffffc02010bc:	b9eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010c0:	00004697          	auipc	a3,0x4
ffffffffc02010c4:	92868693          	addi	a3,a3,-1752 # ffffffffc02049e8 <commands+0x920>
ffffffffc02010c8:	00004617          	auipc	a2,0x4
ffffffffc02010cc:	80860613          	addi	a2,a2,-2040 # ffffffffc02048d0 <commands+0x808>
ffffffffc02010d0:	0c000593          	li	a1,192
ffffffffc02010d4:	00004517          	auipc	a0,0x4
ffffffffc02010d8:	81450513          	addi	a0,a0,-2028 # ffffffffc02048e8 <commands+0x820>
ffffffffc02010dc:	b7eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!list_empty(&free_list));
ffffffffc02010e0:	00004697          	auipc	a3,0x4
ffffffffc02010e4:	99068693          	addi	a3,a3,-1648 # ffffffffc0204a70 <commands+0x9a8>
ffffffffc02010e8:	00003617          	auipc	a2,0x3
ffffffffc02010ec:	7e860613          	addi	a2,a2,2024 # ffffffffc02048d0 <commands+0x808>
ffffffffc02010f0:	0d900593          	li	a1,217
ffffffffc02010f4:	00003517          	auipc	a0,0x3
ffffffffc02010f8:	7f450513          	addi	a0,a0,2036 # ffffffffc02048e8 <commands+0x820>
ffffffffc02010fc:	b5eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201100:	00004697          	auipc	a3,0x4
ffffffffc0201104:	82068693          	addi	a3,a3,-2016 # ffffffffc0204920 <commands+0x858>
ffffffffc0201108:	00003617          	auipc	a2,0x3
ffffffffc020110c:	7c860613          	addi	a2,a2,1992 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201110:	0d200593          	li	a1,210
ffffffffc0201114:	00003517          	auipc	a0,0x3
ffffffffc0201118:	7d450513          	addi	a0,a0,2004 # ffffffffc02048e8 <commands+0x820>
ffffffffc020111c:	b3eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 3);
ffffffffc0201120:	00004697          	auipc	a3,0x4
ffffffffc0201124:	94068693          	addi	a3,a3,-1728 # ffffffffc0204a60 <commands+0x998>
ffffffffc0201128:	00003617          	auipc	a2,0x3
ffffffffc020112c:	7a860613          	addi	a2,a2,1960 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201130:	0d000593          	li	a1,208
ffffffffc0201134:	00003517          	auipc	a0,0x3
ffffffffc0201138:	7b450513          	addi	a0,a0,1972 # ffffffffc02048e8 <commands+0x820>
ffffffffc020113c:	b1eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201140:	00004697          	auipc	a3,0x4
ffffffffc0201144:	90868693          	addi	a3,a3,-1784 # ffffffffc0204a48 <commands+0x980>
ffffffffc0201148:	00003617          	auipc	a2,0x3
ffffffffc020114c:	78860613          	addi	a2,a2,1928 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201150:	0cb00593          	li	a1,203
ffffffffc0201154:	00003517          	auipc	a0,0x3
ffffffffc0201158:	79450513          	addi	a0,a0,1940 # ffffffffc02048e8 <commands+0x820>
ffffffffc020115c:	afeff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201160:	00004697          	auipc	a3,0x4
ffffffffc0201164:	8c868693          	addi	a3,a3,-1848 # ffffffffc0204a28 <commands+0x960>
ffffffffc0201168:	00003617          	auipc	a2,0x3
ffffffffc020116c:	76860613          	addi	a2,a2,1896 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201170:	0c200593          	li	a1,194
ffffffffc0201174:	00003517          	auipc	a0,0x3
ffffffffc0201178:	77450513          	addi	a0,a0,1908 # ffffffffc02048e8 <commands+0x820>
ffffffffc020117c:	adeff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != NULL);
ffffffffc0201180:	00004697          	auipc	a3,0x4
ffffffffc0201184:	93868693          	addi	a3,a3,-1736 # ffffffffc0204ab8 <commands+0x9f0>
ffffffffc0201188:	00003617          	auipc	a2,0x3
ffffffffc020118c:	74860613          	addi	a2,a2,1864 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201190:	0f800593          	li	a1,248
ffffffffc0201194:	00003517          	auipc	a0,0x3
ffffffffc0201198:	75450513          	addi	a0,a0,1876 # ffffffffc02048e8 <commands+0x820>
ffffffffc020119c:	abeff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc02011a0:	00004697          	auipc	a3,0x4
ffffffffc02011a4:	90868693          	addi	a3,a3,-1784 # ffffffffc0204aa8 <commands+0x9e0>
ffffffffc02011a8:	00003617          	auipc	a2,0x3
ffffffffc02011ac:	72860613          	addi	a2,a2,1832 # ffffffffc02048d0 <commands+0x808>
ffffffffc02011b0:	0df00593          	li	a1,223
ffffffffc02011b4:	00003517          	auipc	a0,0x3
ffffffffc02011b8:	73450513          	addi	a0,a0,1844 # ffffffffc02048e8 <commands+0x820>
ffffffffc02011bc:	a9eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011c0:	00004697          	auipc	a3,0x4
ffffffffc02011c4:	88868693          	addi	a3,a3,-1912 # ffffffffc0204a48 <commands+0x980>
ffffffffc02011c8:	00003617          	auipc	a2,0x3
ffffffffc02011cc:	70860613          	addi	a2,a2,1800 # ffffffffc02048d0 <commands+0x808>
ffffffffc02011d0:	0dd00593          	li	a1,221
ffffffffc02011d4:	00003517          	auipc	a0,0x3
ffffffffc02011d8:	71450513          	addi	a0,a0,1812 # ffffffffc02048e8 <commands+0x820>
ffffffffc02011dc:	a7eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02011e0:	00004697          	auipc	a3,0x4
ffffffffc02011e4:	8a868693          	addi	a3,a3,-1880 # ffffffffc0204a88 <commands+0x9c0>
ffffffffc02011e8:	00003617          	auipc	a2,0x3
ffffffffc02011ec:	6e860613          	addi	a2,a2,1768 # ffffffffc02048d0 <commands+0x808>
ffffffffc02011f0:	0dc00593          	li	a1,220
ffffffffc02011f4:	00003517          	auipc	a0,0x3
ffffffffc02011f8:	6f450513          	addi	a0,a0,1780 # ffffffffc02048e8 <commands+0x820>
ffffffffc02011fc:	a5eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201200:	00003697          	auipc	a3,0x3
ffffffffc0201204:	72068693          	addi	a3,a3,1824 # ffffffffc0204920 <commands+0x858>
ffffffffc0201208:	00003617          	auipc	a2,0x3
ffffffffc020120c:	6c860613          	addi	a2,a2,1736 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201210:	0b900593          	li	a1,185
ffffffffc0201214:	00003517          	auipc	a0,0x3
ffffffffc0201218:	6d450513          	addi	a0,a0,1748 # ffffffffc02048e8 <commands+0x820>
ffffffffc020121c:	a3eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201220:	00004697          	auipc	a3,0x4
ffffffffc0201224:	82868693          	addi	a3,a3,-2008 # ffffffffc0204a48 <commands+0x980>
ffffffffc0201228:	00003617          	auipc	a2,0x3
ffffffffc020122c:	6a860613          	addi	a2,a2,1704 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201230:	0d600593          	li	a1,214
ffffffffc0201234:	00003517          	auipc	a0,0x3
ffffffffc0201238:	6b450513          	addi	a0,a0,1716 # ffffffffc02048e8 <commands+0x820>
ffffffffc020123c:	a1eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201240:	00003697          	auipc	a3,0x3
ffffffffc0201244:	72068693          	addi	a3,a3,1824 # ffffffffc0204960 <commands+0x898>
ffffffffc0201248:	00003617          	auipc	a2,0x3
ffffffffc020124c:	68860613          	addi	a2,a2,1672 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201250:	0d400593          	li	a1,212
ffffffffc0201254:	00003517          	auipc	a0,0x3
ffffffffc0201258:	69450513          	addi	a0,a0,1684 # ffffffffc02048e8 <commands+0x820>
ffffffffc020125c:	9feff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201260:	00003697          	auipc	a3,0x3
ffffffffc0201264:	6e068693          	addi	a3,a3,1760 # ffffffffc0204940 <commands+0x878>
ffffffffc0201268:	00003617          	auipc	a2,0x3
ffffffffc020126c:	66860613          	addi	a2,a2,1640 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201270:	0d300593          	li	a1,211
ffffffffc0201274:	00003517          	auipc	a0,0x3
ffffffffc0201278:	67450513          	addi	a0,a0,1652 # ffffffffc02048e8 <commands+0x820>
ffffffffc020127c:	9deff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201280:	00003697          	auipc	a3,0x3
ffffffffc0201284:	6e068693          	addi	a3,a3,1760 # ffffffffc0204960 <commands+0x898>
ffffffffc0201288:	00003617          	auipc	a2,0x3
ffffffffc020128c:	64860613          	addi	a2,a2,1608 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201290:	0bb00593          	li	a1,187
ffffffffc0201294:	00003517          	auipc	a0,0x3
ffffffffc0201298:	65450513          	addi	a0,a0,1620 # ffffffffc02048e8 <commands+0x820>
ffffffffc020129c:	9beff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(count == 0);
ffffffffc02012a0:	00004697          	auipc	a3,0x4
ffffffffc02012a4:	96868693          	addi	a3,a3,-1688 # ffffffffc0204c08 <commands+0xb40>
ffffffffc02012a8:	00003617          	auipc	a2,0x3
ffffffffc02012ac:	62860613          	addi	a2,a2,1576 # ffffffffc02048d0 <commands+0x808>
ffffffffc02012b0:	12500593          	li	a1,293
ffffffffc02012b4:	00003517          	auipc	a0,0x3
ffffffffc02012b8:	63450513          	addi	a0,a0,1588 # ffffffffc02048e8 <commands+0x820>
ffffffffc02012bc:	99eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc02012c0:	00003697          	auipc	a3,0x3
ffffffffc02012c4:	7e868693          	addi	a3,a3,2024 # ffffffffc0204aa8 <commands+0x9e0>
ffffffffc02012c8:	00003617          	auipc	a2,0x3
ffffffffc02012cc:	60860613          	addi	a2,a2,1544 # ffffffffc02048d0 <commands+0x808>
ffffffffc02012d0:	11a00593          	li	a1,282
ffffffffc02012d4:	00003517          	auipc	a0,0x3
ffffffffc02012d8:	61450513          	addi	a0,a0,1556 # ffffffffc02048e8 <commands+0x820>
ffffffffc02012dc:	97eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012e0:	00003697          	auipc	a3,0x3
ffffffffc02012e4:	76868693          	addi	a3,a3,1896 # ffffffffc0204a48 <commands+0x980>
ffffffffc02012e8:	00003617          	auipc	a2,0x3
ffffffffc02012ec:	5e860613          	addi	a2,a2,1512 # ffffffffc02048d0 <commands+0x808>
ffffffffc02012f0:	11800593          	li	a1,280
ffffffffc02012f4:	00003517          	auipc	a0,0x3
ffffffffc02012f8:	5f450513          	addi	a0,a0,1524 # ffffffffc02048e8 <commands+0x820>
ffffffffc02012fc:	95eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201300:	00003697          	auipc	a3,0x3
ffffffffc0201304:	70868693          	addi	a3,a3,1800 # ffffffffc0204a08 <commands+0x940>
ffffffffc0201308:	00003617          	auipc	a2,0x3
ffffffffc020130c:	5c860613          	addi	a2,a2,1480 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201310:	0c100593          	li	a1,193
ffffffffc0201314:	00003517          	auipc	a0,0x3
ffffffffc0201318:	5d450513          	addi	a0,a0,1492 # ffffffffc02048e8 <commands+0x820>
ffffffffc020131c:	93eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201320:	00004697          	auipc	a3,0x4
ffffffffc0201324:	8a868693          	addi	a3,a3,-1880 # ffffffffc0204bc8 <commands+0xb00>
ffffffffc0201328:	00003617          	auipc	a2,0x3
ffffffffc020132c:	5a860613          	addi	a2,a2,1448 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201330:	11200593          	li	a1,274
ffffffffc0201334:	00003517          	auipc	a0,0x3
ffffffffc0201338:	5b450513          	addi	a0,a0,1460 # ffffffffc02048e8 <commands+0x820>
ffffffffc020133c:	91eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201340:	00004697          	auipc	a3,0x4
ffffffffc0201344:	86868693          	addi	a3,a3,-1944 # ffffffffc0204ba8 <commands+0xae0>
ffffffffc0201348:	00003617          	auipc	a2,0x3
ffffffffc020134c:	58860613          	addi	a2,a2,1416 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201350:	11000593          	li	a1,272
ffffffffc0201354:	00003517          	auipc	a0,0x3
ffffffffc0201358:	59450513          	addi	a0,a0,1428 # ffffffffc02048e8 <commands+0x820>
ffffffffc020135c:	8feff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201360:	00004697          	auipc	a3,0x4
ffffffffc0201364:	82068693          	addi	a3,a3,-2016 # ffffffffc0204b80 <commands+0xab8>
ffffffffc0201368:	00003617          	auipc	a2,0x3
ffffffffc020136c:	56860613          	addi	a2,a2,1384 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201370:	10e00593          	li	a1,270
ffffffffc0201374:	00003517          	auipc	a0,0x3
ffffffffc0201378:	57450513          	addi	a0,a0,1396 # ffffffffc02048e8 <commands+0x820>
ffffffffc020137c:	8deff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201380:	00003697          	auipc	a3,0x3
ffffffffc0201384:	7d868693          	addi	a3,a3,2008 # ffffffffc0204b58 <commands+0xa90>
ffffffffc0201388:	00003617          	auipc	a2,0x3
ffffffffc020138c:	54860613          	addi	a2,a2,1352 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201390:	10d00593          	li	a1,269
ffffffffc0201394:	00003517          	auipc	a0,0x3
ffffffffc0201398:	55450513          	addi	a0,a0,1364 # ffffffffc02048e8 <commands+0x820>
ffffffffc020139c:	8beff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 + 2 == p1);
ffffffffc02013a0:	00003697          	auipc	a3,0x3
ffffffffc02013a4:	7a868693          	addi	a3,a3,1960 # ffffffffc0204b48 <commands+0xa80>
ffffffffc02013a8:	00003617          	auipc	a2,0x3
ffffffffc02013ac:	52860613          	addi	a2,a2,1320 # ffffffffc02048d0 <commands+0x808>
ffffffffc02013b0:	10800593          	li	a1,264
ffffffffc02013b4:	00003517          	auipc	a0,0x3
ffffffffc02013b8:	53450513          	addi	a0,a0,1332 # ffffffffc02048e8 <commands+0x820>
ffffffffc02013bc:	89eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013c0:	00003697          	auipc	a3,0x3
ffffffffc02013c4:	68868693          	addi	a3,a3,1672 # ffffffffc0204a48 <commands+0x980>
ffffffffc02013c8:	00003617          	auipc	a2,0x3
ffffffffc02013cc:	50860613          	addi	a2,a2,1288 # ffffffffc02048d0 <commands+0x808>
ffffffffc02013d0:	10700593          	li	a1,263
ffffffffc02013d4:	00003517          	auipc	a0,0x3
ffffffffc02013d8:	51450513          	addi	a0,a0,1300 # ffffffffc02048e8 <commands+0x820>
ffffffffc02013dc:	87eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02013e0:	00003697          	auipc	a3,0x3
ffffffffc02013e4:	74868693          	addi	a3,a3,1864 # ffffffffc0204b28 <commands+0xa60>
ffffffffc02013e8:	00003617          	auipc	a2,0x3
ffffffffc02013ec:	4e860613          	addi	a2,a2,1256 # ffffffffc02048d0 <commands+0x808>
ffffffffc02013f0:	10600593          	li	a1,262
ffffffffc02013f4:	00003517          	auipc	a0,0x3
ffffffffc02013f8:	4f450513          	addi	a0,a0,1268 # ffffffffc02048e8 <commands+0x820>
ffffffffc02013fc:	85eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201400:	00003697          	auipc	a3,0x3
ffffffffc0201404:	6f868693          	addi	a3,a3,1784 # ffffffffc0204af8 <commands+0xa30>
ffffffffc0201408:	00003617          	auipc	a2,0x3
ffffffffc020140c:	4c860613          	addi	a2,a2,1224 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201410:	10500593          	li	a1,261
ffffffffc0201414:	00003517          	auipc	a0,0x3
ffffffffc0201418:	4d450513          	addi	a0,a0,1236 # ffffffffc02048e8 <commands+0x820>
ffffffffc020141c:	83eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201420:	00003697          	auipc	a3,0x3
ffffffffc0201424:	6c068693          	addi	a3,a3,1728 # ffffffffc0204ae0 <commands+0xa18>
ffffffffc0201428:	00003617          	auipc	a2,0x3
ffffffffc020142c:	4a860613          	addi	a2,a2,1192 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201430:	10400593          	li	a1,260
ffffffffc0201434:	00003517          	auipc	a0,0x3
ffffffffc0201438:	4b450513          	addi	a0,a0,1204 # ffffffffc02048e8 <commands+0x820>
ffffffffc020143c:	81eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201440:	00003697          	auipc	a3,0x3
ffffffffc0201444:	60868693          	addi	a3,a3,1544 # ffffffffc0204a48 <commands+0x980>
ffffffffc0201448:	00003617          	auipc	a2,0x3
ffffffffc020144c:	48860613          	addi	a2,a2,1160 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201450:	0fe00593          	li	a1,254
ffffffffc0201454:	00003517          	auipc	a0,0x3
ffffffffc0201458:	49450513          	addi	a0,a0,1172 # ffffffffc02048e8 <commands+0x820>
ffffffffc020145c:	ffffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!PageProperty(p0));
ffffffffc0201460:	00003697          	auipc	a3,0x3
ffffffffc0201464:	66868693          	addi	a3,a3,1640 # ffffffffc0204ac8 <commands+0xa00>
ffffffffc0201468:	00003617          	auipc	a2,0x3
ffffffffc020146c:	46860613          	addi	a2,a2,1128 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201470:	0f900593          	li	a1,249
ffffffffc0201474:	00003517          	auipc	a0,0x3
ffffffffc0201478:	47450513          	addi	a0,a0,1140 # ffffffffc02048e8 <commands+0x820>
ffffffffc020147c:	fdffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201480:	00003697          	auipc	a3,0x3
ffffffffc0201484:	76868693          	addi	a3,a3,1896 # ffffffffc0204be8 <commands+0xb20>
ffffffffc0201488:	00003617          	auipc	a2,0x3
ffffffffc020148c:	44860613          	addi	a2,a2,1096 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201490:	11700593          	li	a1,279
ffffffffc0201494:	00003517          	auipc	a0,0x3
ffffffffc0201498:	45450513          	addi	a0,a0,1108 # ffffffffc02048e8 <commands+0x820>
ffffffffc020149c:	fbffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == 0);
ffffffffc02014a0:	00003697          	auipc	a3,0x3
ffffffffc02014a4:	77868693          	addi	a3,a3,1912 # ffffffffc0204c18 <commands+0xb50>
ffffffffc02014a8:	00003617          	auipc	a2,0x3
ffffffffc02014ac:	42860613          	addi	a2,a2,1064 # ffffffffc02048d0 <commands+0x808>
ffffffffc02014b0:	12600593          	li	a1,294
ffffffffc02014b4:	00003517          	auipc	a0,0x3
ffffffffc02014b8:	43450513          	addi	a0,a0,1076 # ffffffffc02048e8 <commands+0x820>
ffffffffc02014bc:	f9ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == nr_free_pages());
ffffffffc02014c0:	00003697          	auipc	a3,0x3
ffffffffc02014c4:	44068693          	addi	a3,a3,1088 # ffffffffc0204900 <commands+0x838>
ffffffffc02014c8:	00003617          	auipc	a2,0x3
ffffffffc02014cc:	40860613          	addi	a2,a2,1032 # ffffffffc02048d0 <commands+0x808>
ffffffffc02014d0:	0f300593          	li	a1,243
ffffffffc02014d4:	00003517          	auipc	a0,0x3
ffffffffc02014d8:	41450513          	addi	a0,a0,1044 # ffffffffc02048e8 <commands+0x820>
ffffffffc02014dc:	f7ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02014e0:	00003697          	auipc	a3,0x3
ffffffffc02014e4:	46068693          	addi	a3,a3,1120 # ffffffffc0204940 <commands+0x878>
ffffffffc02014e8:	00003617          	auipc	a2,0x3
ffffffffc02014ec:	3e860613          	addi	a2,a2,1000 # ffffffffc02048d0 <commands+0x808>
ffffffffc02014f0:	0ba00593          	li	a1,186
ffffffffc02014f4:	00003517          	auipc	a0,0x3
ffffffffc02014f8:	3f450513          	addi	a0,a0,1012 # ffffffffc02048e8 <commands+0x820>
ffffffffc02014fc:	f5ffe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201500 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201500:	1141                	addi	sp,sp,-16
ffffffffc0201502:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201504:	14058463          	beqz	a1,ffffffffc020164c <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc0201508:	00659693          	slli	a3,a1,0x6
ffffffffc020150c:	96aa                	add	a3,a3,a0
ffffffffc020150e:	87aa                	mv	a5,a0
ffffffffc0201510:	02d50263          	beq	a0,a3,ffffffffc0201534 <default_free_pages+0x34>
ffffffffc0201514:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201516:	8b05                	andi	a4,a4,1
ffffffffc0201518:	10071a63          	bnez	a4,ffffffffc020162c <default_free_pages+0x12c>
ffffffffc020151c:	6798                	ld	a4,8(a5)
ffffffffc020151e:	8b09                	andi	a4,a4,2
ffffffffc0201520:	10071663          	bnez	a4,ffffffffc020162c <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201524:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201528:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020152c:	04078793          	addi	a5,a5,64
ffffffffc0201530:	fed792e3          	bne	a5,a3,ffffffffc0201514 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201534:	2581                	sext.w	a1,a1
ffffffffc0201536:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201538:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020153c:	4789                	li	a5,2
ffffffffc020153e:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201542:	00008697          	auipc	a3,0x8
ffffffffc0201546:	eee68693          	addi	a3,a3,-274 # ffffffffc0209430 <free_area>
ffffffffc020154a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020154c:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020154e:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201552:	9db9                	addw	a1,a1,a4
ffffffffc0201554:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201556:	0ad78463          	beq	a5,a3,ffffffffc02015fe <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc020155a:	fe878713          	addi	a4,a5,-24
ffffffffc020155e:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201562:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201564:	00e56a63          	bltu	a0,a4,ffffffffc0201578 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201568:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020156a:	04d70c63          	beq	a4,a3,ffffffffc02015c2 <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc020156e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201570:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201574:	fee57ae3          	bgeu	a0,a4,ffffffffc0201568 <default_free_pages+0x68>
ffffffffc0201578:	c199                	beqz	a1,ffffffffc020157e <default_free_pages+0x7e>
ffffffffc020157a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020157e:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201580:	e390                	sd	a2,0(a5)
ffffffffc0201582:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201584:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201586:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201588:	00d70d63          	beq	a4,a3,ffffffffc02015a2 <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc020158c:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201590:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0201594:	02059813          	slli	a6,a1,0x20
ffffffffc0201598:	01a85793          	srli	a5,a6,0x1a
ffffffffc020159c:	97b2                	add	a5,a5,a2
ffffffffc020159e:	02f50c63          	beq	a0,a5,ffffffffc02015d6 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02015a2:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc02015a4:	00d78c63          	beq	a5,a3,ffffffffc02015bc <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc02015a8:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02015aa:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc02015ae:	02061593          	slli	a1,a2,0x20
ffffffffc02015b2:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02015b6:	972a                	add	a4,a4,a0
ffffffffc02015b8:	04e68a63          	beq	a3,a4,ffffffffc020160c <default_free_pages+0x10c>
}
ffffffffc02015bc:	60a2                	ld	ra,8(sp)
ffffffffc02015be:	0141                	addi	sp,sp,16
ffffffffc02015c0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02015c2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015c4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02015c6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02015c8:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015ca:	02d70763          	beq	a4,a3,ffffffffc02015f8 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc02015ce:	8832                	mv	a6,a2
ffffffffc02015d0:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02015d2:	87ba                	mv	a5,a4
ffffffffc02015d4:	bf71                	j	ffffffffc0201570 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02015d6:	491c                	lw	a5,16(a0)
ffffffffc02015d8:	9dbd                	addw	a1,a1,a5
ffffffffc02015da:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02015de:	57f5                	li	a5,-3
ffffffffc02015e0:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015e4:	01853803          	ld	a6,24(a0)
ffffffffc02015e8:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc02015ea:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02015ec:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc02015f0:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc02015f2:	0105b023          	sd	a6,0(a1)
ffffffffc02015f6:	b77d                	j	ffffffffc02015a4 <default_free_pages+0xa4>
ffffffffc02015f8:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015fa:	873e                	mv	a4,a5
ffffffffc02015fc:	bf41                	j	ffffffffc020158c <default_free_pages+0x8c>
}
ffffffffc02015fe:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201600:	e390                	sd	a2,0(a5)
ffffffffc0201602:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201604:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201606:	ed1c                	sd	a5,24(a0)
ffffffffc0201608:	0141                	addi	sp,sp,16
ffffffffc020160a:	8082                	ret
            base->property += p->property;
ffffffffc020160c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201610:	ff078693          	addi	a3,a5,-16
ffffffffc0201614:	9e39                	addw	a2,a2,a4
ffffffffc0201616:	c910                	sw	a2,16(a0)
ffffffffc0201618:	5775                	li	a4,-3
ffffffffc020161a:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020161e:	6398                	ld	a4,0(a5)
ffffffffc0201620:	679c                	ld	a5,8(a5)
}
ffffffffc0201622:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201624:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201626:	e398                	sd	a4,0(a5)
ffffffffc0201628:	0141                	addi	sp,sp,16
ffffffffc020162a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020162c:	00003697          	auipc	a3,0x3
ffffffffc0201630:	60468693          	addi	a3,a3,1540 # ffffffffc0204c30 <commands+0xb68>
ffffffffc0201634:	00003617          	auipc	a2,0x3
ffffffffc0201638:	29c60613          	addi	a2,a2,668 # ffffffffc02048d0 <commands+0x808>
ffffffffc020163c:	08300593          	li	a1,131
ffffffffc0201640:	00003517          	auipc	a0,0x3
ffffffffc0201644:	2a850513          	addi	a0,a0,680 # ffffffffc02048e8 <commands+0x820>
ffffffffc0201648:	e13fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc020164c:	00003697          	auipc	a3,0x3
ffffffffc0201650:	5dc68693          	addi	a3,a3,1500 # ffffffffc0204c28 <commands+0xb60>
ffffffffc0201654:	00003617          	auipc	a2,0x3
ffffffffc0201658:	27c60613          	addi	a2,a2,636 # ffffffffc02048d0 <commands+0x808>
ffffffffc020165c:	08000593          	li	a1,128
ffffffffc0201660:	00003517          	auipc	a0,0x3
ffffffffc0201664:	28850513          	addi	a0,a0,648 # ffffffffc02048e8 <commands+0x820>
ffffffffc0201668:	df3fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc020166c <default_alloc_pages>:
    assert(n > 0);
ffffffffc020166c:	c941                	beqz	a0,ffffffffc02016fc <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc020166e:	00008597          	auipc	a1,0x8
ffffffffc0201672:	dc258593          	addi	a1,a1,-574 # ffffffffc0209430 <free_area>
ffffffffc0201676:	0105a803          	lw	a6,16(a1)
ffffffffc020167a:	872a                	mv	a4,a0
ffffffffc020167c:	02081793          	slli	a5,a6,0x20
ffffffffc0201680:	9381                	srli	a5,a5,0x20
ffffffffc0201682:	00a7ee63          	bltu	a5,a0,ffffffffc020169e <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201686:	87ae                	mv	a5,a1
ffffffffc0201688:	a801                	j	ffffffffc0201698 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc020168a:	ff87a683          	lw	a3,-8(a5)
ffffffffc020168e:	02069613          	slli	a2,a3,0x20
ffffffffc0201692:	9201                	srli	a2,a2,0x20
ffffffffc0201694:	00e67763          	bgeu	a2,a4,ffffffffc02016a2 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201698:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020169a:	feb798e3          	bne	a5,a1,ffffffffc020168a <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020169e:	4501                	li	a0,0
}
ffffffffc02016a0:	8082                	ret
    return listelm->prev;
ffffffffc02016a2:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02016a6:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02016aa:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02016ae:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02016b2:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02016b6:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02016ba:	02c77863          	bgeu	a4,a2,ffffffffc02016ea <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02016be:	071a                	slli	a4,a4,0x6
ffffffffc02016c0:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02016c2:	41c686bb          	subw	a3,a3,t3
ffffffffc02016c6:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016c8:	00870613          	addi	a2,a4,8
ffffffffc02016cc:	4689                	li	a3,2
ffffffffc02016ce:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02016d2:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02016d6:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc02016da:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02016de:	e290                	sd	a2,0(a3)
ffffffffc02016e0:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02016e4:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc02016e6:	01173c23          	sd	a7,24(a4)
ffffffffc02016ea:	41c8083b          	subw	a6,a6,t3
ffffffffc02016ee:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02016f2:	5775                	li	a4,-3
ffffffffc02016f4:	17c1                	addi	a5,a5,-16
ffffffffc02016f6:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02016fa:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02016fc:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02016fe:	00003697          	auipc	a3,0x3
ffffffffc0201702:	52a68693          	addi	a3,a3,1322 # ffffffffc0204c28 <commands+0xb60>
ffffffffc0201706:	00003617          	auipc	a2,0x3
ffffffffc020170a:	1ca60613          	addi	a2,a2,458 # ffffffffc02048d0 <commands+0x808>
ffffffffc020170e:	06200593          	li	a1,98
ffffffffc0201712:	00003517          	auipc	a0,0x3
ffffffffc0201716:	1d650513          	addi	a0,a0,470 # ffffffffc02048e8 <commands+0x820>
default_alloc_pages(size_t n) {
ffffffffc020171a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020171c:	d3ffe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201720 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201720:	1141                	addi	sp,sp,-16
ffffffffc0201722:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201724:	c5f1                	beqz	a1,ffffffffc02017f0 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0201726:	00659693          	slli	a3,a1,0x6
ffffffffc020172a:	96aa                	add	a3,a3,a0
ffffffffc020172c:	87aa                	mv	a5,a0
ffffffffc020172e:	00d50f63          	beq	a0,a3,ffffffffc020174c <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201732:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201734:	8b05                	andi	a4,a4,1
ffffffffc0201736:	cf49                	beqz	a4,ffffffffc02017d0 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201738:	0007a823          	sw	zero,16(a5)
ffffffffc020173c:	0007b423          	sd	zero,8(a5)
ffffffffc0201740:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201744:	04078793          	addi	a5,a5,64
ffffffffc0201748:	fed795e3          	bne	a5,a3,ffffffffc0201732 <default_init_memmap+0x12>
    base->property = n;
ffffffffc020174c:	2581                	sext.w	a1,a1
ffffffffc020174e:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201750:	4789                	li	a5,2
ffffffffc0201752:	00850713          	addi	a4,a0,8
ffffffffc0201756:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020175a:	00008697          	auipc	a3,0x8
ffffffffc020175e:	cd668693          	addi	a3,a3,-810 # ffffffffc0209430 <free_area>
ffffffffc0201762:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201764:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201766:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020176a:	9db9                	addw	a1,a1,a4
ffffffffc020176c:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020176e:	04d78a63          	beq	a5,a3,ffffffffc02017c2 <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc0201772:	fe878713          	addi	a4,a5,-24
ffffffffc0201776:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020177a:	4581                	li	a1,0
            if (base < page) {
ffffffffc020177c:	00e56a63          	bltu	a0,a4,ffffffffc0201790 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201780:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201782:	02d70263          	beq	a4,a3,ffffffffc02017a6 <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc0201786:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201788:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020178c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201780 <default_init_memmap+0x60>
ffffffffc0201790:	c199                	beqz	a1,ffffffffc0201796 <default_init_memmap+0x76>
ffffffffc0201792:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201796:	6398                	ld	a4,0(a5)
}
ffffffffc0201798:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020179a:	e390                	sd	a2,0(a5)
ffffffffc020179c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020179e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017a0:	ed18                	sd	a4,24(a0)
ffffffffc02017a2:	0141                	addi	sp,sp,16
ffffffffc02017a4:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017a6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017a8:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02017aa:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02017ac:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02017ae:	00d70663          	beq	a4,a3,ffffffffc02017ba <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc02017b2:	8832                	mv	a6,a2
ffffffffc02017b4:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02017b6:	87ba                	mv	a5,a4
ffffffffc02017b8:	bfc1                	j	ffffffffc0201788 <default_init_memmap+0x68>
}
ffffffffc02017ba:	60a2                	ld	ra,8(sp)
ffffffffc02017bc:	e290                	sd	a2,0(a3)
ffffffffc02017be:	0141                	addi	sp,sp,16
ffffffffc02017c0:	8082                	ret
ffffffffc02017c2:	60a2                	ld	ra,8(sp)
ffffffffc02017c4:	e390                	sd	a2,0(a5)
ffffffffc02017c6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017c8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017ca:	ed1c                	sd	a5,24(a0)
ffffffffc02017cc:	0141                	addi	sp,sp,16
ffffffffc02017ce:	8082                	ret
        assert(PageReserved(p));
ffffffffc02017d0:	00003697          	auipc	a3,0x3
ffffffffc02017d4:	48868693          	addi	a3,a3,1160 # ffffffffc0204c58 <commands+0xb90>
ffffffffc02017d8:	00003617          	auipc	a2,0x3
ffffffffc02017dc:	0f860613          	addi	a2,a2,248 # ffffffffc02048d0 <commands+0x808>
ffffffffc02017e0:	04900593          	li	a1,73
ffffffffc02017e4:	00003517          	auipc	a0,0x3
ffffffffc02017e8:	10450513          	addi	a0,a0,260 # ffffffffc02048e8 <commands+0x820>
ffffffffc02017ec:	c6ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc02017f0:	00003697          	auipc	a3,0x3
ffffffffc02017f4:	43868693          	addi	a3,a3,1080 # ffffffffc0204c28 <commands+0xb60>
ffffffffc02017f8:	00003617          	auipc	a2,0x3
ffffffffc02017fc:	0d860613          	addi	a2,a2,216 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201800:	04600593          	li	a1,70
ffffffffc0201804:	00003517          	auipc	a0,0x3
ffffffffc0201808:	0e450513          	addi	a0,a0,228 # ffffffffc02048e8 <commands+0x820>
ffffffffc020180c:	c4ffe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201810 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201810:	c94d                	beqz	a0,ffffffffc02018c2 <slob_free+0xb2>
{
ffffffffc0201812:	1141                	addi	sp,sp,-16
ffffffffc0201814:	e022                	sd	s0,0(sp)
ffffffffc0201816:	e406                	sd	ra,8(sp)
ffffffffc0201818:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc020181a:	e9c1                	bnez	a1,ffffffffc02018aa <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020181c:	100027f3          	csrr	a5,sstatus
ffffffffc0201820:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201822:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201824:	ebd9                	bnez	a5,ffffffffc02018ba <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201826:	00007617          	auipc	a2,0x7
ffffffffc020182a:	7fa60613          	addi	a2,a2,2042 # ffffffffc0209020 <slobfree>
ffffffffc020182e:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201830:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201832:	679c                	ld	a5,8(a5)
ffffffffc0201834:	02877a63          	bgeu	a4,s0,ffffffffc0201868 <slob_free+0x58>
ffffffffc0201838:	00f46463          	bltu	s0,a5,ffffffffc0201840 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020183c:	fef76ae3          	bltu	a4,a5,ffffffffc0201830 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201840:	400c                	lw	a1,0(s0)
ffffffffc0201842:	00459693          	slli	a3,a1,0x4
ffffffffc0201846:	96a2                	add	a3,a3,s0
ffffffffc0201848:	02d78a63          	beq	a5,a3,ffffffffc020187c <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc020184c:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc020184e:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201850:	00469793          	slli	a5,a3,0x4
ffffffffc0201854:	97ba                	add	a5,a5,a4
ffffffffc0201856:	02f40e63          	beq	s0,a5,ffffffffc0201892 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc020185a:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc020185c:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc020185e:	e129                	bnez	a0,ffffffffc02018a0 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201860:	60a2                	ld	ra,8(sp)
ffffffffc0201862:	6402                	ld	s0,0(sp)
ffffffffc0201864:	0141                	addi	sp,sp,16
ffffffffc0201866:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201868:	fcf764e3          	bltu	a4,a5,ffffffffc0201830 <slob_free+0x20>
ffffffffc020186c:	fcf472e3          	bgeu	s0,a5,ffffffffc0201830 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201870:	400c                	lw	a1,0(s0)
ffffffffc0201872:	00459693          	slli	a3,a1,0x4
ffffffffc0201876:	96a2                	add	a3,a3,s0
ffffffffc0201878:	fcd79ae3          	bne	a5,a3,ffffffffc020184c <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc020187c:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc020187e:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201880:	9db5                	addw	a1,a1,a3
ffffffffc0201882:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201884:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201886:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201888:	00469793          	slli	a5,a3,0x4
ffffffffc020188c:	97ba                	add	a5,a5,a4
ffffffffc020188e:	fcf416e3          	bne	s0,a5,ffffffffc020185a <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201892:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201894:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201896:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201898:	9ebd                	addw	a3,a3,a5
ffffffffc020189a:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc020189c:	e70c                	sd	a1,8(a4)
ffffffffc020189e:	d169                	beqz	a0,ffffffffc0201860 <slob_free+0x50>
}
ffffffffc02018a0:	6402                	ld	s0,0(sp)
ffffffffc02018a2:	60a2                	ld	ra,8(sp)
ffffffffc02018a4:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02018a6:	86aff06f          	j	ffffffffc0200910 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc02018aa:	25bd                	addiw	a1,a1,15
ffffffffc02018ac:	8191                	srli	a1,a1,0x4
ffffffffc02018ae:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018b0:	100027f3          	csrr	a5,sstatus
ffffffffc02018b4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02018b6:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018b8:	d7bd                	beqz	a5,ffffffffc0201826 <slob_free+0x16>
        intr_disable();
ffffffffc02018ba:	85cff0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        return 1;
ffffffffc02018be:	4505                	li	a0,1
ffffffffc02018c0:	b79d                	j	ffffffffc0201826 <slob_free+0x16>
ffffffffc02018c2:	8082                	ret

ffffffffc02018c4 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc02018c4:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02018c6:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc02018c8:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02018cc:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc02018ce:	34e000ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
	if (!page)
ffffffffc02018d2:	c91d                	beqz	a0,ffffffffc0201908 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc02018d4:	0000c697          	auipc	a3,0xc
ffffffffc02018d8:	bdc6b683          	ld	a3,-1060(a3) # ffffffffc020d4b0 <pages>
ffffffffc02018dc:	8d15                	sub	a0,a0,a3
ffffffffc02018de:	8519                	srai	a0,a0,0x6
ffffffffc02018e0:	00004697          	auipc	a3,0x4
ffffffffc02018e4:	0b86b683          	ld	a3,184(a3) # ffffffffc0205998 <nbase>
ffffffffc02018e8:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc02018ea:	00c51793          	slli	a5,a0,0xc
ffffffffc02018ee:	83b1                	srli	a5,a5,0xc
ffffffffc02018f0:	0000c717          	auipc	a4,0xc
ffffffffc02018f4:	bb873703          	ld	a4,-1096(a4) # ffffffffc020d4a8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02018f8:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc02018fa:	00e7fa63          	bgeu	a5,a4,ffffffffc020190e <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc02018fe:	0000c697          	auipc	a3,0xc
ffffffffc0201902:	bc26b683          	ld	a3,-1086(a3) # ffffffffc020d4c0 <va_pa_offset>
ffffffffc0201906:	9536                	add	a0,a0,a3
}
ffffffffc0201908:	60a2                	ld	ra,8(sp)
ffffffffc020190a:	0141                	addi	sp,sp,16
ffffffffc020190c:	8082                	ret
ffffffffc020190e:	86aa                	mv	a3,a0
ffffffffc0201910:	00003617          	auipc	a2,0x3
ffffffffc0201914:	3a860613          	addi	a2,a2,936 # ffffffffc0204cb8 <default_pmm_manager+0x38>
ffffffffc0201918:	07100593          	li	a1,113
ffffffffc020191c:	00003517          	auipc	a0,0x3
ffffffffc0201920:	3c450513          	addi	a0,a0,964 # ffffffffc0204ce0 <default_pmm_manager+0x60>
ffffffffc0201924:	b37fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201928 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201928:	1101                	addi	sp,sp,-32
ffffffffc020192a:	ec06                	sd	ra,24(sp)
ffffffffc020192c:	e822                	sd	s0,16(sp)
ffffffffc020192e:	e426                	sd	s1,8(sp)
ffffffffc0201930:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201932:	01050713          	addi	a4,a0,16
ffffffffc0201936:	6785                	lui	a5,0x1
ffffffffc0201938:	0cf77363          	bgeu	a4,a5,ffffffffc02019fe <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc020193c:	00f50493          	addi	s1,a0,15
ffffffffc0201940:	8091                	srli	s1,s1,0x4
ffffffffc0201942:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201944:	10002673          	csrr	a2,sstatus
ffffffffc0201948:	8a09                	andi	a2,a2,2
ffffffffc020194a:	e25d                	bnez	a2,ffffffffc02019f0 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc020194c:	00007917          	auipc	s2,0x7
ffffffffc0201950:	6d490913          	addi	s2,s2,1748 # ffffffffc0209020 <slobfree>
ffffffffc0201954:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201958:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc020195a:	4398                	lw	a4,0(a5)
ffffffffc020195c:	08975e63          	bge	a4,s1,ffffffffc02019f8 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201960:	00d78b63          	beq	a5,a3,ffffffffc0201976 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201964:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201966:	4018                	lw	a4,0(s0)
ffffffffc0201968:	02975a63          	bge	a4,s1,ffffffffc020199c <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc020196c:	00093683          	ld	a3,0(s2)
ffffffffc0201970:	87a2                	mv	a5,s0
ffffffffc0201972:	fed799e3          	bne	a5,a3,ffffffffc0201964 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc0201976:	ee31                	bnez	a2,ffffffffc02019d2 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201978:	4501                	li	a0,0
ffffffffc020197a:	f4bff0ef          	jal	ra,ffffffffc02018c4 <__slob_get_free_pages.constprop.0>
ffffffffc020197e:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201980:	cd05                	beqz	a0,ffffffffc02019b8 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201982:	6585                	lui	a1,0x1
ffffffffc0201984:	e8dff0ef          	jal	ra,ffffffffc0201810 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201988:	10002673          	csrr	a2,sstatus
ffffffffc020198c:	8a09                	andi	a2,a2,2
ffffffffc020198e:	ee05                	bnez	a2,ffffffffc02019c6 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201990:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201994:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201996:	4018                	lw	a4,0(s0)
ffffffffc0201998:	fc974ae3          	blt	a4,s1,ffffffffc020196c <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc020199c:	04e48763          	beq	s1,a4,ffffffffc02019ea <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc02019a0:	00449693          	slli	a3,s1,0x4
ffffffffc02019a4:	96a2                	add	a3,a3,s0
ffffffffc02019a6:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc02019a8:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc02019aa:	9f05                	subw	a4,a4,s1
ffffffffc02019ac:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc02019ae:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc02019b0:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc02019b2:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc02019b6:	e20d                	bnez	a2,ffffffffc02019d8 <slob_alloc.constprop.0+0xb0>
}
ffffffffc02019b8:	60e2                	ld	ra,24(sp)
ffffffffc02019ba:	8522                	mv	a0,s0
ffffffffc02019bc:	6442                	ld	s0,16(sp)
ffffffffc02019be:	64a2                	ld	s1,8(sp)
ffffffffc02019c0:	6902                	ld	s2,0(sp)
ffffffffc02019c2:	6105                	addi	sp,sp,32
ffffffffc02019c4:	8082                	ret
        intr_disable();
ffffffffc02019c6:	f51fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
			cur = slobfree;
ffffffffc02019ca:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc02019ce:	4605                	li	a2,1
ffffffffc02019d0:	b7d1                	j	ffffffffc0201994 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc02019d2:	f3ffe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc02019d6:	b74d                	j	ffffffffc0201978 <slob_alloc.constprop.0+0x50>
ffffffffc02019d8:	f39fe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
}
ffffffffc02019dc:	60e2                	ld	ra,24(sp)
ffffffffc02019de:	8522                	mv	a0,s0
ffffffffc02019e0:	6442                	ld	s0,16(sp)
ffffffffc02019e2:	64a2                	ld	s1,8(sp)
ffffffffc02019e4:	6902                	ld	s2,0(sp)
ffffffffc02019e6:	6105                	addi	sp,sp,32
ffffffffc02019e8:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc02019ea:	6418                	ld	a4,8(s0)
ffffffffc02019ec:	e798                	sd	a4,8(a5)
ffffffffc02019ee:	b7d1                	j	ffffffffc02019b2 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc02019f0:	f27fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        return 1;
ffffffffc02019f4:	4605                	li	a2,1
ffffffffc02019f6:	bf99                	j	ffffffffc020194c <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc02019f8:	843e                	mv	s0,a5
ffffffffc02019fa:	87b6                	mv	a5,a3
ffffffffc02019fc:	b745                	j	ffffffffc020199c <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc02019fe:	00003697          	auipc	a3,0x3
ffffffffc0201a02:	2f268693          	addi	a3,a3,754 # ffffffffc0204cf0 <default_pmm_manager+0x70>
ffffffffc0201a06:	00003617          	auipc	a2,0x3
ffffffffc0201a0a:	eca60613          	addi	a2,a2,-310 # ffffffffc02048d0 <commands+0x808>
ffffffffc0201a0e:	06300593          	li	a1,99
ffffffffc0201a12:	00003517          	auipc	a0,0x3
ffffffffc0201a16:	2fe50513          	addi	a0,a0,766 # ffffffffc0204d10 <default_pmm_manager+0x90>
ffffffffc0201a1a:	a41fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201a1e <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201a1e:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201a20:	00003517          	auipc	a0,0x3
ffffffffc0201a24:	30850513          	addi	a0,a0,776 # ffffffffc0204d28 <default_pmm_manager+0xa8>
{
ffffffffc0201a28:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201a2a:	f6afe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201a2e:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a30:	00003517          	auipc	a0,0x3
ffffffffc0201a34:	31050513          	addi	a0,a0,784 # ffffffffc0204d40 <default_pmm_manager+0xc0>
}
ffffffffc0201a38:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a3a:	f5afe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201a3e <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201a3e:	1101                	addi	sp,sp,-32
ffffffffc0201a40:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201a42:	6905                	lui	s2,0x1
{
ffffffffc0201a44:	e822                	sd	s0,16(sp)
ffffffffc0201a46:	ec06                	sd	ra,24(sp)
ffffffffc0201a48:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201a4a:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc0201a4e:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201a50:	04a7f963          	bgeu	a5,a0,ffffffffc0201aa2 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201a54:	4561                	li	a0,24
ffffffffc0201a56:	ed3ff0ef          	jal	ra,ffffffffc0201928 <slob_alloc.constprop.0>
ffffffffc0201a5a:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201a5c:	c929                	beqz	a0,ffffffffc0201aae <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201a5e:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201a62:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201a64:	00f95763          	bge	s2,a5,ffffffffc0201a72 <kmalloc+0x34>
ffffffffc0201a68:	6705                	lui	a4,0x1
ffffffffc0201a6a:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201a6c:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201a6e:	fef74ee3          	blt	a4,a5,ffffffffc0201a6a <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201a72:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201a74:	e51ff0ef          	jal	ra,ffffffffc02018c4 <__slob_get_free_pages.constprop.0>
ffffffffc0201a78:	e488                	sd	a0,8(s1)
ffffffffc0201a7a:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201a7c:	c525                	beqz	a0,ffffffffc0201ae4 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a7e:	100027f3          	csrr	a5,sstatus
ffffffffc0201a82:	8b89                	andi	a5,a5,2
ffffffffc0201a84:	ef8d                	bnez	a5,ffffffffc0201abe <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201a86:	0000c797          	auipc	a5,0xc
ffffffffc0201a8a:	a0a78793          	addi	a5,a5,-1526 # ffffffffc020d490 <bigblocks>
ffffffffc0201a8e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201a90:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201a92:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201a94:	60e2                	ld	ra,24(sp)
ffffffffc0201a96:	8522                	mv	a0,s0
ffffffffc0201a98:	6442                	ld	s0,16(sp)
ffffffffc0201a9a:	64a2                	ld	s1,8(sp)
ffffffffc0201a9c:	6902                	ld	s2,0(sp)
ffffffffc0201a9e:	6105                	addi	sp,sp,32
ffffffffc0201aa0:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201aa2:	0541                	addi	a0,a0,16
ffffffffc0201aa4:	e85ff0ef          	jal	ra,ffffffffc0201928 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201aa8:	01050413          	addi	s0,a0,16
ffffffffc0201aac:	f565                	bnez	a0,ffffffffc0201a94 <kmalloc+0x56>
ffffffffc0201aae:	4401                	li	s0,0
}
ffffffffc0201ab0:	60e2                	ld	ra,24(sp)
ffffffffc0201ab2:	8522                	mv	a0,s0
ffffffffc0201ab4:	6442                	ld	s0,16(sp)
ffffffffc0201ab6:	64a2                	ld	s1,8(sp)
ffffffffc0201ab8:	6902                	ld	s2,0(sp)
ffffffffc0201aba:	6105                	addi	sp,sp,32
ffffffffc0201abc:	8082                	ret
        intr_disable();
ffffffffc0201abe:	e59fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201ac2:	0000c797          	auipc	a5,0xc
ffffffffc0201ac6:	9ce78793          	addi	a5,a5,-1586 # ffffffffc020d490 <bigblocks>
ffffffffc0201aca:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201acc:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201ace:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201ad0:	e41fe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
		return bb->pages;
ffffffffc0201ad4:	6480                	ld	s0,8(s1)
}
ffffffffc0201ad6:	60e2                	ld	ra,24(sp)
ffffffffc0201ad8:	64a2                	ld	s1,8(sp)
ffffffffc0201ada:	8522                	mv	a0,s0
ffffffffc0201adc:	6442                	ld	s0,16(sp)
ffffffffc0201ade:	6902                	ld	s2,0(sp)
ffffffffc0201ae0:	6105                	addi	sp,sp,32
ffffffffc0201ae2:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ae4:	45e1                	li	a1,24
ffffffffc0201ae6:	8526                	mv	a0,s1
ffffffffc0201ae8:	d29ff0ef          	jal	ra,ffffffffc0201810 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201aec:	b765                	j	ffffffffc0201a94 <kmalloc+0x56>

ffffffffc0201aee <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201aee:	c169                	beqz	a0,ffffffffc0201bb0 <kfree+0xc2>
{
ffffffffc0201af0:	1101                	addi	sp,sp,-32
ffffffffc0201af2:	e822                	sd	s0,16(sp)
ffffffffc0201af4:	ec06                	sd	ra,24(sp)
ffffffffc0201af6:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201af8:	03451793          	slli	a5,a0,0x34
ffffffffc0201afc:	842a                	mv	s0,a0
ffffffffc0201afe:	e3d9                	bnez	a5,ffffffffc0201b84 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b00:	100027f3          	csrr	a5,sstatus
ffffffffc0201b04:	8b89                	andi	a5,a5,2
ffffffffc0201b06:	e7d9                	bnez	a5,ffffffffc0201b94 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b08:	0000c797          	auipc	a5,0xc
ffffffffc0201b0c:	9887b783          	ld	a5,-1656(a5) # ffffffffc020d490 <bigblocks>
    return 0;
ffffffffc0201b10:	4601                	li	a2,0
ffffffffc0201b12:	cbad                	beqz	a5,ffffffffc0201b84 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b14:	0000c697          	auipc	a3,0xc
ffffffffc0201b18:	97c68693          	addi	a3,a3,-1668 # ffffffffc020d490 <bigblocks>
ffffffffc0201b1c:	a021                	j	ffffffffc0201b24 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b1e:	01048693          	addi	a3,s1,16
ffffffffc0201b22:	c3a5                	beqz	a5,ffffffffc0201b82 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201b24:	6798                	ld	a4,8(a5)
ffffffffc0201b26:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201b28:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201b2a:	fe871ae3          	bne	a4,s0,ffffffffc0201b1e <kfree+0x30>
				*last = bb->next;
ffffffffc0201b2e:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201b30:	ee2d                	bnez	a2,ffffffffc0201baa <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201b32:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201b36:	4098                	lw	a4,0(s1)
ffffffffc0201b38:	08f46963          	bltu	s0,a5,ffffffffc0201bca <kfree+0xdc>
ffffffffc0201b3c:	0000c697          	auipc	a3,0xc
ffffffffc0201b40:	9846b683          	ld	a3,-1660(a3) # ffffffffc020d4c0 <va_pa_offset>
ffffffffc0201b44:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201b46:	8031                	srli	s0,s0,0xc
ffffffffc0201b48:	0000c797          	auipc	a5,0xc
ffffffffc0201b4c:	9607b783          	ld	a5,-1696(a5) # ffffffffc020d4a8 <npage>
ffffffffc0201b50:	06f47163          	bgeu	s0,a5,ffffffffc0201bb2 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b54:	00004517          	auipc	a0,0x4
ffffffffc0201b58:	e4453503          	ld	a0,-444(a0) # ffffffffc0205998 <nbase>
ffffffffc0201b5c:	8c09                	sub	s0,s0,a0
ffffffffc0201b5e:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201b60:	0000c517          	auipc	a0,0xc
ffffffffc0201b64:	95053503          	ld	a0,-1712(a0) # ffffffffc020d4b0 <pages>
ffffffffc0201b68:	4585                	li	a1,1
ffffffffc0201b6a:	9522                	add	a0,a0,s0
ffffffffc0201b6c:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201b70:	0ea000ef          	jal	ra,ffffffffc0201c5a <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201b74:	6442                	ld	s0,16(sp)
ffffffffc0201b76:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b78:	8526                	mv	a0,s1
}
ffffffffc0201b7a:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b7c:	45e1                	li	a1,24
}
ffffffffc0201b7e:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201b80:	b941                	j	ffffffffc0201810 <slob_free>
ffffffffc0201b82:	e20d                	bnez	a2,ffffffffc0201ba4 <kfree+0xb6>
ffffffffc0201b84:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201b88:	6442                	ld	s0,16(sp)
ffffffffc0201b8a:	60e2                	ld	ra,24(sp)
ffffffffc0201b8c:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201b8e:	4581                	li	a1,0
}
ffffffffc0201b90:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201b92:	b9bd                	j	ffffffffc0201810 <slob_free>
        intr_disable();
ffffffffc0201b94:	d83fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b98:	0000c797          	auipc	a5,0xc
ffffffffc0201b9c:	8f87b783          	ld	a5,-1800(a5) # ffffffffc020d490 <bigblocks>
        return 1;
ffffffffc0201ba0:	4605                	li	a2,1
ffffffffc0201ba2:	fbad                	bnez	a5,ffffffffc0201b14 <kfree+0x26>
        intr_enable();
ffffffffc0201ba4:	d6dfe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc0201ba8:	bff1                	j	ffffffffc0201b84 <kfree+0x96>
ffffffffc0201baa:	d67fe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc0201bae:	b751                	j	ffffffffc0201b32 <kfree+0x44>
ffffffffc0201bb0:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201bb2:	00003617          	auipc	a2,0x3
ffffffffc0201bb6:	1d660613          	addi	a2,a2,470 # ffffffffc0204d88 <default_pmm_manager+0x108>
ffffffffc0201bba:	06900593          	li	a1,105
ffffffffc0201bbe:	00003517          	auipc	a0,0x3
ffffffffc0201bc2:	12250513          	addi	a0,a0,290 # ffffffffc0204ce0 <default_pmm_manager+0x60>
ffffffffc0201bc6:	895fe0ef          	jal	ra,ffffffffc020045a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201bca:	86a2                	mv	a3,s0
ffffffffc0201bcc:	00003617          	auipc	a2,0x3
ffffffffc0201bd0:	19460613          	addi	a2,a2,404 # ffffffffc0204d60 <default_pmm_manager+0xe0>
ffffffffc0201bd4:	07700593          	li	a1,119
ffffffffc0201bd8:	00003517          	auipc	a0,0x3
ffffffffc0201bdc:	10850513          	addi	a0,a0,264 # ffffffffc0204ce0 <default_pmm_manager+0x60>
ffffffffc0201be0:	87bfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201be4 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201be4:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201be6:	00003617          	auipc	a2,0x3
ffffffffc0201bea:	1a260613          	addi	a2,a2,418 # ffffffffc0204d88 <default_pmm_manager+0x108>
ffffffffc0201bee:	06900593          	li	a1,105
ffffffffc0201bf2:	00003517          	auipc	a0,0x3
ffffffffc0201bf6:	0ee50513          	addi	a0,a0,238 # ffffffffc0204ce0 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201bfa:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201bfc:	85ffe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c00 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201c00:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201c02:	00003617          	auipc	a2,0x3
ffffffffc0201c06:	1a660613          	addi	a2,a2,422 # ffffffffc0204da8 <default_pmm_manager+0x128>
ffffffffc0201c0a:	07f00593          	li	a1,127
ffffffffc0201c0e:	00003517          	auipc	a0,0x3
ffffffffc0201c12:	0d250513          	addi	a0,a0,210 # ffffffffc0204ce0 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201c16:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201c18:	843fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c1c <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c1c:	100027f3          	csrr	a5,sstatus
ffffffffc0201c20:	8b89                	andi	a5,a5,2
ffffffffc0201c22:	e799                	bnez	a5,ffffffffc0201c30 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c24:	0000c797          	auipc	a5,0xc
ffffffffc0201c28:	8947b783          	ld	a5,-1900(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0201c2c:	6f9c                	ld	a5,24(a5)
ffffffffc0201c2e:	8782                	jr	a5
{
ffffffffc0201c30:	1141                	addi	sp,sp,-16
ffffffffc0201c32:	e406                	sd	ra,8(sp)
ffffffffc0201c34:	e022                	sd	s0,0(sp)
ffffffffc0201c36:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201c38:	cdffe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c3c:	0000c797          	auipc	a5,0xc
ffffffffc0201c40:	87c7b783          	ld	a5,-1924(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0201c44:	6f9c                	ld	a5,24(a5)
ffffffffc0201c46:	8522                	mv	a0,s0
ffffffffc0201c48:	9782                	jalr	a5
ffffffffc0201c4a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201c4c:	cc5fe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201c50:	60a2                	ld	ra,8(sp)
ffffffffc0201c52:	8522                	mv	a0,s0
ffffffffc0201c54:	6402                	ld	s0,0(sp)
ffffffffc0201c56:	0141                	addi	sp,sp,16
ffffffffc0201c58:	8082                	ret

ffffffffc0201c5a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c5a:	100027f3          	csrr	a5,sstatus
ffffffffc0201c5e:	8b89                	andi	a5,a5,2
ffffffffc0201c60:	e799                	bnez	a5,ffffffffc0201c6e <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201c62:	0000c797          	auipc	a5,0xc
ffffffffc0201c66:	8567b783          	ld	a5,-1962(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0201c6a:	739c                	ld	a5,32(a5)
ffffffffc0201c6c:	8782                	jr	a5
{
ffffffffc0201c6e:	1101                	addi	sp,sp,-32
ffffffffc0201c70:	ec06                	sd	ra,24(sp)
ffffffffc0201c72:	e822                	sd	s0,16(sp)
ffffffffc0201c74:	e426                	sd	s1,8(sp)
ffffffffc0201c76:	842a                	mv	s0,a0
ffffffffc0201c78:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201c7a:	c9dfe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201c7e:	0000c797          	auipc	a5,0xc
ffffffffc0201c82:	83a7b783          	ld	a5,-1990(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0201c86:	739c                	ld	a5,32(a5)
ffffffffc0201c88:	85a6                	mv	a1,s1
ffffffffc0201c8a:	8522                	mv	a0,s0
ffffffffc0201c8c:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201c8e:	6442                	ld	s0,16(sp)
ffffffffc0201c90:	60e2                	ld	ra,24(sp)
ffffffffc0201c92:	64a2                	ld	s1,8(sp)
ffffffffc0201c94:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201c96:	c7bfe06f          	j	ffffffffc0200910 <intr_enable>

ffffffffc0201c9a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c9a:	100027f3          	csrr	a5,sstatus
ffffffffc0201c9e:	8b89                	andi	a5,a5,2
ffffffffc0201ca0:	e799                	bnez	a5,ffffffffc0201cae <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201ca2:	0000c797          	auipc	a5,0xc
ffffffffc0201ca6:	8167b783          	ld	a5,-2026(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0201caa:	779c                	ld	a5,40(a5)
ffffffffc0201cac:	8782                	jr	a5
{
ffffffffc0201cae:	1141                	addi	sp,sp,-16
ffffffffc0201cb0:	e406                	sd	ra,8(sp)
ffffffffc0201cb2:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201cb4:	c63fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201cb8:	0000c797          	auipc	a5,0xc
ffffffffc0201cbc:	8007b783          	ld	a5,-2048(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0201cc0:	779c                	ld	a5,40(a5)
ffffffffc0201cc2:	9782                	jalr	a5
ffffffffc0201cc4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201cc6:	c4bfe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201cca:	60a2                	ld	ra,8(sp)
ffffffffc0201ccc:	8522                	mv	a0,s0
ffffffffc0201cce:	6402                	ld	s0,0(sp)
ffffffffc0201cd0:	0141                	addi	sp,sp,16
ffffffffc0201cd2:	8082                	ret

ffffffffc0201cd4 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201cd4:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201cd8:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201cdc:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201cde:	078e                	slli	a5,a5,0x3
{
ffffffffc0201ce0:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201ce2:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201ce6:	6094                	ld	a3,0(s1)
{
ffffffffc0201ce8:	f04a                	sd	s2,32(sp)
ffffffffc0201cea:	ec4e                	sd	s3,24(sp)
ffffffffc0201cec:	e852                	sd	s4,16(sp)
ffffffffc0201cee:	fc06                	sd	ra,56(sp)
ffffffffc0201cf0:	f822                	sd	s0,48(sp)
ffffffffc0201cf2:	e456                	sd	s5,8(sp)
ffffffffc0201cf4:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201cf6:	0016f793          	andi	a5,a3,1
{
ffffffffc0201cfa:	892e                	mv	s2,a1
ffffffffc0201cfc:	8a32                	mv	s4,a2
ffffffffc0201cfe:	0000b997          	auipc	s3,0xb
ffffffffc0201d02:	7aa98993          	addi	s3,s3,1962 # ffffffffc020d4a8 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201d06:	efbd                	bnez	a5,ffffffffc0201d84 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d08:	14060c63          	beqz	a2,ffffffffc0201e60 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d0c:	100027f3          	csrr	a5,sstatus
ffffffffc0201d10:	8b89                	andi	a5,a5,2
ffffffffc0201d12:	14079963          	bnez	a5,ffffffffc0201e64 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d16:	0000b797          	auipc	a5,0xb
ffffffffc0201d1a:	7a27b783          	ld	a5,1954(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0201d1e:	6f9c                	ld	a5,24(a5)
ffffffffc0201d20:	4505                	li	a0,1
ffffffffc0201d22:	9782                	jalr	a5
ffffffffc0201d24:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d26:	12040d63          	beqz	s0,ffffffffc0201e60 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201d2a:	0000bb17          	auipc	s6,0xb
ffffffffc0201d2e:	786b0b13          	addi	s6,s6,1926 # ffffffffc020d4b0 <pages>
ffffffffc0201d32:	000b3503          	ld	a0,0(s6)
ffffffffc0201d36:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201d3a:	0000b997          	auipc	s3,0xb
ffffffffc0201d3e:	76e98993          	addi	s3,s3,1902 # ffffffffc020d4a8 <npage>
ffffffffc0201d42:	40a40533          	sub	a0,s0,a0
ffffffffc0201d46:	8519                	srai	a0,a0,0x6
ffffffffc0201d48:	9556                	add	a0,a0,s5
ffffffffc0201d4a:	0009b703          	ld	a4,0(s3)
ffffffffc0201d4e:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201d52:	4685                	li	a3,1
ffffffffc0201d54:	c014                	sw	a3,0(s0)
ffffffffc0201d56:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d58:	0532                	slli	a0,a0,0xc
ffffffffc0201d5a:	16e7f763          	bgeu	a5,a4,ffffffffc0201ec8 <get_pte+0x1f4>
ffffffffc0201d5e:	0000b797          	auipc	a5,0xb
ffffffffc0201d62:	7627b783          	ld	a5,1890(a5) # ffffffffc020d4c0 <va_pa_offset>
ffffffffc0201d66:	6605                	lui	a2,0x1
ffffffffc0201d68:	4581                	li	a1,0
ffffffffc0201d6a:	953e                	add	a0,a0,a5
ffffffffc0201d6c:	0a6020ef          	jal	ra,ffffffffc0203e12 <memset>
    return page - pages + nbase;
ffffffffc0201d70:	000b3683          	ld	a3,0(s6)
ffffffffc0201d74:	40d406b3          	sub	a3,s0,a3
ffffffffc0201d78:	8699                	srai	a3,a3,0x6
ffffffffc0201d7a:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201d7c:	06aa                	slli	a3,a3,0xa
ffffffffc0201d7e:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201d82:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201d84:	77fd                	lui	a5,0xfffff
ffffffffc0201d86:	068a                	slli	a3,a3,0x2
ffffffffc0201d88:	0009b703          	ld	a4,0(s3)
ffffffffc0201d8c:	8efd                	and	a3,a3,a5
ffffffffc0201d8e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201d92:	10e7ff63          	bgeu	a5,a4,ffffffffc0201eb0 <get_pte+0x1dc>
ffffffffc0201d96:	0000ba97          	auipc	s5,0xb
ffffffffc0201d9a:	72aa8a93          	addi	s5,s5,1834 # ffffffffc020d4c0 <va_pa_offset>
ffffffffc0201d9e:	000ab403          	ld	s0,0(s5)
ffffffffc0201da2:	01595793          	srli	a5,s2,0x15
ffffffffc0201da6:	1ff7f793          	andi	a5,a5,511
ffffffffc0201daa:	96a2                	add	a3,a3,s0
ffffffffc0201dac:	00379413          	slli	s0,a5,0x3
ffffffffc0201db0:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201db2:	6014                	ld	a3,0(s0)
ffffffffc0201db4:	0016f793          	andi	a5,a3,1
ffffffffc0201db8:	ebad                	bnez	a5,ffffffffc0201e2a <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201dba:	0a0a0363          	beqz	s4,ffffffffc0201e60 <get_pte+0x18c>
ffffffffc0201dbe:	100027f3          	csrr	a5,sstatus
ffffffffc0201dc2:	8b89                	andi	a5,a5,2
ffffffffc0201dc4:	efcd                	bnez	a5,ffffffffc0201e7e <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201dc6:	0000b797          	auipc	a5,0xb
ffffffffc0201dca:	6f27b783          	ld	a5,1778(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0201dce:	6f9c                	ld	a5,24(a5)
ffffffffc0201dd0:	4505                	li	a0,1
ffffffffc0201dd2:	9782                	jalr	a5
ffffffffc0201dd4:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201dd6:	c4c9                	beqz	s1,ffffffffc0201e60 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201dd8:	0000bb17          	auipc	s6,0xb
ffffffffc0201ddc:	6d8b0b13          	addi	s6,s6,1752 # ffffffffc020d4b0 <pages>
ffffffffc0201de0:	000b3503          	ld	a0,0(s6)
ffffffffc0201de4:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201de8:	0009b703          	ld	a4,0(s3)
ffffffffc0201dec:	40a48533          	sub	a0,s1,a0
ffffffffc0201df0:	8519                	srai	a0,a0,0x6
ffffffffc0201df2:	9552                	add	a0,a0,s4
ffffffffc0201df4:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201df8:	4685                	li	a3,1
ffffffffc0201dfa:	c094                	sw	a3,0(s1)
ffffffffc0201dfc:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201dfe:	0532                	slli	a0,a0,0xc
ffffffffc0201e00:	0ee7f163          	bgeu	a5,a4,ffffffffc0201ee2 <get_pte+0x20e>
ffffffffc0201e04:	000ab783          	ld	a5,0(s5)
ffffffffc0201e08:	6605                	lui	a2,0x1
ffffffffc0201e0a:	4581                	li	a1,0
ffffffffc0201e0c:	953e                	add	a0,a0,a5
ffffffffc0201e0e:	004020ef          	jal	ra,ffffffffc0203e12 <memset>
    return page - pages + nbase;
ffffffffc0201e12:	000b3683          	ld	a3,0(s6)
ffffffffc0201e16:	40d486b3          	sub	a3,s1,a3
ffffffffc0201e1a:	8699                	srai	a3,a3,0x6
ffffffffc0201e1c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e1e:	06aa                	slli	a3,a3,0xa
ffffffffc0201e20:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e24:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e26:	0009b703          	ld	a4,0(s3)
ffffffffc0201e2a:	068a                	slli	a3,a3,0x2
ffffffffc0201e2c:	757d                	lui	a0,0xfffff
ffffffffc0201e2e:	8ee9                	and	a3,a3,a0
ffffffffc0201e30:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e34:	06e7f263          	bgeu	a5,a4,ffffffffc0201e98 <get_pte+0x1c4>
ffffffffc0201e38:	000ab503          	ld	a0,0(s5)
ffffffffc0201e3c:	00c95913          	srli	s2,s2,0xc
ffffffffc0201e40:	1ff97913          	andi	s2,s2,511
ffffffffc0201e44:	96aa                	add	a3,a3,a0
ffffffffc0201e46:	00391513          	slli	a0,s2,0x3
ffffffffc0201e4a:	9536                	add	a0,a0,a3
}
ffffffffc0201e4c:	70e2                	ld	ra,56(sp)
ffffffffc0201e4e:	7442                	ld	s0,48(sp)
ffffffffc0201e50:	74a2                	ld	s1,40(sp)
ffffffffc0201e52:	7902                	ld	s2,32(sp)
ffffffffc0201e54:	69e2                	ld	s3,24(sp)
ffffffffc0201e56:	6a42                	ld	s4,16(sp)
ffffffffc0201e58:	6aa2                	ld	s5,8(sp)
ffffffffc0201e5a:	6b02                	ld	s6,0(sp)
ffffffffc0201e5c:	6121                	addi	sp,sp,64
ffffffffc0201e5e:	8082                	ret
            return NULL;
ffffffffc0201e60:	4501                	li	a0,0
ffffffffc0201e62:	b7ed                	j	ffffffffc0201e4c <get_pte+0x178>
        intr_disable();
ffffffffc0201e64:	ab3fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e68:	0000b797          	auipc	a5,0xb
ffffffffc0201e6c:	6507b783          	ld	a5,1616(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0201e70:	6f9c                	ld	a5,24(a5)
ffffffffc0201e72:	4505                	li	a0,1
ffffffffc0201e74:	9782                	jalr	a5
ffffffffc0201e76:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201e78:	a99fe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc0201e7c:	b56d                	j	ffffffffc0201d26 <get_pte+0x52>
        intr_disable();
ffffffffc0201e7e:	a99fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
ffffffffc0201e82:	0000b797          	auipc	a5,0xb
ffffffffc0201e86:	6367b783          	ld	a5,1590(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0201e8a:	6f9c                	ld	a5,24(a5)
ffffffffc0201e8c:	4505                	li	a0,1
ffffffffc0201e8e:	9782                	jalr	a5
ffffffffc0201e90:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201e92:	a7ffe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc0201e96:	b781                	j	ffffffffc0201dd6 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e98:	00003617          	auipc	a2,0x3
ffffffffc0201e9c:	e2060613          	addi	a2,a2,-480 # ffffffffc0204cb8 <default_pmm_manager+0x38>
ffffffffc0201ea0:	0fb00593          	li	a1,251
ffffffffc0201ea4:	00003517          	auipc	a0,0x3
ffffffffc0201ea8:	f2c50513          	addi	a0,a0,-212 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0201eac:	daefe0ef          	jal	ra,ffffffffc020045a <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201eb0:	00003617          	auipc	a2,0x3
ffffffffc0201eb4:	e0860613          	addi	a2,a2,-504 # ffffffffc0204cb8 <default_pmm_manager+0x38>
ffffffffc0201eb8:	0ee00593          	li	a1,238
ffffffffc0201ebc:	00003517          	auipc	a0,0x3
ffffffffc0201ec0:	f1450513          	addi	a0,a0,-236 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0201ec4:	d96fe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ec8:	86aa                	mv	a3,a0
ffffffffc0201eca:	00003617          	auipc	a2,0x3
ffffffffc0201ece:	dee60613          	addi	a2,a2,-530 # ffffffffc0204cb8 <default_pmm_manager+0x38>
ffffffffc0201ed2:	0eb00593          	li	a1,235
ffffffffc0201ed6:	00003517          	auipc	a0,0x3
ffffffffc0201eda:	efa50513          	addi	a0,a0,-262 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0201ede:	d7cfe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ee2:	86aa                	mv	a3,a0
ffffffffc0201ee4:	00003617          	auipc	a2,0x3
ffffffffc0201ee8:	dd460613          	addi	a2,a2,-556 # ffffffffc0204cb8 <default_pmm_manager+0x38>
ffffffffc0201eec:	0f800593          	li	a1,248
ffffffffc0201ef0:	00003517          	auipc	a0,0x3
ffffffffc0201ef4:	ee050513          	addi	a0,a0,-288 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0201ef8:	d62fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201efc <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201efc:	1141                	addi	sp,sp,-16
ffffffffc0201efe:	e022                	sd	s0,0(sp)
ffffffffc0201f00:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f02:	4601                	li	a2,0
{
ffffffffc0201f04:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f06:	dcfff0ef          	jal	ra,ffffffffc0201cd4 <get_pte>
    if (ptep_store != NULL)
ffffffffc0201f0a:	c011                	beqz	s0,ffffffffc0201f0e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201f0c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f0e:	c511                	beqz	a0,ffffffffc0201f1a <get_page+0x1e>
ffffffffc0201f10:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201f12:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f14:	0017f713          	andi	a4,a5,1
ffffffffc0201f18:	e709                	bnez	a4,ffffffffc0201f22 <get_page+0x26>
}
ffffffffc0201f1a:	60a2                	ld	ra,8(sp)
ffffffffc0201f1c:	6402                	ld	s0,0(sp)
ffffffffc0201f1e:	0141                	addi	sp,sp,16
ffffffffc0201f20:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f22:	078a                	slli	a5,a5,0x2
ffffffffc0201f24:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201f26:	0000b717          	auipc	a4,0xb
ffffffffc0201f2a:	58273703          	ld	a4,1410(a4) # ffffffffc020d4a8 <npage>
ffffffffc0201f2e:	00e7ff63          	bgeu	a5,a4,ffffffffc0201f4c <get_page+0x50>
ffffffffc0201f32:	60a2                	ld	ra,8(sp)
ffffffffc0201f34:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201f36:	fff80537          	lui	a0,0xfff80
ffffffffc0201f3a:	97aa                	add	a5,a5,a0
ffffffffc0201f3c:	079a                	slli	a5,a5,0x6
ffffffffc0201f3e:	0000b517          	auipc	a0,0xb
ffffffffc0201f42:	57253503          	ld	a0,1394(a0) # ffffffffc020d4b0 <pages>
ffffffffc0201f46:	953e                	add	a0,a0,a5
ffffffffc0201f48:	0141                	addi	sp,sp,16
ffffffffc0201f4a:	8082                	ret
ffffffffc0201f4c:	c99ff0ef          	jal	ra,ffffffffc0201be4 <pa2page.part.0>

ffffffffc0201f50 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201f50:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f52:	4601                	li	a2,0
{
ffffffffc0201f54:	ec26                	sd	s1,24(sp)
ffffffffc0201f56:	f406                	sd	ra,40(sp)
ffffffffc0201f58:	f022                	sd	s0,32(sp)
ffffffffc0201f5a:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f5c:	d79ff0ef          	jal	ra,ffffffffc0201cd4 <get_pte>
    if (ptep != NULL)
ffffffffc0201f60:	c511                	beqz	a0,ffffffffc0201f6c <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0201f62:	611c                	ld	a5,0(a0)
ffffffffc0201f64:	842a                	mv	s0,a0
ffffffffc0201f66:	0017f713          	andi	a4,a5,1
ffffffffc0201f6a:	e711                	bnez	a4,ffffffffc0201f76 <page_remove+0x26>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201f6c:	70a2                	ld	ra,40(sp)
ffffffffc0201f6e:	7402                	ld	s0,32(sp)
ffffffffc0201f70:	64e2                	ld	s1,24(sp)
ffffffffc0201f72:	6145                	addi	sp,sp,48
ffffffffc0201f74:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f76:	078a                	slli	a5,a5,0x2
ffffffffc0201f78:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201f7a:	0000b717          	auipc	a4,0xb
ffffffffc0201f7e:	52e73703          	ld	a4,1326(a4) # ffffffffc020d4a8 <npage>
ffffffffc0201f82:	06e7f363          	bgeu	a5,a4,ffffffffc0201fe8 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f86:	fff80537          	lui	a0,0xfff80
ffffffffc0201f8a:	97aa                	add	a5,a5,a0
ffffffffc0201f8c:	079a                	slli	a5,a5,0x6
ffffffffc0201f8e:	0000b517          	auipc	a0,0xb
ffffffffc0201f92:	52253503          	ld	a0,1314(a0) # ffffffffc020d4b0 <pages>
ffffffffc0201f96:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201f98:	411c                	lw	a5,0(a0)
ffffffffc0201f9a:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201f9e:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201fa0:	cb11                	beqz	a4,ffffffffc0201fb4 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0201fa2:	00043023          	sd	zero,0(s0)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201fa6:	12048073          	sfence.vma	s1
}
ffffffffc0201faa:	70a2                	ld	ra,40(sp)
ffffffffc0201fac:	7402                	ld	s0,32(sp)
ffffffffc0201fae:	64e2                	ld	s1,24(sp)
ffffffffc0201fb0:	6145                	addi	sp,sp,48
ffffffffc0201fb2:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201fb4:	100027f3          	csrr	a5,sstatus
ffffffffc0201fb8:	8b89                	andi	a5,a5,2
ffffffffc0201fba:	eb89                	bnez	a5,ffffffffc0201fcc <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0201fbc:	0000b797          	auipc	a5,0xb
ffffffffc0201fc0:	4fc7b783          	ld	a5,1276(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0201fc4:	739c                	ld	a5,32(a5)
ffffffffc0201fc6:	4585                	li	a1,1
ffffffffc0201fc8:	9782                	jalr	a5
    if (flag) {
ffffffffc0201fca:	bfe1                	j	ffffffffc0201fa2 <page_remove+0x52>
        intr_disable();
ffffffffc0201fcc:	e42a                	sd	a0,8(sp)
ffffffffc0201fce:	949fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
ffffffffc0201fd2:	0000b797          	auipc	a5,0xb
ffffffffc0201fd6:	4e67b783          	ld	a5,1254(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc0201fda:	739c                	ld	a5,32(a5)
ffffffffc0201fdc:	6522                	ld	a0,8(sp)
ffffffffc0201fde:	4585                	li	a1,1
ffffffffc0201fe0:	9782                	jalr	a5
        intr_enable();
ffffffffc0201fe2:	92ffe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc0201fe6:	bf75                	j	ffffffffc0201fa2 <page_remove+0x52>
ffffffffc0201fe8:	bfdff0ef          	jal	ra,ffffffffc0201be4 <pa2page.part.0>

ffffffffc0201fec <page_insert>:
{
ffffffffc0201fec:	7139                	addi	sp,sp,-64
ffffffffc0201fee:	e852                	sd	s4,16(sp)
ffffffffc0201ff0:	8a32                	mv	s4,a2
ffffffffc0201ff2:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201ff4:	4605                	li	a2,1
{
ffffffffc0201ff6:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201ff8:	85d2                	mv	a1,s4
{
ffffffffc0201ffa:	f426                	sd	s1,40(sp)
ffffffffc0201ffc:	fc06                	sd	ra,56(sp)
ffffffffc0201ffe:	f04a                	sd	s2,32(sp)
ffffffffc0202000:	ec4e                	sd	s3,24(sp)
ffffffffc0202002:	e456                	sd	s5,8(sp)
ffffffffc0202004:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202006:	ccfff0ef          	jal	ra,ffffffffc0201cd4 <get_pte>
    if (ptep == NULL)
ffffffffc020200a:	c961                	beqz	a0,ffffffffc02020da <page_insert+0xee>
    page->ref += 1;
ffffffffc020200c:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc020200e:	611c                	ld	a5,0(a0)
ffffffffc0202010:	89aa                	mv	s3,a0
ffffffffc0202012:	0016871b          	addiw	a4,a3,1
ffffffffc0202016:	c018                	sw	a4,0(s0)
ffffffffc0202018:	0017f713          	andi	a4,a5,1
ffffffffc020201c:	ef05                	bnez	a4,ffffffffc0202054 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc020201e:	0000b717          	auipc	a4,0xb
ffffffffc0202022:	49273703          	ld	a4,1170(a4) # ffffffffc020d4b0 <pages>
ffffffffc0202026:	8c19                	sub	s0,s0,a4
ffffffffc0202028:	000807b7          	lui	a5,0x80
ffffffffc020202c:	8419                	srai	s0,s0,0x6
ffffffffc020202e:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202030:	042a                	slli	s0,s0,0xa
ffffffffc0202032:	8cc1                	or	s1,s1,s0
ffffffffc0202034:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202038:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020203c:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202040:	4501                	li	a0,0
}
ffffffffc0202042:	70e2                	ld	ra,56(sp)
ffffffffc0202044:	7442                	ld	s0,48(sp)
ffffffffc0202046:	74a2                	ld	s1,40(sp)
ffffffffc0202048:	7902                	ld	s2,32(sp)
ffffffffc020204a:	69e2                	ld	s3,24(sp)
ffffffffc020204c:	6a42                	ld	s4,16(sp)
ffffffffc020204e:	6aa2                	ld	s5,8(sp)
ffffffffc0202050:	6121                	addi	sp,sp,64
ffffffffc0202052:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202054:	078a                	slli	a5,a5,0x2
ffffffffc0202056:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202058:	0000b717          	auipc	a4,0xb
ffffffffc020205c:	45073703          	ld	a4,1104(a4) # ffffffffc020d4a8 <npage>
ffffffffc0202060:	06e7ff63          	bgeu	a5,a4,ffffffffc02020de <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202064:	0000ba97          	auipc	s5,0xb
ffffffffc0202068:	44ca8a93          	addi	s5,s5,1100 # ffffffffc020d4b0 <pages>
ffffffffc020206c:	000ab703          	ld	a4,0(s5)
ffffffffc0202070:	fff80937          	lui	s2,0xfff80
ffffffffc0202074:	993e                	add	s2,s2,a5
ffffffffc0202076:	091a                	slli	s2,s2,0x6
ffffffffc0202078:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc020207a:	01240c63          	beq	s0,s2,ffffffffc0202092 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc020207e:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd72b1c>
ffffffffc0202082:	fff7869b          	addiw	a3,a5,-1
ffffffffc0202086:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc020208a:	c691                	beqz	a3,ffffffffc0202096 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020208c:	120a0073          	sfence.vma	s4
}
ffffffffc0202090:	bf59                	j	ffffffffc0202026 <page_insert+0x3a>
ffffffffc0202092:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202094:	bf49                	j	ffffffffc0202026 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202096:	100027f3          	csrr	a5,sstatus
ffffffffc020209a:	8b89                	andi	a5,a5,2
ffffffffc020209c:	ef91                	bnez	a5,ffffffffc02020b8 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc020209e:	0000b797          	auipc	a5,0xb
ffffffffc02020a2:	41a7b783          	ld	a5,1050(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc02020a6:	739c                	ld	a5,32(a5)
ffffffffc02020a8:	4585                	li	a1,1
ffffffffc02020aa:	854a                	mv	a0,s2
ffffffffc02020ac:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02020ae:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020b2:	120a0073          	sfence.vma	s4
ffffffffc02020b6:	bf85                	j	ffffffffc0202026 <page_insert+0x3a>
        intr_disable();
ffffffffc02020b8:	85ffe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02020bc:	0000b797          	auipc	a5,0xb
ffffffffc02020c0:	3fc7b783          	ld	a5,1020(a5) # ffffffffc020d4b8 <pmm_manager>
ffffffffc02020c4:	739c                	ld	a5,32(a5)
ffffffffc02020c6:	4585                	li	a1,1
ffffffffc02020c8:	854a                	mv	a0,s2
ffffffffc02020ca:	9782                	jalr	a5
        intr_enable();
ffffffffc02020cc:	845fe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc02020d0:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020d4:	120a0073          	sfence.vma	s4
ffffffffc02020d8:	b7b9                	j	ffffffffc0202026 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02020da:	5571                	li	a0,-4
ffffffffc02020dc:	b79d                	j	ffffffffc0202042 <page_insert+0x56>
ffffffffc02020de:	b07ff0ef          	jal	ra,ffffffffc0201be4 <pa2page.part.0>

ffffffffc02020e2 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02020e2:	00003797          	auipc	a5,0x3
ffffffffc02020e6:	b9e78793          	addi	a5,a5,-1122 # ffffffffc0204c80 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02020ea:	638c                	ld	a1,0(a5)
{
ffffffffc02020ec:	7159                	addi	sp,sp,-112
ffffffffc02020ee:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02020f0:	00003517          	auipc	a0,0x3
ffffffffc02020f4:	cf050513          	addi	a0,a0,-784 # ffffffffc0204de0 <default_pmm_manager+0x160>
    pmm_manager = &default_pmm_manager;
ffffffffc02020f8:	0000bb17          	auipc	s6,0xb
ffffffffc02020fc:	3c0b0b13          	addi	s6,s6,960 # ffffffffc020d4b8 <pmm_manager>
{
ffffffffc0202100:	f486                	sd	ra,104(sp)
ffffffffc0202102:	e8ca                	sd	s2,80(sp)
ffffffffc0202104:	e4ce                	sd	s3,72(sp)
ffffffffc0202106:	f0a2                	sd	s0,96(sp)
ffffffffc0202108:	eca6                	sd	s1,88(sp)
ffffffffc020210a:	e0d2                	sd	s4,64(sp)
ffffffffc020210c:	fc56                	sd	s5,56(sp)
ffffffffc020210e:	f45e                	sd	s7,40(sp)
ffffffffc0202110:	f062                	sd	s8,32(sp)
ffffffffc0202112:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202114:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202118:	87cfe0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc020211c:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202120:	0000b997          	auipc	s3,0xb
ffffffffc0202124:	3a098993          	addi	s3,s3,928 # ffffffffc020d4c0 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202128:	679c                	ld	a5,8(a5)
ffffffffc020212a:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020212c:	57f5                	li	a5,-3
ffffffffc020212e:	07fa                	slli	a5,a5,0x1e
ffffffffc0202130:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202134:	fc8fe0ef          	jal	ra,ffffffffc02008fc <get_memory_base>
ffffffffc0202138:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020213a:	fccfe0ef          	jal	ra,ffffffffc0200906 <get_memory_size>
    if (mem_size == 0) {
ffffffffc020213e:	200505e3          	beqz	a0,ffffffffc0202b48 <pmm_init+0xa66>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0202142:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202144:	00003517          	auipc	a0,0x3
ffffffffc0202148:	cd450513          	addi	a0,a0,-812 # ffffffffc0204e18 <default_pmm_manager+0x198>
ffffffffc020214c:	848fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0202150:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202154:	fff40693          	addi	a3,s0,-1
ffffffffc0202158:	864a                	mv	a2,s2
ffffffffc020215a:	85a6                	mv	a1,s1
ffffffffc020215c:	00003517          	auipc	a0,0x3
ffffffffc0202160:	cd450513          	addi	a0,a0,-812 # ffffffffc0204e30 <default_pmm_manager+0x1b0>
ffffffffc0202164:	830fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202168:	c8000737          	lui	a4,0xc8000
ffffffffc020216c:	87a2                	mv	a5,s0
ffffffffc020216e:	54876163          	bltu	a4,s0,ffffffffc02026b0 <pmm_init+0x5ce>
ffffffffc0202172:	757d                	lui	a0,0xfffff
ffffffffc0202174:	0000c617          	auipc	a2,0xc
ffffffffc0202178:	36f60613          	addi	a2,a2,879 # ffffffffc020e4e3 <end+0xfff>
ffffffffc020217c:	8e69                	and	a2,a2,a0
ffffffffc020217e:	0000b497          	auipc	s1,0xb
ffffffffc0202182:	32a48493          	addi	s1,s1,810 # ffffffffc020d4a8 <npage>
ffffffffc0202186:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020218a:	0000bb97          	auipc	s7,0xb
ffffffffc020218e:	326b8b93          	addi	s7,s7,806 # ffffffffc020d4b0 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202192:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202194:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202198:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020219c:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020219e:	02f50863          	beq	a0,a5,ffffffffc02021ce <pmm_init+0xec>
ffffffffc02021a2:	4781                	li	a5,0
ffffffffc02021a4:	4585                	li	a1,1
ffffffffc02021a6:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02021aa:	00679513          	slli	a0,a5,0x6
ffffffffc02021ae:	9532                	add	a0,a0,a2
ffffffffc02021b0:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fdf1b24>
ffffffffc02021b4:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02021b8:	6088                	ld	a0,0(s1)
ffffffffc02021ba:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02021bc:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02021c0:	00d50733          	add	a4,a0,a3
ffffffffc02021c4:	fee7e3e3          	bltu	a5,a4,ffffffffc02021aa <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02021c8:	071a                	slli	a4,a4,0x6
ffffffffc02021ca:	00e606b3          	add	a3,a2,a4
ffffffffc02021ce:	c02007b7          	lui	a5,0xc0200
ffffffffc02021d2:	2ef6ece3          	bltu	a3,a5,ffffffffc0202cca <pmm_init+0xbe8>
ffffffffc02021d6:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02021da:	77fd                	lui	a5,0xfffff
ffffffffc02021dc:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02021de:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02021e0:	5086eb63          	bltu	a3,s0,ffffffffc02026f6 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02021e4:	00003517          	auipc	a0,0x3
ffffffffc02021e8:	c7450513          	addi	a0,a0,-908 # ffffffffc0204e58 <default_pmm_manager+0x1d8>
ffffffffc02021ec:	fa9fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02021f0:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02021f4:	0000b917          	auipc	s2,0xb
ffffffffc02021f8:	2ac90913          	addi	s2,s2,684 # ffffffffc020d4a0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02021fc:	7b9c                	ld	a5,48(a5)
ffffffffc02021fe:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202200:	00003517          	auipc	a0,0x3
ffffffffc0202204:	c7050513          	addi	a0,a0,-912 # ffffffffc0204e70 <default_pmm_manager+0x1f0>
ffffffffc0202208:	f8dfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020220c:	00006697          	auipc	a3,0x6
ffffffffc0202210:	df468693          	addi	a3,a3,-524 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0202214:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202218:	c02007b7          	lui	a5,0xc0200
ffffffffc020221c:	28f6ebe3          	bltu	a3,a5,ffffffffc0202cb2 <pmm_init+0xbd0>
ffffffffc0202220:	0009b783          	ld	a5,0(s3)
ffffffffc0202224:	8e9d                	sub	a3,a3,a5
ffffffffc0202226:	0000b797          	auipc	a5,0xb
ffffffffc020222a:	26d7b923          	sd	a3,626(a5) # ffffffffc020d498 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020222e:	100027f3          	csrr	a5,sstatus
ffffffffc0202232:	8b89                	andi	a5,a5,2
ffffffffc0202234:	4a079763          	bnez	a5,ffffffffc02026e2 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202238:	000b3783          	ld	a5,0(s6)
ffffffffc020223c:	779c                	ld	a5,40(a5)
ffffffffc020223e:	9782                	jalr	a5
ffffffffc0202240:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202242:	6098                	ld	a4,0(s1)
ffffffffc0202244:	c80007b7          	lui	a5,0xc8000
ffffffffc0202248:	83b1                	srli	a5,a5,0xc
ffffffffc020224a:	66e7e363          	bltu	a5,a4,ffffffffc02028b0 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc020224e:	00093503          	ld	a0,0(s2)
ffffffffc0202252:	62050f63          	beqz	a0,ffffffffc0202890 <pmm_init+0x7ae>
ffffffffc0202256:	03451793          	slli	a5,a0,0x34
ffffffffc020225a:	62079b63          	bnez	a5,ffffffffc0202890 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020225e:	4601                	li	a2,0
ffffffffc0202260:	4581                	li	a1,0
ffffffffc0202262:	c9bff0ef          	jal	ra,ffffffffc0201efc <get_page>
ffffffffc0202266:	60051563          	bnez	a0,ffffffffc0202870 <pmm_init+0x78e>
ffffffffc020226a:	100027f3          	csrr	a5,sstatus
ffffffffc020226e:	8b89                	andi	a5,a5,2
ffffffffc0202270:	44079e63          	bnez	a5,ffffffffc02026cc <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202274:	000b3783          	ld	a5,0(s6)
ffffffffc0202278:	4505                	li	a0,1
ffffffffc020227a:	6f9c                	ld	a5,24(a5)
ffffffffc020227c:	9782                	jalr	a5
ffffffffc020227e:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202280:	00093503          	ld	a0,0(s2)
ffffffffc0202284:	4681                	li	a3,0
ffffffffc0202286:	4601                	li	a2,0
ffffffffc0202288:	85d2                	mv	a1,s4
ffffffffc020228a:	d63ff0ef          	jal	ra,ffffffffc0201fec <page_insert>
ffffffffc020228e:	26051ae3          	bnez	a0,ffffffffc0202d02 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202292:	00093503          	ld	a0,0(s2)
ffffffffc0202296:	4601                	li	a2,0
ffffffffc0202298:	4581                	li	a1,0
ffffffffc020229a:	a3bff0ef          	jal	ra,ffffffffc0201cd4 <get_pte>
ffffffffc020229e:	240502e3          	beqz	a0,ffffffffc0202ce2 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc02022a2:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02022a4:	0017f713          	andi	a4,a5,1
ffffffffc02022a8:	5a070263          	beqz	a4,ffffffffc020284c <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02022ac:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02022ae:	078a                	slli	a5,a5,0x2
ffffffffc02022b0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02022b2:	58e7fb63          	bgeu	a5,a4,ffffffffc0202848 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02022b6:	000bb683          	ld	a3,0(s7)
ffffffffc02022ba:	fff80637          	lui	a2,0xfff80
ffffffffc02022be:	97b2                	add	a5,a5,a2
ffffffffc02022c0:	079a                	slli	a5,a5,0x6
ffffffffc02022c2:	97b6                	add	a5,a5,a3
ffffffffc02022c4:	14fa17e3          	bne	s4,a5,ffffffffc0202c12 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc02022c8:	000a2683          	lw	a3,0(s4) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc02022cc:	4785                	li	a5,1
ffffffffc02022ce:	12f692e3          	bne	a3,a5,ffffffffc0202bf2 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02022d2:	00093503          	ld	a0,0(s2)
ffffffffc02022d6:	77fd                	lui	a5,0xfffff
ffffffffc02022d8:	6114                	ld	a3,0(a0)
ffffffffc02022da:	068a                	slli	a3,a3,0x2
ffffffffc02022dc:	8efd                	and	a3,a3,a5
ffffffffc02022de:	00c6d613          	srli	a2,a3,0xc
ffffffffc02022e2:	0ee67ce3          	bgeu	a2,a4,ffffffffc0202bda <pmm_init+0xaf8>
ffffffffc02022e6:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02022ea:	96e2                	add	a3,a3,s8
ffffffffc02022ec:	0006ba83          	ld	s5,0(a3)
ffffffffc02022f0:	0a8a                	slli	s5,s5,0x2
ffffffffc02022f2:	00fafab3          	and	s5,s5,a5
ffffffffc02022f6:	00cad793          	srli	a5,s5,0xc
ffffffffc02022fa:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0202bc0 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02022fe:	4601                	li	a2,0
ffffffffc0202300:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202302:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202304:	9d1ff0ef          	jal	ra,ffffffffc0201cd4 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202308:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020230a:	55551363          	bne	a0,s5,ffffffffc0202850 <pmm_init+0x76e>
ffffffffc020230e:	100027f3          	csrr	a5,sstatus
ffffffffc0202312:	8b89                	andi	a5,a5,2
ffffffffc0202314:	3a079163          	bnez	a5,ffffffffc02026b6 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202318:	000b3783          	ld	a5,0(s6)
ffffffffc020231c:	4505                	li	a0,1
ffffffffc020231e:	6f9c                	ld	a5,24(a5)
ffffffffc0202320:	9782                	jalr	a5
ffffffffc0202322:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202324:	00093503          	ld	a0,0(s2)
ffffffffc0202328:	46d1                	li	a3,20
ffffffffc020232a:	6605                	lui	a2,0x1
ffffffffc020232c:	85e2                	mv	a1,s8
ffffffffc020232e:	cbfff0ef          	jal	ra,ffffffffc0201fec <page_insert>
ffffffffc0202332:	060517e3          	bnez	a0,ffffffffc0202ba0 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202336:	00093503          	ld	a0,0(s2)
ffffffffc020233a:	4601                	li	a2,0
ffffffffc020233c:	6585                	lui	a1,0x1
ffffffffc020233e:	997ff0ef          	jal	ra,ffffffffc0201cd4 <get_pte>
ffffffffc0202342:	02050fe3          	beqz	a0,ffffffffc0202b80 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202346:	611c                	ld	a5,0(a0)
ffffffffc0202348:	0107f713          	andi	a4,a5,16
ffffffffc020234c:	7c070e63          	beqz	a4,ffffffffc0202b28 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202350:	8b91                	andi	a5,a5,4
ffffffffc0202352:	7a078b63          	beqz	a5,ffffffffc0202b08 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202356:	00093503          	ld	a0,0(s2)
ffffffffc020235a:	611c                	ld	a5,0(a0)
ffffffffc020235c:	8bc1                	andi	a5,a5,16
ffffffffc020235e:	78078563          	beqz	a5,ffffffffc0202ae8 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202362:	000c2703          	lw	a4,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc0202366:	4785                	li	a5,1
ffffffffc0202368:	76f71063          	bne	a4,a5,ffffffffc0202ac8 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc020236c:	4681                	li	a3,0
ffffffffc020236e:	6605                	lui	a2,0x1
ffffffffc0202370:	85d2                	mv	a1,s4
ffffffffc0202372:	c7bff0ef          	jal	ra,ffffffffc0201fec <page_insert>
ffffffffc0202376:	72051963          	bnez	a0,ffffffffc0202aa8 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc020237a:	000a2703          	lw	a4,0(s4)
ffffffffc020237e:	4789                	li	a5,2
ffffffffc0202380:	70f71463          	bne	a4,a5,ffffffffc0202a88 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202384:	000c2783          	lw	a5,0(s8)
ffffffffc0202388:	6e079063          	bnez	a5,ffffffffc0202a68 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020238c:	00093503          	ld	a0,0(s2)
ffffffffc0202390:	4601                	li	a2,0
ffffffffc0202392:	6585                	lui	a1,0x1
ffffffffc0202394:	941ff0ef          	jal	ra,ffffffffc0201cd4 <get_pte>
ffffffffc0202398:	6a050863          	beqz	a0,ffffffffc0202a48 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc020239c:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc020239e:	00177793          	andi	a5,a4,1
ffffffffc02023a2:	4a078563          	beqz	a5,ffffffffc020284c <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02023a6:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02023a8:	00271793          	slli	a5,a4,0x2
ffffffffc02023ac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02023ae:	48d7fd63          	bgeu	a5,a3,ffffffffc0202848 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02023b2:	000bb683          	ld	a3,0(s7)
ffffffffc02023b6:	fff80ab7          	lui	s5,0xfff80
ffffffffc02023ba:	97d6                	add	a5,a5,s5
ffffffffc02023bc:	079a                	slli	a5,a5,0x6
ffffffffc02023be:	97b6                	add	a5,a5,a3
ffffffffc02023c0:	66fa1463          	bne	s4,a5,ffffffffc0202a28 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc02023c4:	8b41                	andi	a4,a4,16
ffffffffc02023c6:	64071163          	bnez	a4,ffffffffc0202a08 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc02023ca:	00093503          	ld	a0,0(s2)
ffffffffc02023ce:	4581                	li	a1,0
ffffffffc02023d0:	b81ff0ef          	jal	ra,ffffffffc0201f50 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc02023d4:	000a2c83          	lw	s9,0(s4)
ffffffffc02023d8:	4785                	li	a5,1
ffffffffc02023da:	60fc9763          	bne	s9,a5,ffffffffc02029e8 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc02023de:	000c2783          	lw	a5,0(s8)
ffffffffc02023e2:	5e079363          	bnez	a5,ffffffffc02029c8 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc02023e6:	00093503          	ld	a0,0(s2)
ffffffffc02023ea:	6585                	lui	a1,0x1
ffffffffc02023ec:	b65ff0ef          	jal	ra,ffffffffc0201f50 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc02023f0:	000a2783          	lw	a5,0(s4)
ffffffffc02023f4:	52079a63          	bnez	a5,ffffffffc0202928 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc02023f8:	000c2783          	lw	a5,0(s8)
ffffffffc02023fc:	50079663          	bnez	a5,ffffffffc0202908 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202400:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202404:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202406:	000a3683          	ld	a3,0(s4)
ffffffffc020240a:	068a                	slli	a3,a3,0x2
ffffffffc020240c:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc020240e:	42b6fd63          	bgeu	a3,a1,ffffffffc0202848 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202412:	000bb503          	ld	a0,0(s7)
ffffffffc0202416:	96d6                	add	a3,a3,s5
ffffffffc0202418:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020241a:	00d507b3          	add	a5,a0,a3
ffffffffc020241e:	439c                	lw	a5,0(a5)
ffffffffc0202420:	4d979463          	bne	a5,s9,ffffffffc02028e8 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202424:	8699                	srai	a3,a3,0x6
ffffffffc0202426:	00080637          	lui	a2,0x80
ffffffffc020242a:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc020242c:	00c69713          	slli	a4,a3,0xc
ffffffffc0202430:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202432:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202434:	48b77e63          	bgeu	a4,a1,ffffffffc02028d0 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202438:	0009b703          	ld	a4,0(s3)
ffffffffc020243c:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc020243e:	629c                	ld	a5,0(a3)
ffffffffc0202440:	078a                	slli	a5,a5,0x2
ffffffffc0202442:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202444:	40b7f263          	bgeu	a5,a1,ffffffffc0202848 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202448:	8f91                	sub	a5,a5,a2
ffffffffc020244a:	079a                	slli	a5,a5,0x6
ffffffffc020244c:	953e                	add	a0,a0,a5
ffffffffc020244e:	100027f3          	csrr	a5,sstatus
ffffffffc0202452:	8b89                	andi	a5,a5,2
ffffffffc0202454:	30079963          	bnez	a5,ffffffffc0202766 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202458:	000b3783          	ld	a5,0(s6)
ffffffffc020245c:	4585                	li	a1,1
ffffffffc020245e:	739c                	ld	a5,32(a5)
ffffffffc0202460:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202462:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202466:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202468:	078a                	slli	a5,a5,0x2
ffffffffc020246a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020246c:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202848 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202470:	000bb503          	ld	a0,0(s7)
ffffffffc0202474:	fff80737          	lui	a4,0xfff80
ffffffffc0202478:	97ba                	add	a5,a5,a4
ffffffffc020247a:	079a                	slli	a5,a5,0x6
ffffffffc020247c:	953e                	add	a0,a0,a5
ffffffffc020247e:	100027f3          	csrr	a5,sstatus
ffffffffc0202482:	8b89                	andi	a5,a5,2
ffffffffc0202484:	2c079563          	bnez	a5,ffffffffc020274e <pmm_init+0x66c>
ffffffffc0202488:	000b3783          	ld	a5,0(s6)
ffffffffc020248c:	4585                	li	a1,1
ffffffffc020248e:	739c                	ld	a5,32(a5)
ffffffffc0202490:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202492:	00093783          	ld	a5,0(s2)
ffffffffc0202496:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b1c>
    asm volatile("sfence.vma");
ffffffffc020249a:	12000073          	sfence.vma
ffffffffc020249e:	100027f3          	csrr	a5,sstatus
ffffffffc02024a2:	8b89                	andi	a5,a5,2
ffffffffc02024a4:	28079b63          	bnez	a5,ffffffffc020273a <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc02024a8:	000b3783          	ld	a5,0(s6)
ffffffffc02024ac:	779c                	ld	a5,40(a5)
ffffffffc02024ae:	9782                	jalr	a5
ffffffffc02024b0:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02024b2:	4b441b63          	bne	s0,s4,ffffffffc0202968 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02024b6:	00003517          	auipc	a0,0x3
ffffffffc02024ba:	ce250513          	addi	a0,a0,-798 # ffffffffc0205198 <default_pmm_manager+0x518>
ffffffffc02024be:	cd7fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02024c2:	100027f3          	csrr	a5,sstatus
ffffffffc02024c6:	8b89                	andi	a5,a5,2
ffffffffc02024c8:	24079f63          	bnez	a5,ffffffffc0202726 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc02024cc:	000b3783          	ld	a5,0(s6)
ffffffffc02024d0:	779c                	ld	a5,40(a5)
ffffffffc02024d2:	9782                	jalr	a5
ffffffffc02024d4:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02024d6:	6098                	ld	a4,0(s1)
ffffffffc02024d8:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02024dc:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02024de:	00c71793          	slli	a5,a4,0xc
ffffffffc02024e2:	6a05                	lui	s4,0x1
ffffffffc02024e4:	02f47c63          	bgeu	s0,a5,ffffffffc020251c <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02024e8:	00c45793          	srli	a5,s0,0xc
ffffffffc02024ec:	00093503          	ld	a0,0(s2)
ffffffffc02024f0:	2ee7ff63          	bgeu	a5,a4,ffffffffc02027ee <pmm_init+0x70c>
ffffffffc02024f4:	0009b583          	ld	a1,0(s3)
ffffffffc02024f8:	4601                	li	a2,0
ffffffffc02024fa:	95a2                	add	a1,a1,s0
ffffffffc02024fc:	fd8ff0ef          	jal	ra,ffffffffc0201cd4 <get_pte>
ffffffffc0202500:	32050463          	beqz	a0,ffffffffc0202828 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202504:	611c                	ld	a5,0(a0)
ffffffffc0202506:	078a                	slli	a5,a5,0x2
ffffffffc0202508:	0157f7b3          	and	a5,a5,s5
ffffffffc020250c:	2e879e63          	bne	a5,s0,ffffffffc0202808 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202510:	6098                	ld	a4,0(s1)
ffffffffc0202512:	9452                	add	s0,s0,s4
ffffffffc0202514:	00c71793          	slli	a5,a4,0xc
ffffffffc0202518:	fcf468e3          	bltu	s0,a5,ffffffffc02024e8 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc020251c:	00093783          	ld	a5,0(s2)
ffffffffc0202520:	639c                	ld	a5,0(a5)
ffffffffc0202522:	42079363          	bnez	a5,ffffffffc0202948 <pmm_init+0x866>
ffffffffc0202526:	100027f3          	csrr	a5,sstatus
ffffffffc020252a:	8b89                	andi	a5,a5,2
ffffffffc020252c:	24079963          	bnez	a5,ffffffffc020277e <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202530:	000b3783          	ld	a5,0(s6)
ffffffffc0202534:	4505                	li	a0,1
ffffffffc0202536:	6f9c                	ld	a5,24(a5)
ffffffffc0202538:	9782                	jalr	a5
ffffffffc020253a:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020253c:	00093503          	ld	a0,0(s2)
ffffffffc0202540:	4699                	li	a3,6
ffffffffc0202542:	10000613          	li	a2,256
ffffffffc0202546:	85d2                	mv	a1,s4
ffffffffc0202548:	aa5ff0ef          	jal	ra,ffffffffc0201fec <page_insert>
ffffffffc020254c:	44051e63          	bnez	a0,ffffffffc02029a8 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202550:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0202554:	4785                	li	a5,1
ffffffffc0202556:	42f71963          	bne	a4,a5,ffffffffc0202988 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020255a:	00093503          	ld	a0,0(s2)
ffffffffc020255e:	6405                	lui	s0,0x1
ffffffffc0202560:	4699                	li	a3,6
ffffffffc0202562:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc0202566:	85d2                	mv	a1,s4
ffffffffc0202568:	a85ff0ef          	jal	ra,ffffffffc0201fec <page_insert>
ffffffffc020256c:	72051363          	bnez	a0,ffffffffc0202c92 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202570:	000a2703          	lw	a4,0(s4)
ffffffffc0202574:	4789                	li	a5,2
ffffffffc0202576:	6ef71e63          	bne	a4,a5,ffffffffc0202c72 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc020257a:	00003597          	auipc	a1,0x3
ffffffffc020257e:	d6658593          	addi	a1,a1,-666 # ffffffffc02052e0 <default_pmm_manager+0x660>
ffffffffc0202582:	10000513          	li	a0,256
ffffffffc0202586:	021010ef          	jal	ra,ffffffffc0203da6 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020258a:	10040593          	addi	a1,s0,256
ffffffffc020258e:	10000513          	li	a0,256
ffffffffc0202592:	027010ef          	jal	ra,ffffffffc0203db8 <strcmp>
ffffffffc0202596:	6a051e63          	bnez	a0,ffffffffc0202c52 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc020259a:	000bb683          	ld	a3,0(s7)
ffffffffc020259e:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc02025a2:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc02025a4:	40da06b3          	sub	a3,s4,a3
ffffffffc02025a8:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02025aa:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc02025ac:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02025ae:	8031                	srli	s0,s0,0xc
ffffffffc02025b0:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc02025b4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02025b6:	30f77d63          	bgeu	a4,a5,ffffffffc02028d0 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02025ba:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02025be:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02025c2:	96be                	add	a3,a3,a5
ffffffffc02025c4:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02025c8:	7a8010ef          	jal	ra,ffffffffc0203d70 <strlen>
ffffffffc02025cc:	66051363          	bnez	a0,ffffffffc0202c32 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc02025d0:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc02025d4:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02025d6:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fdf1b1c>
ffffffffc02025da:	068a                	slli	a3,a3,0x2
ffffffffc02025dc:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc02025de:	26f6f563          	bgeu	a3,a5,ffffffffc0202848 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc02025e2:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02025e4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02025e6:	2ef47563          	bgeu	s0,a5,ffffffffc02028d0 <pmm_init+0x7ee>
ffffffffc02025ea:	0009b403          	ld	s0,0(s3)
ffffffffc02025ee:	9436                	add	s0,s0,a3
ffffffffc02025f0:	100027f3          	csrr	a5,sstatus
ffffffffc02025f4:	8b89                	andi	a5,a5,2
ffffffffc02025f6:	1e079163          	bnez	a5,ffffffffc02027d8 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc02025fa:	000b3783          	ld	a5,0(s6)
ffffffffc02025fe:	4585                	li	a1,1
ffffffffc0202600:	8552                	mv	a0,s4
ffffffffc0202602:	739c                	ld	a5,32(a5)
ffffffffc0202604:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202606:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202608:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020260a:	078a                	slli	a5,a5,0x2
ffffffffc020260c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020260e:	22e7fd63          	bgeu	a5,a4,ffffffffc0202848 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202612:	000bb503          	ld	a0,0(s7)
ffffffffc0202616:	fff80737          	lui	a4,0xfff80
ffffffffc020261a:	97ba                	add	a5,a5,a4
ffffffffc020261c:	079a                	slli	a5,a5,0x6
ffffffffc020261e:	953e                	add	a0,a0,a5
ffffffffc0202620:	100027f3          	csrr	a5,sstatus
ffffffffc0202624:	8b89                	andi	a5,a5,2
ffffffffc0202626:	18079d63          	bnez	a5,ffffffffc02027c0 <pmm_init+0x6de>
ffffffffc020262a:	000b3783          	ld	a5,0(s6)
ffffffffc020262e:	4585                	li	a1,1
ffffffffc0202630:	739c                	ld	a5,32(a5)
ffffffffc0202632:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202634:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202638:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020263a:	078a                	slli	a5,a5,0x2
ffffffffc020263c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020263e:	20e7f563          	bgeu	a5,a4,ffffffffc0202848 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202642:	000bb503          	ld	a0,0(s7)
ffffffffc0202646:	fff80737          	lui	a4,0xfff80
ffffffffc020264a:	97ba                	add	a5,a5,a4
ffffffffc020264c:	079a                	slli	a5,a5,0x6
ffffffffc020264e:	953e                	add	a0,a0,a5
ffffffffc0202650:	100027f3          	csrr	a5,sstatus
ffffffffc0202654:	8b89                	andi	a5,a5,2
ffffffffc0202656:	14079963          	bnez	a5,ffffffffc02027a8 <pmm_init+0x6c6>
ffffffffc020265a:	000b3783          	ld	a5,0(s6)
ffffffffc020265e:	4585                	li	a1,1
ffffffffc0202660:	739c                	ld	a5,32(a5)
ffffffffc0202662:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202664:	00093783          	ld	a5,0(s2)
ffffffffc0202668:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc020266c:	12000073          	sfence.vma
ffffffffc0202670:	100027f3          	csrr	a5,sstatus
ffffffffc0202674:	8b89                	andi	a5,a5,2
ffffffffc0202676:	10079f63          	bnez	a5,ffffffffc0202794 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc020267a:	000b3783          	ld	a5,0(s6)
ffffffffc020267e:	779c                	ld	a5,40(a5)
ffffffffc0202680:	9782                	jalr	a5
ffffffffc0202682:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202684:	4c8c1e63          	bne	s8,s0,ffffffffc0202b60 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202688:	00003517          	auipc	a0,0x3
ffffffffc020268c:	cd050513          	addi	a0,a0,-816 # ffffffffc0205358 <default_pmm_manager+0x6d8>
ffffffffc0202690:	b05fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202694:	7406                	ld	s0,96(sp)
ffffffffc0202696:	70a6                	ld	ra,104(sp)
ffffffffc0202698:	64e6                	ld	s1,88(sp)
ffffffffc020269a:	6946                	ld	s2,80(sp)
ffffffffc020269c:	69a6                	ld	s3,72(sp)
ffffffffc020269e:	6a06                	ld	s4,64(sp)
ffffffffc02026a0:	7ae2                	ld	s5,56(sp)
ffffffffc02026a2:	7b42                	ld	s6,48(sp)
ffffffffc02026a4:	7ba2                	ld	s7,40(sp)
ffffffffc02026a6:	7c02                	ld	s8,32(sp)
ffffffffc02026a8:	6ce2                	ld	s9,24(sp)
ffffffffc02026aa:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc02026ac:	b72ff06f          	j	ffffffffc0201a1e <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc02026b0:	c80007b7          	lui	a5,0xc8000
ffffffffc02026b4:	bc7d                	j	ffffffffc0202172 <pmm_init+0x90>
        intr_disable();
ffffffffc02026b6:	a60fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02026ba:	000b3783          	ld	a5,0(s6)
ffffffffc02026be:	4505                	li	a0,1
ffffffffc02026c0:	6f9c                	ld	a5,24(a5)
ffffffffc02026c2:	9782                	jalr	a5
ffffffffc02026c4:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02026c6:	a4afe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc02026ca:	b9a9                	j	ffffffffc0202324 <pmm_init+0x242>
        intr_disable();
ffffffffc02026cc:	a4afe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
ffffffffc02026d0:	000b3783          	ld	a5,0(s6)
ffffffffc02026d4:	4505                	li	a0,1
ffffffffc02026d6:	6f9c                	ld	a5,24(a5)
ffffffffc02026d8:	9782                	jalr	a5
ffffffffc02026da:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02026dc:	a34fe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc02026e0:	b645                	j	ffffffffc0202280 <pmm_init+0x19e>
        intr_disable();
ffffffffc02026e2:	a34fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026e6:	000b3783          	ld	a5,0(s6)
ffffffffc02026ea:	779c                	ld	a5,40(a5)
ffffffffc02026ec:	9782                	jalr	a5
ffffffffc02026ee:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02026f0:	a20fe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc02026f4:	b6b9                	j	ffffffffc0202242 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02026f6:	6705                	lui	a4,0x1
ffffffffc02026f8:	177d                	addi	a4,a4,-1
ffffffffc02026fa:	96ba                	add	a3,a3,a4
ffffffffc02026fc:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc02026fe:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202702:	14a77363          	bgeu	a4,a0,ffffffffc0202848 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202706:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc020270a:	fff80537          	lui	a0,0xfff80
ffffffffc020270e:	972a                	add	a4,a4,a0
ffffffffc0202710:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202712:	8c1d                	sub	s0,s0,a5
ffffffffc0202714:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202718:	00c45593          	srli	a1,s0,0xc
ffffffffc020271c:	9532                	add	a0,a0,a2
ffffffffc020271e:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202720:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202724:	b4c1                	j	ffffffffc02021e4 <pmm_init+0x102>
        intr_disable();
ffffffffc0202726:	9f0fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020272a:	000b3783          	ld	a5,0(s6)
ffffffffc020272e:	779c                	ld	a5,40(a5)
ffffffffc0202730:	9782                	jalr	a5
ffffffffc0202732:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202734:	9dcfe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc0202738:	bb79                	j	ffffffffc02024d6 <pmm_init+0x3f4>
        intr_disable();
ffffffffc020273a:	9dcfe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
ffffffffc020273e:	000b3783          	ld	a5,0(s6)
ffffffffc0202742:	779c                	ld	a5,40(a5)
ffffffffc0202744:	9782                	jalr	a5
ffffffffc0202746:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202748:	9c8fe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc020274c:	b39d                	j	ffffffffc02024b2 <pmm_init+0x3d0>
ffffffffc020274e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202750:	9c6fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202754:	000b3783          	ld	a5,0(s6)
ffffffffc0202758:	6522                	ld	a0,8(sp)
ffffffffc020275a:	4585                	li	a1,1
ffffffffc020275c:	739c                	ld	a5,32(a5)
ffffffffc020275e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202760:	9b0fe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc0202764:	b33d                	j	ffffffffc0202492 <pmm_init+0x3b0>
ffffffffc0202766:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202768:	9aefe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
ffffffffc020276c:	000b3783          	ld	a5,0(s6)
ffffffffc0202770:	6522                	ld	a0,8(sp)
ffffffffc0202772:	4585                	li	a1,1
ffffffffc0202774:	739c                	ld	a5,32(a5)
ffffffffc0202776:	9782                	jalr	a5
        intr_enable();
ffffffffc0202778:	998fe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc020277c:	b1dd                	j	ffffffffc0202462 <pmm_init+0x380>
        intr_disable();
ffffffffc020277e:	998fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202782:	000b3783          	ld	a5,0(s6)
ffffffffc0202786:	4505                	li	a0,1
ffffffffc0202788:	6f9c                	ld	a5,24(a5)
ffffffffc020278a:	9782                	jalr	a5
ffffffffc020278c:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020278e:	982fe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc0202792:	b36d                	j	ffffffffc020253c <pmm_init+0x45a>
        intr_disable();
ffffffffc0202794:	982fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202798:	000b3783          	ld	a5,0(s6)
ffffffffc020279c:	779c                	ld	a5,40(a5)
ffffffffc020279e:	9782                	jalr	a5
ffffffffc02027a0:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02027a2:	96efe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc02027a6:	bdf9                	j	ffffffffc0202684 <pmm_init+0x5a2>
ffffffffc02027a8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027aa:	96cfe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027ae:	000b3783          	ld	a5,0(s6)
ffffffffc02027b2:	6522                	ld	a0,8(sp)
ffffffffc02027b4:	4585                	li	a1,1
ffffffffc02027b6:	739c                	ld	a5,32(a5)
ffffffffc02027b8:	9782                	jalr	a5
        intr_enable();
ffffffffc02027ba:	956fe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc02027be:	b55d                	j	ffffffffc0202664 <pmm_init+0x582>
ffffffffc02027c0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027c2:	954fe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
ffffffffc02027c6:	000b3783          	ld	a5,0(s6)
ffffffffc02027ca:	6522                	ld	a0,8(sp)
ffffffffc02027cc:	4585                	li	a1,1
ffffffffc02027ce:	739c                	ld	a5,32(a5)
ffffffffc02027d0:	9782                	jalr	a5
        intr_enable();
ffffffffc02027d2:	93efe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc02027d6:	bdb9                	j	ffffffffc0202634 <pmm_init+0x552>
        intr_disable();
ffffffffc02027d8:	93efe0ef          	jal	ra,ffffffffc0200916 <intr_disable>
ffffffffc02027dc:	000b3783          	ld	a5,0(s6)
ffffffffc02027e0:	4585                	li	a1,1
ffffffffc02027e2:	8552                	mv	a0,s4
ffffffffc02027e4:	739c                	ld	a5,32(a5)
ffffffffc02027e6:	9782                	jalr	a5
        intr_enable();
ffffffffc02027e8:	928fe0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc02027ec:	bd29                	j	ffffffffc0202606 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02027ee:	86a2                	mv	a3,s0
ffffffffc02027f0:	00002617          	auipc	a2,0x2
ffffffffc02027f4:	4c860613          	addi	a2,a2,1224 # ffffffffc0204cb8 <default_pmm_manager+0x38>
ffffffffc02027f8:	1a400593          	li	a1,420
ffffffffc02027fc:	00002517          	auipc	a0,0x2
ffffffffc0202800:	5d450513          	addi	a0,a0,1492 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202804:	c57fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202808:	00003697          	auipc	a3,0x3
ffffffffc020280c:	9f068693          	addi	a3,a3,-1552 # ffffffffc02051f8 <default_pmm_manager+0x578>
ffffffffc0202810:	00002617          	auipc	a2,0x2
ffffffffc0202814:	0c060613          	addi	a2,a2,192 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202818:	1a500593          	li	a1,421
ffffffffc020281c:	00002517          	auipc	a0,0x2
ffffffffc0202820:	5b450513          	addi	a0,a0,1460 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202824:	c37fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202828:	00003697          	auipc	a3,0x3
ffffffffc020282c:	99068693          	addi	a3,a3,-1648 # ffffffffc02051b8 <default_pmm_manager+0x538>
ffffffffc0202830:	00002617          	auipc	a2,0x2
ffffffffc0202834:	0a060613          	addi	a2,a2,160 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202838:	1a400593          	li	a1,420
ffffffffc020283c:	00002517          	auipc	a0,0x2
ffffffffc0202840:	59450513          	addi	a0,a0,1428 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202844:	c17fd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc0202848:	b9cff0ef          	jal	ra,ffffffffc0201be4 <pa2page.part.0>
ffffffffc020284c:	bb4ff0ef          	jal	ra,ffffffffc0201c00 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202850:	00002697          	auipc	a3,0x2
ffffffffc0202854:	76068693          	addi	a3,a3,1888 # ffffffffc0204fb0 <default_pmm_manager+0x330>
ffffffffc0202858:	00002617          	auipc	a2,0x2
ffffffffc020285c:	07860613          	addi	a2,a2,120 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202860:	17400593          	li	a1,372
ffffffffc0202864:	00002517          	auipc	a0,0x2
ffffffffc0202868:	56c50513          	addi	a0,a0,1388 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc020286c:	beffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202870:	00002697          	auipc	a3,0x2
ffffffffc0202874:	68068693          	addi	a3,a3,1664 # ffffffffc0204ef0 <default_pmm_manager+0x270>
ffffffffc0202878:	00002617          	auipc	a2,0x2
ffffffffc020287c:	05860613          	addi	a2,a2,88 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202880:	16700593          	li	a1,359
ffffffffc0202884:	00002517          	auipc	a0,0x2
ffffffffc0202888:	54c50513          	addi	a0,a0,1356 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc020288c:	bcffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202890:	00002697          	auipc	a3,0x2
ffffffffc0202894:	62068693          	addi	a3,a3,1568 # ffffffffc0204eb0 <default_pmm_manager+0x230>
ffffffffc0202898:	00002617          	auipc	a2,0x2
ffffffffc020289c:	03860613          	addi	a2,a2,56 # ffffffffc02048d0 <commands+0x808>
ffffffffc02028a0:	16600593          	li	a1,358
ffffffffc02028a4:	00002517          	auipc	a0,0x2
ffffffffc02028a8:	52c50513          	addi	a0,a0,1324 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc02028ac:	baffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02028b0:	00002697          	auipc	a3,0x2
ffffffffc02028b4:	5e068693          	addi	a3,a3,1504 # ffffffffc0204e90 <default_pmm_manager+0x210>
ffffffffc02028b8:	00002617          	auipc	a2,0x2
ffffffffc02028bc:	01860613          	addi	a2,a2,24 # ffffffffc02048d0 <commands+0x808>
ffffffffc02028c0:	16500593          	li	a1,357
ffffffffc02028c4:	00002517          	auipc	a0,0x2
ffffffffc02028c8:	50c50513          	addi	a0,a0,1292 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc02028cc:	b8ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    return KADDR(page2pa(page));
ffffffffc02028d0:	00002617          	auipc	a2,0x2
ffffffffc02028d4:	3e860613          	addi	a2,a2,1000 # ffffffffc0204cb8 <default_pmm_manager+0x38>
ffffffffc02028d8:	07100593          	li	a1,113
ffffffffc02028dc:	00002517          	auipc	a0,0x2
ffffffffc02028e0:	40450513          	addi	a0,a0,1028 # ffffffffc0204ce0 <default_pmm_manager+0x60>
ffffffffc02028e4:	b77fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc02028e8:	00003697          	auipc	a3,0x3
ffffffffc02028ec:	85868693          	addi	a3,a3,-1960 # ffffffffc0205140 <default_pmm_manager+0x4c0>
ffffffffc02028f0:	00002617          	auipc	a2,0x2
ffffffffc02028f4:	fe060613          	addi	a2,a2,-32 # ffffffffc02048d0 <commands+0x808>
ffffffffc02028f8:	18d00593          	li	a1,397
ffffffffc02028fc:	00002517          	auipc	a0,0x2
ffffffffc0202900:	4d450513          	addi	a0,a0,1236 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202904:	b57fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202908:	00002697          	auipc	a3,0x2
ffffffffc020290c:	7f068693          	addi	a3,a3,2032 # ffffffffc02050f8 <default_pmm_manager+0x478>
ffffffffc0202910:	00002617          	auipc	a2,0x2
ffffffffc0202914:	fc060613          	addi	a2,a2,-64 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202918:	18b00593          	li	a1,395
ffffffffc020291c:	00002517          	auipc	a0,0x2
ffffffffc0202920:	4b450513          	addi	a0,a0,1204 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202924:	b37fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202928:	00003697          	auipc	a3,0x3
ffffffffc020292c:	80068693          	addi	a3,a3,-2048 # ffffffffc0205128 <default_pmm_manager+0x4a8>
ffffffffc0202930:	00002617          	auipc	a2,0x2
ffffffffc0202934:	fa060613          	addi	a2,a2,-96 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202938:	18a00593          	li	a1,394
ffffffffc020293c:	00002517          	auipc	a0,0x2
ffffffffc0202940:	49450513          	addi	a0,a0,1172 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202944:	b17fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202948:	00003697          	auipc	a3,0x3
ffffffffc020294c:	8c868693          	addi	a3,a3,-1848 # ffffffffc0205210 <default_pmm_manager+0x590>
ffffffffc0202950:	00002617          	auipc	a2,0x2
ffffffffc0202954:	f8060613          	addi	a2,a2,-128 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202958:	1a800593          	li	a1,424
ffffffffc020295c:	00002517          	auipc	a0,0x2
ffffffffc0202960:	47450513          	addi	a0,a0,1140 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202964:	af7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202968:	00003697          	auipc	a3,0x3
ffffffffc020296c:	80868693          	addi	a3,a3,-2040 # ffffffffc0205170 <default_pmm_manager+0x4f0>
ffffffffc0202970:	00002617          	auipc	a2,0x2
ffffffffc0202974:	f6060613          	addi	a2,a2,-160 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202978:	19500593          	li	a1,405
ffffffffc020297c:	00002517          	auipc	a0,0x2
ffffffffc0202980:	45450513          	addi	a0,a0,1108 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202984:	ad7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202988:	00003697          	auipc	a3,0x3
ffffffffc020298c:	8e068693          	addi	a3,a3,-1824 # ffffffffc0205268 <default_pmm_manager+0x5e8>
ffffffffc0202990:	00002617          	auipc	a2,0x2
ffffffffc0202994:	f4060613          	addi	a2,a2,-192 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202998:	1ad00593          	li	a1,429
ffffffffc020299c:	00002517          	auipc	a0,0x2
ffffffffc02029a0:	43450513          	addi	a0,a0,1076 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc02029a4:	ab7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02029a8:	00003697          	auipc	a3,0x3
ffffffffc02029ac:	88068693          	addi	a3,a3,-1920 # ffffffffc0205228 <default_pmm_manager+0x5a8>
ffffffffc02029b0:	00002617          	auipc	a2,0x2
ffffffffc02029b4:	f2060613          	addi	a2,a2,-224 # ffffffffc02048d0 <commands+0x808>
ffffffffc02029b8:	1ac00593          	li	a1,428
ffffffffc02029bc:	00002517          	auipc	a0,0x2
ffffffffc02029c0:	41450513          	addi	a0,a0,1044 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc02029c4:	a97fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02029c8:	00002697          	auipc	a3,0x2
ffffffffc02029cc:	73068693          	addi	a3,a3,1840 # ffffffffc02050f8 <default_pmm_manager+0x478>
ffffffffc02029d0:	00002617          	auipc	a2,0x2
ffffffffc02029d4:	f0060613          	addi	a2,a2,-256 # ffffffffc02048d0 <commands+0x808>
ffffffffc02029d8:	18700593          	li	a1,391
ffffffffc02029dc:	00002517          	auipc	a0,0x2
ffffffffc02029e0:	3f450513          	addi	a0,a0,1012 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc02029e4:	a77fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02029e8:	00002697          	auipc	a3,0x2
ffffffffc02029ec:	5b068693          	addi	a3,a3,1456 # ffffffffc0204f98 <default_pmm_manager+0x318>
ffffffffc02029f0:	00002617          	auipc	a2,0x2
ffffffffc02029f4:	ee060613          	addi	a2,a2,-288 # ffffffffc02048d0 <commands+0x808>
ffffffffc02029f8:	18600593          	li	a1,390
ffffffffc02029fc:	00002517          	auipc	a0,0x2
ffffffffc0202a00:	3d450513          	addi	a0,a0,980 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202a04:	a57fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a08:	00002697          	auipc	a3,0x2
ffffffffc0202a0c:	70868693          	addi	a3,a3,1800 # ffffffffc0205110 <default_pmm_manager+0x490>
ffffffffc0202a10:	00002617          	auipc	a2,0x2
ffffffffc0202a14:	ec060613          	addi	a2,a2,-320 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202a18:	18300593          	li	a1,387
ffffffffc0202a1c:	00002517          	auipc	a0,0x2
ffffffffc0202a20:	3b450513          	addi	a0,a0,948 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202a24:	a37fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a28:	00002697          	auipc	a3,0x2
ffffffffc0202a2c:	55868693          	addi	a3,a3,1368 # ffffffffc0204f80 <default_pmm_manager+0x300>
ffffffffc0202a30:	00002617          	auipc	a2,0x2
ffffffffc0202a34:	ea060613          	addi	a2,a2,-352 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202a38:	18200593          	li	a1,386
ffffffffc0202a3c:	00002517          	auipc	a0,0x2
ffffffffc0202a40:	39450513          	addi	a0,a0,916 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202a44:	a17fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a48:	00002697          	auipc	a3,0x2
ffffffffc0202a4c:	5d868693          	addi	a3,a3,1496 # ffffffffc0205020 <default_pmm_manager+0x3a0>
ffffffffc0202a50:	00002617          	auipc	a2,0x2
ffffffffc0202a54:	e8060613          	addi	a2,a2,-384 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202a58:	18100593          	li	a1,385
ffffffffc0202a5c:	00002517          	auipc	a0,0x2
ffffffffc0202a60:	37450513          	addi	a0,a0,884 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202a64:	9f7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a68:	00002697          	auipc	a3,0x2
ffffffffc0202a6c:	69068693          	addi	a3,a3,1680 # ffffffffc02050f8 <default_pmm_manager+0x478>
ffffffffc0202a70:	00002617          	auipc	a2,0x2
ffffffffc0202a74:	e6060613          	addi	a2,a2,-416 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202a78:	18000593          	li	a1,384
ffffffffc0202a7c:	00002517          	auipc	a0,0x2
ffffffffc0202a80:	35450513          	addi	a0,a0,852 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202a84:	9d7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202a88:	00002697          	auipc	a3,0x2
ffffffffc0202a8c:	65868693          	addi	a3,a3,1624 # ffffffffc02050e0 <default_pmm_manager+0x460>
ffffffffc0202a90:	00002617          	auipc	a2,0x2
ffffffffc0202a94:	e4060613          	addi	a2,a2,-448 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202a98:	17f00593          	li	a1,383
ffffffffc0202a9c:	00002517          	auipc	a0,0x2
ffffffffc0202aa0:	33450513          	addi	a0,a0,820 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202aa4:	9b7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202aa8:	00002697          	auipc	a3,0x2
ffffffffc0202aac:	60868693          	addi	a3,a3,1544 # ffffffffc02050b0 <default_pmm_manager+0x430>
ffffffffc0202ab0:	00002617          	auipc	a2,0x2
ffffffffc0202ab4:	e2060613          	addi	a2,a2,-480 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202ab8:	17e00593          	li	a1,382
ffffffffc0202abc:	00002517          	auipc	a0,0x2
ffffffffc0202ac0:	31450513          	addi	a0,a0,788 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202ac4:	997fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202ac8:	00002697          	auipc	a3,0x2
ffffffffc0202acc:	5d068693          	addi	a3,a3,1488 # ffffffffc0205098 <default_pmm_manager+0x418>
ffffffffc0202ad0:	00002617          	auipc	a2,0x2
ffffffffc0202ad4:	e0060613          	addi	a2,a2,-512 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202ad8:	17c00593          	li	a1,380
ffffffffc0202adc:	00002517          	auipc	a0,0x2
ffffffffc0202ae0:	2f450513          	addi	a0,a0,756 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202ae4:	977fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202ae8:	00002697          	auipc	a3,0x2
ffffffffc0202aec:	59068693          	addi	a3,a3,1424 # ffffffffc0205078 <default_pmm_manager+0x3f8>
ffffffffc0202af0:	00002617          	auipc	a2,0x2
ffffffffc0202af4:	de060613          	addi	a2,a2,-544 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202af8:	17b00593          	li	a1,379
ffffffffc0202afc:	00002517          	auipc	a0,0x2
ffffffffc0202b00:	2d450513          	addi	a0,a0,724 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202b04:	957fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202b08:	00002697          	auipc	a3,0x2
ffffffffc0202b0c:	56068693          	addi	a3,a3,1376 # ffffffffc0205068 <default_pmm_manager+0x3e8>
ffffffffc0202b10:	00002617          	auipc	a2,0x2
ffffffffc0202b14:	dc060613          	addi	a2,a2,-576 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202b18:	17a00593          	li	a1,378
ffffffffc0202b1c:	00002517          	auipc	a0,0x2
ffffffffc0202b20:	2b450513          	addi	a0,a0,692 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202b24:	937fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202b28:	00002697          	auipc	a3,0x2
ffffffffc0202b2c:	53068693          	addi	a3,a3,1328 # ffffffffc0205058 <default_pmm_manager+0x3d8>
ffffffffc0202b30:	00002617          	auipc	a2,0x2
ffffffffc0202b34:	da060613          	addi	a2,a2,-608 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202b38:	17900593          	li	a1,377
ffffffffc0202b3c:	00002517          	auipc	a0,0x2
ffffffffc0202b40:	29450513          	addi	a0,a0,660 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202b44:	917fd0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("DTB memory info not available");
ffffffffc0202b48:	00002617          	auipc	a2,0x2
ffffffffc0202b4c:	2b060613          	addi	a2,a2,688 # ffffffffc0204df8 <default_pmm_manager+0x178>
ffffffffc0202b50:	06400593          	li	a1,100
ffffffffc0202b54:	00002517          	auipc	a0,0x2
ffffffffc0202b58:	27c50513          	addi	a0,a0,636 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202b5c:	8fffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202b60:	00002697          	auipc	a3,0x2
ffffffffc0202b64:	61068693          	addi	a3,a3,1552 # ffffffffc0205170 <default_pmm_manager+0x4f0>
ffffffffc0202b68:	00002617          	auipc	a2,0x2
ffffffffc0202b6c:	d6860613          	addi	a2,a2,-664 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202b70:	1bf00593          	li	a1,447
ffffffffc0202b74:	00002517          	auipc	a0,0x2
ffffffffc0202b78:	25c50513          	addi	a0,a0,604 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202b7c:	8dffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202b80:	00002697          	auipc	a3,0x2
ffffffffc0202b84:	4a068693          	addi	a3,a3,1184 # ffffffffc0205020 <default_pmm_manager+0x3a0>
ffffffffc0202b88:	00002617          	auipc	a2,0x2
ffffffffc0202b8c:	d4860613          	addi	a2,a2,-696 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202b90:	17800593          	li	a1,376
ffffffffc0202b94:	00002517          	auipc	a0,0x2
ffffffffc0202b98:	23c50513          	addi	a0,a0,572 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202b9c:	8bffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202ba0:	00002697          	auipc	a3,0x2
ffffffffc0202ba4:	44068693          	addi	a3,a3,1088 # ffffffffc0204fe0 <default_pmm_manager+0x360>
ffffffffc0202ba8:	00002617          	auipc	a2,0x2
ffffffffc0202bac:	d2860613          	addi	a2,a2,-728 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202bb0:	17700593          	li	a1,375
ffffffffc0202bb4:	00002517          	auipc	a0,0x2
ffffffffc0202bb8:	21c50513          	addi	a0,a0,540 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202bbc:	89ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202bc0:	86d6                	mv	a3,s5
ffffffffc0202bc2:	00002617          	auipc	a2,0x2
ffffffffc0202bc6:	0f660613          	addi	a2,a2,246 # ffffffffc0204cb8 <default_pmm_manager+0x38>
ffffffffc0202bca:	17300593          	li	a1,371
ffffffffc0202bce:	00002517          	auipc	a0,0x2
ffffffffc0202bd2:	20250513          	addi	a0,a0,514 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202bd6:	885fd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202bda:	00002617          	auipc	a2,0x2
ffffffffc0202bde:	0de60613          	addi	a2,a2,222 # ffffffffc0204cb8 <default_pmm_manager+0x38>
ffffffffc0202be2:	17200593          	li	a1,370
ffffffffc0202be6:	00002517          	auipc	a0,0x2
ffffffffc0202bea:	1ea50513          	addi	a0,a0,490 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202bee:	86dfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202bf2:	00002697          	auipc	a3,0x2
ffffffffc0202bf6:	3a668693          	addi	a3,a3,934 # ffffffffc0204f98 <default_pmm_manager+0x318>
ffffffffc0202bfa:	00002617          	auipc	a2,0x2
ffffffffc0202bfe:	cd660613          	addi	a2,a2,-810 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202c02:	17000593          	li	a1,368
ffffffffc0202c06:	00002517          	auipc	a0,0x2
ffffffffc0202c0a:	1ca50513          	addi	a0,a0,458 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202c0e:	84dfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c12:	00002697          	auipc	a3,0x2
ffffffffc0202c16:	36e68693          	addi	a3,a3,878 # ffffffffc0204f80 <default_pmm_manager+0x300>
ffffffffc0202c1a:	00002617          	auipc	a2,0x2
ffffffffc0202c1e:	cb660613          	addi	a2,a2,-842 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202c22:	16f00593          	li	a1,367
ffffffffc0202c26:	00002517          	auipc	a0,0x2
ffffffffc0202c2a:	1aa50513          	addi	a0,a0,426 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202c2e:	82dfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c32:	00002697          	auipc	a3,0x2
ffffffffc0202c36:	6fe68693          	addi	a3,a3,1790 # ffffffffc0205330 <default_pmm_manager+0x6b0>
ffffffffc0202c3a:	00002617          	auipc	a2,0x2
ffffffffc0202c3e:	c9660613          	addi	a2,a2,-874 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202c42:	1b600593          	li	a1,438
ffffffffc0202c46:	00002517          	auipc	a0,0x2
ffffffffc0202c4a:	18a50513          	addi	a0,a0,394 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202c4e:	80dfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c52:	00002697          	auipc	a3,0x2
ffffffffc0202c56:	6a668693          	addi	a3,a3,1702 # ffffffffc02052f8 <default_pmm_manager+0x678>
ffffffffc0202c5a:	00002617          	auipc	a2,0x2
ffffffffc0202c5e:	c7660613          	addi	a2,a2,-906 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202c62:	1b300593          	li	a1,435
ffffffffc0202c66:	00002517          	auipc	a0,0x2
ffffffffc0202c6a:	16a50513          	addi	a0,a0,362 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202c6e:	fecfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202c72:	00002697          	auipc	a3,0x2
ffffffffc0202c76:	65668693          	addi	a3,a3,1622 # ffffffffc02052c8 <default_pmm_manager+0x648>
ffffffffc0202c7a:	00002617          	auipc	a2,0x2
ffffffffc0202c7e:	c5660613          	addi	a2,a2,-938 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202c82:	1af00593          	li	a1,431
ffffffffc0202c86:	00002517          	auipc	a0,0x2
ffffffffc0202c8a:	14a50513          	addi	a0,a0,330 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202c8e:	fccfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202c92:	00002697          	auipc	a3,0x2
ffffffffc0202c96:	5ee68693          	addi	a3,a3,1518 # ffffffffc0205280 <default_pmm_manager+0x600>
ffffffffc0202c9a:	00002617          	auipc	a2,0x2
ffffffffc0202c9e:	c3660613          	addi	a2,a2,-970 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202ca2:	1ae00593          	li	a1,430
ffffffffc0202ca6:	00002517          	auipc	a0,0x2
ffffffffc0202caa:	12a50513          	addi	a0,a0,298 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202cae:	facfd0ef          	jal	ra,ffffffffc020045a <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202cb2:	00002617          	auipc	a2,0x2
ffffffffc0202cb6:	0ae60613          	addi	a2,a2,174 # ffffffffc0204d60 <default_pmm_manager+0xe0>
ffffffffc0202cba:	0cb00593          	li	a1,203
ffffffffc0202cbe:	00002517          	auipc	a0,0x2
ffffffffc0202cc2:	11250513          	addi	a0,a0,274 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202cc6:	f94fd0ef          	jal	ra,ffffffffc020045a <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202cca:	00002617          	auipc	a2,0x2
ffffffffc0202cce:	09660613          	addi	a2,a2,150 # ffffffffc0204d60 <default_pmm_manager+0xe0>
ffffffffc0202cd2:	08000593          	li	a1,128
ffffffffc0202cd6:	00002517          	auipc	a0,0x2
ffffffffc0202cda:	0fa50513          	addi	a0,a0,250 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202cde:	f7cfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202ce2:	00002697          	auipc	a3,0x2
ffffffffc0202ce6:	26e68693          	addi	a3,a3,622 # ffffffffc0204f50 <default_pmm_manager+0x2d0>
ffffffffc0202cea:	00002617          	auipc	a2,0x2
ffffffffc0202cee:	be660613          	addi	a2,a2,-1050 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202cf2:	16e00593          	li	a1,366
ffffffffc0202cf6:	00002517          	auipc	a0,0x2
ffffffffc0202cfa:	0da50513          	addi	a0,a0,218 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202cfe:	f5cfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202d02:	00002697          	auipc	a3,0x2
ffffffffc0202d06:	21e68693          	addi	a3,a3,542 # ffffffffc0204f20 <default_pmm_manager+0x2a0>
ffffffffc0202d0a:	00002617          	auipc	a2,0x2
ffffffffc0202d0e:	bc660613          	addi	a2,a2,-1082 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202d12:	16b00593          	li	a1,363
ffffffffc0202d16:	00002517          	auipc	a0,0x2
ffffffffc0202d1a:	0ba50513          	addi	a0,a0,186 # ffffffffc0204dd0 <default_pmm_manager+0x150>
ffffffffc0202d1e:	f3cfd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202d22 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202d22:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202d24:	00002697          	auipc	a3,0x2
ffffffffc0202d28:	65468693          	addi	a3,a3,1620 # ffffffffc0205378 <default_pmm_manager+0x6f8>
ffffffffc0202d2c:	00002617          	auipc	a2,0x2
ffffffffc0202d30:	ba460613          	addi	a2,a2,-1116 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202d34:	08800593          	li	a1,136
ffffffffc0202d38:	00002517          	auipc	a0,0x2
ffffffffc0202d3c:	66050513          	addi	a0,a0,1632 # ffffffffc0205398 <default_pmm_manager+0x718>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202d40:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202d42:	f18fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202d46 <find_vma>:
{
ffffffffc0202d46:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0202d48:	c505                	beqz	a0,ffffffffc0202d70 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0202d4a:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202d4c:	c501                	beqz	a0,ffffffffc0202d54 <find_vma+0xe>
ffffffffc0202d4e:	651c                	ld	a5,8(a0)
ffffffffc0202d50:	02f5f263          	bgeu	a1,a5,ffffffffc0202d74 <find_vma+0x2e>
    return listelm->next;
ffffffffc0202d54:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0202d56:	00f68d63          	beq	a3,a5,ffffffffc0202d70 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202d5a:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7df2b04>
ffffffffc0202d5e:	00e5e663          	bltu	a1,a4,ffffffffc0202d6a <find_vma+0x24>
ffffffffc0202d62:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202d66:	00e5ec63          	bltu	a1,a4,ffffffffc0202d7e <find_vma+0x38>
ffffffffc0202d6a:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202d6c:	fef697e3          	bne	a3,a5,ffffffffc0202d5a <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0202d70:	4501                	li	a0,0
}
ffffffffc0202d72:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202d74:	691c                	ld	a5,16(a0)
ffffffffc0202d76:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0202d54 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0202d7a:	ea88                	sd	a0,16(a3)
ffffffffc0202d7c:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202d7e:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202d82:	ea88                	sd	a0,16(a3)
ffffffffc0202d84:	8082                	ret

ffffffffc0202d86 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202d86:	6590                	ld	a2,8(a1)
ffffffffc0202d88:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202d8c:	1141                	addi	sp,sp,-16
ffffffffc0202d8e:	e406                	sd	ra,8(sp)
ffffffffc0202d90:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202d92:	01066763          	bltu	a2,a6,ffffffffc0202da0 <insert_vma_struct+0x1a>
ffffffffc0202d96:	a085                	j	ffffffffc0202df6 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202d98:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202d9c:	04e66863          	bltu	a2,a4,ffffffffc0202dec <insert_vma_struct+0x66>
ffffffffc0202da0:	86be                	mv	a3,a5
ffffffffc0202da2:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202da4:	fef51ae3          	bne	a0,a5,ffffffffc0202d98 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202da8:	02a68463          	beq	a3,a0,ffffffffc0202dd0 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202dac:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202db0:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202db4:	08e8f163          	bgeu	a7,a4,ffffffffc0202e36 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202db8:	04e66f63          	bltu	a2,a4,ffffffffc0202e16 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0202dbc:	00f50a63          	beq	a0,a5,ffffffffc0202dd0 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202dc0:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202dc4:	05076963          	bltu	a4,a6,ffffffffc0202e16 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0202dc8:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202dcc:	02c77363          	bgeu	a4,a2,ffffffffc0202df2 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202dd0:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202dd2:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202dd4:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202dd8:	e390                	sd	a2,0(a5)
ffffffffc0202dda:	e690                	sd	a2,8(a3)
}
ffffffffc0202ddc:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202dde:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202de0:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202de2:	0017079b          	addiw	a5,a4,1
ffffffffc0202de6:	d11c                	sw	a5,32(a0)
}
ffffffffc0202de8:	0141                	addi	sp,sp,16
ffffffffc0202dea:	8082                	ret
    if (le_prev != list)
ffffffffc0202dec:	fca690e3          	bne	a3,a0,ffffffffc0202dac <insert_vma_struct+0x26>
ffffffffc0202df0:	bfd1                	j	ffffffffc0202dc4 <insert_vma_struct+0x3e>
ffffffffc0202df2:	f31ff0ef          	jal	ra,ffffffffc0202d22 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202df6:	00002697          	auipc	a3,0x2
ffffffffc0202dfa:	5b268693          	addi	a3,a3,1458 # ffffffffc02053a8 <default_pmm_manager+0x728>
ffffffffc0202dfe:	00002617          	auipc	a2,0x2
ffffffffc0202e02:	ad260613          	addi	a2,a2,-1326 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202e06:	08e00593          	li	a1,142
ffffffffc0202e0a:	00002517          	auipc	a0,0x2
ffffffffc0202e0e:	58e50513          	addi	a0,a0,1422 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc0202e12:	e48fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e16:	00002697          	auipc	a3,0x2
ffffffffc0202e1a:	5d268693          	addi	a3,a3,1490 # ffffffffc02053e8 <default_pmm_manager+0x768>
ffffffffc0202e1e:	00002617          	auipc	a2,0x2
ffffffffc0202e22:	ab260613          	addi	a2,a2,-1358 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202e26:	08700593          	li	a1,135
ffffffffc0202e2a:	00002517          	auipc	a0,0x2
ffffffffc0202e2e:	56e50513          	addi	a0,a0,1390 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc0202e32:	e28fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e36:	00002697          	auipc	a3,0x2
ffffffffc0202e3a:	59268693          	addi	a3,a3,1426 # ffffffffc02053c8 <default_pmm_manager+0x748>
ffffffffc0202e3e:	00002617          	auipc	a2,0x2
ffffffffc0202e42:	a9260613          	addi	a2,a2,-1390 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202e46:	08600593          	li	a1,134
ffffffffc0202e4a:	00002517          	auipc	a0,0x2
ffffffffc0202e4e:	54e50513          	addi	a0,a0,1358 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc0202e52:	e08fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202e56 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202e56:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202e58:	03000513          	li	a0,48
{
ffffffffc0202e5c:	fc06                	sd	ra,56(sp)
ffffffffc0202e5e:	f822                	sd	s0,48(sp)
ffffffffc0202e60:	f426                	sd	s1,40(sp)
ffffffffc0202e62:	f04a                	sd	s2,32(sp)
ffffffffc0202e64:	ec4e                	sd	s3,24(sp)
ffffffffc0202e66:	e852                	sd	s4,16(sp)
ffffffffc0202e68:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202e6a:	bd5fe0ef          	jal	ra,ffffffffc0201a3e <kmalloc>
    if (mm != NULL)
ffffffffc0202e6e:	2e050f63          	beqz	a0,ffffffffc020316c <vmm_init+0x316>
ffffffffc0202e72:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0202e74:	e508                	sd	a0,8(a0)
ffffffffc0202e76:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202e78:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202e7c:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202e80:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202e84:	02053423          	sd	zero,40(a0)
ffffffffc0202e88:	03200413          	li	s0,50
ffffffffc0202e8c:	a811                	j	ffffffffc0202ea0 <vmm_init+0x4a>
        vma->vm_start = vm_start;
ffffffffc0202e8e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202e90:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202e92:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0202e96:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202e98:	8526                	mv	a0,s1
ffffffffc0202e9a:	eedff0ef          	jal	ra,ffffffffc0202d86 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202e9e:	c80d                	beqz	s0,ffffffffc0202ed0 <vmm_init+0x7a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202ea0:	03000513          	li	a0,48
ffffffffc0202ea4:	b9bfe0ef          	jal	ra,ffffffffc0201a3e <kmalloc>
ffffffffc0202ea8:	85aa                	mv	a1,a0
ffffffffc0202eaa:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202eae:	f165                	bnez	a0,ffffffffc0202e8e <vmm_init+0x38>
        assert(vma != NULL);
ffffffffc0202eb0:	00002697          	auipc	a3,0x2
ffffffffc0202eb4:	6d068693          	addi	a3,a3,1744 # ffffffffc0205580 <default_pmm_manager+0x900>
ffffffffc0202eb8:	00002617          	auipc	a2,0x2
ffffffffc0202ebc:	a1860613          	addi	a2,a2,-1512 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202ec0:	0da00593          	li	a1,218
ffffffffc0202ec4:	00002517          	auipc	a0,0x2
ffffffffc0202ec8:	4d450513          	addi	a0,a0,1236 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc0202ecc:	d8efd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc0202ed0:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202ed4:	1f900913          	li	s2,505
ffffffffc0202ed8:	a819                	j	ffffffffc0202eee <vmm_init+0x98>
        vma->vm_start = vm_start;
ffffffffc0202eda:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202edc:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202ede:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202ee2:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202ee4:	8526                	mv	a0,s1
ffffffffc0202ee6:	ea1ff0ef          	jal	ra,ffffffffc0202d86 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202eea:	03240a63          	beq	s0,s2,ffffffffc0202f1e <vmm_init+0xc8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202eee:	03000513          	li	a0,48
ffffffffc0202ef2:	b4dfe0ef          	jal	ra,ffffffffc0201a3e <kmalloc>
ffffffffc0202ef6:	85aa                	mv	a1,a0
ffffffffc0202ef8:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202efc:	fd79                	bnez	a0,ffffffffc0202eda <vmm_init+0x84>
        assert(vma != NULL);
ffffffffc0202efe:	00002697          	auipc	a3,0x2
ffffffffc0202f02:	68268693          	addi	a3,a3,1666 # ffffffffc0205580 <default_pmm_manager+0x900>
ffffffffc0202f06:	00002617          	auipc	a2,0x2
ffffffffc0202f0a:	9ca60613          	addi	a2,a2,-1590 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202f0e:	0e100593          	li	a1,225
ffffffffc0202f12:	00002517          	auipc	a0,0x2
ffffffffc0202f16:	48650513          	addi	a0,a0,1158 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc0202f1a:	d40fd0ef          	jal	ra,ffffffffc020045a <__panic>
    return listelm->next;
ffffffffc0202f1e:	649c                	ld	a5,8(s1)
ffffffffc0202f20:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202f22:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202f26:	18f48363          	beq	s1,a5,ffffffffc02030ac <vmm_init+0x256>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202f2a:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202f2e:	ffe70693          	addi	a3,a4,-2 # ffe <kern_entry-0xffffffffc01ff002>
ffffffffc0202f32:	10d61d63          	bne	a2,a3,ffffffffc020304c <vmm_init+0x1f6>
ffffffffc0202f36:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202f3a:	10e69963          	bne	a3,a4,ffffffffc020304c <vmm_init+0x1f6>
    for (i = 1; i <= step2; i++)
ffffffffc0202f3e:	0715                	addi	a4,a4,5
ffffffffc0202f40:	679c                	ld	a5,8(a5)
ffffffffc0202f42:	feb712e3          	bne	a4,a1,ffffffffc0202f26 <vmm_init+0xd0>
ffffffffc0202f46:	4a1d                	li	s4,7
ffffffffc0202f48:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202f4a:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202f4e:	85a2                	mv	a1,s0
ffffffffc0202f50:	8526                	mv	a0,s1
ffffffffc0202f52:	df5ff0ef          	jal	ra,ffffffffc0202d46 <find_vma>
ffffffffc0202f56:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0202f58:	18050a63          	beqz	a0,ffffffffc02030ec <vmm_init+0x296>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202f5c:	00140593          	addi	a1,s0,1
ffffffffc0202f60:	8526                	mv	a0,s1
ffffffffc0202f62:	de5ff0ef          	jal	ra,ffffffffc0202d46 <find_vma>
ffffffffc0202f66:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202f68:	16050263          	beqz	a0,ffffffffc02030cc <vmm_init+0x276>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202f6c:	85d2                	mv	a1,s4
ffffffffc0202f6e:	8526                	mv	a0,s1
ffffffffc0202f70:	dd7ff0ef          	jal	ra,ffffffffc0202d46 <find_vma>
        assert(vma3 == NULL);
ffffffffc0202f74:	18051c63          	bnez	a0,ffffffffc020310c <vmm_init+0x2b6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202f78:	00340593          	addi	a1,s0,3
ffffffffc0202f7c:	8526                	mv	a0,s1
ffffffffc0202f7e:	dc9ff0ef          	jal	ra,ffffffffc0202d46 <find_vma>
        assert(vma4 == NULL);
ffffffffc0202f82:	1c051563          	bnez	a0,ffffffffc020314c <vmm_init+0x2f6>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202f86:	00440593          	addi	a1,s0,4
ffffffffc0202f8a:	8526                	mv	a0,s1
ffffffffc0202f8c:	dbbff0ef          	jal	ra,ffffffffc0202d46 <find_vma>
        assert(vma5 == NULL);
ffffffffc0202f90:	18051e63          	bnez	a0,ffffffffc020312c <vmm_init+0x2d6>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202f94:	00893783          	ld	a5,8(s2)
ffffffffc0202f98:	0c879a63          	bne	a5,s0,ffffffffc020306c <vmm_init+0x216>
ffffffffc0202f9c:	01093783          	ld	a5,16(s2)
ffffffffc0202fa0:	0d479663          	bne	a5,s4,ffffffffc020306c <vmm_init+0x216>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202fa4:	0089b783          	ld	a5,8(s3)
ffffffffc0202fa8:	0e879263          	bne	a5,s0,ffffffffc020308c <vmm_init+0x236>
ffffffffc0202fac:	0109b783          	ld	a5,16(s3)
ffffffffc0202fb0:	0d479e63          	bne	a5,s4,ffffffffc020308c <vmm_init+0x236>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202fb4:	0415                	addi	s0,s0,5
ffffffffc0202fb6:	0a15                	addi	s4,s4,5
ffffffffc0202fb8:	f9541be3          	bne	s0,s5,ffffffffc0202f4e <vmm_init+0xf8>
ffffffffc0202fbc:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0202fbe:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0202fc0:	85a2                	mv	a1,s0
ffffffffc0202fc2:	8526                	mv	a0,s1
ffffffffc0202fc4:	d83ff0ef          	jal	ra,ffffffffc0202d46 <find_vma>
ffffffffc0202fc8:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0202fcc:	c90d                	beqz	a0,ffffffffc0202ffe <vmm_init+0x1a8>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0202fce:	6914                	ld	a3,16(a0)
ffffffffc0202fd0:	6510                	ld	a2,8(a0)
ffffffffc0202fd2:	00002517          	auipc	a0,0x2
ffffffffc0202fd6:	53650513          	addi	a0,a0,1334 # ffffffffc0205508 <default_pmm_manager+0x888>
ffffffffc0202fda:	9bafd0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0202fde:	00002697          	auipc	a3,0x2
ffffffffc0202fe2:	55268693          	addi	a3,a3,1362 # ffffffffc0205530 <default_pmm_manager+0x8b0>
ffffffffc0202fe6:	00002617          	auipc	a2,0x2
ffffffffc0202fea:	8ea60613          	addi	a2,a2,-1814 # ffffffffc02048d0 <commands+0x808>
ffffffffc0202fee:	10700593          	li	a1,263
ffffffffc0202ff2:	00002517          	auipc	a0,0x2
ffffffffc0202ff6:	3a650513          	addi	a0,a0,934 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc0202ffa:	c60fd0ef          	jal	ra,ffffffffc020045a <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0202ffe:	147d                	addi	s0,s0,-1
ffffffffc0203000:	fd2410e3          	bne	s0,s2,ffffffffc0202fc0 <vmm_init+0x16a>
ffffffffc0203004:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc0203006:	00a48c63          	beq	s1,a0,ffffffffc020301e <vmm_init+0x1c8>
    __list_del(listelm->prev, listelm->next);
ffffffffc020300a:	6118                	ld	a4,0(a0)
ffffffffc020300c:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020300e:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203010:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203012:	e398                	sd	a4,0(a5)
ffffffffc0203014:	adbfe0ef          	jal	ra,ffffffffc0201aee <kfree>
    return listelm->next;
ffffffffc0203018:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc020301a:	fea498e3          	bne	s1,a0,ffffffffc020300a <vmm_init+0x1b4>
    kfree(mm); // kfree mm
ffffffffc020301e:	8526                	mv	a0,s1
ffffffffc0203020:	acffe0ef          	jal	ra,ffffffffc0201aee <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203024:	00002517          	auipc	a0,0x2
ffffffffc0203028:	52450513          	addi	a0,a0,1316 # ffffffffc0205548 <default_pmm_manager+0x8c8>
ffffffffc020302c:	968fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203030:	7442                	ld	s0,48(sp)
ffffffffc0203032:	70e2                	ld	ra,56(sp)
ffffffffc0203034:	74a2                	ld	s1,40(sp)
ffffffffc0203036:	7902                	ld	s2,32(sp)
ffffffffc0203038:	69e2                	ld	s3,24(sp)
ffffffffc020303a:	6a42                	ld	s4,16(sp)
ffffffffc020303c:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc020303e:	00002517          	auipc	a0,0x2
ffffffffc0203042:	52a50513          	addi	a0,a0,1322 # ffffffffc0205568 <default_pmm_manager+0x8e8>
}
ffffffffc0203046:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203048:	94cfd06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020304c:	00002697          	auipc	a3,0x2
ffffffffc0203050:	3d468693          	addi	a3,a3,980 # ffffffffc0205420 <default_pmm_manager+0x7a0>
ffffffffc0203054:	00002617          	auipc	a2,0x2
ffffffffc0203058:	87c60613          	addi	a2,a2,-1924 # ffffffffc02048d0 <commands+0x808>
ffffffffc020305c:	0eb00593          	li	a1,235
ffffffffc0203060:	00002517          	auipc	a0,0x2
ffffffffc0203064:	33850513          	addi	a0,a0,824 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc0203068:	bf2fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc020306c:	00002697          	auipc	a3,0x2
ffffffffc0203070:	43c68693          	addi	a3,a3,1084 # ffffffffc02054a8 <default_pmm_manager+0x828>
ffffffffc0203074:	00002617          	auipc	a2,0x2
ffffffffc0203078:	85c60613          	addi	a2,a2,-1956 # ffffffffc02048d0 <commands+0x808>
ffffffffc020307c:	0fc00593          	li	a1,252
ffffffffc0203080:	00002517          	auipc	a0,0x2
ffffffffc0203084:	31850513          	addi	a0,a0,792 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc0203088:	bd2fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc020308c:	00002697          	auipc	a3,0x2
ffffffffc0203090:	44c68693          	addi	a3,a3,1100 # ffffffffc02054d8 <default_pmm_manager+0x858>
ffffffffc0203094:	00002617          	auipc	a2,0x2
ffffffffc0203098:	83c60613          	addi	a2,a2,-1988 # ffffffffc02048d0 <commands+0x808>
ffffffffc020309c:	0fd00593          	li	a1,253
ffffffffc02030a0:	00002517          	auipc	a0,0x2
ffffffffc02030a4:	2f850513          	addi	a0,a0,760 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc02030a8:	bb2fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02030ac:	00002697          	auipc	a3,0x2
ffffffffc02030b0:	35c68693          	addi	a3,a3,860 # ffffffffc0205408 <default_pmm_manager+0x788>
ffffffffc02030b4:	00002617          	auipc	a2,0x2
ffffffffc02030b8:	81c60613          	addi	a2,a2,-2020 # ffffffffc02048d0 <commands+0x808>
ffffffffc02030bc:	0e900593          	li	a1,233
ffffffffc02030c0:	00002517          	auipc	a0,0x2
ffffffffc02030c4:	2d850513          	addi	a0,a0,728 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc02030c8:	b92fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2 != NULL);
ffffffffc02030cc:	00002697          	auipc	a3,0x2
ffffffffc02030d0:	39c68693          	addi	a3,a3,924 # ffffffffc0205468 <default_pmm_manager+0x7e8>
ffffffffc02030d4:	00001617          	auipc	a2,0x1
ffffffffc02030d8:	7fc60613          	addi	a2,a2,2044 # ffffffffc02048d0 <commands+0x808>
ffffffffc02030dc:	0f400593          	li	a1,244
ffffffffc02030e0:	00002517          	auipc	a0,0x2
ffffffffc02030e4:	2b850513          	addi	a0,a0,696 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc02030e8:	b72fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1 != NULL);
ffffffffc02030ec:	00002697          	auipc	a3,0x2
ffffffffc02030f0:	36c68693          	addi	a3,a3,876 # ffffffffc0205458 <default_pmm_manager+0x7d8>
ffffffffc02030f4:	00001617          	auipc	a2,0x1
ffffffffc02030f8:	7dc60613          	addi	a2,a2,2012 # ffffffffc02048d0 <commands+0x808>
ffffffffc02030fc:	0f200593          	li	a1,242
ffffffffc0203100:	00002517          	auipc	a0,0x2
ffffffffc0203104:	29850513          	addi	a0,a0,664 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc0203108:	b52fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma3 == NULL);
ffffffffc020310c:	00002697          	auipc	a3,0x2
ffffffffc0203110:	36c68693          	addi	a3,a3,876 # ffffffffc0205478 <default_pmm_manager+0x7f8>
ffffffffc0203114:	00001617          	auipc	a2,0x1
ffffffffc0203118:	7bc60613          	addi	a2,a2,1980 # ffffffffc02048d0 <commands+0x808>
ffffffffc020311c:	0f600593          	li	a1,246
ffffffffc0203120:	00002517          	auipc	a0,0x2
ffffffffc0203124:	27850513          	addi	a0,a0,632 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc0203128:	b32fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma5 == NULL);
ffffffffc020312c:	00002697          	auipc	a3,0x2
ffffffffc0203130:	36c68693          	addi	a3,a3,876 # ffffffffc0205498 <default_pmm_manager+0x818>
ffffffffc0203134:	00001617          	auipc	a2,0x1
ffffffffc0203138:	79c60613          	addi	a2,a2,1948 # ffffffffc02048d0 <commands+0x808>
ffffffffc020313c:	0fa00593          	li	a1,250
ffffffffc0203140:	00002517          	auipc	a0,0x2
ffffffffc0203144:	25850513          	addi	a0,a0,600 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc0203148:	b12fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma4 == NULL);
ffffffffc020314c:	00002697          	auipc	a3,0x2
ffffffffc0203150:	33c68693          	addi	a3,a3,828 # ffffffffc0205488 <default_pmm_manager+0x808>
ffffffffc0203154:	00001617          	auipc	a2,0x1
ffffffffc0203158:	77c60613          	addi	a2,a2,1916 # ffffffffc02048d0 <commands+0x808>
ffffffffc020315c:	0f800593          	li	a1,248
ffffffffc0203160:	00002517          	auipc	a0,0x2
ffffffffc0203164:	23850513          	addi	a0,a0,568 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc0203168:	af2fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(mm != NULL);
ffffffffc020316c:	00002697          	auipc	a3,0x2
ffffffffc0203170:	42468693          	addi	a3,a3,1060 # ffffffffc0205590 <default_pmm_manager+0x910>
ffffffffc0203174:	00001617          	auipc	a2,0x1
ffffffffc0203178:	75c60613          	addi	a2,a2,1884 # ffffffffc02048d0 <commands+0x808>
ffffffffc020317c:	0d200593          	li	a1,210
ffffffffc0203180:	00002517          	auipc	a0,0x2
ffffffffc0203184:	21850513          	addi	a0,a0,536 # ffffffffc0205398 <default_pmm_manager+0x718>
ffffffffc0203188:	ad2fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc020318c <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc020318c:	8526                	mv	a0,s1
	jalr s0
ffffffffc020318e:	9402                	jalr	s0

	jal do_exit
ffffffffc0203190:	426000ef          	jal	ra,ffffffffc02035b6 <do_exit>

ffffffffc0203194 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203194:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203196:	0e800513          	li	a0,232
{
ffffffffc020319a:	e022                	sd	s0,0(sp)
ffffffffc020319c:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020319e:	8a1fe0ef          	jal	ra,ffffffffc0201a3e <kmalloc>
ffffffffc02031a2:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc02031a4:	c521                	beqz	a0,ffffffffc02031ec <alloc_proc+0x58>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;      // ����״̬��Ϊδ��ʼ��
ffffffffc02031a6:	57fd                	li	a5,-1
ffffffffc02031a8:	1782                	slli	a5,a5,0x20
ffffffffc02031aa:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                 // ���д�����ʼ��Ϊ0
        proc->kstack = 0;               // �ں�ջ��ַ��ʼ��Ϊ0
        proc->need_resched = 0;         // ����Ҫ���µ���
        proc->parent = NULL;            // ������ָ����ΪNULL
        proc->mm = NULL;                // �ڴ�����ṹ��ΪNULL
        memset(&(proc->context), 0, sizeof(struct context)); // ����������
ffffffffc02031ac:	07000613          	li	a2,112
ffffffffc02031b0:	4581                	li	a1,0
        proc->runs = 0;                 // ���д�����ʼ��Ϊ0
ffffffffc02031b2:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;               // �ں�ջ��ַ��ʼ��Ϊ0
ffffffffc02031b6:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;         // ����Ҫ���µ���
ffffffffc02031ba:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;            // ������ָ����ΪNULL
ffffffffc02031be:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                // �ڴ�����ṹ��ΪNULL
ffffffffc02031c2:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // ����������
ffffffffc02031c6:	03050513          	addi	a0,a0,48
ffffffffc02031ca:	449000ef          	jal	ra,ffffffffc0203e12 <memset>
        proc->tf = NULL;                // ����ָ֡����ΪNULL
        proc->pgdir = boot_pgdir_pa;             // ҳĿ¼��ַ��ΪNULL
ffffffffc02031ce:	0000a797          	auipc	a5,0xa
ffffffffc02031d2:	2ca7b783          	ld	a5,714(a5) # ffffffffc020d498 <boot_pgdir_pa>
        proc->tf = NULL;                // ����ָ֡����ΪNULL
ffffffffc02031d6:	0a043023          	sd	zero,160(s0)
        proc->pgdir = boot_pgdir_pa;             // ҳĿ¼��ַ��ΪNULL
ffffffffc02031da:	f45c                	sd	a5,168(s0)
        proc->flags = 0;                // ���̱�־����
ffffffffc02031dc:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1); // ����������
ffffffffc02031e0:	4641                	li	a2,16
ffffffffc02031e2:	4581                	li	a1,0
ffffffffc02031e4:	0b440513          	addi	a0,s0,180
ffffffffc02031e8:	42b000ef          	jal	ra,ffffffffc0203e12 <memset>
        
    }
    return proc;
}
ffffffffc02031ec:	60a2                	ld	ra,8(sp)
ffffffffc02031ee:	8522                	mv	a0,s0
ffffffffc02031f0:	6402                	ld	s0,0(sp)
ffffffffc02031f2:	0141                	addi	sp,sp,16
ffffffffc02031f4:	8082                	ret

ffffffffc02031f6 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc02031f6:	0000a797          	auipc	a5,0xa
ffffffffc02031fa:	2d27b783          	ld	a5,722(a5) # ffffffffc020d4c8 <current>
ffffffffc02031fe:	73c8                	ld	a0,160(a5)
ffffffffc0203200:	b5dfd06f          	j	ffffffffc0200d5c <forkrets>

ffffffffc0203204 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0203204:	7179                	addi	sp,sp,-48
ffffffffc0203206:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc0203208:	0000a497          	auipc	s1,0xa
ffffffffc020320c:	24048493          	addi	s1,s1,576 # ffffffffc020d448 <name.2>
{
ffffffffc0203210:	f022                	sd	s0,32(sp)
ffffffffc0203212:	e84a                	sd	s2,16(sp)
ffffffffc0203214:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203216:	0000a917          	auipc	s2,0xa
ffffffffc020321a:	2b293903          	ld	s2,690(s2) # ffffffffc020d4c8 <current>
    memset(name, 0, sizeof(name));
ffffffffc020321e:	4641                	li	a2,16
ffffffffc0203220:	4581                	li	a1,0
ffffffffc0203222:	8526                	mv	a0,s1
{
ffffffffc0203224:	f406                	sd	ra,40(sp)
ffffffffc0203226:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203228:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));
ffffffffc020322c:	3e7000ef          	jal	ra,ffffffffc0203e12 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc0203230:	0b490593          	addi	a1,s2,180
ffffffffc0203234:	463d                	li	a2,15
ffffffffc0203236:	8526                	mv	a0,s1
ffffffffc0203238:	3ed000ef          	jal	ra,ffffffffc0203e24 <memcpy>
ffffffffc020323c:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020323e:	85ce                	mv	a1,s3
ffffffffc0203240:	00002517          	auipc	a0,0x2
ffffffffc0203244:	36050513          	addi	a0,a0,864 # ffffffffc02055a0 <default_pmm_manager+0x920>
ffffffffc0203248:	f4dfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc020324c:	85a2                	mv	a1,s0
ffffffffc020324e:	00002517          	auipc	a0,0x2
ffffffffc0203252:	37a50513          	addi	a0,a0,890 # ffffffffc02055c8 <default_pmm_manager+0x948>
ffffffffc0203256:	f3ffc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc020325a:	00002517          	auipc	a0,0x2
ffffffffc020325e:	37e50513          	addi	a0,a0,894 # ffffffffc02055d8 <default_pmm_manager+0x958>
ffffffffc0203262:	f33fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0203266:	70a2                	ld	ra,40(sp)
ffffffffc0203268:	7402                	ld	s0,32(sp)
ffffffffc020326a:	64e2                	ld	s1,24(sp)
ffffffffc020326c:	6942                	ld	s2,16(sp)
ffffffffc020326e:	69a2                	ld	s3,8(sp)
ffffffffc0203270:	4501                	li	a0,0
ffffffffc0203272:	6145                	addi	sp,sp,48
ffffffffc0203274:	8082                	ret

ffffffffc0203276 <proc_run>:
{
ffffffffc0203276:	7179                	addi	sp,sp,-48
ffffffffc0203278:	ec26                	sd	s1,24(sp)
    if (proc != current)
ffffffffc020327a:	0000a497          	auipc	s1,0xa
ffffffffc020327e:	24e48493          	addi	s1,s1,590 # ffffffffc020d4c8 <current>
ffffffffc0203282:	609c                	ld	a5,0(s1)
{
ffffffffc0203284:	f406                	sd	ra,40(sp)
ffffffffc0203286:	f022                	sd	s0,32(sp)
    if (proc != current)
ffffffffc0203288:	02a78a63          	beq	a5,a0,ffffffffc02032bc <proc_run+0x46>
ffffffffc020328c:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020328e:	10002773          	csrr	a4,sstatus
ffffffffc0203292:	8b09                	andi	a4,a4,2
        switch_to(&(prev->context), &(next->context));
ffffffffc0203294:	03078513          	addi	a0,a5,48
ffffffffc0203298:	03040593          	addi	a1,s0,48
ffffffffc020329c:	e70d                	bnez	a4,ffffffffc02032c6 <proc_run+0x50>
        if (next->pgdir != NULL) {
ffffffffc020329e:	745c                	ld	a5,168(s0)
        current = proc;
ffffffffc02032a0:	e080                	sd	s0,0(s1)
        if (next->pgdir != NULL) {
ffffffffc02032a2:	cb81                	beqz	a5,ffffffffc02032b2 <proc_run+0x3c>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc02032a4:	80000737          	lui	a4,0x80000
ffffffffc02032a8:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc02032ac:	8fd9                	or	a5,a5,a4
ffffffffc02032ae:	18079073          	csrw	satp,a5
}
ffffffffc02032b2:	7402                	ld	s0,32(sp)
ffffffffc02032b4:	70a2                	ld	ra,40(sp)
ffffffffc02032b6:	64e2                	ld	s1,24(sp)
ffffffffc02032b8:	6145                	addi	sp,sp,48
        switch_to(&(prev->context), &(next->context));
ffffffffc02032ba:	a349                	j	ffffffffc020383c <switch_to>
}
ffffffffc02032bc:	70a2                	ld	ra,40(sp)
ffffffffc02032be:	7402                	ld	s0,32(sp)
ffffffffc02032c0:	64e2                	ld	s1,24(sp)
ffffffffc02032c2:	6145                	addi	sp,sp,48
ffffffffc02032c4:	8082                	ret
ffffffffc02032c6:	e42e                	sd	a1,8(sp)
ffffffffc02032c8:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02032ca:	e4cfd0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        if (next->pgdir != NULL) {
ffffffffc02032ce:	745c                	ld	a5,168(s0)
        current = proc;
ffffffffc02032d0:	e080                	sd	s0,0(s1)
        if (next->pgdir != NULL) {
ffffffffc02032d2:	6502                	ld	a0,0(sp)
ffffffffc02032d4:	65a2                	ld	a1,8(sp)
ffffffffc02032d6:	cb81                	beqz	a5,ffffffffc02032e6 <proc_run+0x70>
ffffffffc02032d8:	80000737          	lui	a4,0x80000
ffffffffc02032dc:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc02032e0:	8fd9                	or	a5,a5,a4
ffffffffc02032e2:	18079073          	csrw	satp,a5
        switch_to(&(prev->context), &(next->context));
ffffffffc02032e6:	556000ef          	jal	ra,ffffffffc020383c <switch_to>
}
ffffffffc02032ea:	7402                	ld	s0,32(sp)
ffffffffc02032ec:	70a2                	ld	ra,40(sp)
ffffffffc02032ee:	64e2                	ld	s1,24(sp)
ffffffffc02032f0:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc02032f2:	e1efd06f          	j	ffffffffc0200910 <intr_enable>

ffffffffc02032f6 <do_fork>:
{
ffffffffc02032f6:	7179                	addi	sp,sp,-48
ffffffffc02032f8:	ec26                	sd	s1,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02032fa:	0000a497          	auipc	s1,0xa
ffffffffc02032fe:	1e648493          	addi	s1,s1,486 # ffffffffc020d4e0 <nr_process>
ffffffffc0203302:	4098                	lw	a4,0(s1)
{
ffffffffc0203304:	f406                	sd	ra,40(sp)
ffffffffc0203306:	f022                	sd	s0,32(sp)
ffffffffc0203308:	e84a                	sd	s2,16(sp)
ffffffffc020330a:	e44e                	sd	s3,8(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020330c:	6785                	lui	a5,0x1
ffffffffc020330e:	20f75963          	bge	a4,a5,ffffffffc0203520 <do_fork+0x22a>
ffffffffc0203312:	892e                	mv	s2,a1
ffffffffc0203314:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc0203316:	e7fff0ef          	jal	ra,ffffffffc0203194 <alloc_proc>
ffffffffc020331a:	89aa                	mv	s3,a0
ffffffffc020331c:	20050763          	beqz	a0,ffffffffc020352a <do_fork+0x234>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203320:	4509                	li	a0,2
ffffffffc0203322:	8fbfe0ef          	jal	ra,ffffffffc0201c1c <alloc_pages>
    if (page != NULL)
ffffffffc0203326:	1e050863          	beqz	a0,ffffffffc0203516 <do_fork+0x220>
    return page - pages + nbase;
ffffffffc020332a:	0000a697          	auipc	a3,0xa
ffffffffc020332e:	1866b683          	ld	a3,390(a3) # ffffffffc020d4b0 <pages>
ffffffffc0203332:	40d506b3          	sub	a3,a0,a3
ffffffffc0203336:	8699                	srai	a3,a3,0x6
ffffffffc0203338:	00002517          	auipc	a0,0x2
ffffffffc020333c:	66053503          	ld	a0,1632(a0) # ffffffffc0205998 <nbase>
ffffffffc0203340:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc0203342:	00c69793          	slli	a5,a3,0xc
ffffffffc0203346:	83b1                	srli	a5,a5,0xc
ffffffffc0203348:	0000a717          	auipc	a4,0xa
ffffffffc020334c:	16073703          	ld	a4,352(a4) # ffffffffc020d4a8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0203350:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203352:	1ee7fe63          	bgeu	a5,a4,ffffffffc020354e <do_fork+0x258>
    assert(current->mm == NULL);
ffffffffc0203356:	0000a797          	auipc	a5,0xa
ffffffffc020335a:	1727b783          	ld	a5,370(a5) # ffffffffc020d4c8 <current>
ffffffffc020335e:	779c                	ld	a5,40(a5)
ffffffffc0203360:	0000a717          	auipc	a4,0xa
ffffffffc0203364:	16073703          	ld	a4,352(a4) # ffffffffc020d4c0 <va_pa_offset>
ffffffffc0203368:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc020336a:	00d9b823          	sd	a3,16(s3)
    assert(current->mm == NULL);
ffffffffc020336e:	1c079063          	bnez	a5,ffffffffc020352e <do_fork+0x238>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0203372:	6789                	lui	a5,0x2
ffffffffc0203374:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc0203378:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc020337a:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc020337c:	0ad9b023          	sd	a3,160(s3)
    *(proc->tf) = *tf;
ffffffffc0203380:	87b6                	mv	a5,a3
ffffffffc0203382:	12040893          	addi	a7,s0,288
ffffffffc0203386:	00063803          	ld	a6,0(a2)
ffffffffc020338a:	6608                	ld	a0,8(a2)
ffffffffc020338c:	6a0c                	ld	a1,16(a2)
ffffffffc020338e:	6e18                	ld	a4,24(a2)
ffffffffc0203390:	0107b023          	sd	a6,0(a5)
ffffffffc0203394:	e788                	sd	a0,8(a5)
ffffffffc0203396:	eb8c                	sd	a1,16(a5)
ffffffffc0203398:	ef98                	sd	a4,24(a5)
ffffffffc020339a:	02060613          	addi	a2,a2,32
ffffffffc020339e:	02078793          	addi	a5,a5,32
ffffffffc02033a2:	ff1612e3          	bne	a2,a7,ffffffffc0203386 <do_fork+0x90>
    proc->tf->gpr.a0 = 0;
ffffffffc02033a6:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02033aa:	12090463          	beqz	s2,ffffffffc02034d2 <do_fork+0x1dc>
ffffffffc02033ae:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02033b2:	00000797          	auipc	a5,0x0
ffffffffc02033b6:	e4478793          	addi	a5,a5,-444 # ffffffffc02031f6 <forkret>
ffffffffc02033ba:	02f9b823          	sd	a5,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02033be:	02d9bc23          	sd	a3,56(s3)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02033c2:	100027f3          	csrr	a5,sstatus
ffffffffc02033c6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02033c8:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02033ca:	12079563          	bnez	a5,ffffffffc02034f4 <do_fork+0x1fe>
    if (++last_pid >= MAX_PID)
ffffffffc02033ce:	00006817          	auipc	a6,0x6
ffffffffc02033d2:	c5a80813          	addi	a6,a6,-934 # ffffffffc0209028 <last_pid.1>
ffffffffc02033d6:	00082783          	lw	a5,0(a6)
ffffffffc02033da:	6709                	lui	a4,0x2
ffffffffc02033dc:	0017851b          	addiw	a0,a5,1
ffffffffc02033e0:	00a82023          	sw	a0,0(a6)
ffffffffc02033e4:	08e55063          	bge	a0,a4,ffffffffc0203464 <do_fork+0x16e>
    if (last_pid >= next_safe)
ffffffffc02033e8:	00006317          	auipc	t1,0x6
ffffffffc02033ec:	c4430313          	addi	t1,t1,-956 # ffffffffc020902c <next_safe.0>
ffffffffc02033f0:	00032783          	lw	a5,0(t1)
ffffffffc02033f4:	0000a417          	auipc	s0,0xa
ffffffffc02033f8:	06440413          	addi	s0,s0,100 # ffffffffc020d458 <proc_list>
ffffffffc02033fc:	06f55c63          	bge	a0,a5,ffffffffc0203474 <do_fork+0x17e>
        proc->pid = get_pid();
ffffffffc0203400:	00a9a223          	sw	a0,4(s3)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203404:	45a9                	li	a1,10
ffffffffc0203406:	2501                	sext.w	a0,a0
ffffffffc0203408:	564000ef          	jal	ra,ffffffffc020396c <hash32>
ffffffffc020340c:	02051793          	slli	a5,a0,0x20
ffffffffc0203410:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0203414:	00006797          	auipc	a5,0x6
ffffffffc0203418:	03478793          	addi	a5,a5,52 # ffffffffc0209448 <hash_list>
ffffffffc020341c:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc020341e:	6510                	ld	a2,8(a0)
ffffffffc0203420:	0d898793          	addi	a5,s3,216
ffffffffc0203424:	6414                	ld	a3,8(s0)
        nr_process++;
ffffffffc0203426:	4098                	lw	a4,0(s1)
    prev->next = next->prev = elm;
ffffffffc0203428:	e21c                	sd	a5,0(a2)
ffffffffc020342a:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc020342c:	0ec9b023          	sd	a2,224(s3)
        list_add(&proc_list, &(proc->list_link));
ffffffffc0203430:	0c898793          	addi	a5,s3,200
    elm->prev = prev;
ffffffffc0203434:	0ca9bc23          	sd	a0,216(s3)
    prev->next = next->prev = elm;
ffffffffc0203438:	e29c                	sd	a5,0(a3)
        nr_process++;
ffffffffc020343a:	2705                	addiw	a4,a4,1
ffffffffc020343c:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc020343e:	0cd9b823          	sd	a3,208(s3)
    elm->prev = prev;
ffffffffc0203442:	0c89b423          	sd	s0,200(s3)
ffffffffc0203446:	c098                	sw	a4,0(s1)
    if (flag) {
ffffffffc0203448:	0a091a63          	bnez	s2,ffffffffc02034fc <do_fork+0x206>
    wakeup_proc(proc);
ffffffffc020344c:	854e                	mv	a0,s3
ffffffffc020344e:	458000ef          	jal	ra,ffffffffc02038a6 <wakeup_proc>
    ret = proc->pid;
ffffffffc0203452:	0049a503          	lw	a0,4(s3)
}
ffffffffc0203456:	70a2                	ld	ra,40(sp)
ffffffffc0203458:	7402                	ld	s0,32(sp)
ffffffffc020345a:	64e2                	ld	s1,24(sp)
ffffffffc020345c:	6942                	ld	s2,16(sp)
ffffffffc020345e:	69a2                	ld	s3,8(sp)
ffffffffc0203460:	6145                	addi	sp,sp,48
ffffffffc0203462:	8082                	ret
        last_pid = 1;
ffffffffc0203464:	4785                	li	a5,1
ffffffffc0203466:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020346a:	4505                	li	a0,1
ffffffffc020346c:	00006317          	auipc	t1,0x6
ffffffffc0203470:	bc030313          	addi	t1,t1,-1088 # ffffffffc020902c <next_safe.0>
    return listelm->next;
ffffffffc0203474:	0000a417          	auipc	s0,0xa
ffffffffc0203478:	fe440413          	addi	s0,s0,-28 # ffffffffc020d458 <proc_list>
ffffffffc020347c:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0203480:	6789                	lui	a5,0x2
ffffffffc0203482:	00f32023          	sw	a5,0(t1)
ffffffffc0203486:	86aa                	mv	a3,a0
ffffffffc0203488:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020348a:	6e89                	lui	t4,0x2
ffffffffc020348c:	088e0063          	beq	t3,s0,ffffffffc020350c <do_fork+0x216>
ffffffffc0203490:	88ae                	mv	a7,a1
ffffffffc0203492:	87f2                	mv	a5,t3
ffffffffc0203494:	6609                	lui	a2,0x2
ffffffffc0203496:	a811                	j	ffffffffc02034aa <do_fork+0x1b4>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203498:	00e6d663          	bge	a3,a4,ffffffffc02034a4 <do_fork+0x1ae>
ffffffffc020349c:	00c75463          	bge	a4,a2,ffffffffc02034a4 <do_fork+0x1ae>
ffffffffc02034a0:	863a                	mv	a2,a4
ffffffffc02034a2:	4885                	li	a7,1
ffffffffc02034a4:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02034a6:	00878d63          	beq	a5,s0,ffffffffc02034c0 <do_fork+0x1ca>
            if (proc->pid == last_pid)
ffffffffc02034aa:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc02034ae:	fed715e3          	bne	a4,a3,ffffffffc0203498 <do_fork+0x1a2>
                if (++last_pid >= next_safe)
ffffffffc02034b2:	2685                	addiw	a3,a3,1
ffffffffc02034b4:	04c6d763          	bge	a3,a2,ffffffffc0203502 <do_fork+0x20c>
ffffffffc02034b8:	679c                	ld	a5,8(a5)
ffffffffc02034ba:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02034bc:	fe8797e3          	bne	a5,s0,ffffffffc02034aa <do_fork+0x1b4>
ffffffffc02034c0:	c581                	beqz	a1,ffffffffc02034c8 <do_fork+0x1d2>
ffffffffc02034c2:	00d82023          	sw	a3,0(a6)
ffffffffc02034c6:	8536                	mv	a0,a3
ffffffffc02034c8:	f2088ce3          	beqz	a7,ffffffffc0203400 <do_fork+0x10a>
ffffffffc02034cc:	00c32023          	sw	a2,0(t1)
ffffffffc02034d0:	bf05                	j	ffffffffc0203400 <do_fork+0x10a>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02034d2:	8936                	mv	s2,a3
ffffffffc02034d4:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02034d8:	00000797          	auipc	a5,0x0
ffffffffc02034dc:	d1e78793          	addi	a5,a5,-738 # ffffffffc02031f6 <forkret>
ffffffffc02034e0:	02f9b823          	sd	a5,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02034e4:	02d9bc23          	sd	a3,56(s3)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02034e8:	100027f3          	csrr	a5,sstatus
ffffffffc02034ec:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02034ee:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02034f0:	ec078fe3          	beqz	a5,ffffffffc02033ce <do_fork+0xd8>
        intr_disable();
ffffffffc02034f4:	c22fd0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        return 1;
ffffffffc02034f8:	4905                	li	s2,1
ffffffffc02034fa:	bdd1                	j	ffffffffc02033ce <do_fork+0xd8>
        intr_enable();
ffffffffc02034fc:	c14fd0ef          	jal	ra,ffffffffc0200910 <intr_enable>
ffffffffc0203500:	b7b1                	j	ffffffffc020344c <do_fork+0x156>
                    if (last_pid >= MAX_PID)
ffffffffc0203502:	01d6c363          	blt	a3,t4,ffffffffc0203508 <do_fork+0x212>
                        last_pid = 1;
ffffffffc0203506:	4685                	li	a3,1
                    goto repeat;
ffffffffc0203508:	4585                	li	a1,1
ffffffffc020350a:	b749                	j	ffffffffc020348c <do_fork+0x196>
ffffffffc020350c:	cd81                	beqz	a1,ffffffffc0203524 <do_fork+0x22e>
ffffffffc020350e:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0203512:	8536                	mv	a0,a3
ffffffffc0203514:	b5f5                	j	ffffffffc0203400 <do_fork+0x10a>
    kfree(proc);
ffffffffc0203516:	854e                	mv	a0,s3
ffffffffc0203518:	dd6fe0ef          	jal	ra,ffffffffc0201aee <kfree>
    ret = -E_NO_MEM;
ffffffffc020351c:	5571                	li	a0,-4
    goto fork_out;
ffffffffc020351e:	bf25                	j	ffffffffc0203456 <do_fork+0x160>
    int ret = -E_NO_FREE_PROC;
ffffffffc0203520:	556d                	li	a0,-5
ffffffffc0203522:	bf15                	j	ffffffffc0203456 <do_fork+0x160>
    return last_pid;
ffffffffc0203524:	00082503          	lw	a0,0(a6)
ffffffffc0203528:	bde1                	j	ffffffffc0203400 <do_fork+0x10a>
    ret = -E_NO_MEM;
ffffffffc020352a:	5571                	li	a0,-4
    return ret;
ffffffffc020352c:	b72d                	j	ffffffffc0203456 <do_fork+0x160>
    assert(current->mm == NULL);
ffffffffc020352e:	00002697          	auipc	a3,0x2
ffffffffc0203532:	0ca68693          	addi	a3,a3,202 # ffffffffc02055f8 <default_pmm_manager+0x978>
ffffffffc0203536:	00001617          	auipc	a2,0x1
ffffffffc020353a:	39a60613          	addi	a2,a2,922 # ffffffffc02048d0 <commands+0x808>
ffffffffc020353e:	12800593          	li	a1,296
ffffffffc0203542:	00002517          	auipc	a0,0x2
ffffffffc0203546:	0ce50513          	addi	a0,a0,206 # ffffffffc0205610 <default_pmm_manager+0x990>
ffffffffc020354a:	f11fc0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc020354e:	00001617          	auipc	a2,0x1
ffffffffc0203552:	76a60613          	addi	a2,a2,1898 # ffffffffc0204cb8 <default_pmm_manager+0x38>
ffffffffc0203556:	07100593          	li	a1,113
ffffffffc020355a:	00001517          	auipc	a0,0x1
ffffffffc020355e:	78650513          	addi	a0,a0,1926 # ffffffffc0204ce0 <default_pmm_manager+0x60>
ffffffffc0203562:	ef9fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203566 <kernel_thread>:
{
ffffffffc0203566:	7129                	addi	sp,sp,-320
ffffffffc0203568:	fa22                	sd	s0,304(sp)
ffffffffc020356a:	f626                	sd	s1,296(sp)
ffffffffc020356c:	f24a                	sd	s2,288(sp)
ffffffffc020356e:	84ae                	mv	s1,a1
ffffffffc0203570:	892a                	mv	s2,a0
ffffffffc0203572:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0203574:	4581                	li	a1,0
ffffffffc0203576:	12000613          	li	a2,288
ffffffffc020357a:	850a                	mv	a0,sp
{
ffffffffc020357c:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020357e:	095000ef          	jal	ra,ffffffffc0203e12 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0203582:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0203584:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0203586:	100027f3          	csrr	a5,sstatus
ffffffffc020358a:	edd7f793          	andi	a5,a5,-291
ffffffffc020358e:	1207e793          	ori	a5,a5,288
ffffffffc0203592:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203594:	860a                	mv	a2,sp
ffffffffc0203596:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020359a:	00000797          	auipc	a5,0x0
ffffffffc020359e:	bf278793          	addi	a5,a5,-1038 # ffffffffc020318c <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035a2:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02035a4:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035a6:	d51ff0ef          	jal	ra,ffffffffc02032f6 <do_fork>
}
ffffffffc02035aa:	70f2                	ld	ra,312(sp)
ffffffffc02035ac:	7452                	ld	s0,304(sp)
ffffffffc02035ae:	74b2                	ld	s1,296(sp)
ffffffffc02035b0:	7912                	ld	s2,288(sp)
ffffffffc02035b2:	6131                	addi	sp,sp,320
ffffffffc02035b4:	8082                	ret

ffffffffc02035b6 <do_exit>:
{
ffffffffc02035b6:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc02035b8:	00002617          	auipc	a2,0x2
ffffffffc02035bc:	07060613          	addi	a2,a2,112 # ffffffffc0205628 <default_pmm_manager+0x9a8>
ffffffffc02035c0:	19800593          	li	a1,408
ffffffffc02035c4:	00002517          	auipc	a0,0x2
ffffffffc02035c8:	04c50513          	addi	a0,a0,76 # ffffffffc0205610 <default_pmm_manager+0x990>
{
ffffffffc02035cc:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc02035ce:	e8dfc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02035d2 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc02035d2:	7179                	addi	sp,sp,-48
ffffffffc02035d4:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc02035d6:	0000a797          	auipc	a5,0xa
ffffffffc02035da:	e8278793          	addi	a5,a5,-382 # ffffffffc020d458 <proc_list>
ffffffffc02035de:	f406                	sd	ra,40(sp)
ffffffffc02035e0:	f022                	sd	s0,32(sp)
ffffffffc02035e2:	e84a                	sd	s2,16(sp)
ffffffffc02035e4:	e44e                	sd	s3,8(sp)
ffffffffc02035e6:	00006497          	auipc	s1,0x6
ffffffffc02035ea:	e6248493          	addi	s1,s1,-414 # ffffffffc0209448 <hash_list>
ffffffffc02035ee:	e79c                	sd	a5,8(a5)
ffffffffc02035f0:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc02035f2:	0000a717          	auipc	a4,0xa
ffffffffc02035f6:	e5670713          	addi	a4,a4,-426 # ffffffffc020d448 <name.2>
ffffffffc02035fa:	87a6                	mv	a5,s1
ffffffffc02035fc:	e79c                	sd	a5,8(a5)
ffffffffc02035fe:	e39c                	sd	a5,0(a5)
ffffffffc0203600:	07c1                	addi	a5,a5,16
ffffffffc0203602:	fef71de3          	bne	a4,a5,ffffffffc02035fc <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0203606:	b8fff0ef          	jal	ra,ffffffffc0203194 <alloc_proc>
ffffffffc020360a:	0000a917          	auipc	s2,0xa
ffffffffc020360e:	ec690913          	addi	s2,s2,-314 # ffffffffc020d4d0 <idleproc>
ffffffffc0203612:	00a93023          	sd	a0,0(s2)
ffffffffc0203616:	18050d63          	beqz	a0,ffffffffc02037b0 <proc_init+0x1de>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc020361a:	07000513          	li	a0,112
ffffffffc020361e:	c20fe0ef          	jal	ra,ffffffffc0201a3e <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0203622:	07000613          	li	a2,112
ffffffffc0203626:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0203628:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc020362a:	7e8000ef          	jal	ra,ffffffffc0203e12 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc020362e:	00093503          	ld	a0,0(s2)
ffffffffc0203632:	85a2                	mv	a1,s0
ffffffffc0203634:	07000613          	li	a2,112
ffffffffc0203638:	03050513          	addi	a0,a0,48
ffffffffc020363c:	001000ef          	jal	ra,ffffffffc0203e3c <memcmp>
ffffffffc0203640:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc0203642:	453d                	li	a0,15
ffffffffc0203644:	bfafe0ef          	jal	ra,ffffffffc0201a3e <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0203648:	463d                	li	a2,15
ffffffffc020364a:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc020364c:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc020364e:	7c4000ef          	jal	ra,ffffffffc0203e12 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc0203652:	00093503          	ld	a0,0(s2)
ffffffffc0203656:	463d                	li	a2,15
ffffffffc0203658:	85a2                	mv	a1,s0
ffffffffc020365a:	0b450513          	addi	a0,a0,180
ffffffffc020365e:	7de000ef          	jal	ra,ffffffffc0203e3c <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc0203662:	00093783          	ld	a5,0(s2)
ffffffffc0203666:	0000a717          	auipc	a4,0xa
ffffffffc020366a:	e3273703          	ld	a4,-462(a4) # ffffffffc020d498 <boot_pgdir_pa>
ffffffffc020366e:	77d4                	ld	a3,168(a5)
ffffffffc0203670:	0ee68463          	beq	a3,a4,ffffffffc0203758 <proc_init+0x186>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0203674:	4709                	li	a4,2
ffffffffc0203676:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0203678:	00003717          	auipc	a4,0x3
ffffffffc020367c:	98870713          	addi	a4,a4,-1656 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203680:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0203684:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc0203686:	4705                	li	a4,1
ffffffffc0203688:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020368a:	4641                	li	a2,16
ffffffffc020368c:	4581                	li	a1,0
ffffffffc020368e:	8522                	mv	a0,s0
ffffffffc0203690:	782000ef          	jal	ra,ffffffffc0203e12 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203694:	463d                	li	a2,15
ffffffffc0203696:	00002597          	auipc	a1,0x2
ffffffffc020369a:	fda58593          	addi	a1,a1,-38 # ffffffffc0205670 <default_pmm_manager+0x9f0>
ffffffffc020369e:	8522                	mv	a0,s0
ffffffffc02036a0:	784000ef          	jal	ra,ffffffffc0203e24 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc02036a4:	0000a717          	auipc	a4,0xa
ffffffffc02036a8:	e3c70713          	addi	a4,a4,-452 # ffffffffc020d4e0 <nr_process>
ffffffffc02036ac:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc02036ae:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036b2:	4601                	li	a2,0
    nr_process++;
ffffffffc02036b4:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036b6:	00002597          	auipc	a1,0x2
ffffffffc02036ba:	fc258593          	addi	a1,a1,-62 # ffffffffc0205678 <default_pmm_manager+0x9f8>
ffffffffc02036be:	00000517          	auipc	a0,0x0
ffffffffc02036c2:	b4650513          	addi	a0,a0,-1210 # ffffffffc0203204 <init_main>
    nr_process++;
ffffffffc02036c6:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc02036c8:	0000a797          	auipc	a5,0xa
ffffffffc02036cc:	e0d7b023          	sd	a3,-512(a5) # ffffffffc020d4c8 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036d0:	e97ff0ef          	jal	ra,ffffffffc0203566 <kernel_thread>
ffffffffc02036d4:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc02036d6:	0ea05963          	blez	a0,ffffffffc02037c8 <proc_init+0x1f6>
    if (0 < pid && pid < MAX_PID)
ffffffffc02036da:	6789                	lui	a5,0x2
ffffffffc02036dc:	fff5071b          	addiw	a4,a0,-1
ffffffffc02036e0:	17f9                	addi	a5,a5,-2
ffffffffc02036e2:	2501                	sext.w	a0,a0
ffffffffc02036e4:	02e7e363          	bltu	a5,a4,ffffffffc020370a <proc_init+0x138>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02036e8:	45a9                	li	a1,10
ffffffffc02036ea:	282000ef          	jal	ra,ffffffffc020396c <hash32>
ffffffffc02036ee:	02051793          	slli	a5,a0,0x20
ffffffffc02036f2:	01c7d693          	srli	a3,a5,0x1c
ffffffffc02036f6:	96a6                	add	a3,a3,s1
ffffffffc02036f8:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02036fa:	a029                	j	ffffffffc0203704 <proc_init+0x132>
            if (proc->pid == pid)
ffffffffc02036fc:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc0203700:	0a870563          	beq	a4,s0,ffffffffc02037aa <proc_init+0x1d8>
    return listelm->next;
ffffffffc0203704:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203706:	fef69be3          	bne	a3,a5,ffffffffc02036fc <proc_init+0x12a>
    return NULL;
ffffffffc020370a:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020370c:	0b478493          	addi	s1,a5,180
ffffffffc0203710:	4641                	li	a2,16
ffffffffc0203712:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0203714:	0000a417          	auipc	s0,0xa
ffffffffc0203718:	dc440413          	addi	s0,s0,-572 # ffffffffc020d4d8 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020371c:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc020371e:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203720:	6f2000ef          	jal	ra,ffffffffc0203e12 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203724:	463d                	li	a2,15
ffffffffc0203726:	00002597          	auipc	a1,0x2
ffffffffc020372a:	f8258593          	addi	a1,a1,-126 # ffffffffc02056a8 <default_pmm_manager+0xa28>
ffffffffc020372e:	8526                	mv	a0,s1
ffffffffc0203730:	6f4000ef          	jal	ra,ffffffffc0203e24 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203734:	00093783          	ld	a5,0(s2)
ffffffffc0203738:	c7e1                	beqz	a5,ffffffffc0203800 <proc_init+0x22e>
ffffffffc020373a:	43dc                	lw	a5,4(a5)
ffffffffc020373c:	e3f1                	bnez	a5,ffffffffc0203800 <proc_init+0x22e>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020373e:	601c                	ld	a5,0(s0)
ffffffffc0203740:	c3c5                	beqz	a5,ffffffffc02037e0 <proc_init+0x20e>
ffffffffc0203742:	43d8                	lw	a4,4(a5)
ffffffffc0203744:	4785                	li	a5,1
ffffffffc0203746:	08f71d63          	bne	a4,a5,ffffffffc02037e0 <proc_init+0x20e>
}
ffffffffc020374a:	70a2                	ld	ra,40(sp)
ffffffffc020374c:	7402                	ld	s0,32(sp)
ffffffffc020374e:	64e2                	ld	s1,24(sp)
ffffffffc0203750:	6942                	ld	s2,16(sp)
ffffffffc0203752:	69a2                	ld	s3,8(sp)
ffffffffc0203754:	6145                	addi	sp,sp,48
ffffffffc0203756:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc0203758:	73d8                	ld	a4,160(a5)
ffffffffc020375a:	ff09                	bnez	a4,ffffffffc0203674 <proc_init+0xa2>
ffffffffc020375c:	f0099ce3          	bnez	s3,ffffffffc0203674 <proc_init+0xa2>
ffffffffc0203760:	6394                	ld	a3,0(a5)
ffffffffc0203762:	577d                	li	a4,-1
ffffffffc0203764:	1702                	slli	a4,a4,0x20
ffffffffc0203766:	f0e697e3          	bne	a3,a4,ffffffffc0203674 <proc_init+0xa2>
ffffffffc020376a:	4798                	lw	a4,8(a5)
ffffffffc020376c:	f00714e3          	bnez	a4,ffffffffc0203674 <proc_init+0xa2>
ffffffffc0203770:	6b98                	ld	a4,16(a5)
ffffffffc0203772:	f00711e3          	bnez	a4,ffffffffc0203674 <proc_init+0xa2>
ffffffffc0203776:	4f98                	lw	a4,24(a5)
ffffffffc0203778:	2701                	sext.w	a4,a4
ffffffffc020377a:	ee071de3          	bnez	a4,ffffffffc0203674 <proc_init+0xa2>
ffffffffc020377e:	7398                	ld	a4,32(a5)
ffffffffc0203780:	ee071ae3          	bnez	a4,ffffffffc0203674 <proc_init+0xa2>
ffffffffc0203784:	7798                	ld	a4,40(a5)
ffffffffc0203786:	ee0717e3          	bnez	a4,ffffffffc0203674 <proc_init+0xa2>
ffffffffc020378a:	0b07a703          	lw	a4,176(a5)
ffffffffc020378e:	8d59                	or	a0,a0,a4
ffffffffc0203790:	0005071b          	sext.w	a4,a0
ffffffffc0203794:	ee0710e3          	bnez	a4,ffffffffc0203674 <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc0203798:	00002517          	auipc	a0,0x2
ffffffffc020379c:	ec050513          	addi	a0,a0,-320 # ffffffffc0205658 <default_pmm_manager+0x9d8>
ffffffffc02037a0:	9f5fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    idleproc->pid = 0;
ffffffffc02037a4:	00093783          	ld	a5,0(s2)
ffffffffc02037a8:	b5f1                	j	ffffffffc0203674 <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02037aa:	f2878793          	addi	a5,a5,-216
ffffffffc02037ae:	bfb9                	j	ffffffffc020370c <proc_init+0x13a>
        panic("cannot alloc idleproc.\n");
ffffffffc02037b0:	00002617          	auipc	a2,0x2
ffffffffc02037b4:	e9060613          	addi	a2,a2,-368 # ffffffffc0205640 <default_pmm_manager+0x9c0>
ffffffffc02037b8:	1b300593          	li	a1,435
ffffffffc02037bc:	00002517          	auipc	a0,0x2
ffffffffc02037c0:	e5450513          	addi	a0,a0,-428 # ffffffffc0205610 <default_pmm_manager+0x990>
ffffffffc02037c4:	c97fc0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("create init_main failed.\n");
ffffffffc02037c8:	00002617          	auipc	a2,0x2
ffffffffc02037cc:	ec060613          	addi	a2,a2,-320 # ffffffffc0205688 <default_pmm_manager+0xa08>
ffffffffc02037d0:	1d000593          	li	a1,464
ffffffffc02037d4:	00002517          	auipc	a0,0x2
ffffffffc02037d8:	e3c50513          	addi	a0,a0,-452 # ffffffffc0205610 <default_pmm_manager+0x990>
ffffffffc02037dc:	c7ffc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02037e0:	00002697          	auipc	a3,0x2
ffffffffc02037e4:	ef868693          	addi	a3,a3,-264 # ffffffffc02056d8 <default_pmm_manager+0xa58>
ffffffffc02037e8:	00001617          	auipc	a2,0x1
ffffffffc02037ec:	0e860613          	addi	a2,a2,232 # ffffffffc02048d0 <commands+0x808>
ffffffffc02037f0:	1d700593          	li	a1,471
ffffffffc02037f4:	00002517          	auipc	a0,0x2
ffffffffc02037f8:	e1c50513          	addi	a0,a0,-484 # ffffffffc0205610 <default_pmm_manager+0x990>
ffffffffc02037fc:	c5ffc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203800:	00002697          	auipc	a3,0x2
ffffffffc0203804:	eb068693          	addi	a3,a3,-336 # ffffffffc02056b0 <default_pmm_manager+0xa30>
ffffffffc0203808:	00001617          	auipc	a2,0x1
ffffffffc020380c:	0c860613          	addi	a2,a2,200 # ffffffffc02048d0 <commands+0x808>
ffffffffc0203810:	1d600593          	li	a1,470
ffffffffc0203814:	00002517          	auipc	a0,0x2
ffffffffc0203818:	dfc50513          	addi	a0,a0,-516 # ffffffffc0205610 <default_pmm_manager+0x990>
ffffffffc020381c:	c3ffc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203820 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0203820:	1141                	addi	sp,sp,-16
ffffffffc0203822:	e022                	sd	s0,0(sp)
ffffffffc0203824:	e406                	sd	ra,8(sp)
ffffffffc0203826:	0000a417          	auipc	s0,0xa
ffffffffc020382a:	ca240413          	addi	s0,s0,-862 # ffffffffc020d4c8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc020382e:	6018                	ld	a4,0(s0)
ffffffffc0203830:	4f1c                	lw	a5,24(a4)
ffffffffc0203832:	2781                	sext.w	a5,a5
ffffffffc0203834:	dff5                	beqz	a5,ffffffffc0203830 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0203836:	0a2000ef          	jal	ra,ffffffffc02038d8 <schedule>
ffffffffc020383a:	bfd5                	j	ffffffffc020382e <cpu_idle+0xe>

ffffffffc020383c <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc020383c:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0203840:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0203844:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0203846:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0203848:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc020384c:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0203850:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0203854:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0203858:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc020385c:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0203860:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0203864:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0203868:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc020386c:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0203870:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0203874:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0203878:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc020387a:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc020387c:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0203880:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0203884:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0203888:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc020388c:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0203890:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0203894:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0203898:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020389c:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02038a0:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02038a4:	8082                	ret

ffffffffc02038a6 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038a6:	411c                	lw	a5,0(a0)
ffffffffc02038a8:	4705                	li	a4,1
ffffffffc02038aa:	37f9                	addiw	a5,a5,-2
ffffffffc02038ac:	00f77563          	bgeu	a4,a5,ffffffffc02038b6 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc02038b0:	4789                	li	a5,2
ffffffffc02038b2:	c11c                	sw	a5,0(a0)
ffffffffc02038b4:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc02038b6:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038b8:	00002697          	auipc	a3,0x2
ffffffffc02038bc:	e4868693          	addi	a3,a3,-440 # ffffffffc0205700 <default_pmm_manager+0xa80>
ffffffffc02038c0:	00001617          	auipc	a2,0x1
ffffffffc02038c4:	01060613          	addi	a2,a2,16 # ffffffffc02048d0 <commands+0x808>
ffffffffc02038c8:	45a5                	li	a1,9
ffffffffc02038ca:	00002517          	auipc	a0,0x2
ffffffffc02038ce:	e7650513          	addi	a0,a0,-394 # ffffffffc0205740 <default_pmm_manager+0xac0>
wakeup_proc(struct proc_struct *proc) {
ffffffffc02038d2:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038d4:	b87fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02038d8 <schedule>:
}

void
schedule(void) {
ffffffffc02038d8:	1141                	addi	sp,sp,-16
ffffffffc02038da:	e406                	sd	ra,8(sp)
ffffffffc02038dc:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02038de:	100027f3          	csrr	a5,sstatus
ffffffffc02038e2:	8b89                	andi	a5,a5,2
ffffffffc02038e4:	4401                	li	s0,0
ffffffffc02038e6:	efbd                	bnez	a5,ffffffffc0203964 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02038e8:	0000a897          	auipc	a7,0xa
ffffffffc02038ec:	be08b883          	ld	a7,-1056(a7) # ffffffffc020d4c8 <current>
ffffffffc02038f0:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02038f4:	0000a517          	auipc	a0,0xa
ffffffffc02038f8:	bdc53503          	ld	a0,-1060(a0) # ffffffffc020d4d0 <idleproc>
ffffffffc02038fc:	04a88e63          	beq	a7,a0,ffffffffc0203958 <schedule+0x80>
ffffffffc0203900:	0c888693          	addi	a3,a7,200
ffffffffc0203904:	0000a617          	auipc	a2,0xa
ffffffffc0203908:	b5460613          	addi	a2,a2,-1196 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc020390c:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020390e:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203910:	4809                	li	a6,2
ffffffffc0203912:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0203914:	00c78863          	beq	a5,a2,ffffffffc0203924 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203918:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020391c:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203920:	03070163          	beq	a4,a6,ffffffffc0203942 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc0203924:	fef697e3          	bne	a3,a5,ffffffffc0203912 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203928:	ed89                	bnez	a1,ffffffffc0203942 <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc020392a:	451c                	lw	a5,8(a0)
ffffffffc020392c:	2785                	addiw	a5,a5,1
ffffffffc020392e:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0203930:	00a88463          	beq	a7,a0,ffffffffc0203938 <schedule+0x60>
            proc_run(next);
ffffffffc0203934:	943ff0ef          	jal	ra,ffffffffc0203276 <proc_run>
    if (flag) {
ffffffffc0203938:	e819                	bnez	s0,ffffffffc020394e <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020393a:	60a2                	ld	ra,8(sp)
ffffffffc020393c:	6402                	ld	s0,0(sp)
ffffffffc020393e:	0141                	addi	sp,sp,16
ffffffffc0203940:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203942:	4198                	lw	a4,0(a1)
ffffffffc0203944:	4789                	li	a5,2
ffffffffc0203946:	fef712e3          	bne	a4,a5,ffffffffc020392a <schedule+0x52>
ffffffffc020394a:	852e                	mv	a0,a1
ffffffffc020394c:	bff9                	j	ffffffffc020392a <schedule+0x52>
}
ffffffffc020394e:	6402                	ld	s0,0(sp)
ffffffffc0203950:	60a2                	ld	ra,8(sp)
ffffffffc0203952:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0203954:	fbdfc06f          	j	ffffffffc0200910 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203958:	0000a617          	auipc	a2,0xa
ffffffffc020395c:	b0060613          	addi	a2,a2,-1280 # ffffffffc020d458 <proc_list>
ffffffffc0203960:	86b2                	mv	a3,a2
ffffffffc0203962:	b76d                	j	ffffffffc020390c <schedule+0x34>
        intr_disable();
ffffffffc0203964:	fb3fc0ef          	jal	ra,ffffffffc0200916 <intr_disable>
        return 1;
ffffffffc0203968:	4405                	li	s0,1
ffffffffc020396a:	bfbd                	j	ffffffffc02038e8 <schedule+0x10>

ffffffffc020396c <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc020396c:	9e3707b7          	lui	a5,0x9e370
ffffffffc0203970:	2785                	addiw	a5,a5,1
ffffffffc0203972:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0203976:	02000793          	li	a5,32
ffffffffc020397a:	9f8d                	subw	a5,a5,a1
}
ffffffffc020397c:	00f5553b          	srlw	a0,a0,a5
ffffffffc0203980:	8082                	ret

ffffffffc0203982 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203982:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203986:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203988:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020398c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020398e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203992:	f022                	sd	s0,32(sp)
ffffffffc0203994:	ec26                	sd	s1,24(sp)
ffffffffc0203996:	e84a                	sd	s2,16(sp)
ffffffffc0203998:	f406                	sd	ra,40(sp)
ffffffffc020399a:	e44e                	sd	s3,8(sp)
ffffffffc020399c:	84aa                	mv	s1,a0
ffffffffc020399e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02039a0:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02039a4:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02039a6:	03067e63          	bgeu	a2,a6,ffffffffc02039e2 <printnum+0x60>
ffffffffc02039aa:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02039ac:	00805763          	blez	s0,ffffffffc02039ba <printnum+0x38>
ffffffffc02039b0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02039b2:	85ca                	mv	a1,s2
ffffffffc02039b4:	854e                	mv	a0,s3
ffffffffc02039b6:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02039b8:	fc65                	bnez	s0,ffffffffc02039b0 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039ba:	1a02                	slli	s4,s4,0x20
ffffffffc02039bc:	00002797          	auipc	a5,0x2
ffffffffc02039c0:	d9c78793          	addi	a5,a5,-612 # ffffffffc0205758 <default_pmm_manager+0xad8>
ffffffffc02039c4:	020a5a13          	srli	s4,s4,0x20
ffffffffc02039c8:	9a3e                	add	s4,s4,a5
}
ffffffffc02039ca:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039cc:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02039d0:	70a2                	ld	ra,40(sp)
ffffffffc02039d2:	69a2                	ld	s3,8(sp)
ffffffffc02039d4:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039d6:	85ca                	mv	a1,s2
ffffffffc02039d8:	87a6                	mv	a5,s1
}
ffffffffc02039da:	6942                	ld	s2,16(sp)
ffffffffc02039dc:	64e2                	ld	s1,24(sp)
ffffffffc02039de:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039e0:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02039e2:	03065633          	divu	a2,a2,a6
ffffffffc02039e6:	8722                	mv	a4,s0
ffffffffc02039e8:	f9bff0ef          	jal	ra,ffffffffc0203982 <printnum>
ffffffffc02039ec:	b7f9                	j	ffffffffc02039ba <printnum+0x38>

ffffffffc02039ee <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02039ee:	7119                	addi	sp,sp,-128
ffffffffc02039f0:	f4a6                	sd	s1,104(sp)
ffffffffc02039f2:	f0ca                	sd	s2,96(sp)
ffffffffc02039f4:	ecce                	sd	s3,88(sp)
ffffffffc02039f6:	e8d2                	sd	s4,80(sp)
ffffffffc02039f8:	e4d6                	sd	s5,72(sp)
ffffffffc02039fa:	e0da                	sd	s6,64(sp)
ffffffffc02039fc:	fc5e                	sd	s7,56(sp)
ffffffffc02039fe:	f06a                	sd	s10,32(sp)
ffffffffc0203a00:	fc86                	sd	ra,120(sp)
ffffffffc0203a02:	f8a2                	sd	s0,112(sp)
ffffffffc0203a04:	f862                	sd	s8,48(sp)
ffffffffc0203a06:	f466                	sd	s9,40(sp)
ffffffffc0203a08:	ec6e                	sd	s11,24(sp)
ffffffffc0203a0a:	892a                	mv	s2,a0
ffffffffc0203a0c:	84ae                	mv	s1,a1
ffffffffc0203a0e:	8d32                	mv	s10,a2
ffffffffc0203a10:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a12:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203a16:	5b7d                	li	s6,-1
ffffffffc0203a18:	00002a97          	auipc	s5,0x2
ffffffffc0203a1c:	d6ca8a93          	addi	s5,s5,-660 # ffffffffc0205784 <default_pmm_manager+0xb04>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203a20:	00002b97          	auipc	s7,0x2
ffffffffc0203a24:	f40b8b93          	addi	s7,s7,-192 # ffffffffc0205960 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a28:	000d4503          	lbu	a0,0(s10)
ffffffffc0203a2c:	001d0413          	addi	s0,s10,1
ffffffffc0203a30:	01350a63          	beq	a0,s3,ffffffffc0203a44 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0203a34:	c121                	beqz	a0,ffffffffc0203a74 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0203a36:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a38:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203a3a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a3c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203a40:	ff351ae3          	bne	a0,s3,ffffffffc0203a34 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a44:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203a48:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203a4c:	4c81                	li	s9,0
ffffffffc0203a4e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0203a50:	5c7d                	li	s8,-1
ffffffffc0203a52:	5dfd                	li	s11,-1
ffffffffc0203a54:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0203a58:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a5a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203a5e:	0ff5f593          	zext.b	a1,a1
ffffffffc0203a62:	00140d13          	addi	s10,s0,1
ffffffffc0203a66:	04b56263          	bltu	a0,a1,ffffffffc0203aaa <vprintfmt+0xbc>
ffffffffc0203a6a:	058a                	slli	a1,a1,0x2
ffffffffc0203a6c:	95d6                	add	a1,a1,s5
ffffffffc0203a6e:	4194                	lw	a3,0(a1)
ffffffffc0203a70:	96d6                	add	a3,a3,s5
ffffffffc0203a72:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203a74:	70e6                	ld	ra,120(sp)
ffffffffc0203a76:	7446                	ld	s0,112(sp)
ffffffffc0203a78:	74a6                	ld	s1,104(sp)
ffffffffc0203a7a:	7906                	ld	s2,96(sp)
ffffffffc0203a7c:	69e6                	ld	s3,88(sp)
ffffffffc0203a7e:	6a46                	ld	s4,80(sp)
ffffffffc0203a80:	6aa6                	ld	s5,72(sp)
ffffffffc0203a82:	6b06                	ld	s6,64(sp)
ffffffffc0203a84:	7be2                	ld	s7,56(sp)
ffffffffc0203a86:	7c42                	ld	s8,48(sp)
ffffffffc0203a88:	7ca2                	ld	s9,40(sp)
ffffffffc0203a8a:	7d02                	ld	s10,32(sp)
ffffffffc0203a8c:	6de2                	ld	s11,24(sp)
ffffffffc0203a8e:	6109                	addi	sp,sp,128
ffffffffc0203a90:	8082                	ret
            padc = '0';
ffffffffc0203a92:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0203a94:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a98:	846a                	mv	s0,s10
ffffffffc0203a9a:	00140d13          	addi	s10,s0,1
ffffffffc0203a9e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203aa2:	0ff5f593          	zext.b	a1,a1
ffffffffc0203aa6:	fcb572e3          	bgeu	a0,a1,ffffffffc0203a6a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0203aaa:	85a6                	mv	a1,s1
ffffffffc0203aac:	02500513          	li	a0,37
ffffffffc0203ab0:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203ab2:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203ab6:	8d22                	mv	s10,s0
ffffffffc0203ab8:	f73788e3          	beq	a5,s3,ffffffffc0203a28 <vprintfmt+0x3a>
ffffffffc0203abc:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0203ac0:	1d7d                	addi	s10,s10,-1
ffffffffc0203ac2:	ff379de3          	bne	a5,s3,ffffffffc0203abc <vprintfmt+0xce>
ffffffffc0203ac6:	b78d                	j	ffffffffc0203a28 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0203ac8:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0203acc:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ad0:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0203ad2:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0203ad6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203ada:	02d86463          	bltu	a6,a3,ffffffffc0203b02 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0203ade:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203ae2:	002c169b          	slliw	a3,s8,0x2
ffffffffc0203ae6:	0186873b          	addw	a4,a3,s8
ffffffffc0203aea:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203aee:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0203af0:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203af4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203af6:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0203afa:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203afe:	fed870e3          	bgeu	a6,a3,ffffffffc0203ade <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0203b02:	f40ddce3          	bgez	s11,ffffffffc0203a5a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0203b06:	8de2                	mv	s11,s8
ffffffffc0203b08:	5c7d                	li	s8,-1
ffffffffc0203b0a:	bf81                	j	ffffffffc0203a5a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0203b0c:	fffdc693          	not	a3,s11
ffffffffc0203b10:	96fd                	srai	a3,a3,0x3f
ffffffffc0203b12:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b16:	00144603          	lbu	a2,1(s0)
ffffffffc0203b1a:	2d81                	sext.w	s11,s11
ffffffffc0203b1c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203b1e:	bf35                	j	ffffffffc0203a5a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0203b20:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b24:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0203b28:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b2a:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0203b2c:	bfd9                	j	ffffffffc0203b02 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0203b2e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b30:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b34:	01174463          	blt	a4,a7,ffffffffc0203b3c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0203b38:	1a088e63          	beqz	a7,ffffffffc0203cf4 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0203b3c:	000a3603          	ld	a2,0(s4)
ffffffffc0203b40:	46c1                	li	a3,16
ffffffffc0203b42:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203b44:	2781                	sext.w	a5,a5
ffffffffc0203b46:	876e                	mv	a4,s11
ffffffffc0203b48:	85a6                	mv	a1,s1
ffffffffc0203b4a:	854a                	mv	a0,s2
ffffffffc0203b4c:	e37ff0ef          	jal	ra,ffffffffc0203982 <printnum>
            break;
ffffffffc0203b50:	bde1                	j	ffffffffc0203a28 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0203b52:	000a2503          	lw	a0,0(s4)
ffffffffc0203b56:	85a6                	mv	a1,s1
ffffffffc0203b58:	0a21                	addi	s4,s4,8
ffffffffc0203b5a:	9902                	jalr	s2
            break;
ffffffffc0203b5c:	b5f1                	j	ffffffffc0203a28 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203b5e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b60:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b64:	01174463          	blt	a4,a7,ffffffffc0203b6c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0203b68:	18088163          	beqz	a7,ffffffffc0203cea <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0203b6c:	000a3603          	ld	a2,0(s4)
ffffffffc0203b70:	46a9                	li	a3,10
ffffffffc0203b72:	8a2e                	mv	s4,a1
ffffffffc0203b74:	bfc1                	j	ffffffffc0203b44 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b76:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0203b7a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b7c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203b7e:	bdf1                	j	ffffffffc0203a5a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0203b80:	85a6                	mv	a1,s1
ffffffffc0203b82:	02500513          	li	a0,37
ffffffffc0203b86:	9902                	jalr	s2
            break;
ffffffffc0203b88:	b545                	j	ffffffffc0203a28 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b8a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0203b8e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b90:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203b92:	b5e1                	j	ffffffffc0203a5a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0203b94:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b96:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b9a:	01174463          	blt	a4,a7,ffffffffc0203ba2 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0203b9e:	14088163          	beqz	a7,ffffffffc0203ce0 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0203ba2:	000a3603          	ld	a2,0(s4)
ffffffffc0203ba6:	46a1                	li	a3,8
ffffffffc0203ba8:	8a2e                	mv	s4,a1
ffffffffc0203baa:	bf69                	j	ffffffffc0203b44 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0203bac:	03000513          	li	a0,48
ffffffffc0203bb0:	85a6                	mv	a1,s1
ffffffffc0203bb2:	e03e                	sd	a5,0(sp)
ffffffffc0203bb4:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203bb6:	85a6                	mv	a1,s1
ffffffffc0203bb8:	07800513          	li	a0,120
ffffffffc0203bbc:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203bbe:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203bc0:	6782                	ld	a5,0(sp)
ffffffffc0203bc2:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203bc4:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0203bc8:	bfb5                	j	ffffffffc0203b44 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203bca:	000a3403          	ld	s0,0(s4)
ffffffffc0203bce:	008a0713          	addi	a4,s4,8
ffffffffc0203bd2:	e03a                	sd	a4,0(sp)
ffffffffc0203bd4:	14040263          	beqz	s0,ffffffffc0203d18 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0203bd8:	0fb05763          	blez	s11,ffffffffc0203cc6 <vprintfmt+0x2d8>
ffffffffc0203bdc:	02d00693          	li	a3,45
ffffffffc0203be0:	0cd79163          	bne	a5,a3,ffffffffc0203ca2 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203be4:	00044783          	lbu	a5,0(s0)
ffffffffc0203be8:	0007851b          	sext.w	a0,a5
ffffffffc0203bec:	cf85                	beqz	a5,ffffffffc0203c24 <vprintfmt+0x236>
ffffffffc0203bee:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203bf2:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203bf6:	000c4563          	bltz	s8,ffffffffc0203c00 <vprintfmt+0x212>
ffffffffc0203bfa:	3c7d                	addiw	s8,s8,-1
ffffffffc0203bfc:	036c0263          	beq	s8,s6,ffffffffc0203c20 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0203c00:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c02:	0e0c8e63          	beqz	s9,ffffffffc0203cfe <vprintfmt+0x310>
ffffffffc0203c06:	3781                	addiw	a5,a5,-32
ffffffffc0203c08:	0ef47b63          	bgeu	s0,a5,ffffffffc0203cfe <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0203c0c:	03f00513          	li	a0,63
ffffffffc0203c10:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c12:	000a4783          	lbu	a5,0(s4)
ffffffffc0203c16:	3dfd                	addiw	s11,s11,-1
ffffffffc0203c18:	0a05                	addi	s4,s4,1
ffffffffc0203c1a:	0007851b          	sext.w	a0,a5
ffffffffc0203c1e:	ffe1                	bnez	a5,ffffffffc0203bf6 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0203c20:	01b05963          	blez	s11,ffffffffc0203c32 <vprintfmt+0x244>
ffffffffc0203c24:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0203c26:	85a6                	mv	a1,s1
ffffffffc0203c28:	02000513          	li	a0,32
ffffffffc0203c2c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0203c2e:	fe0d9be3          	bnez	s11,ffffffffc0203c24 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c32:	6a02                	ld	s4,0(sp)
ffffffffc0203c34:	bbd5                	j	ffffffffc0203a28 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203c36:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c38:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0203c3c:	01174463          	blt	a4,a7,ffffffffc0203c44 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0203c40:	08088d63          	beqz	a7,ffffffffc0203cda <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0203c44:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203c48:	0a044d63          	bltz	s0,ffffffffc0203d02 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0203c4c:	8622                	mv	a2,s0
ffffffffc0203c4e:	8a66                	mv	s4,s9
ffffffffc0203c50:	46a9                	li	a3,10
ffffffffc0203c52:	bdcd                	j	ffffffffc0203b44 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0203c54:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203c58:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0203c5a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203c5c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0203c60:	8fb5                	xor	a5,a5,a3
ffffffffc0203c62:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203c66:	02d74163          	blt	a4,a3,ffffffffc0203c88 <vprintfmt+0x29a>
ffffffffc0203c6a:	00369793          	slli	a5,a3,0x3
ffffffffc0203c6e:	97de                	add	a5,a5,s7
ffffffffc0203c70:	639c                	ld	a5,0(a5)
ffffffffc0203c72:	cb99                	beqz	a5,ffffffffc0203c88 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203c74:	86be                	mv	a3,a5
ffffffffc0203c76:	00000617          	auipc	a2,0x0
ffffffffc0203c7a:	21260613          	addi	a2,a2,530 # ffffffffc0203e88 <etext+0x28>
ffffffffc0203c7e:	85a6                	mv	a1,s1
ffffffffc0203c80:	854a                	mv	a0,s2
ffffffffc0203c82:	0ce000ef          	jal	ra,ffffffffc0203d50 <printfmt>
ffffffffc0203c86:	b34d                	j	ffffffffc0203a28 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203c88:	00002617          	auipc	a2,0x2
ffffffffc0203c8c:	af060613          	addi	a2,a2,-1296 # ffffffffc0205778 <default_pmm_manager+0xaf8>
ffffffffc0203c90:	85a6                	mv	a1,s1
ffffffffc0203c92:	854a                	mv	a0,s2
ffffffffc0203c94:	0bc000ef          	jal	ra,ffffffffc0203d50 <printfmt>
ffffffffc0203c98:	bb41                	j	ffffffffc0203a28 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0203c9a:	00002417          	auipc	s0,0x2
ffffffffc0203c9e:	ad640413          	addi	s0,s0,-1322 # ffffffffc0205770 <default_pmm_manager+0xaf0>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203ca2:	85e2                	mv	a1,s8
ffffffffc0203ca4:	8522                	mv	a0,s0
ffffffffc0203ca6:	e43e                	sd	a5,8(sp)
ffffffffc0203ca8:	0e2000ef          	jal	ra,ffffffffc0203d8a <strnlen>
ffffffffc0203cac:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0203cb0:	01b05b63          	blez	s11,ffffffffc0203cc6 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0203cb4:	67a2                	ld	a5,8(sp)
ffffffffc0203cb6:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203cba:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0203cbc:	85a6                	mv	a1,s1
ffffffffc0203cbe:	8552                	mv	a0,s4
ffffffffc0203cc0:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203cc2:	fe0d9ce3          	bnez	s11,ffffffffc0203cba <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203cc6:	00044783          	lbu	a5,0(s0)
ffffffffc0203cca:	00140a13          	addi	s4,s0,1
ffffffffc0203cce:	0007851b          	sext.w	a0,a5
ffffffffc0203cd2:	d3a5                	beqz	a5,ffffffffc0203c32 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203cd4:	05e00413          	li	s0,94
ffffffffc0203cd8:	bf39                	j	ffffffffc0203bf6 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0203cda:	000a2403          	lw	s0,0(s4)
ffffffffc0203cde:	b7ad                	j	ffffffffc0203c48 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0203ce0:	000a6603          	lwu	a2,0(s4)
ffffffffc0203ce4:	46a1                	li	a3,8
ffffffffc0203ce6:	8a2e                	mv	s4,a1
ffffffffc0203ce8:	bdb1                	j	ffffffffc0203b44 <vprintfmt+0x156>
ffffffffc0203cea:	000a6603          	lwu	a2,0(s4)
ffffffffc0203cee:	46a9                	li	a3,10
ffffffffc0203cf0:	8a2e                	mv	s4,a1
ffffffffc0203cf2:	bd89                	j	ffffffffc0203b44 <vprintfmt+0x156>
ffffffffc0203cf4:	000a6603          	lwu	a2,0(s4)
ffffffffc0203cf8:	46c1                	li	a3,16
ffffffffc0203cfa:	8a2e                	mv	s4,a1
ffffffffc0203cfc:	b5a1                	j	ffffffffc0203b44 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0203cfe:	9902                	jalr	s2
ffffffffc0203d00:	bf09                	j	ffffffffc0203c12 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0203d02:	85a6                	mv	a1,s1
ffffffffc0203d04:	02d00513          	li	a0,45
ffffffffc0203d08:	e03e                	sd	a5,0(sp)
ffffffffc0203d0a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0203d0c:	6782                	ld	a5,0(sp)
ffffffffc0203d0e:	8a66                	mv	s4,s9
ffffffffc0203d10:	40800633          	neg	a2,s0
ffffffffc0203d14:	46a9                	li	a3,10
ffffffffc0203d16:	b53d                	j	ffffffffc0203b44 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0203d18:	03b05163          	blez	s11,ffffffffc0203d3a <vprintfmt+0x34c>
ffffffffc0203d1c:	02d00693          	li	a3,45
ffffffffc0203d20:	f6d79de3          	bne	a5,a3,ffffffffc0203c9a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0203d24:	00002417          	auipc	s0,0x2
ffffffffc0203d28:	a4c40413          	addi	s0,s0,-1460 # ffffffffc0205770 <default_pmm_manager+0xaf0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d2c:	02800793          	li	a5,40
ffffffffc0203d30:	02800513          	li	a0,40
ffffffffc0203d34:	00140a13          	addi	s4,s0,1
ffffffffc0203d38:	bd6d                	j	ffffffffc0203bf2 <vprintfmt+0x204>
ffffffffc0203d3a:	00002a17          	auipc	s4,0x2
ffffffffc0203d3e:	a37a0a13          	addi	s4,s4,-1481 # ffffffffc0205771 <default_pmm_manager+0xaf1>
ffffffffc0203d42:	02800513          	li	a0,40
ffffffffc0203d46:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203d4a:	05e00413          	li	s0,94
ffffffffc0203d4e:	b565                	j	ffffffffc0203bf6 <vprintfmt+0x208>

ffffffffc0203d50 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d50:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203d52:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d56:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203d58:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d5a:	ec06                	sd	ra,24(sp)
ffffffffc0203d5c:	f83a                	sd	a4,48(sp)
ffffffffc0203d5e:	fc3e                	sd	a5,56(sp)
ffffffffc0203d60:	e0c2                	sd	a6,64(sp)
ffffffffc0203d62:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203d64:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203d66:	c89ff0ef          	jal	ra,ffffffffc02039ee <vprintfmt>
}
ffffffffc0203d6a:	60e2                	ld	ra,24(sp)
ffffffffc0203d6c:	6161                	addi	sp,sp,80
ffffffffc0203d6e:	8082                	ret

ffffffffc0203d70 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203d70:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0203d74:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0203d76:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0203d78:	cb81                	beqz	a5,ffffffffc0203d88 <strlen+0x18>
        cnt ++;
ffffffffc0203d7a:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0203d7c:	00a707b3          	add	a5,a4,a0
ffffffffc0203d80:	0007c783          	lbu	a5,0(a5)
ffffffffc0203d84:	fbfd                	bnez	a5,ffffffffc0203d7a <strlen+0xa>
ffffffffc0203d86:	8082                	ret
    }
    return cnt;
}
ffffffffc0203d88:	8082                	ret

ffffffffc0203d8a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203d8a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203d8c:	e589                	bnez	a1,ffffffffc0203d96 <strnlen+0xc>
ffffffffc0203d8e:	a811                	j	ffffffffc0203da2 <strnlen+0x18>
        cnt ++;
ffffffffc0203d90:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203d92:	00f58863          	beq	a1,a5,ffffffffc0203da2 <strnlen+0x18>
ffffffffc0203d96:	00f50733          	add	a4,a0,a5
ffffffffc0203d9a:	00074703          	lbu	a4,0(a4)
ffffffffc0203d9e:	fb6d                	bnez	a4,ffffffffc0203d90 <strnlen+0x6>
ffffffffc0203da0:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203da2:	852e                	mv	a0,a1
ffffffffc0203da4:	8082                	ret

ffffffffc0203da6 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203da6:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203da8:	0005c703          	lbu	a4,0(a1)
ffffffffc0203dac:	0785                	addi	a5,a5,1
ffffffffc0203dae:	0585                	addi	a1,a1,1
ffffffffc0203db0:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203db4:	fb75                	bnez	a4,ffffffffc0203da8 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203db6:	8082                	ret

ffffffffc0203db8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203db8:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203dbc:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203dc0:	cb89                	beqz	a5,ffffffffc0203dd2 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0203dc2:	0505                	addi	a0,a0,1
ffffffffc0203dc4:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203dc6:	fee789e3          	beq	a5,a4,ffffffffc0203db8 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203dca:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203dce:	9d19                	subw	a0,a0,a4
ffffffffc0203dd0:	8082                	ret
ffffffffc0203dd2:	4501                	li	a0,0
ffffffffc0203dd4:	bfed                	j	ffffffffc0203dce <strcmp+0x16>

ffffffffc0203dd6 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203dd6:	c20d                	beqz	a2,ffffffffc0203df8 <strncmp+0x22>
ffffffffc0203dd8:	962e                	add	a2,a2,a1
ffffffffc0203dda:	a031                	j	ffffffffc0203de6 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0203ddc:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203dde:	00e79a63          	bne	a5,a4,ffffffffc0203df2 <strncmp+0x1c>
ffffffffc0203de2:	00b60b63          	beq	a2,a1,ffffffffc0203df8 <strncmp+0x22>
ffffffffc0203de6:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203dea:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203dec:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203df0:	f7f5                	bnez	a5,ffffffffc0203ddc <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203df2:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0203df6:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203df8:	4501                	li	a0,0
ffffffffc0203dfa:	8082                	ret

ffffffffc0203dfc <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203dfc:	00054783          	lbu	a5,0(a0)
ffffffffc0203e00:	c799                	beqz	a5,ffffffffc0203e0e <strchr+0x12>
        if (*s == c) {
ffffffffc0203e02:	00f58763          	beq	a1,a5,ffffffffc0203e10 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0203e06:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0203e0a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203e0c:	fbfd                	bnez	a5,ffffffffc0203e02 <strchr+0x6>
    }
    return NULL;
ffffffffc0203e0e:	4501                	li	a0,0
}
ffffffffc0203e10:	8082                	ret

ffffffffc0203e12 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203e12:	ca01                	beqz	a2,ffffffffc0203e22 <memset+0x10>
ffffffffc0203e14:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203e16:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203e18:	0785                	addi	a5,a5,1
ffffffffc0203e1a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203e1e:	fec79de3          	bne	a5,a2,ffffffffc0203e18 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203e22:	8082                	ret

ffffffffc0203e24 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203e24:	ca19                	beqz	a2,ffffffffc0203e3a <memcpy+0x16>
ffffffffc0203e26:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203e28:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203e2a:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e2e:	0585                	addi	a1,a1,1
ffffffffc0203e30:	0785                	addi	a5,a5,1
ffffffffc0203e32:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203e36:	fec59ae3          	bne	a1,a2,ffffffffc0203e2a <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203e3a:	8082                	ret

ffffffffc0203e3c <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203e3c:	c205                	beqz	a2,ffffffffc0203e5c <memcmp+0x20>
ffffffffc0203e3e:	962e                	add	a2,a2,a1
ffffffffc0203e40:	a019                	j	ffffffffc0203e46 <memcmp+0xa>
ffffffffc0203e42:	00c58d63          	beq	a1,a2,ffffffffc0203e5c <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203e46:	00054783          	lbu	a5,0(a0)
ffffffffc0203e4a:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203e4e:	0505                	addi	a0,a0,1
ffffffffc0203e50:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203e52:	fee788e3          	beq	a5,a4,ffffffffc0203e42 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e56:	40e7853b          	subw	a0,a5,a4
ffffffffc0203e5a:	8082                	ret
    }
    return 0;
ffffffffc0203e5c:	4501                	li	a0,0
}
ffffffffc0203e5e:	8082                	ret
