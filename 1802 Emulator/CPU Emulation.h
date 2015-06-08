//
//  CPU Emulation.h
//  1802 Emulator
//
//  Created by Donald Meyer on 6/1/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#ifndef _802_Emulator_CPU_Emulation_h
#define _802_Emulator_CPU_Emulation_h

#include "etypes.h"


#define CPU_MEM_SIZE	0x10000		// 64k

#define CPU_PAGE_SIZE	0x0800		// 1k

#define CPU_NUM_PAGES	( CPU_MEM_SIZE / CPU_PAGE_SIZE )


struct CPU {
	uint16_t reg[16];	// 16-bits
	
	uint8_t I;	// 4-bits
	uint8_t N;	// 4-bits
	
	uint8_t X;	// 4-bits
	uint8_t P;	// 4-bits
	
	uint8_t IE;	// 1-bit
	
	uint8_t D;	// 8-bits
	uint8_t DF;	// 1-bit
	
	uint8_t T;	// 8-bits
	
	uint8_t Q;		// 1-bit
	uint8_t EF[4];	// 1-Bit
};


typedef struct CPU  CPU;


typedef void (*outputCallback_t)(void *userData, uint8_t port, uint8_t data);

typedef uint8_t (*inputCallback_t)(void *userData, uint8_t port );



int CPU_makeReadPage( int page );
int CPU_makeReadWritePage( int page );
void CPU_makeAllPagesRAM();

int CPU_writeByteToMemory( uint8_t data, uint16_t addr );
int CPU_writeToMemory( const uint8_t *src, uint16_t addr, uint16_t length );

int CPU_readByteFromMemory( uint16_t addr, uint8_t *data_p );
int CPU_readFromMemory( uint16_t addr, uint16_t length, uint8_t *dest );


void CPU_reset();

void CPU_step();


const CPU *CPU_getCPU();

long CPU_getCycleCount();


void CPU_setInputCallback( inputCallback_t callback, void *userData );

void CPU_setOutputCallback( outputCallback_t callback, void *userData );


CPU *CPU_getCPU_Unit_Test();

#endif
