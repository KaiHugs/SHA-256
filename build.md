# Build

## Quick Build

```bash
cd ~
cp -r /mnt/c/Users/Kai/Documents/GitHub/SHA-256 ~/SHA-256
cd ~/SHA-256/code

sed -i '/^void _start(void) {$/,/^}$/d' miner.c

cat > string_utils.c << 'EOF'
void* memset(void* dest, int c, unsigned long n) {
    unsigned char* d = (unsigned char*)dest;
    while (n--) *d++ = (unsigned char)c;
    return dest;
}

void* memcpy(void* dest, const void* src, unsigned long n) {
    unsigned char* d = (unsigned char*)dest;
    const unsigned char* s = (const unsigned char*)src;
    while (n--) *d++ = *s++;
    return dest;
}
EOF

sed -i '/echo "✓ start.o"/a\\necho -e "${YELLOW}Compiling string utilities...${NC}"\n$CC -march=$ARCH -mabi=$ABI -O2 -c string_utils.c -o string_utils.o\necho "✓ string_utils.o"' build.sh

sed -i 's/start.o miner.o -o miner.elf/start.o string_utils.o miner.o -o miner.elf/' build.sh

chmod +x build.sh
./build.sh
```

## Clean Build

```bash
cd ~/SHA-256/code
./build.sh clean
./build.sh
```

## Copy to Windows

```bash
cp ~/SHA-256/code/program.hex /mnt/c/Users/Kai/Documents/GitHub/SHA-256/code/
```