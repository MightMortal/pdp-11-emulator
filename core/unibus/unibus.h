//
// Created by Aleksandr Parfenov on 01.10.16.
//

#ifndef PDP_11_EMULATOR_UNIBUS_H
#define PDP_11_EMULATOR_UNIBUS_H

#include "../../common.h"

#include <vector>

#include "unibus_device.h"

class UnibusDeviceConfiguration;

class Unibus {
public:
    // Connect new device to the bus
    bool register_device(UnibusDevice *device, uint18 base_address, uint18 reserve_space_size);

    uint16 read_word(uint18 address);
    void write_word(uint18 address, uint16 value);
    uint8 read_byte(uint18 address);
    void write_byte(uint18 address, uint8 value);

    // Non-processor request of the bus-control
    void npr_request(UnibusDevice *device);
    // Request of the bus-control
    void br_request(UnibusDevice *device, uint8 priority);
    // Send interrupt to the processor. Simplify full operation of sending interrupt (bus-request is not required)
    void cpu_interrupt(uint18 address, int priority);

    // Used by CPU during RESET operation
    void reset_bus_devices();
    // Execute current master device
    void master_device_execute();
private:
    UnibusDeviceConfiguration *get_registered_device(uint18 address);

    vector<UnibusDeviceConfiguration *> _registered_devices;
    pair<uint8, UnibusDeviceConfiguration *> _master_device;
    vector<pair<uint8, UnibusDeviceConfiguration *> > _master_requests_queue;
};

#endif //PDP_11_EMULATOR_UNIBUS_H
