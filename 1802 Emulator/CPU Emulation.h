//
//  CPU Emulation.h
//  1802 Emulator
//
//  Created by Donald Meyer on 6/1/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#ifndef _802_Emulator_CPU_Emulation_h
#define _802_Emulator_CPU_Emulation_h



#define MEM_SIZE	0x10000		// 64k


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



extern uint8_t memory[MEM_SIZE];



void reset();

void step();

long getCycleCount();


#endif
