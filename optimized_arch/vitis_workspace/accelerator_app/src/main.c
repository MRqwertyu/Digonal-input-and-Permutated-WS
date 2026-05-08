#include <stdio.h>
#include "xil_printf.h"
#include "xil_io.h"
#include "sleep.h"

// Your exact hardware memory map addresses
#define GPIO_BASE_ADDR 0x41200000 
#define BRAM_BASE_ADDR 0x40000000 

int main() {
    print("\n\r----------------------------------------\n\r");
    print(" Zybo Z7 Systolic Accelerator Booting...\n\r");
    print("----------------------------------------\n\r");

    // 1. Set the number of tiles to 30
    // We connected num_tiles to GPIO Channel 1
    xil_printf("Configuring array for 30 tiles...\n\r");
    Xil_Out32(GPIO_BASE_ADDR, 30);

    // 2. Pulse the Start Signal
    // We connected 'start' to GPIO Channel 2. 
    // Channel 2 is always offset by 8 bytes from the base address.
    xil_printf("Firing accelerator...\n\r");
    Xil_Out32(GPIO_BASE_ADDR + 8, 1); // Set Start HIGH
    usleep(10);                       // Tiny 10 microsecond pause
    Xil_Out32(GPIO_BASE_ADDR + 8, 0); // Set Start LOW

    // 3. Wait for Hardware
    // The hardware runs at 100MHz+, so it finishes in a fraction of a millisecond.
    // We will sleep the ARM processor for 1 second just to be absolutely safe.
    sleep(1); 

    // 4. Read Results from BRAM
    print("\n\rMath Complete! Reading BRAM Results:\n\r");
    
    // Read the 6 output columns. 
    // AXI memory uses byte-addressing, so we multiply the index by 4 (32-bits = 4 bytes)
    for (int i = 0; i < 6; i++) {
        u32 result = Xil_In32(BRAM_BASE_ADDR + (i * 4));
        xil_printf("Column [%d] Output: %lu\n\r", i, result);
    }

    print("\n\r----------------------------------------\n\r");
    print(" Test Complete! \n\r");
    print("----------------------------------------\n\r");
    
    return 0;
}