module neptune.arch.idt;

import std.port;
import std.stdio;

ulong isrs[256];

// Extern declarations for interrupt service routines
extern(C)
{
    void _isr0();
    void _isr1();
    void _isr2();
    void _isr3();
    void _isr4();
    void _isr5();
    void _isr6();
    void _isr7();
    void _isr8();
    void _isr9();
    void _isr10();
    void _isr11();
    void _isr12();
    void _isr13();
    void _isr14();
    void _isr15();
    void _isr16();
    void _isr17();
    void _isr18();
    void _isr19();
    void _isr20();
    void _isr21();
    void _isr22();
    void _isr23();
    void _isr24();
    void _isr25();
    void _isr26();
    void _isr27();
    void _isr28();
    void _isr29();
    void _isr30();
    void _isr31();
    void _isr32();
    void _isr33();
    void _isr34();
    void _isr35();
    void _isr36();
    void _isr37();
    void _isr38();
    void _isr39();
    void _isr40();
    void _isr41();
    void _isr42();
    void _isr43();
    void _isr44();
    void _isr45();
    void _isr46();
    void _isr47();
    void _isr48();
    void _isr49();
    void _isr50();
    void _isr51();
    void _isr52();
    void _isr53();
    void _isr54();
    void _isr55();
    void _isr56();
    void _isr57();
    void _isr58();
    void _isr59();
    void _isr60();
    void _isr61();
    void _isr62();
    void _isr63();
    void _isr64();
    void _isr65();
    void _isr66();
    void _isr67();
    void _isr68();
    void _isr69();
    void _isr70();
    void _isr71();
    void _isr72();
    void _isr73();
    void _isr74();
    void _isr75();
    void _isr76();
    void _isr77();
    void _isr78();
    void _isr79();
    void _isr80();
    void _isr81();
    void _isr82();
    void _isr83();
    void _isr84();
    void _isr85();
    void _isr86();
    void _isr87();
    void _isr88();
    void _isr89();
    void _isr90();
    void _isr91();
    void _isr92();
    void _isr93();
    void _isr94();
    void _isr95();
    void _isr96();
    void _isr97();
    void _isr98();
    void _isr99();
    void _isr100();
    void _isr101();
    void _isr102();
    void _isr103();
    void _isr104();
    void _isr105();
    void _isr106();
    void _isr107();
    void _isr108();
    void _isr109();
    void _isr110();
    void _isr111();
    void _isr112();
    void _isr113();
    void _isr114();
    void _isr115();
    void _isr116();
    void _isr117();
    void _isr118();
    void _isr119();
    void _isr120();
    void _isr121();
    void _isr122();
    void _isr123();
    void _isr124();
    void _isr125();
    void _isr126();
    void _isr127();
    void _isr128();
    void _isr129();
    void _isr130();
    void _isr131();
    void _isr132();
    void _isr133();
    void _isr134();
    void _isr135();
    void _isr136();
    void _isr137();
    void _isr138();
    void _isr139();
    void _isr140();
    void _isr141();
    void _isr142();
    void _isr143();
    void _isr144();
    void _isr145();
    void _isr146();
    void _isr147();
    void _isr148();
    void _isr149();
    void _isr150();
    void _isr151();
    void _isr152();
    void _isr153();
    void _isr154();
    void _isr155();
    void _isr156();
    void _isr157();
    void _isr158();
    void _isr159();
    void _isr160();
    void _isr161();
    void _isr162();
    void _isr163();
    void _isr164();
    void _isr165();
    void _isr166();
    void _isr167();
    void _isr168();
    void _isr169();
    void _isr170();
    void _isr171();
    void _isr172();
    void _isr173();
    void _isr174();
    void _isr175();
    void _isr176();
    void _isr177();
    void _isr178();
    void _isr179();
    void _isr180();
    void _isr181();
    void _isr182();
    void _isr183();
    void _isr184();
    void _isr185();
    void _isr186();
    void _isr187();
    void _isr188();
    void _isr189();
    void _isr190();
    void _isr191();
    void _isr192();
    void _isr193();
    void _isr194();
    void _isr195();
    void _isr196();
    void _isr197();
    void _isr198();
    void _isr199();
    void _isr200();
    void _isr201();
    void _isr202();
    void _isr203();
    void _isr204();
    void _isr205();
    void _isr206();
    void _isr207();
    void _isr208();
    void _isr209();
    void _isr210();
    void _isr211();
    void _isr212();
    void _isr213();
    void _isr214();
    void _isr215();
    void _isr216();
    void _isr217();
    void _isr218();
    void _isr219();
    void _isr220();
    void _isr221();
    void _isr222();
    void _isr223();
    void _isr224();
    void _isr225();
    void _isr226();
    void _isr227();
    void _isr228();
    void _isr229();
    void _isr230();
    void _isr231();
    void _isr232();
    void _isr233();
    void _isr234();
    void _isr235();
    void _isr236();
    void _isr237();
    void _isr238();
    void _isr239();
    void _isr240();
    void _isr241();
    void _isr242();
    void _isr243();
    void _isr244();
    void _isr245();
    void _isr246();
    void _isr247();
    void _isr248();
    void _isr249();
    void _isr250();
    void _isr251();
    void _isr252();
    void _isr253();
    void _isr254();
    void _isr255();
}

