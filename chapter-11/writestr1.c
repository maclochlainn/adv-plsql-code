/*
 * writestr1.c
 * Chapter 11, Oracle Database 12c PL/SQL Advanced Programming Technique
 * by Michael McLaughlin
 *
 * ALERTS:
 *
 * This script opens a file and write a single line
 * of text to the file. It is used in conjunction
 * with the create_library1.sql script.
 *
 * Compilation instructions are below. You need to have
 * a C compiler installed on your local platform. If
 * you do not have a C compiler this is not possible.
 * You do the following:
 *  - You need to compile this as a shared library in
 *    UNIX, which has an *.so extension and as a
 *    Dynamic Link Library (*.DLL) on the Windows
 *    platforms.
 *  - On UNIX, there are two different ways to compile
 *    a shared library. They are noted below for
 *    reference:
 *    - Solaris: gcc -G -o sample.so sample.c
 *    - GNU:     gcc -shared -o sample.so sample.c
 *  - It is assumed Microsoft's IDE is well designed
 *    and provides help messages to compile a DLL.
 */

/* Include standard IO. */
#include <stdio.h>

/* Declare a writestr function. */
void writestr1(char *path, char *message)
{
  /* Declare a FILE variable. */
  FILE *file_name;

  /* Open the File. */
  file_name = fopen(path,"w");

  /* Write to file the message received. */
  fprintf(file_name,"%s\n",message);

  /* Close the file. */
  fclose(file_name);

}
