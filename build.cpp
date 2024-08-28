#include "build.h"


int main(int argc, char* argv[]) {
    /* --------- OPEN THE DISK IMAGE FILE --------- */

    if (argc > 2) {
        std::cerr << "Too Many Arguments Provided" << std::endl;
        return 1;
    }

    const char* out_filename = "disk.img";
    if (argc == 2) {
        out_filename = argv[1];
    } // Else, it uses the default disk.img name

    std::ofstream outfile(out_filename, std::ios::binary);
    if (!outfile) {
        std::cerr << "Error opening file: " << out_filename << std::endl;
        return 1;
    }

    /* --------- POPULATE THE BOOT SECTOR WITH DATA --------- */
    char disk[DISK_SIZE] = {0};
    memset(disk, 0x12, DISK_SIZE);
    //Fill the disk with 0x12 just so I can tell what's been initialized

    if (!writeBootloader(disk)){
        std::cerr << "Failed to write bootloader to boot sector" << std::endl;
        return 1;
    }
    writePartitionTable(disk);
    writeMBRSignature(disk);

    /* --------- WRITE BOOT SECTOR DATA TO THE FILE --------- */

    outfile.write(disk, DISK_SIZE);
    if (!outfile) {
        std::cerr << "Error writing to file: " << argv[1] << std::endl;
        return 1;
    }

    outfile.close();
    return 0;
}

bool writeBootloader(char* bootsector){
    memset(bootsector, 0x90, BOOTLOADER_CODE_SIZE);

    //Makefile should ensure that bootsector code file exists and is up-to-date
    //Open that file
    std::ifstream bootsector_code_file(BOOTSECTOR_CODE_FILENAME, std::ios::binary);
    if (!bootsector_code_file) {
        std::cerr << "Could not open bootsector code file" << std::endl;
        return false;
    }
    bootsector_code_file.read(bootsector, BOOTLOADER_CODE_SIZE);

    //Check if the read worked
    // !! COMMENTED OUT BECAUSE BOOTSECTOR CODE FILE MAY BE SHORTER AND THAT'S FINE WE JUST LEAVE THE REST UNINITIALIZED
    /*
    if ((bootsector_code_file.rdstate() & std::ifstream::failbit) != 0){
        //Fail bit is set on this stream, so something has gone wrong reading from the file (probably it's too short)
        bool eof_reached = (bootsector_code_file.rdstate() & std::ifstream::eofbit);
        std::cerr << "Error reading from bootloader code file! EOF: " << eof_reached << std::endl;
        return false;
    }
    */

    return true;
}

void writePartitionTable(char* bootsector){
    //Zero out the region just to be safe (since we're not fully filling it)
    memset(bootsector + PARTITION_TABLE_OFFSET, 0x00, PARTITION_TABLE_TOTAL_SIZE);
    
    //Write the first (and only) partition.
    partition_table_t main_partition = {};
    main_partition.boot_indicator = BOOT_INDICATOR_BOOTABLE;
    main_partition.partition_type = PARTITION_TYPE_FAT32_LBA;
    memset(main_partition.CHS_start, 0xFF, CHS_SIZE);
    memset(main_partition.CHS_end, 0xFF, CHS_SIZE);
    main_partition.LBA_start = 0x1;
    main_partition.LBA_end = NUM_SECTORS - 1;

    memcpy(bootsector + PARTITION_TABLE_OFFSET, &main_partition, PARTITION_TABLE_ENTRY_SIZE);
    return;
}

void writeMBRSignature(char* bootsector){
    uint16_t *signature_pointer;
    signature_pointer = reinterpret_cast<uint16_t*>(bootsector + MBR_BOOT_SIGNATURE_OFFSET);
    *signature_pointer = MBR_BOOT_SIGNATURE_VALUE;
    return;
}