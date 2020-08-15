#include <iostream>
#include <stdlib.h>
#include <sstream>

#include "util.h"

void warning(std::string message) {
    std::cerr << YELLOW << "WARNING: " << RESET << message << std::endl;
}

void error(std::string message) {
    std::cerr << RED << "ERROR: " << RESET << message << std::endl;
    exit(EXIT_FAILURE);
}

std::string to_hex_string(uint32_t val) {
    std::stringstream ss;
    ss << std::hex << (int)val;
    return ss.str();
}