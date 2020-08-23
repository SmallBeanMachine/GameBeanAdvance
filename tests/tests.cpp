#include "catch/catch.hpp"
#include "../src/gba.h"

#include <iostream>

// note for test cases: do not assume registers or memory values are set to 0 before starting
// a test. set them manually to 0 if you want them to be 0.

// Just a faster way to check flags
void check_flags(bool fN, bool fZ, bool fC, bool fV) {
    REQUIRE(flag_N == fN);
    REQUIRE(flag_Z == fZ);
    REQUIRE(flag_C == fC);
    REQUIRE(flag_V == fV);
}

void wipe_registers() {
    for (int i = 0; i < NUM_REGISTERS; ++i) {
        memory.regs[i] = 0x00000000;
    }
}

TEST_CASE("CPU Thumb Mode - ADD Two Registers") {
    wipe_registers();
    SECTION("ADD R1, R2 into R3") {
        memory.regs[1] = 0x00000001;
        memory.regs[2] = 0x00000001;
        execute(0x1853);
        REQUIRE(memory.regs[3] == 0x00000002);

        check_flags(false, false, false, false);
    }
    wipe_registers();
}

TEST_CASE("CPU Thumb Mode - ADD Immediate Register") {
    wipe_registers();
    SECTION("ADD R2, 0x00") {
        memory.regs[2] = 0x00000000;
        execute(0x3200);
        REQUIRE(memory.regs[2] == 0x00000000);

        check_flags(false, true, false, false);
        // REQUIRE(flag_N == false);
        // REQUIRE(flag_Z == true);
        // REQUIRE(flag_C == false);
        // REQUIRE(flag_V == false);
    }

    SECTION("ADD R2, 0x01") {
        memory.regs[2] = 0x7FFFFFFF;
        execute(0x3201);
        REQUIRE(memory.regs[2] == 0x80000000);

        check_flags(true, false, false, true);
        // REQUIRE(flag_N == true);
        // REQUIRE(flag_Z == false);
        // REQUIRE(flag_C == false);
        // REQUIRE(flag_V == true);
    }

    SECTION("ADD R2, 0xFF (No Overflow)") {
        memory.regs[2] = 0x00000000;
        execute(0x32FF);
        REQUIRE(memory.regs[2] == 0x000000FF);

        check_flags(false, false, false, false);
        // REQUIRE(flag_N == false);
        // REQUIRE(flag_Z == false);
        // REQUIRE(flag_C == false);
        // REQUIRE(flag_V == false);
    }

    SECTION("ADD R2, 0xFF (Overflow)") {
        memory.regs[2] = 0xFFFFFFFF;
        execute(0x3280);
        REQUIRE(memory.regs[2] == 0x0000007F);

        check_flags(false, false, true, true);
        // REQUIRE(flag_N == false);
        // REQUIRE(flag_Z == false);
        // REQUIRE(flag_C == true);
        // REQUIRE(flag_V == true);
    }
    wipe_registers();
}

TEST_CASE("CPU Thumb Mode - MOV Immediate") {
    wipe_registers();
    SECTION("MOV R2, 0xCD") {
        memory.regs[2] = 0x00000000;
        execute(0x22CD);
        REQUIRE(memory.regs[2] == 0xCD);
    }
    wipe_registers();
}
