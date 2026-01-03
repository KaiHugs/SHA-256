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

void delay(unsigned int cycles) {
    for (volatile unsigned int i = 0; i < cycles; i++);
}

int main(void) {
    MINER_MAX_NONCE = 0x12345678;
    delay(10);
    
    unsigned int status = MINER_CONTROL;
    
    MINER_CONTROL = CTRL_START;
    
    delay(1000);
    
    status = MINER_CONTROL;
    if (status & CTRL_BUSY) {

        while (MINER_CONTROL & CTRL_BUSY) {
            delay(100);
        }
    }
    
    status = MINER_CONTROL;
    unsigned int nonce = MINER_NONCE_OUT;
    
    while (1) {
        delay(1000000);
    }
    
    return 0;
}