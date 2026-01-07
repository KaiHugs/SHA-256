// int main() {
//     volatile int *ptr = (volatile int *)0x1234;
//     int value = *ptr;  
    
//     while(1); 
// }

#define MINER_BASE      0x80000000
#define MINER_CONTROL   (*(volatile unsigned int*)(MINER_BASE + 0x00))
#define MINER_MAX_NONCE (*(volatile unsigned int*)(MINER_BASE + 0x04))
#define MINER_NONCE_OUT (*(volatile unsigned int*)(MINER_BASE + 0x08))

#define CTRL_START      (1 << 0)
#define CTRL_BUSY       (1 << 1)
#define CTRL_FOUND      (1 << 2)

// void delay(unsigned int cycles) {
//     for (volatile unsigned int i = 0; i < cycles; i++);
// }

// int main(void) {
//     MINER_MAX_NONCE = 0x12345678;
//     delay(10);
    
//     unsigned int status = MINER_CONTROL;
    
//     MINER_CONTROL = CTRL_START;
    
//     delay(1000);
    
//     status = MINER_CONTROL;
//     if (status & CTRL_BUSY) {

//         while (MINER_CONTROL & CTRL_BUSY) {
//             delay(100);
//         }
//     }
    
//     status = MINER_CONTROL;
//     unsigned int nonce = MINER_NONCE_OUT;
    
//     while (1) {
//         delay(1000000);
//     }
    
//     return 0;
// }







////////////////////////





/*
  Bitcoin Miner Software for PicoRV32 + FPGA Hardware
  Author: Kai Hughes | 2026
  
  This software interfaces with the hardware bitcoin miner
  through memory-mapped I/O registers.
  
  Compile with RISC-V GCC:
  riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -T link.ld miner.c -o miner.elf
  riscv32-unknown-elf-objcopy -O verilog miner.elf program.hex
 */

#define MINER_BASE      0x80000000

#define MINER_CTRL      (*(volatile unsigned int*)(MINER_BASE + 0x00))
#define MINER_MAX_NONCE (*(volatile unsigned int*)(MINER_BASE + 0x04))
#define MINER_NONCE_OUT (*(volatile unsigned int*)(MINER_BASE + 0x08))
#define MINER_HASH_OUT(i) (*(volatile unsigned int*)(MINER_BASE + 0x0C + (i)*4))
#define MINER_TARGET(i)   (*(volatile unsigned int*)(MINER_BASE + 0x30 + (i)*4))
#define MINER_HEADER(i)   (*(volatile unsigned int*)(MINER_BASE + 0x50 + (i)*4))

#define CTRL_START      (1 << 0)
#define CTRL_BUSY       (1 << 1)
#define CTRL_FOUND      (1 << 2)
#define CTRL_EXHAUSTED  (1 << 3)

typedef struct {
    unsigned int version;
    unsigned char prev_hash[32];
    unsigned char merkle_root[32];
    unsigned int timestamp;
    unsigned int bits;
    unsigned int nonce;
} __attribute__((packed)) bitcoin_header_t;

static inline unsigned int bswap32(unsigned int x) {
    return ((x & 0xFF000000) >> 24) |
           ((x & 0x00FF0000) >>  8) |
           ((x & 0x0000FF00) <<  8) |
           ((x & 0x000000FF) << 24);
}


void delay(unsigned int cycles) {
    for (volatile unsigned int i = 0; i < cycles; i++);
}

void load_header(const bitcoin_header_t* header) {
    unsigned int* src = (unsigned int*)header;
    for (int i = 0; i < 20; i++) {
        MINER_HEADER(i) = src[i];
    }
}

void set_target(const unsigned char* target_bytes) {
    unsigned int* target_words = (unsigned int*)target_bytes;
    for (int i = 0; i < 8; i++) {
        MINER_TARGET(i) = target_words[i];
    }
}

void bits_to_target(unsigned int bits, unsigned char* target) {
    unsigned int exponent = (bits >> 24) & 0xFF;
    unsigned int mantissa = bits & 0x00FFFFFF;

    for (int i = 0; i < 32; i++) {
        target[i] = 0;
    }

    if (exponent <= 3) {
        unsigned int shift = 8 * (3 - exponent);
        mantissa >>= shift;
        target[0] = mantissa & 0xFF;
        target[1] = (mantissa >> 8) & 0xFF;
        target[2] = (mantissa >> 16) & 0xFF;
    } else if (exponent < 32) {
        target[exponent - 3] = mantissa & 0xFF;
        target[exponent - 2] = (mantissa >> 8) & 0xFF;
        target[exponent - 1] = (mantissa >> 16) & 0xFF;
    }
}

void start_mining(unsigned int max_nonce) {
    MINER_MAX_NONCE = max_nonce;
    MINER_CTRL = CTRL_START;
}

int is_mining_done(void) {
    unsigned int status = MINER_CTRL;
    return (status & (CTRL_FOUND | CTRL_EXHAUSTED)) != 0;
}

int wait_for_result(void) {
    while (MINER_CTRL & CTRL_BUSY);
    return (MINER_CTRL & CTRL_FOUND) != 0;
}

void read_hash(unsigned char* hash_out) {
    unsigned int* words = (unsigned int*)hash_out;
    for (int i = 0; i < 8; i++) {
        words[i] = MINER_HASH_OUT(i);
    }
}

void mine_genesis_block(void) {
    bitcoin_header_t genesis = {
        .version = 1,
        .prev_hash = {0},
        .merkle_root = {
            0x3b, 0xa3, 0xed, 0xfd, 0x7a, 0x7b, 0x12, 0xb2,
            0x7a, 0xc7, 0x2c, 0x3e, 0x67, 0x76, 0x8f, 0x61,
            0x7f, 0xc8, 0x1b, 0xc3, 0x88, 0x8a, 0x51, 0x32,
            0x3a, 0x9f, 0xb8, 0xaa, 0x4b, 0x1e, 0x5e, 0x4a
        },
        .timestamp = 0x29ab5f49,
        .bits = 0x1d00ffff,
        .nonce = 0
    };

    unsigned char target[32];
    bits_to_target(genesis.bits, target);

    load_header(&genesis);
    set_target(target);
    start_mining(0x00100000);

    if (wait_for_result()) {
        unsigned int nonce = MINER_NONCE_OUT;
        unsigned char hash[32];
        read_hash(hash);
    }
}

void mine_custom_block(
    unsigned int version,
    const unsigned char* prev_hash,
    const unsigned char* merkle_root,
    unsigned int timestamp,
    unsigned int bits,
    unsigned int nonce_start,
    unsigned int nonce_range
) {
    bitcoin_header_t header;
    header.version = version;
    header.timestamp = timestamp;
    header.bits = bits;
    header.nonce = nonce_start;

    for (int i = 0; i < 32; i++) {
        header.prev_hash[i] = prev_hash[i];
        header.merkle_root[i] = merkle_root[i];
    }

    unsigned char target[32];
    bits_to_target(bits, target);

    load_header(&header);
    set_target(target);
    start_mining(nonce_start + nonce_range);

    wait_for_result();
}

void main(void) {
    delay(1000);
    mine_genesis_block();

    while (1) {
        delay(10000);
    }
}

// REMOVED: _start() function - it's already in start.S