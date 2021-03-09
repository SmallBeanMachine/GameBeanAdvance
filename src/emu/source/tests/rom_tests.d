module rom_tests;

import cpu_state;
import arm7tdmi;
import memory;
import gba;
import util;
import cpu_state;

import std.conv;
import std.stdio;
import std.algorithm;
import std.array;
import std.range;

void check_cpu_state(CpuState expected, CpuState actual, string error_message) {
    for (int i = 0; i < 16; i++) {
        assert(expected.regs[i] == actual.regs[i], error_message ~ " at register #" ~ to!string(i));
    }

    assert( expected.type           ==  actual.type,           error_message);
    assert( expected.opcode         ==  actual.opcode,         error_message);
    assert((expected.mode & 0x1F)   == (actual.mode & 0x1F),   error_message);
    assert( expected.mem_0x03000003 ==  actual.mem_0x03000003, error_message);
}

CpuState[] produce_expected_cpu_states(string file_name, uint num_lines) {
    CpuState[] states;

    foreach (line; File(file_name).byLine().take(num_lines)) {
        states = states ~ [produce_expected_cpu_state(line)];
    }

    return states;
}

CpuState produce_expected_cpu_state(char[] input_string) {
    CpuState state;
    string[] tokens = to!string(input_string).split();

    state.type           = tokens[0] == "ARM" ? cpu_state.CpuType.ARM : cpu_state.CpuType.THUMB;
    state.opcode         = to!uint(tokens[1][2..$],  16);
    state.mode           = to!uint(tokens[18], 16);
    state.mem_0x03000003 = to!uint(tokens[19], 16);

    for (int i = 0; i < 16; i++) state.regs[i] = to!uint(tokens[i + 2], 16);

    return state;
}

void test_thumb_mode(string gba_file, string log_file, int num_instructions) {
    Memory   memory = new Memory();
    ARM7TDMI cpu    = new ARM7TDMI(memory);

    CpuState[] expected_output = produce_expected_cpu_states(log_file, num_instructions);
    
    ubyte[] rom = get_rom_as_bytes(gba_file);
    cpu.memory.rom_1[0..0x02000000] = rom[0..rom.length];

    set_cpu_state(cpu, expected_output[0]);
    cpu.set_mode(cpu.MODE_SYSTEM);

    bool wasPreviousInstructionARM = true; // if so, we reset the CPU's state
    for (int i = 0; i < num_instructions - 1; i++) {
        if (expected_output[i].type == cpu_state.CpuType.THUMB) {
            if (wasPreviousInstructionARM) {
                cpu.set_bit_T(true);
                set_cpu_state(cpu, expected_output[i]);
            }
            
            uint opcode = cpu.fetch();
            cpu.execute(opcode);
            check_cpu_state(expected_output[i + 1], get_cpu_state(cpu), "Failed at instruction #" ~ to!string(i) ~ " with opcode 0x" ~ to_hex_string(opcode));
        } else {
            wasPreviousInstructionARM = true;
        }
    }

    // make sure we've reached B infin
    assert(cpu.fetch() == 0xE7FE, "ROM did not reach B infin!");
}

void test_arm_mode(string gba_file, string log_file, int num_instructions, int start_instruction, bool b_infin_check) {
    Memory   memory = new Memory();
    ARM7TDMI cpu    = new ARM7TDMI(memory);

    CpuState[] expected_output = produce_expected_cpu_states(log_file, num_instructions);
    
    ubyte[] rom = get_rom_as_bytes(gba_file);
    cpu.memory.rom_1[0..0x01000000] = rom[0..rom.length];

    set_cpu_state(cpu, expected_output[0]);
    cpu.set_bit_T(true);
    cpu.set_mode(cpu.MODE_SYSTEM);

    for (int i = 0; i < num_instructions - 1; i++) {
        // ARM instructions won't be run until log #190 is passed (the ARM that occurs before then is needless 
        // busywork as far as these tests are concerned, and make it harder to unit test the emulator).
        if (i == start_instruction) {
            cpu.set_bit_T(false);
            cpu.cpsr = (cpu.cpsr & 0x00FFFFFFFF) | 0x60000000; // theres a bit of arm instructions that edit the CPSR that we skip, so let's manually set it.
        }

        if (i < start_instruction) cpu.set_bit_T(true);

        if (i > start_instruction || expected_output[i].type == cpu_state.CpuType.THUMB) {
            uint opcode = cpu.fetch();
            cpu.execute(opcode);
            check_cpu_state(expected_output[i + 1], get_cpu_state(cpu), "Failed at instruction #" ~ to!string(i) ~ " with opcode 0x" ~ to_hex_string(opcode));
        } else {
            set_cpu_state(cpu, expected_output[i + 1]);
        }
    }

    // make sure we've reached B infin
    if (b_infin_check) assert(cpu.fetch() == 0xE7FE, "ROM did not reach B infin!");
}



unittest {
    test_thumb_mode("../../tests/asm/bin/thumb-simple.gba", "../../tests/asm/logs/thumb-simple.log", 3666);
}

unittest {
    test_arm_mode("../../tests/asm/bin/arm-addressing-mode-1.gba", "../../tests/asm/logs/arm-addressing-mode-1.log", 1290, 216, true);
}

unittest {
    test_arm_mode("../../tests/asm/bin/arm-addressing-mode-2.gba", "../../tests/asm/logs/arm-addressing-mode-2.log", 1290, 212, true);
}

unittest {
    test_arm_mode("../../tests/asm/bin/arm-addressing-mode-3.gba", "../../tests/asm/logs/arm-addressing-mode-3.log", 1290, 212, true);
}

unittest {
    test_arm_mode("../../tests/asm/bin/arm-opcodes.gba", "../../tests/asm/logs/arm-opcodes.log", 2100, 276, true);
}

unittest {
    test_arm_mode("../../tests/asm/bin/Fountain.gba", "../../tests/asm/logs/Fountain.log", 300000, 0, false);
}

unittest {
    test_arm_mode("roms/superstarsaga.gba", "../../tests/asm/logs/superstarsaga.log", 2100, 0, false);
}