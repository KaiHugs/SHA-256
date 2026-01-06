# RISC-V Toolchain Setup for Ubuntu/WSL

I've set up the toolchain on 4 different computers through WSL. This lists some issues I've ran into (some issues I still don't really know why). 

---

## Begin by trying the most conventional way

```bash
https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v12.2.0-1/xpack-riscv-none-elf-gcc-12.2.0-1-linux-x64.tar.gz

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

#just verification (should be no errors)
riscv32-unknown-elf-gcc --version
```

---

## Issues

### Issue #1: chmod doesn't work

**What is seen**
```bash
chmod +x build.sh
chmod: changing permissions of 'build.sh': Operation not permitted
```

**Fix:** Copy project to Linux side first
```bash
cp -r /mnt/c/Users/Kai/Documents/GitHub/SHA-256 ~/SHA-256
cd ~/SHA-256/code
chmod +x build.sh  # works now
```

**Follow** Never work directly in `/mnt/c/`. Always copy to `~/` first.

---

### Issue #2: apt-get is just completely broken

**What is seen:**
```bash
sudo apt-get install npm
E: Package 'npm' has no installation candidate

sudo apt-get install build-essential
E: Package 'build-essential' has no installation candidate

sudo apt-get install gcc
E: Package 'gcc' has no installation candidate
```

Or network errors:
```bash
Err:5 http://archive.ubuntu.com/ubuntu noble/universe amd64 Packages
  Error reading from server - read (104: Connection reset by peer)
```

**Followw** Don't use apt-get. Download pre-built toolchain instead (see top).

**If you really need apt-get:**
```bash
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update

sudo sed -i 's|http://archive.ubuntu.com|http://us.archive.ubuntu.com|g' /etc/apt/sources.list
sudo apt-get update

wsl --shutdown
wsl
```
---

### Issue #3: RISC-V toolchain doesn't exist in apt MOST COMMON

**What is seen**
```bash
sudo apt-get install riscv32-unknown-elf-gcc
E: Unable to locate package riscv32-unknown-elf-gcc

sudo apt-get install gcc-riscv64-unknown-elf
E: Unable to locate package gcc-riscv64-unknown-elf
```

**Most likely why this is occuring:** Ubuntu repos don't have this specific toolchain variant.

**What doesn't work:**
- `apt-get install riscv32-unknown-elf-gcc` -> doesn't exist
- `apt-get install gcc-riscv64-unknown-elf` -> doesn't exist
- `apt-get install gcc-riscv64-linux-gnu` -> exists but wrong arch/ABI
- Building from source -> needs gcc which apt-get can't install

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

**Follow** Symlinks (see step 3 at top)

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
#should be around 300MB+
```

**Fix:** Use the xPack link at the top. It's current and maintained.

---

### Issue #6: Extract in Windows breaks symlinks

**What you see:**
```bash
# After extracting in Windows:
Error 0x80070522: A required privilege is not held by the client
```

**Fix:** Extract in WSL, DO NOT TRY EXTRACING THROUGH WINDOWS RIGHT CLICK
```bash
tar -xzf toolchain.tar.gz  # in WSL
```

---
### Issue #7: PATH not set
**What you see:**
```bash
riscv32-unknown-elf-gcc --version
riscv32-unknown-elf-gcc: command not found
```
But you just created the symlinks.

**Why:** `~/bin` isn't in your PATH yet.

**Fix:**
```bash
export PATH="$HOME/bin:$PATH"
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
```

Then: 
```bash
source ~/.bashrc
```
---

## Quick Reference

### Check if toolchain is working
```bash
riscv32-unknown-elf-gcc --version
```

### Verify PATH
```bash
echo $PATH
#should include /home/*user*/bin
```

### Check symlinks
```bash
ls -la ~/bin/
#should see symlinks pointing to xpack-riscv-none-elf-gcc-*/bin/*
```

### Test compile
```bash
cd ~/SHA-256/code
./build.sh
```

---

## Common Mistakes

 **Working in `/mnt/c/`**
-> Files can't be chmod'd

 **Trying to use apt-get for toolchain**
-> Packages don't exist or apt is broken

 **Extracting tar.gz in Windows**
-> Breaks symlinks

 **Not creating symlinks**
-> Build script can't find tools

 **Forgetting to add PATH to .bashrc**
-> Works in current terminal but not after reboot

---

## Alternative Toolchains (if xPack fails)


### Build from source (last resort)
If apt-get IS working (just verify first):
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
Can take a bit to build
---

## Links

- **xPack Toolchain:** https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases
- **RISC-V GNU Toolchain:** https://github.com/riscv/riscv-gnu-toolchain

---

**Last updated:** January 6, 2026  
**Tested on:** WSL Ubuntu 24.04