void init_isr_array()
{
    isrs[0] = cast(ulong)& _isr0;
    isrs[1] = cast(ulong)& _isr1;
    isrs[2] = cast(ulong)& _isr2;
    isrs[3] = cast(ulong)& _isr3;
    isrs[4] = cast(ulong)& _isr4;
    isrs[5] = cast(ulong)& _isr5;
    isrs[6] = cast(ulong)& _isr6;
    isrs[7] = cast(ulong)& _isr7;
    isrs[8] = cast(ulong)& _isr8;
    isrs[9] = cast(ulong)& _isr9;
    isrs[10] = cast(ulong)& _isr10;
    isrs[11] = cast(ulong)& _isr11;
    isrs[12] = cast(ulong)& _isr12;
    isrs[13] = cast(ulong)& _isr13;
    isrs[14] = cast(ulong)& _isr14;
    isrs[15] = cast(ulong)& _isr15;
    isrs[16] = cast(ulong)& _isr16;
    isrs[17] = cast(ulong)& _isr17;
    isrs[18] = cast(ulong)& _isr18;
    isrs[19] = cast(ulong)& _isr19;
    isrs[20] = cast(ulong)& _isr20;
    isrs[21] = cast(ulong)& _isr21;
    isrs[22] = cast(ulong)& _isr22;
    isrs[23] = cast(ulong)& _isr23;
    isrs[24] = cast(ulong)& _isr24;
    isrs[25] = cast(ulong)& _isr25;
    isrs[26] = cast(ulong)& _isr26;
    isrs[27] = cast(ulong)& _isr27;
    isrs[28] = cast(ulong)& _isr28;
    isrs[29] = cast(ulong)& _isr29;
    isrs[30] = cast(ulong)& _isr30;
    isrs[31] = cast(ulong)& _isr31;
    isrs[32] = cast(ulong)& _isr32;
    isrs[33] = cast(ulong)& _isr33;
    isrs[34] = cast(ulong)& _isr34;
    isrs[35] = cast(ulong)& _isr35;
    isrs[36] = cast(ulong)& _isr36;
    isrs[37] = cast(ulong)& _isr37;
    isrs[38] = cast(ulong)& _isr38;
    isrs[39] = cast(ulong)& _isr39;
    isrs[40] = cast(ulong)& _isr40;
    isrs[41] = cast(ulong)& _isr41;
    isrs[42] = cast(ulong)& _isr42;
    isrs[43] = cast(ulong)& _isr43;
    isrs[44] = cast(ulong)& _isr44;
    isrs[45] = cast(ulong)& _isr45;
    isrs[46] = cast(ulong)& _isr46;
    isrs[47] = cast(ulong)& _isr47;
    isrs[48] = cast(ulong)& _isr48;
    isrs[49] = cast(ulong)& _isr49;
    isrs[50] = cast(ulong)& _isr50;
    isrs[51] = cast(ulong)& _isr51;
    isrs[52] = cast(ulong)& _isr52;
    isrs[53] = cast(ulong)& _isr53;
    isrs[54] = cast(ulong)& _isr54;
    isrs[55] = cast(ulong)& _isr55;
    isrs[56] = cast(ulong)& _isr56;
    isrs[57] = cast(ulong)& _isr57;
    isrs[58] = cast(ulong)& _isr58;
    isrs[59] = cast(ulong)& _isr59;
    isrs[60] = cast(ulong)& _isr60;
    isrs[61] = cast(ulong)& _isr61;
    isrs[62] = cast(ulong)& _isr62;
    isrs[63] = cast(ulong)& _isr63;
    isrs[64] = cast(ulong)& _isr64;
    isrs[65] = cast(ulong)& _isr65;
    isrs[66] = cast(ulong)& _isr66;
    isrs[67] = cast(ulong)& _isr67;
    isrs[68] = cast(ulong)& _isr68;
    isrs[69] = cast(ulong)& _isr69;
    isrs[70] = cast(ulong)& _isr70;
    isrs[71] = cast(ulong)& _isr71;
    isrs[72] = cast(ulong)& _isr72;
    isrs[73] = cast(ulong)& _isr73;
    isrs[74] = cast(ulong)& _isr74;
    isrs[75] = cast(ulong)& _isr75;
    isrs[76] = cast(ulong)& _isr76;
    isrs[77] = cast(ulong)& _isr77;
    isrs[78] = cast(ulong)& _isr78;
    isrs[79] = cast(ulong)& _isr79;
    isrs[80] = cast(ulong)& _isr80;
    isrs[81] = cast(ulong)& _isr81;
    isrs[82] = cast(ulong)& _isr82;
    isrs[83] = cast(ulong)& _isr83;
    isrs[84] = cast(ulong)& _isr84;
    isrs[85] = cast(ulong)& _isr85;
    isrs[86] = cast(ulong)& _isr86;
    isrs[87] = cast(ulong)& _isr87;
    isrs[88] = cast(ulong)& _isr88;
    isrs[89] = cast(ulong)& _isr89;
    isrs[90] = cast(ulong)& _isr90;
    isrs[91] = cast(ulong)& _isr91;
    isrs[92] = cast(ulong)& _isr92;
    isrs[93] = cast(ulong)& _isr93;
    isrs[94] = cast(ulong)& _isr94;
    isrs[95] = cast(ulong)& _isr95;
    isrs[96] = cast(ulong)& _isr96;
    isrs[97] = cast(ulong)& _isr97;
    isrs[98] = cast(ulong)& _isr98;
    isrs[99] = cast(ulong)& _isr99;
    isrs[100] = cast(ulong)& _isr100;
    isrs[101] = cast(ulong)& _isr101;
    isrs[102] = cast(ulong)& _isr102;
    isrs[103] = cast(ulong)& _isr103;
    isrs[104] = cast(ulong)& _isr104;
    isrs[105] = cast(ulong)& _isr105;
    isrs[106] = cast(ulong)& _isr106;
    isrs[107] = cast(ulong)& _isr107;
    isrs[108] = cast(ulong)& _isr108;
    isrs[109] = cast(ulong)& _isr109;
    isrs[110] = cast(ulong)& _isr110;
    isrs[111] = cast(ulong)& _isr111;
    isrs[112] = cast(ulong)& _isr112;
    isrs[113] = cast(ulong)& _isr113;
    isrs[114] = cast(ulong)& _isr114;
    isrs[115] = cast(ulong)& _isr115;
    isrs[116] = cast(ulong)& _isr116;
    isrs[117] = cast(ulong)& _isr117;
    isrs[118] = cast(ulong)& _isr118;
    isrs[119] = cast(ulong)& _isr119;
    isrs[120] = cast(ulong)& _isr120;
    isrs[121] = cast(ulong)& _isr121;
    isrs[122] = cast(ulong)& _isr122;
    isrs[123] = cast(ulong)& _isr123;
    isrs[124] = cast(ulong)& _isr124;
    isrs[125] = cast(ulong)& _isr125;
    isrs[126] = cast(ulong)& _isr126;
    isrs[127] = cast(ulong)& _isr127;
    isrs[128] = cast(ulong)& _isr128;
    isrs[129] = cast(ulong)& _isr129;
    isrs[130] = cast(ulong)& _isr130;
    isrs[131] = cast(ulong)& _isr131;
    isrs[132] = cast(ulong)& _isr132;
    isrs[133] = cast(ulong)& _isr133;
    isrs[134] = cast(ulong)& _isr134;
    isrs[135] = cast(ulong)& _isr135;
    isrs[136] = cast(ulong)& _isr136;
    isrs[137] = cast(ulong)& _isr137;
    isrs[138] = cast(ulong)& _isr138;
    isrs[139] = cast(ulong)& _isr139;
    isrs[140] = cast(ulong)& _isr140;
    isrs[141] = cast(ulong)& _isr141;
    isrs[142] = cast(ulong)& _isr142;
    isrs[143] = cast(ulong)& _isr143;
    isrs[144] = cast(ulong)& _isr144;
    isrs[145] = cast(ulong)& _isr145;
    isrs[146] = cast(ulong)& _isr146;
    isrs[147] = cast(ulong)& _isr147;
    isrs[148] = cast(ulong)& _isr148;
    isrs[149] = cast(ulong)& _isr149;
    isrs[150] = cast(ulong)& _isr150;
    isrs[151] = cast(ulong)& _isr151;
    isrs[152] = cast(ulong)& _isr152;
    isrs[153] = cast(ulong)& _isr153;
    isrs[154] = cast(ulong)& _isr154;
    isrs[155] = cast(ulong)& _isr155;
    isrs[156] = cast(ulong)& _isr156;
    isrs[157] = cast(ulong)& _isr157;
    isrs[158] = cast(ulong)& _isr158;
    isrs[159] = cast(ulong)& _isr159;
    isrs[160] = cast(ulong)& _isr160;
    isrs[161] = cast(ulong)& _isr161;
    isrs[162] = cast(ulong)& _isr162;
    isrs[163] = cast(ulong)& _isr163;
    isrs[164] = cast(ulong)& _isr164;
    isrs[165] = cast(ulong)& _isr165;
    isrs[166] = cast(ulong)& _isr166;
    isrs[167] = cast(ulong)& _isr167;
    isrs[168] = cast(ulong)& _isr168;
    isrs[169] = cast(ulong)& _isr169;
    isrs[170] = cast(ulong)& _isr170;
    isrs[171] = cast(ulong)& _isr171;
    isrs[172] = cast(ulong)& _isr172;
    isrs[173] = cast(ulong)& _isr173;
    isrs[174] = cast(ulong)& _isr174;
    isrs[175] = cast(ulong)& _isr175;
    isrs[176] = cast(ulong)& _isr176;
    isrs[177] = cast(ulong)& _isr177;
    isrs[178] = cast(ulong)& _isr178;
    isrs[179] = cast(ulong)& _isr179;
    isrs[180] = cast(ulong)& _isr180;
    isrs[181] = cast(ulong)& _isr181;
    isrs[182] = cast(ulong)& _isr182;
    isrs[183] = cast(ulong)& _isr183;
    isrs[184] = cast(ulong)& _isr184;
    isrs[185] = cast(ulong)& _isr185;
    isrs[186] = cast(ulong)& _isr186;
    isrs[187] = cast(ulong)& _isr187;
    isrs[188] = cast(ulong)& _isr188;
    isrs[189] = cast(ulong)& _isr189;
    isrs[190] = cast(ulong)& _isr190;
    isrs[191] = cast(ulong)& _isr191;
    isrs[192] = cast(ulong)& _isr192;
    isrs[193] = cast(ulong)& _isr193;
    isrs[194] = cast(ulong)& _isr194;
    isrs[195] = cast(ulong)& _isr195;
    isrs[196] = cast(ulong)& _isr196;
    isrs[197] = cast(ulong)& _isr197;
    isrs[198] = cast(ulong)& _isr198;
    isrs[199] = cast(ulong)& _isr199;
    isrs[200] = cast(ulong)& _isr200;
    isrs[201] = cast(ulong)& _isr201;
    isrs[202] = cast(ulong)& _isr202;
    isrs[203] = cast(ulong)& _isr203;
    isrs[204] = cast(ulong)& _isr204;
    isrs[205] = cast(ulong)& _isr205;
    isrs[206] = cast(ulong)& _isr206;
    isrs[207] = cast(ulong)& _isr207;
    isrs[208] = cast(ulong)& _isr208;
    isrs[209] = cast(ulong)& _isr209;
    isrs[210] = cast(ulong)& _isr210;
    isrs[211] = cast(ulong)& _isr211;
    isrs[212] = cast(ulong)& _isr212;
    isrs[213] = cast(ulong)& _isr213;
    isrs[214] = cast(ulong)& _isr214;
    isrs[215] = cast(ulong)& _isr215;
    isrs[216] = cast(ulong)& _isr216;
    isrs[217] = cast(ulong)& _isr217;
    isrs[218] = cast(ulong)& _isr218;
    isrs[219] = cast(ulong)& _isr219;
    isrs[220] = cast(ulong)& _isr220;
    isrs[221] = cast(ulong)& _isr221;
    isrs[222] = cast(ulong)& _isr222;
    isrs[223] = cast(ulong)& _isr223;
    isrs[224] = cast(ulong)& _isr224;
    isrs[225] = cast(ulong)& _isr225;
    isrs[226] = cast(ulong)& _isr226;
    isrs[227] = cast(ulong)& _isr227;
    isrs[228] = cast(ulong)& _isr228;
    isrs[229] = cast(ulong)& _isr229;
    isrs[230] = cast(ulong)& _isr230;
    isrs[231] = cast(ulong)& _isr231;
    isrs[232] = cast(ulong)& _isr232;
    isrs[233] = cast(ulong)& _isr233;
    isrs[234] = cast(ulong)& _isr234;
    isrs[235] = cast(ulong)& _isr235;
    isrs[236] = cast(ulong)& _isr236;
    isrs[237] = cast(ulong)& _isr237;
    isrs[238] = cast(ulong)& _isr238;
    isrs[239] = cast(ulong)& _isr239;
    isrs[240] = cast(ulong)& _isr240;

    isrs[241] = cast(ulong)& _isr241;
    isrs[242] = cast(ulong)& _isr242;
    isrs[243] = cast(ulong)& _isr243;
    isrs[244] = cast(ulong)& _isr244;
    isrs[245] = cast(ulong)& _isr245;
    isrs[246] = cast(ulong)& _isr246;
    isrs[247] = cast(ulong)& _isr247;
    isrs[248] = cast(ulong)& _isr248;
    isrs[249] = cast(ulong)& _isr249;
    isrs[250] = cast(ulong)& _isr250;
    isrs[251] = cast(ulong)& _isr251;
    isrs[252] = cast(ulong)& _isr252;
    isrs[253] = cast(ulong)& _isr253;
    isrs[254] = cast(ulong)& _isr254;
    isrs[255] = cast(ulong)& _isr255;
}

