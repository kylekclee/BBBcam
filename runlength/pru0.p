// *
// * PRU_memAcc_DDR_sharedRAM.p
// *
// * Copyright (C) 2012 Texas Instruments Incorporated - http://www.ti.com/
// *
// *
// *  Redistribution and use in source and binary forms, with or without
// *  modification, are permitted provided that the following conditions
// *  are met:
// *
// *    Redistributions of source code must retain the above copyright
// *    notice, this list of conditions and the following disclaimer.
// *
// *    Redistributions in binary form must reproduce the above copyright
// *    notice, this list of conditions and the following disclaimer in the
// *    documentation and/or other materials provided with the
// *    distribution.
// *
// *    Neither the name of Texas Instruments Incorporated nor the names of
// *    its contributors may be used to endorse or promote products derived
// *    from this software without specific prior written permission.
// *
// *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// *  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// *
// *

// *
// * ============================================================================
// * Copyright (c) Texas Instruments Inc 2010-12
// *
// * Use of this software is controlled by the terms and conditions found in the
// * license agreement under which this software has been supplied or provided.
// * ============================================================================
// *


// *****************************************************************************/
// file:   PRU_memAcc_DDR_sharedRAM.p
//
// brief:  PRU Example to access DDR and PRU shared Memory.
//
//
//  (C) Copyright 2012, Texas Instruments, Inc
//
//  author     M. Watkins
//
//  version    0.1     Created
// *****************************************************************************/


.origin 0
.entrypoint MEMACCESS_DDR_PRUSHAREDRAM

#include "PRU_memAcc_DDR_sharedRAM.hp"

// Address for the Constant table Block Index Register (CTBIR) for PRU0
#define CTBIR_0          0x22020

// Address for the Constant table Programmable Pointer Register 0(CTPPR_0) for PRU0
#define CTPPR_0_0         0x22028

// Address for the Constant table Programmable Pointer Register 1(CTPPR_1) for PRU0
#define CTPPR_1_0         0x2202C

//macros

.macro encode
.mparam srcreg
    QBNE    P0_0, srcreg.b0, 255
    CLR     srcreg.b0, 0
P0_0:
    QBLT    NOT_RUN_0, srcreg.b0, THRESHOLD // pixel is above threshold
    QBNE    P0_1, srcreg.b1, 255
    CLR     srcreg.b1, 0
P0_1:
    QBLT    NOT_RUN_0, srcreg.b1, THRESHOLD // pixel is above threshold
    QBNE    P0_2, srcreg.b2, 255
    CLR     srcreg.b2, 0
P0_2:
    QBLT    NOT_RUN_0, srcreg.b2, THRESHOLD // pixel is above threshold
    QBNE    P0_3, srcreg.b3, 255
    CLR     srcreg.b3, 0
P0_3:
    QBLT    NOT_RUN_0, srcreg.b3, THRESHOLD // pixel is above threshold
    QBA     ENCODE_ZERO_0 // all pixels are below threhsold
NOT_RUN_0:
    // at least one pixel is above threshold
    // check runlen_status
    // we weren't in a run, so don't need to write run data to pru mem
    QBEQ    WRITE_BYTE_0, runlen_status, 0
// we were in a run, so write run to pru mem 
WRITE_RUN_0:
    LSL runlen_counter, runlen_counter, 24 // move count to three most significant bytes
    ADD runlen_counter, runlen_counter, 255 // set least significant byte to 255 to 
    SBBO    runlen_counter, encoding_dst, 0, 4 // the run to pru mem
    ADD encoding_dst, encoding_dst, 4 // increment offset into pru mem
    // reset runlength status and counter
    MOV runlen_status, 0
    MOV runlen_counter, 0
// write byte of raw data to pru mem
WRITE_BYTE_0:
    // copy the entire byte
    SBBO    srcreg, encoding_dst, 0, 4 // copy register to offset encoding_src in pru mem
    ADD encoding_dst, encoding_dst, 4 // increment offset into pru mem
    QBA END_ENCODE
ENCODE_ZERO_0: // all pixels are below threshold
    QBEQ    ADD_TO_RUN_0, runlen_status, 1 // we're already in a run
    MOV     runlen_status, 1 // start of a run, set runlen_status to 1
