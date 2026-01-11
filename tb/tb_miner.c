//Author: Kai Hughes | 2026 

// memory mapped io registers for miner hardware
#define MINER_BASE      0x80000000
#define MINER_CTRL      (*(volatile unsigned int*)(MINER_BASE + 0x00))
#define MINER_MAX_NONCE (*(volatile unsigned int*)(MINER_BASE + 0x04))
#define MINER_NONCE_OUT (*(volatile unsigned int*)(MINER_BASE + 0x08))
#define MINER_HASH(i)   (*(volatile unsigned int*)(MINER_BASE + 0x0C + (i)*4))
#define MINER_TARGET(i) (*(volatile unsigned int*)(MINER_BASE + 0x30 + (i)*4))
#define MINER_HEADER(i) (*(volatile unsigned int*)(MINER_BASE + 0x50 + (i)*4))

// control register bits
#define CTRL_START      (1 << 0)
#define CTRL_BUSY       (1 << 1)
#define CTRL_FOUND      (1 << 2)
#define CTRL_EXHAUSTED  (1 << 3)

void delay(unsigned int cycles) {
    for (volatile unsigned int i = 0; i < cycles; i++);
}

int main(void) {
    delay(100);
    
    unsigned int status = MINER_CTRL;
    
    // set easy target (most bits set to 1)
    MINER_TARGET(0) = 0xFFFFFFFF;
    MINER_TARGET(1) = 0xFFFFFFFF;
    MINER_TARGET(2) = 0xFFFFFFFF;
    MINER_TARGET(3) = 0xFFFFFFFF;
    MINER_TARGET(4) = 0xFFFFFFFF;
    MINER_TARGET(5) = 0xFFFFFFFF;
    MINER_TARGET(6) = 0xFFFFFFFF;
    MINER_TARGET(7) = 0x00FFFFFF;
    
    // load genesis block header
    MINER_HEADER(0) = 0x00000001;
    MINER_HEADER(1) = 0x00000000;
    MINER_HEADER(2) = 0x00000000;
    MINER_HEADER(3) = 0x00000000;
    MINER_HEADER(4) = 0x00000000;
    MINER_HEADER(5) = 0x00000000;
    MINER_HEADER(6) = 0x00000000;
    MINER_HEADER(7) = 0x00000000;
    MINER_HEADER(8) = 0x3ba3edfd;
    MINER_HEADER(9) = 0x7a7b12b2;
    MINER_HEADER(10) = 0x7ac72c3e;
    MINER_HEADER(11) = 0x76768f61;
    MINER_HEADER(12) = 0x7fc81bc3;
    MINER_HEADER(13) = 0x888a5132;
    MINER_HEADER(14) = 0x3a9fb8aa;
    MINER_HEADER(15) = 0x4b1e5e4a;
    MINER_HEADER(16) = 0x29ab5f49;
    MINER_HEADER(17) = 0xffff001d;
    MINER_HEADER(18) = 0x00000000;
    MINER_HEADER(19) = 0x00000000;
    
    MINER_MAX_NONCE = 0x00100000;
    

    MINER_CTRL = CTRL_START;
    

    while (MINER_CTRL & CTRL_BUSY) {
        delay(1000);
    }
    

    status = MINER_CTRL;
    unsigned int nonce = MINER_NONCE_OUT;
    unsigned int hash0 = MINER_HASH(0);
    unsigned int hash1 = MINER_HASH(1);
    
    while (1) {
        delay(10000);
    }
    
    return 0;
}