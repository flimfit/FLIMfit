#define DATA_DIRECT 0
#define DATA_MAPPED 1

#define MODE_STANDARD     0
#define MODE_POLARISATION 1

#define MODE_GLOBAL_ANALYSIS 0
#define MODE_GLOBAL_BINNING  1

#define DATA_DOUBLE 0
#define DATA_UINT16 1


#define MAX_CONTROLLER_IDX 255

#define SUCCESS                        0
#define ERR_NOT_INIT                   -1001
#define ERR_FIT_IN_PROGRESS            -1002
#define ERR_FAILED_TO_START_THREADS    -1003
#define ERR_NO_FIT                     -1004
#define ERR_OUT_OF_MEMORY              -1005
#define ERR_COULD_NOT_OPEN_MAPPED_FILE -1006
#define ERR_COULD_NOT_START_FIT        -1007
#define ERR_FOUND_NO_REGIONS           -1008
#define ERR_FAILED_TO_MAP_DATA         -1009