ADD_TO_RUN_0:
    ADD runlen_counter, runlen_counter, 1 // increment runlength counter
END_ENCODE:
.endm




MEMACCESS_DDR_PRUSHAREDRAM:

    // Enable OCP master port
    LBCO      r0, CONST_PRUCFG, 4, 4
    CLR     r0, r0, 4         // Clear SYSCFG[STANDBY_INIT] to enable OCP master port
    SBCO      r0, CONST_PRUCFG, 4, 4

    // Configure the programmable pointer register for PRU0 by setting c28_pointer[15:0]
    // field to 0x0120.  This will make C28 point to 0x00012000 (PRU shared RAM).
    MOV     r0, 0x00000100
    MOV       r1, CTPPR_0_0
    ST32      r0, r1

    // Configure the programmable pointer register for PRU0 by setting c31_pointer[15:0]
    // field to 0x0010.  This will make C31 point to 0x80001000 (DDR memory).
    MOV     r0, 0x00100000
    MOV       r1, CTPPR_1_0
    ST32      r0, r1



INIT:
        MOV     r0, 0
        MOV     transfer_ready, 0
        //MOV number_frames, NUMFRAMES + 1
        MOV frame_counter, 0
        SUB frame_counter, frame_counter, 1 // intentional underflow

        // TODO: what does this do? (configure interrupts?)
        LBCO r0, CONST_PRUCFG, 0x34, 4                    
        SET r0, 1
        SBCO r0, CONST_PRUCFG, 0x34, 4

        // set ACK field in PRU mem to 1 to get the ball rolling
        LDI     pr0ack, 1
        SBCO    pr0ack, CONST_PRUSHAREDRAM, 0, 4

        // Load DDR addr from arm host into a ddr_base register
        // TODO: can I use constant table instead?
        MOV     r1, 0
        LBBO    ddr_base, r1, 0, 4

        // move a value other than 1 or 2 to first address of ddr to indicate invalid data
        MOV var1, DDR_INVALID
        SBBO    var1, ddr_base, 0, 4

        // initialize number_frames from the value written to DDR by host
        INIT_NUM_FRAMES
        ADD number_frames, number_frames, 1
        
        // initialize ARM ack to 0
        MOV var1, 0
        //SBCO    var1, CONST_PRUSHAREDRAM, ARM_PRU_ACK_OFFSET, 4
        SBBO    var1, r1, 0, 4

        CLR OE // pull buffer OE low to enable output

        // jump to initialization of ddr, without overwriting DATA_INVALID value
        QBA RESETDDR_1 

RESETDDR:

        // to indicate completion of a group of four frames
        MOV var1, 1
        SBBO    var1, ddr_base, 0, 4

WAIT_ARM_ACK_1:
        MOV r1, ARM_PRU_ACK_OFFSET
        LBBO    var1, r1, 0, 4
        QBNE    WAIT_ARM_ACK_1, var1, 1
        // take possesion of ddr again
//        MOV var1, DDR_INVALID
//        SBBO    var1, ddr_base, 0, 4
        // clear ack from ARM
        MOV var1, 0
        SBBO    var1, r1, 0, 4

//// flush one frame (it's overexposed)
//FLUSH:
//        //write ACK to PRU mem
//        SBCO    pr0ack, CONST_PRUSHAREDRAM, 0, 4
//        NOP
//        NOP
//        NOP
//        NOP
//        NOP
//        NOP
//        QBBC    FLUSH, r31, 30

        // clear the interrupt from pru1
        LDI     var1, 18
        SBCO    var1, C0, 0x24, 4 

RESETDDR_1:
        // set DDR pointer to ddr base address
        SBCO    ddr_base, CONST_PRUSHAREDRAM, CHUNKSIZE + 8, 4
        LBCO    ddr_pointer, CONST_PRUSHAREDRAM, CHUNKSIZE + 8, 4
        // reset DDR counter to 0
        MOV ddr_counter, 0
    

