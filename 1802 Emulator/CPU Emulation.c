// CPU Emulation.c


#include "etypes.h"

#include "CPU Emulation.h"




#define PAGE_SIZE	0x0800		// 1k

#define NUM_PAGES	( MEM_SIZE / PAGE_SIZE )



static void opcode_0();
static void opcode_1();
static void opcode_2();
static void opcode_3();
static void opcode_4();
static void opcode_5();
static void opcode_6();
static void opcode_7();
static void opcode_8();
static void opcode_9();
static void opcode_A();
static void opcode_B();
static void opcode_C();
static void opcode_D();
static void opcode_E();
static void opcode_F();




static int pageWriteFlags[NUM_PAGES];		// True means the page is writeable

uint8_t memory[MEM_SIZE];




static CPU cpu;

typedef void(*op_func)();

static const op_func opfuncs[16] = {
	opcode_0,
	opcode_1,
	opcode_2,
	opcode_3,
	opcode_4,
	opcode_5,
	opcode_6,
	opcode_7,
	opcode_8,
	opcode_9,
	opcode_A,
	opcode_B,
	opcode_C,
	opcode_D,
	opcode_E,
	opcode_F,
};


static long cycleCount;



long getCycleCount()
{
	return cycleCount;
}


void reset()
{
	cpu.I = 0;
	cpu.N = 0;
	
	cpu.Q = 0;
	
	cpu.IE = 1;
	
	cpu.X = 0;
	cpu.P = 0;
	
	cpu.reg[0] = 0;
	
	// Reset metadata
	cycleCount = 0;
}


void step()
{
	fetch();
	execute();
}


//======================================================================================
//======================================================================================


#pragma mark - Memory Access

static uint8_t read( uint16_t addr )
{
	return memory[addr];
}


static void write( uint16_t addr, uint8_t data )
{
	// TODO: check that the page is writeable!
	memory[addr] = data;
}



static uint8_t input( uint8_t port )
{
	// TODO: Implement
	return 0;
}


static void output( uint8_t port, unit8_t data )
{
	// TODO: Implement
}


#pragma mark - Utility

static void setRegLow( uint8_t reg, uint8_t data )
{
	cpu.reg[reg] &= 0xFF00;
	cpu.reg[reg] |= data;
}


static void branch( bool f )
{
	if( f )
	{
		setRegLow( cpu.P, cpu.reg[cpu.P] );
	}
	else
	{
		cpu.reg[cpu.P]++;
	}
}




#pragma mark - Processing

static void fetch()
{
	// Read opcode
	uint8_t op = cpu.reg[cpu.P];

	cpu.N = op & 0x0F;
	cpu.I = op>>4 & 0x0F;
			
	cpu.reg[cpu.P]++;
	
	cycleCount++;
}


static void execute()
{
	(opfuncs[cpu.I])();	
	cycleCount++;
}



#pragma mark Opcodes

static void opcode_0()
{
	if( cpu.N == 0 )
	{
		// Idle
	}
	else
	{
		// LDN
		cpu.D = read( cpu.reg[cpu.N] );
	}	
}


static void opcode_1()
{
	// INC
	cpu.reg[cpu.N]++;
}


static void opcode_2()
{
	// DEC
	cpu.reg[cpu.N]--;
}


static void opcode_3()
{
	switch( cpu.N )
	{
		case 0x00:
			// BR
			branch( TRUE );
			break;

		case 0x01:
			// BQ
			branch( cpu.Q );
			break;

		case 0x02:
			// BZ
			branch( cpu.D == 0 );
			break;

		case 0x03:
			// 
			branch( cpu.DF );
			break;

		case 0x04:
			// B1
			branch( cpu.EF[0] );
			break;

		case 0x05:
			// B2
			branch( cpu.EF[1] );
			break;

		case 0x06:
			// B3
			branch( cpu.EF[2] );
			break;

		case 0x07:
			// B4
			branch( cpu.EF[3] );
			break;

		case 0x08:
			// SKP
			cpu.reg[cpu.P]++;
			break;

		case 0x09:
			// BNQ
			branch( ! cpu.Q );
			break;

		case 0x0A:
			// BNZ
			branch( cpu.D != 0 );
			break;

		case 0x0B:
			// BNF
			branch( ! cpu.DF == 0 );
			break;

		case 0x0C:
			// BN1
			branch( ! cpu.EF[0] );
			break;

		case 0x0D:
			// BN2
			branch( ! cpu.EF[1] );
			break;

		case 0x0E:
			// BN3
			branch( ! cpu.EF[2] );
			break;

		case 0x0F:
			// BN4
			branch( ! cpu.EF[3] );
			break;
	}
}