struct IntHandler
{
	ulong base;
	ulong pThis;
}

struct IDTEntry
{
    align(1):
	ushort offset_low;
	ushort selector;
	ubyte  ist;
	ubyte  flags;
	ushort offset_mid;
	uint offset_high;
	uint reserved;

	static IDTEntry opCall(ubyte index, ulong base, ushort selector = 0x08, ubyte flags = 0x8E, ubyte ist = 0)
    {
        IDTEntry entry;

        entry.offset_low = (base & 0xFFFF);
        entry.offset_mid = (base >> 16) & 0xFFFF;
        entry.offset_high = (base >> 32) & 0xFFFFFFFF;

        entry.selector = selector;
        entry.flags = flags;

        entry.ist = ist;
        entry.reserved = 0;

        return entry;
    }
}

struct IDTPtr
{
	align(1):
	ushort limit;
	ulong base;
}

const ubyte PIC1 = 0x20;
const ubyte PIC2 = 0xA0;
const ubyte ICW1 = 0x11;
const ubyte ICW4 = 0x01;
const ubyte PIC_EOI = 0x20;

extern(C) IntHandler _int_handlers[256];

IDTEntry idt[256];
IDTPtr idtp;

void idt_install()
{
    init_isr_array();

    ubyte irqBase = 32;
	ushort irqMask = 0xFFFD;

	idtp.limit = IDTEntry.sizeof*256-1;
	idtp.base = cast(ulong)&idt;

	for(ushort i=0; i<256; i++)
	{
	    idt[i] = IDTEntry(cast(ubyte)i, cast(ulong)isrs[i]);
	    idt_install_default_handler(cast(ubyte)i);
	}

	//idt[33] = IDTEntry(33, cast(ulong)&_isr33);

	asm
	{
	    "cli";
	    "lidt (%[ptr])" : : [ptr] "a" &idtp;
	}

	//Sent ICW1
	outp(PIC1, ICW1);
	outp(PIC2, ICW1);

	//Send ICW2
	outp(PIC1+1, irqBase);
	outp(PIC2+1, irqBase+8);

	//Send ICW3
	outp(PIC1+1, 4);
	outp(PIC2+1, 2);

	//Send ICW4
	outp(PIC1+1, ICW4);
	outp(PIC2+1, ICW4);

	//Disable all but IRQ 1
	outp(PIC1+1, cast(ubyte)(irqMask&0xFF));
	outp(PIC2+1, cast(ubyte)((irqMask>>8)&0xFF));

	asm
	{
	    "sti";
	}
}

