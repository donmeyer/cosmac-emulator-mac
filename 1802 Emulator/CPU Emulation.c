// CPU Emulation.c


#include "etypes.h"

#include "CPU Emulation.h"




#define PAGE_SIZE	0x0800		// 1k

#define NUM_PAGES	( MEM_SIZE / PAGE_SIZE )


static void fetch();
static void execute();

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

static uint8_t memory[MEM_SIZE];




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


//======================================================================================
//======================================================================================



#pragma mark - Public API

const CPU *CPU_getCPU()
{
	return &cpu;
}


long CPU_getCycleCount()
{
	return cycleCount;
}


void CPU_reset()
{
	cpu.I = 0;
	cpu.N = 0;
	
	cpu.Q = 0;
	
	cpu.IE = 1;
	
	cpu.X = 0;
	cpu.P = 0;
	
	cpu.reg[0] = 0;
	
	// Not sure the hardware does this, but we do, if only to make unit tests sane.
	cpu.D = 0;
	cpu.DF = 0;
	
	// Reset metadata
	cycleCount = 0;
}


void CPU_step()
{
	fetch();
	execute();
}


int CPU_writeToMemory( const uint8_t *src, uint16_t addr, uint16_t length )
{
	while( length-- )
	{
		memory[addr] = *src;
		src++;
		addr++;
	}
	
	// TODO: implement page checking
	return 0;
}


int CPU_readFromMemory( uint16_t addr, uint16_t length, uint8_t *dest )
{
	// TODO: implement
	return 0;
}


#pragma mark Unit Test Support

CPU *CPU_getCPU_Unit_Test()
{
	return &cpu;
}



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


static void output( uint8_t port, uint8_t data )
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
	uint8_t op = read( cpu.reg[cpu.P] );

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
			// BDF
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
			// RET
			{
			uint8_t b = read( cpu.reg[cpu.X] );
			cpu.reg[cpu.X]++;
			cpu.P = b & 0x0F;
			cpu.X = (b>>4) & 0x0F;
			cpu.IE = TRUE;
			}
			break;

		case 0x01:
			// DIS
			{
			uint8_t b = read( cpu.reg[cpu.X] );
			cpu.reg[cpu.X]++;
			cpu.P = b & 0x0F;
			cpu.X = (b>>4) & 0x0F;
			cpu.IE = FALSE;
			}
			break;

		case 0x02:
			// LDXA
			cpu.D = read( cpu.reg[cpu.X] );
			cpu.reg[cpu.X]++;
			break;

		case 0x03:
			// STXD
			write( cpu.reg[cpu.X], cpu.D );
			cpu.reg[cpu.X]--;
			break;

		case 0x04:
			// ADC
			{
				uint16_t accum = cpu.D;
				accum += read( cpu.reg[cpu.P] );
				accum += cpu.DF;
				cpu.D = accum & 0xFF;
				cpu.DF = accum > 0xFF ? 1 : 0;
			}
			break;

		case 0x05:
			// SDB
			{
				uint16_t accum = read( cpu.reg[cpu.X] );
				uint8_t nd = ~(cpu.D);
				accum += nd;
				accum += cpu.DF;
				cpu.D = accum & 0xFF;
				cpu.DF = accum > 0xFF ? 1 : 0;
			}
			break;

		case 0x06:
			// SHRC
			{
				uint8_t df = cpu.D & 0x01;
				cpu.D >>= 1;
				if( cpu.DF )
				{
					cpu.D |= 0x80;
				}
				cpu.DF = df;
			}
			break;

		case 0x07:
			// SMB
			{
				uint16_t accum = cpu.D;
				uint8_t nd = ~read( cpu.reg[cpu.X] );
				accum += nd;
				accum += cpu.DF;
				cpu.D = accum & 0xFF;
				cpu.DF = accum > 0xFF ? 1 : 0;
			}
			break;

		case 0x08:
			// SAV
			write( cpu.reg[cpu.X], cpu.T );
			break;

		case 0x09:
			// MARK
			break;

		case 0x0A:
			// REQ
			break;

		case 0x0B:
			// SEQ
			break;

		case 0x0C:
			// ADCI
			{
			uint16_t accum = cpu.D;
			accum += read( cpu.reg[cpu.P] );
			accum += cpu.DF;
			cpu.D = accum & 0xFF;
			cpu.DF = accum > 0xFF ? 1 : 0;
			cpu.reg[cpu.P]++;
			}
			break;

		case 0x0D:
			// SDBI
			{
			uint16_t accum = read( cpu.reg[cpu.P] );
			uint8_t nd = ~(cpu.D);
			accum += nd;
			accum += cpu.DF;
			cpu.D = accum & 0xFF;
			cpu.DF = accum > 0xFF ? 1 : 0;
			cpu.reg[cpu.P]++;
			}
			break;

		case 0x0E:
			// SHLC
			break;

		case 0x0F:
			// SMBI
			{
				uint16_t accum = cpu.D;
				uint8_t nd = ~read( cpu.reg[cpu.P] );
				accum += nd;
				accum += cpu.DF;
				cpu.D = accum & 0xFF;
				cpu.DF = accum > 0xFF ? 1 : 0;
				cpu.reg[cpu.P]++;
			}
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
			// LBR
			break;

		case 0x01:
			// LBQ
			break;

		case 0x02:
			// LBZ
			break;

		case 0x03:
			// LBDF
			break;

		case 0x04:
			// NOP
			break;

		case 0x05:
			// LSNQ
			break;

		case 0x06:
			// LSNZ
			break;

		case 0x07:
			// LSNF
			break;

		case 0x08:
			// LSKP
			break;

		case 0x09:
			// LBNQ
			break;

		case 0x0A:
			// LBNZ
			break;

		case 0x0B:
			// LBNF
			break;

		case 0x0C:
			// LSIE
			break;

		case 0x0D:
			// LSQ
			break;

		case 0x0E:
			// LSZ
			break;

		case 0x0F:
			// LSDF
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
			// LDX
			cpu.D = read( cpu.reg[cpu.X] );
			break;

		case 0x01:
			// OR
			break;

		case 0x02:
			// AND
			break;

		case 0x03:
			// XOR
			break;

		case 0x04:
			// ADD
			break;

		case 0x05:
			// SD
			break;

		case 0x06:
			// SHR
			break;

		case 0x07:
			// SM
			break;

		case 0x08:
			// LDI
			break;

		case 0x09:
			// ORI
			break;

		case 0x0A:
			// ANI
			break;

		case 0x0B:
			// XRI
			break;

		case 0x0C:
			// ADI
			break;

		case 0x0D:
			// SDI
			break;

		case 0x0E:
			// SHL
			break;

		case 0x0F:
			// SMI
			break;
	}
}
