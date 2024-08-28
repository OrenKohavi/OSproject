#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cstring>

#define BOOTSECTOR_CODE_FILENAME "bootsector_code.bin"

/* Constants */
const size_t SECTOR_SIZE = 512;
const size_t BOOTLOADER_CODE_OFFSET = 0;
const size_t BOOTLOADER_CODE_SIZE = 446;
const size_t PARTITION_TABLE_OFFSET = 446;
const size_t PARTITION_TABLE_ENTRY_SIZE = 16;
const size_t PARTITION_TABLE_MAX_ENTRIES = 4;
const size_t PARTITION_TABLE_TOTAL_SIZE = PARTITION_TABLE_ENTRY_SIZE * PARTITION_TABLE_MAX_ENTRIES;
const size_t MBR_BOOT_SIGNATURE_OFFSET = 510; //0x1FE
const uint16_t MBR_BOOT_SIGNATURE_VALUE = 0xAA55;

const uint8_t BOOT_INDICATOR_BOOTABLE = 0x80;
const uint8_t BOOT_INDICATOR_NONBOOTABLE = 0x00;
const size_t CHS_SIZE = 3;
const size_t LBA_SIZE = 4;

const uint8_t PARTITION_TYPE_FAT32_LBA = 0x0C;

const size_t NUM_SECTORS = 1000;
const size_t DISK_SIZE = SECTOR_SIZE * NUM_SECTORS;

/* Function Prototypes */
bool writeBootloader(char* bootsector);
void writePartitionTable(char* bootsector);
void writeMBRSignature(char* bootsector);


/* Structs */
// MBR Partition entry
typedef struct __attribute__((packed)) {
    uint8_t boot_indicator;
    uint8_t CHS_start[CHS_SIZE];
    uint8_t partition_type;
    uint8_t CHS_end[CHS_SIZE];
    uint32_t LBA_start;
    uint32_t LBA_end;
} partition_table_t;

static_assert(sizeof(partition_table_t) == PARTITION_TABLE_ENTRY_SIZE);