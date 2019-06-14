/* Copyright (C) 1992-2018 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Ulrich Drepper, <drepper@gnu.org>, August 1995.
   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <http://www.gnu.org/licenses/>.  */

#ifndef _TOPPERS_GLIBC_SYSDEP_H
#define _TOPPERS_GLIBC_SYSDEP_H 1

#if defined(__i386__)

/* sysdeps/i386/nptl/tls.h */
/* sysdeps/unix/sysv/linux/i386/sysdep.h */
#ifndef _LINUX_I386_SYSDEP_H
#define _LINUX_I386_SYSDEP_H 1

/* Pointer mangling support.  */

/*
#  define PTR_MANGLE(var)	asm ("xorl %%gs:%c2, %0\n"		      \
				     "roll $9, %0"			      \
				     : "=r" (var)			      \
				     : "0" (var),			      \
				       "i" (offsetof (tcbhead_t,	      \
						      pointer_guard)))
*/
#  define PTR_MANGLE(var)	asm ("xorl %%gs:%c2, %0\n"		      \
				     "roll $9, %0"			      \
				     : "=r" (var)			      \
				     : "0" (var),			      \
				       "i" (0x18))

#endif /* linux/i386/sysdep.h */

#elif defined(__x86_64__)

/* sysdeps/x86_64/nptl/tls.h */
/* sysdeps/unix/sysv/linux/x86_64/sysdep.h */
#ifndef _LINUX_X86_64_SYSDEP_H
#define _LINUX_X86_64_SYSDEP_H 1

/* Pointer mangling support.  */
/*
#  define PTR_MANGLE(var)	asm ("xor %%fs:%c2, %0\n"		      \
				     "rol $2*" LP_SIZE "+1, %0"		      \
				     : "=r" (var)			      \
				     : "0" (var),			      \
				       "i" (offsetof (tcbhead_t,	      \
						      pointer_guard)))
*/

#define LP_SIZE	8

#  define PTR_MANGLE(var)	asm ("xor %%fs:%c2, %0\n"		      \
				     "rol $2*" LP_SIZE "+1, %0"		      \
				     : "=r" (var)			      \
				     : "0" (var),			      \
				       "i" (0x30))

#endif /* linux/x86_64/sysdep.h */

#else

#  define PTR_MANGLE(var)	var

#endif

#endif /* _TOPPERS_GLIBC_SYSDEP_H */
