/*
  string_utils.c
  Developed mainly from pieces of online code, I did not write this 
  Standard implementation of memset and memcpy
 */

void* memset(void* dest, int c, unsigned long n) {
    unsigned char* d = (unsigned char*)dest;
    while (n--) {
        *d++ = (unsigned char)c;
    }
    return dest;
}

void* memcpy(void* dest, const void* src, unsigned long n) {
    unsigned char* d = (unsigned char*)dest;
    const unsigned char* s = (const unsigned char*)src;
    while (n--) {
        *d++ = *s++;
    }
    return dest;
}