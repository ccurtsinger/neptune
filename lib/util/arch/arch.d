/**
 * Architecture and implementation-specific utilities and constants
 *
 * Copyright: 2008 The Neptune Project
 */

module util.arch.arch;

/// Type for interrupt service routines
alias void function() isr_t;

/// Page (frame) size
const ulong FRAME_SIZE = 0x1000;
