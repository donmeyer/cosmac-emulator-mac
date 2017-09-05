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

#define CPU_PAGE_SIZE	0x0400		// 1k

#define CPU_NUM_PAGES	( CPU_MEM_SIZE / CPU_PAGE_SIZE )

#define CPU_NUM_REGS	16



struct CPU {
	uint16_t reg[CPU_NUM_REGS];	// 16-bits

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

typedef void (*ioTrapCallback_t)(void *userData, int inputPort, int outputPort );



int CPU_makeReadPage( int page );
int CPU_makeReadWritePage( int page );
void CPU_makeAllPagesRAM(void);

int CPU_writeByteToMemory( uint8_t data, uint16_t addr );
int CPU_writeToMemory( const uint8_t *src, uint16_t addr, uint16_t length );

int CPU_readByteFromMemory( uint16_t addr, uint8_t *data_p );
int CPU_readFromMemory( uint16_t addr, uint16_t length, uint8_t *dest );


void CPU_reset(void);

void CPU_step(void);
void CPU_fetch(void);
void CPU_execute(void);

const CPU *CPU_getCPU(void);

uint16_t CPU_getPC(void);

long CPU_getCycleCount(void);


void CPU_setEF( int ef, int state );

void CPU_setInputCallback( inputCallback_t callback, void *userData );

void CPU_setOutputCallback( outputCallback_t callback, void *userData );

void CPU_setIOTrapCallback( ioTrapCallback_t callback, void *userData );


CPU *CPU_getCPU_Unit_Test(void);

#endif