READ:

        // TODO: change label of this register
        LBCO transfer_ready, CONST_PRUSHAREDRAM, 4, 4 // == 1 if there's a fresh chunk to transfer

        QBNE    WAIT, transfer_ready, 1


        // transfer_ready == 1
        // set transfer_ready back to 0 and copy to corresponding field in PRU shared ram
        MOV transfer_ready, 0
        SBCO    transfer_ready, CONST_PRUSHAREDRAM, 4, 4
        // load data
        LBCO    data_start, CONST_PRUSHAREDRAM, 8, CHUNKSIZE
        
// run-length encoding implementation
// the following is needed:
//      a convention on the start address in local pru mem for the encoded data buffer
//      encoding_dst, a pointer to keep track of write location for encoded data
//      runlen_status, to keep track of whether we are currently in a run of "zeros" or not
//      runlen_counter, to count number of pixels in current run
//          (or, move that functionality to pru1)
//      in INIT: initialize all these registers
    // encode it and copy it to DDR
    encode r9
    encode r10
    encode r11
    encode r12
    encode r13
    encode r14
    encode r15
    encode r16
    encode r17
    encode r18
    encode r19
    encode r20
    encode r21
    encode r22
    encode r23
    encode r24


    MOV encoding_dst, ENCODING_PRUMEM_BASE // reset the pointer into local pru mem
    LBBO    r9, encoding_dst, 0, CHUNKSIZE // copy encoded data back into registers
    SBBO    r9, ddr_pointer, DDR_OFFSET, CHUNKSIZE // and transfer it to DDR
        
        //write ACK to PRU mem
        SBCO    pr0ack, CONST_PRUSHAREDRAM, 0, 4

        // increment DDR counter
        ADD ddr_counter, ddr_counter, CHUNKSIZE

        // increment DDR memory pointer
        ADD ddr_pointer, ddr_pointer, CHUNKSIZE


        // TODO: are these NOPs still necessary? probably not
WAIT:
        //check if we received the kill signal
        QBBS    FRAME_END, r31, 30
        //QBNE READ, reads_left, 0
        // TODO: testing: want pr0 to read indefinitely
        QBA READ 



FRAME_END:

    // clear the interrupt from pru1
    LDI     var1, 18
    SBCO    var1, C0, 0x24, 4 

    // Send notification to to host that one frame has been read out
    //MOV       r31.b0, PRU0_ARM_INTERRUPT+16
    
    SUB   number_frames, number_frames, 1     // decrement loop counter
    ADD   frame_counter, frame_counter, 1     // increment frame counter
    QBEQ  DONE, number_frames, 0  // repeat loop unless zero
    
    // number of frames completed FRAMES_PER_TRANSFER == 0? 
    MOV   var1, frame_counter.b0
    AND   var1, var1, (FRAMES_PER_TRANSFER - 1)

    // reset ddr pointer every 1, 2, or 4 frames
    QBEQ  RESETDDR, var1, (FRAMES_PER_TRANSFER - 1)

//    // otherwise write to first byte of ddr to indicate completion of an even frame
//    MOV var1, 0
//    SBBO    var1, ddr_base, 0, 4

//WAIT_ARM_ACK_2:
//    // and then wait for arm to ack start of a data transfer
//    MOV r1, ARM_PRU_ACK_OFFSET
//    LBBO    var1, r1, 0, 4
//    QBNE    WAIT_ARM_ACK_2, var1, 1
//    // clear ack from ARM
//    MOV var1, 0
//    //SBCO    var1, CONST_PRUSHAREDRAM, ARM_PRU_ACK_OFFSET, 4
//    SBBO    var1, r1, 0, 4

    // finally resume readout
    QBA   READ 




DONE:
    // give host time to process interrupt from pru1 before it a signal
    MOV r1, DELAYCOUNT

////DELAY:
////    SUB   r1, r1, 1     // decrement loop counter
////
//    // Send notification to to host that one frame has been read out
//    MOV       r31.b0, PRU0_ARM_INTERRUPT+16
////    NOP
//    QBNE    DONE, r1, 0  // repeat loop unless zero




    // TODO: for testing purposes, don't set OE high when done
    // SET OE 

    // Halt the processor
    HALT