static void opcode_4()
{
	// LDA
	cpu.D = read( cpu.reg[cpu.N] );
	cpu.reg[cpu.N]++;
}


static void opcode_5()
{
	// STN
	write( cpu.reg[cpu.N], cpu.D );
}


static void opcode_6()
{
	if( cpu.N == 0 )
	{
		// IRX
		cpu.reg[cpu.X]++;
	}
	else if( cpu.N < 8 )
	{
		// Output 1-7
		output( cpu.N, read( cpu.reg[cpu.X] ) );
		cpu.reg[cpu.X]++;
	}
	else if( cpu.N > 8 )
	{
		// Input 1-7
		uint8_t data = input( cpu.N - 8 );
		write( cpu.reg[cpu.X], data );
		cpu.D = data;
	}
	else
	{
		// Invalid Opcode
		// TODO: Handle this as an error!
	}
}


static void opcode_7()
{
	switch( cpu.N )
	{
		case 0x00:
			// 
			break;

		case 0x01:
			// 
			break;

		case 0x02:
			// 
			break;

		case 0x03:
			// 
			break;

		case 0x04:
			// 
			break;

		case 0x05:
			// 
			break;

		case 0x06:
			// 
			break;

		case 0x07:
			// 
			break;

		case 0x08:
			// 
			break;

		case 0x09:
			// 
			break;

		case 0x0A:
			// 
			break;

		case 0x0B:
			// 
			break;

		case 0x0C:
			// 
			break;

		case 0x0D:
			// 
			break;

		case 0x0E:
			// 
			break;

		case 0x0F:
			// BR
			break;
	}
}


static void opcode_8()
{
	// GLO
	cpu.D = cpu.reg[cpu.N] & 0xFF;
}


static void opcode_9()
{
	// GHI
	cpu.D = (cpu.reg[cpu.N]>>8) & 0xFF;
}


static void opcode_A()
{
	// PLO
	setRegLow( cpu.N, cpu.D );
}


static void opcode_B()
{
	// PHI
	cpu.reg[cpu.N] &= 0x00FF;
	cpu.reg[cpu.N] |= cpu.D<<8;	
}


static void opcode_C()
{
	switch( cpu.N )
	{
		case 0x00:
			// 
			break;

		case 0x01:
			// 
			break;

		case 0x02:
			// 
			break;

		case 0x03:
			// 
			break;

		case 0x04:
			// 
			break;

		case 0x05:
			// 
			break;

		case 0x06:
			// 
			break;

		case 0x07:
			// 
			break;

		case 0x08:
			// 
			break;

		case 0x09:
			// 
			break;

		case 0x0A:
			// 
			break;

		case 0x0B:
			// 
			break;

		case 0x0C:
			// 
			break;

		case 0x0D:
			// 
			break;

		case 0x0E:
			// 
			break;

		case 0x0F:
			// BR
			break;
	}
}


static void opcode_D()
{
	// SEP
	cpu.P = cpu.N;
}


static void opcode_E()
{
	// SEX
	cpu.X = cpu.N;
}


static void opcode_F()
{
	switch( cpu.N )
	{
		case 0x00:
			// 
			break;

		case 0x01:
			// 
			break;

		case 0x02:
			// 
			break;

		case 0x03:
			// 
			break;

		case 0x04:
			// 
			break;

		case 0x05:
			// 
			break;

		case 0x06:
			// 
			break;

		case 0x07:
			// 
			break;

		case 0x08:
			// 
			break;

		case 0x09:
			// 
			break;

		case 0x0A:
			// 
			break;

		case 0x0B:
			// 
			break;

		case 0x0C:
			// 
			break;

		case 0x0D:
			// 
			break;

		case 0x0E:
			// 
			break;

		case 0x0F:
			// BR
			break;
	}
}
