#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <IOKit/IOKitLib.h>

int main(){
  kern_return_t err;

  CFMutableDictionaryRef matching = IOServiceMatching("IntelAccelerator");
  if(!matching){
    printf("unable to create service matching dictionary\n");
    return 0;
  }

  io_iterator_t iterator;
  err = IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iterator);
  if (err != KERN_SUCCESS){
    printf("no matches\n");
    return 0;
  }

  io_service_t service = IOIteratorNext(iterator);

  if (service == IO_OBJECT_NULL){
    printf("unable to find service\n");
    return 0;
  }
  printf("got service: %x\n", service);

  io_connect_t conn = MACH_PORT_NULL;
  err = IOServiceOpen(service, mach_task_self(), 2, &conn);
  if (err != KERN_SUCCESS){
    printf("unable to get user client connection\n");
    return 0;
  }else{
    printf("got userclient connection: %x\n", conn);
  }

  mach_vm_address_t addr = 0x414100000000;
  mach_vm_size_t size = 0x1000;

  err = IOConnectMapMemory(conn, 3, mach_task_self(), &addr, &size, kIOMapAnywhere);
  return 0;
}
