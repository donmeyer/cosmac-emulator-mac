//
//  CPU Emulation.h
//  1802 Emulator
//
//  Created by Donald Meyer on 6/1/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#ifndef _802_Emulator_CPU_Emulation_h
#define _802_Emulator_CPU_Emulation_h



#define CPU_MEM_SIZE	0x10000		// 64k

#define CPU_PAGE_SIZE	0x0800		// 1k

#define CPU_NUM_PAGES	( CPU_MEM_SIZE / CPU_PAGE_SIZE )


struct CPU {
	uint16_t reg[16];	// 16-bits
	
	uint8_t I;	// 4-bits
	uint8_t N;	// 4-bits
	
	uint8_t X;	// 4-bits
	uint8_t P;	// 4-bits
	
	bool IE;	// 1-bit
	
	uint8_t D;	// 8-bits
	uint8_t DF;	// 1-bit
	
	uint8_t T;	// 8-bits
	
	bool Q;		// 1-bit
	bool EF[4];		//
};


typedef struct CPU  CPU;



int CPU_makeReadPage( int page );
int CPU_makeReadWritePage( int page );

int CPU_writeByteToMemory( uint8_t data, uint16_t addr );
int CPU_writeToMemory( const uint8_t *src, uint16_t addr, uint16_t length );

int CPU_readByteFromMemory( uint16_t addr, uint8_t *data_p );
int CPU_readFromMemory( uint16_t addr, uint16_t length, uint8_t *dest );


void CPU_reset();

void CPU_step();


const CPU *CPU_getCPU();

long CPU_getCycleCount();



CPU *CPU_getCPU_Unit_Test();

#endif
