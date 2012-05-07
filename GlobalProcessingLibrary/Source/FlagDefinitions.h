#ifndef _FLAGDEFINITIONS_H
#define _FLAGDEFINITIONS_H

#define DATA_DIRECT 0
#define DATA_MAPPED 1

//----------------------------------------------
#define MODE_STANDARD     0
#define MODE_POLARISATION 1

//----------------------------------------------
#define MODE_GLOBAL_ANALYSIS 0
#define MODE_GLOBAL_BINNING  1

//----------------------------------------------
#define DATA_DOUBLE 0
#define DATA_UINT16 1

//----------------------------------------------
#define MODE_PIXELWISE 0
#define MODE_IMAGEWISE 1
#define MODE_GLOBAL    2

//----------------------------------------------
#define BG_NONE 0
#define BG_VALUE 1
#define BG_IMAGE 2

//----------------------------------------------
#define APPLY_ANSCOME_TRANSFORM  0

//----------------------------------------------
#define FIX            0
#define FIT_LOCALLY    1
#define FIT_GLOBALLY   2
#define FIT            1

//----------------------------------------------
#define DATA_TYPE_TCSPC 0
#define DATA_TYPE_TIMEGATED 1

//----------------------------------------------
#define MAX_CONTROLLER_IDX 255

//----------------------------------------------
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

#endif