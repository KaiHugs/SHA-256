# RISC-V Toolchain Setup for Ubuntu/WSL

I've set up the toolchain on 4 different computers through WSL. This lists some issues I've ran into (some I still don't really know why). 

---

## Start with the normal way
```bash
# Download this in Windows browser:
https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v12.2.0-1/xpack-riscv-none-elf-gcc-12.2.0-1-linux-x64.tar.gz

# Then in WSL:
cd ~
cp /mnt/c/Users/<YOUR_USERNAME>/Downloads/xpack-riscv-none-elf-gcc-12.2.0-1-linux-x64.tar.gz .
tar -xzf xpack-riscv-none-elf-gcc-12.2.0-1-linux-x64.tar.gz

mkdir -p ~/bin
ln -s ~/xpack-riscv-none-elf-gcc-12.2.0-1/bin/riscv-none-elf-gcc ~/bin/riscv32-unknown-elf-gcc
ln -s ~/xpack-riscv-none-elf-gcc-12.2.0-1/bin/riscv-none-elf-objcopy ~/bin/riscv32-unknown-elf-objcopy
ln -s ~/xpack-riscv-none-elf-gcc-12.2.0-1/bin/riscv-none-elf-objdump ~/bin/riscv32-unknown-elf-objdump
ln -s ~/xpack-riscv-none-elf-gcc-12.2.0-1/bin/riscv-none-elf-size ~/bin/riscv32-unknown-elf-size

export PATH="$HOME/bin:$PATH"
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc

riscv32-unknown-elf-gcc --version
```

---

## Issues

### Issue #1: chmod doesn't work

```bash
chmod +x build.sh
chmod: changing permissions of 'build.sh': Operation not permitted
```

**Fix:** Copy project to Linux side first
```bash
cp -r /mnt/c/Users/Kai/Documents/GitHub/SHA-256 ~/SHA-256
cd ~/SHA-256/code
chmod +x build.sh
```

**Rule:** Never work directly in `/mnt/c/`. Always copy to `~/` first.

---

### Issue #2: apt-get is just completely broken

**What you see:**
```bash
sudo apt-get install npm
E: Package 'npm' has no installation candidate

sudo apt-get install build-essential
E: Package 'build-essential' has no installation candidate
```

Or network errors:
```bash
Err:5 http://archive.ubuntu.com/ubuntu noble/universe amd64 Packages
  Error reading from server - read (104: Connection reset by peer)
```

**Fix:** Don't use apt-get. Download pre-built toolchain instead (see top).

**If you really need apt-get:**
```bash
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update

sudo sed -i 's|http://archive.ubuntu.com|http://us.archive.ubuntu.com|g' /etc/apt/sources.list
sudo apt-get update
```

Or restart WSL from PowerShell:
```powershell
wsl --shutdown
wsl
```

---

### Issue #3: RISC-V toolchain doesn't exist in apt (MOST COMMON)

**What you see:**
```bash
sudo apt-get install riscv32-unknown-elf-gcc
E: Unable to locate package riscv32-unknown-elf-gcc

sudo apt-get install gcc-riscv64-unknown-elf
E: Unable to locate package gcc-riscv64-unknown-elf
```

**Why:** Ubuntu repos don't have this specific toolchain.

**What doesn't work:**
- `apt-get install riscv32-unknown-elf-gcc` → doesn't exist
- `apt-get install gcc-riscv64-unknown-elf` → doesn't exist
- `apt-get install gcc-riscv64-linux-gnu` → wrong arch/ABI
- Building from source → needs gcc which apt can't install

**Fix:** Use pre-built xPack toolchain (see top).

---

### Issue #4: Toolchain names don't match

**What you see:**
```bash
./build.sh
Error: RISC-V toolchain not found
Please install riscv32-unknown-elf-gcc
```

But you have:
```bash
riscv-none-elf-gcc --version
riscv-none-elf-gcc (xPack GNU RISC-V Embedded GCC x86_64) 12.2.0
```

**Why:** Build script expects `riscv32-unknown-elf-gcc` but xPack provides `riscv-none-elf-gcc`. Same tools, different names.

**Fix:** Symlinks (see step 3 at top)

---

### Issue #5: Download links are broken

**What you see:**
```bash
wget https://github.com/sifive/freedom-tools/releases/download/...
HTTP request sent, awaiting response... 404 Not Found
```

Or:
```bash
tar -xzf toolchain.tar.gz
gzip: stdin: not in gzip format
tar: Child returned status 1
```

**Check what you downloaded:**
```bash
ls -lh ~/toolchain.tar.gz
# Should be around 300MB+, not 1KB
```

**Fix:** Use the xPack link at the top.

---

### Issue #6: Extract in Windows breaks symlinks

**What you see:**
```bash
Error 0x80070522: A required privilege is not held by the client
```

Or symlinks show as text files.

**Fix:** Extract in WSL, DO NOT extract through Windows right-click
```bash
tar -xzf toolchain.tar.gz
```

---

### Issue #7: PATH not set

**What you see:**
```bash
riscv32-unknown-elf-gcc --version
riscv32-unknown-elf-gcc: command not found
```

**Why:** `~/bin` isn't in your PATH yet.

**Fix:**
```bash
export PATH="$HOME/bin:$PATH"
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## Quick Checks

### Toolchain working?
```bash
riscv32-unknown-elf-gcc --version
```

### PATH set?
```bash
echo $PATH
# Should include /home/your-username/bin
```

### Symlinks good?
```bash
ls -la ~/bin/
# Should see symlinks pointing to xpack-riscv-none-elf-gcc-*/bin/*
```

---

## Code Fixes

Your code needs a couple fixes before it'll compile:

### Fix 1: Remove duplicate _start from miner.c
```bash
cd ~/SHA-256/code
sed -i '/^void _start(void) {$/,/^}$/d' miner.c
```

### Fix 2: Add string_utils.c (memset/memcpy for bare-metal)
```bash
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
```

### Fix 3: Update build.sh
```bash
sed -i '/echo "✓ start.o"/a\\necho -e "${YELLOW}Compiling string utilities...${NC}"\n$CC -march=$ARCH -mabi=$ABI -O2 -c string_utils.c -o string_utils.o\necho "✓ string_utils.o"' build.sh

sed -i 's/start.o miner.o -o miner.elf/start.o string_utils.o miner.o -o miner.elf/' build.sh
```

### Build
```bash
./build.sh
```

Should compile now.

---

## Common Mistakes

❌ Working in `/mnt/c/` → Files can't be chmod'd  
❌ Using apt-get for toolchain → Packages don't exist  
❌ Extracting in Windows → Breaks symlinks  
❌ Skipping symlinks → Build script can't find tools  
❌ Not adding PATH to .bashrc → Doesn't persist after restart  

---

## Alternative: Build from Source (last resort)

Only if apt-get IS working:
```bash
sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev \
    libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf \
    libtool patchutils bc zlib1g-dev libexpat-dev git

git clone https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
./configure --prefix=/opt/riscv --with-arch=rv32i --with-abi=ilp32
sudo make
export PATH="/opt/riscv/bin:$PATH"
```

Takes 30-60 minutes to build.

---

## Links

- **xPack Toolchain:** https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases
- **RISC-V GNU Toolchain:** https://github.com/riscv/riscv-gnu-toolchain

---

**Last updated:** January 6, 2026  
**Tested on:** WSL Ubuntu 24.04