void _int_handler(void* p, ulong interrupt, ulong error, InterruptStack* stack)
{
    writefln("\nInterrupt %u", interrupt);
    writefln("Error Code: %#X", stack.error);
    writefln("  Context\n  -------");
    writefln("  rip    %#016X", stack.rip);
    writefln("  rsp    %#016X", stack.rsp);
    writefln("  rbp    %#016X", stack.rbp);
    //writefln("  rax    %#016X", stack.rax);
    //writefln("  rbx    %#016X", stack.rbx);
    //writefln("  rcx    %#016X", stack.rcx);
    //writefln("  rdx    %#016X", stack.rdx);
    //writefln("  rsi    %#016X", stack.rsi);
    //writefln("  rdi    %#016X", stack.rdi);
    //writefln("  r8     %#016X", stack.r8);
    //writefln("  r9     %#016X", stack.r9);
    //writefln("  r10    %#016X", stack.r10);
    //writefln("  r11    %#016X", stack.r11);
    //writefln("  r12    %#016X", stack.r12);
    //writefln("  r13    %#016X", stack.r13);
    //writefln("  r14    %#016X", stack.r14);
    //writefln("  r15    %#016X", stack.r15);
    writefln("  ss     %#02X", stack.ss);
    writefln("  cs     %#02X", stack.cs);

    for(;;){}
}

void _irq_handler(void* p, ulong interrupt, ulong error, InterruptStack* stack)
{
    write("\nIRQ ");
    print_uint_dec(interrupt);
    write("\n");

    // Acknowledge irq on PIC1
    outp(PIC1, PIC_EOI);

    // Acknowledge irq on PIC2
	if(interrupt >= 40)
		outp(PIC2, PIC_EOI);
}

void idt_install_default_handler(ubyte interrupt)
{
	idt_install_handler(interrupt, cast(ulong)&_int_handler);
}

void idt_install_handler(ubyte interrupt, ulong handler)
{
    _int_handlers[interrupt].base = handler;
    _int_handlers[interrupt].pThis = 0;
}

struct InterruptStack
{
	ulong rax;
	ulong rbx;
	ulong rcx;
	ulong rdx;
	ulong rsi;
	ulong rdi;
	ulong r8;
	ulong r9;
	ulong r10;
	ulong r11;
	ulong r12;
	ulong r13;
	ulong r14;
	ulong r15;
	ulong rbp;
	ulong error;
	ulong rip;
	ulong cs;
	ulong rflags;
	ulong rsp;
	ulong ss;
}
