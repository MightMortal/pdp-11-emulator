//
// Created by Aleksandr Parfenov on 01.10.16.
//

#include <cstring>
#include "ram.h"

RAM::RAM(uint16 memory_size) : _memory_size(memory_size) {
    if ((memory_size & 0x1) == 0x1)
        throw new runtime_error("Wrong memory size");
    _memory_array = (uint8 *) calloc(memory_size, sizeof(uint8));
    RAM::reset();
}

RAM::~RAM() {
    _memory_size = 0;
    free(_memory_array);
    _memory_array = nullptr;
}

void RAM::reset() {
    memset(_memory_array, 0, sizeof(uint8) * _memory_size);
}

uint16 RAM::read_word(uint18 address, uint18 base_address) {
    if ((address - base_address) >= _memory_size || (address & 0x1) == 0x1)
        throw new runtime_error("Illegal memory address access");
    uint16 val = _memory_array[address - base_address] | (_memory_array[address - base_address + 1] << 8);
    return val;
}

void RAM::write_word(uint18 address, uint18 base_address, uint16 value) {
    if ((address - base_address) >= _memory_size || (address & 0x1) == 0x1)
        throw new runtime_error("Illegal memory address access");
    _memory_array[address - base_address] = (uint8) (value & 0xFF);
    _memory_array[address - base_address + 1] = (uint8) ((value & 0xFF00) >> 8);
}

uint8 RAM::read_byte(uint18 address, uint18 base_address) {
    if ((address - base_address) >= _memory_size)
        throw new runtime_error("Illegal memory address access");
    return _memory_array[address - base_address];
}

void RAM::write_byte(uint18 address, uint18 base_address, uint8 value) {
    if ((address - base_address) >= _memory_size)
        throw new runtime_error("Illegal memory address access");
    _memory_array[address - base_address] = value;
}

uint16 RAM::get_memory_size() const {
    return _memory_size;
}
