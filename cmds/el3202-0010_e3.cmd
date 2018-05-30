require ecmc,5.0.0
require ecmctraining,master
require EthercatMC,2.0.1
require stream, 2.7.7
require iocStats,1856ef5

epicsEnvSet("TOP","${TOP}")
epicsEnvSet("STARTUP",  "$(TOP)")
#epicsEnvSet("STREAM_PROTOCOL_PATH", "$(TOP)/protocol")

< $(STARTUP)/general/init

###############################################################################
############# ASYN Configuration:

epicsEnvSet("ECMC_MOTOR_PORT",    "$(SM_MOTOR_PORT=ECAT01)")
epicsEnvSet("ECMC_ASYN_PORT",     "$(SM_ASYN_PORT=ECAT_CPU1)")
epicsEnvSet("ECMC_PREFIX",        "$(SM_ECMC_PREFIX=ICSLab:ecat01:)")

ecmcAsynPortDriverConfigure($(ECMC_ASYN_PORT),1000,0,0)
asynOctetSetOutputEos("$(ECMC_ASYN_PORT)", -1, ";\n")
asynOctetSetInputEos("$(ECMC_ASYN_PORT)", -1, ";\n")
asynSetTraceMask("$(ECMC_ASYN_PORT)", -1, 0x41)
asynSetTraceIOMask("$(ECMC_ASYN_PORT)", -1, 6)
asynSetTraceInfoMask("$(ECMC_ASYN_PORT)", -1, 1)

EthercatMCCreateController("$(ECMC_MOTOR_PORT)", "$(ECMC_ASYN_PORT)", "32", "200", "1000", "")


############# Misc settings:
# Disable function call trace printouts
EthercatMCConfigController ${ECMC_MOTOR_PORT}, "Cfg.SetEnableFuncCallDiag(0)"

# Disable on change printouts from objects (for easy logging)
EthercatMCConfigController ${ECMC_MOTOR_PORT}, "Cfg.SetTraceMaskBit(15,0)"

# Disable on command transform diag
EthercatMCConfigController ${ECMC_MOTOR_PORT}, "Cfg.SetTraceMaskBit(7,0)"

# Choose to generate EPICS-records for EtherCAT-entries 
# (For records use ECMC_GEN_EC_RECORDS="-epicsrecords" otherwise ECMC_GEN_EC_RECORDS="") 
epicsEnvSet("ECMC_GEN_EC_RECORDS",          "-records")

# Update records in 10Hz (skip 99 cycles, based on 1000Hz sample rate)
epicsEnvSet("ECMC_ASYN_SKIP_CYCLES",       "99")

###############################################################################
############# Configure hardware:

epicsEnvSet("ECMC_EC_MASTER_ID"               "0")

#Choose master
EthercatMCConfigController "$(ECMC_MOTOR_PORT)", "Cfg.EcSetMaster($(ECMC_EC_MASTER_ID))"

# Configure EL3202-0010 analog input hardware
#
#0  0:0  PREOP  +  EK1100 EtherCAT-Koppler (2A E-Bus)
#1  0:1  PREOP  +  EL3202-0010 2K. Ana. Eingang PT100 (RTD), hochgenau
#2  0:2  PREOP  +  EL3214 4K. Ana. Eingang PT100 (RTD)
#3  0:3  PREOP  +  EK1100 EtherCAT-Koppler (2A E-Bus)
#4  0:4  PREOP  +  EL3602 2K. Ana. Eingang +/- 10Volt, Diff. 24bit
#5  0:5  PREOP  +  EL4102 2K. Ana. Ausgang 0-10V, 16bit

epicsEnvSet("ECMC_EC_SLAVE_NUM",              "1")


###  < /hardware/ecmcEL3202-0010-analogInput
epicsEnvSet("ECMC_EC_HWTYPE"             "EL3202")
epicsEnvSet("ECMC_EC_VENDOR_ID"          "0x2")
epicsEnvSet("ECMC_EC_PRODUCT_ID"         "0x0c823052")

EthercatMCConfigController "${ECMC_MOTOR_PORT}", "Cfg.EcWriteSdo(${ECMC_EC_SLAVE_NUM},0x1011,0x1,1684107116,4)"

iocshLoad $(STARTUP)/hardware/ecmcEL32XX-chX-analogInput, "ECMC_EC_CHANNEL_ID=1, ECMC_EC_PDO=0x1a00, ECMC_EC_PDO_ENTRY=0x6000"
iocshLoad $(STARTUP)/hardware/ecmcEL32XX-chX-analogInput, "ECMC_EC_CHANNEL_ID=2, ECMC_EC_PDO=0x1a01, ECMC_EC_PDO_ENTRY=0x6010"

< $(STARTUP)/general/slave
< $(STARTUP)/hardware/ecmcEL3202-0010-analogInput$(ECMC_GEN_EC_RECORDS)



############# Configure sensors:
# Common for all channels
< $(STARTUP)/hardware/ecmcEL32X4-Sensor-PT100-common

# Configure channel 1 with S+S Regeltechnik HFT50 PT100
epicsEnvSet("ECMC_EC_SDO_INDEX",         "0x8000")
< $(STARTUP)/hardware/ecmcEL3202-0010-Sensor-chX_S+S_RegelTechnik_HTF50_PT100

# Configure channel 2 with S+S Regeltechnik HFT50 PT100
epicsEnvSet("ECMC_EC_SDO_INDEX",         "0x8010")
< $(STARTUP)/hardware/ecmcEL3202-0010-Sensor-chX_S+S_RegelTechnik_HTF50_PT100

# Apply hardware configuration
EthercatMCConfigController ${ECMC_MOTOR_PORT}, "Cfg.EcApplyConfig(1)"

###############################################################################
############# Configure diagnostics:

EthercatMCConfigController ${ECMC_MOTOR_PORT}, "Cfg.EcSetDiagnostics(1)"
EthercatMCConfigController ${ECMC_MOTOR_PORT}, "Cfg.EcSetDomainFailedCyclesLimit(10)"
EthercatMCConfigController ${ECMC_MOTOR_PORT}, "Cfg.EcEnablePrintouts(0)"

##############################################################################
############# Load general controller level records:

< $(STARTUP)/general/general

# ##############################################################################
# ############# Go to runtime:

EthercatMCConfigController ${ECMC_MOTOR_PORT}, "Cfg.SetAppMode(1)"



dbl > "$(TOP)/../$(ECMC_PREFIX)_PVs.list"

