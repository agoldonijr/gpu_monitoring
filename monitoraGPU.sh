# Copyright (C) 2022 Alcides Goldoni Junior <goldoni@ggaunicamp.com>
# Copyright (C) 2022 Alcides Goldoni Junior <agoldonijr@gmail.com>

#!/bin/bash

#------------------------------------------------------------------------------
# Read variables
GPU_BOTTOM=$1
GPU_TOP=$2
LOG=$3
COUNT=0

#------------------------------------------------------------------------------
#Global variavel
GPU_TEMP=($(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader))
FAN_SPEED=($(nvidia-smi --query-gpu=fan.speed --format=csv,noheader | awk '{print $1}'))

#------------------------------------------------------------------------------
#Define functions

#Log info
write_log (){
    if [ -z $LOG ];
    then
        #Defautl log directory
        LOG=/var/log
    else
         if [ ! -d $LOG ]; then
            mkdir -p $LOG 
            if [ ! -f $LOG/nvidia-fan.log ]; then
                touch $LOG/nvidia-fan.log
        	    printf "GPU Temp \t Fan Perc \t Date \n"  >> $LOG/nvidia-fan.log
            fi
        fi
    fi
    get_info
    printf "%s \t %s \t %s" $GPU_TEMP $FAN_SPEED $(date +%Y-%m-%d-%H:%M:%S)   	>> $LOG/nvidia-fan.log
    printf "\n"                                                 		>> $LOG/nvidia-fan.log
}
#Enable fan control
get_enable (){
    nvidia-settings -a "GPUFanControlState=1"  > /dev/null 2>&1
    nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=50"
}

#Disable fan control
get_disable (){
    nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=30"
    nvidia-settings -a "GPUFanControlState=0"  > /dev/null 2>&1

}

#Get CPU temperature and  fan speed
get_info(){
    GPU_TEMP=($(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader))
    FAN_SPEED=($(nvidia-smi --query-gpu=fan.speed --format=csv,noheader | awk '{print $1}'))

}

#Fan speed up
up (){
    get_info
    FAN_SPEED=$(expr $FAN_SPEED + 22)
    nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=$FAN_SPEED"
    write_log

}

#Fan speed up
down (){
    get_info
    FAN_SPEED=$(expr $FAN_SPEED + 2)
    nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=$FAN_SPEED"
    write_log

}

#------------------------------------------------------------------------------
#MAIN

#Usage
if [ $# -lt 2 ]; 
then
    echo "usage: ./monitoraGPU.sh TempBottom TempTop "
    exit 1;
fi
get_enable
get_info

# Test temperature
if [ "$GPU_TEMP" -gt "$GPU_BOTTOM" ];
then
    up
    sleep 5

    get_info
    while [ "$GPU_TEMP" -gt "$GPU_TOP" ]
    do
        up
        COUNT=$(expr $COUNT + 1)
        if [ "$COUNT" -gt 5 ];
        then
            exit
        fi
        get_info
    done

# Disable manual fan controle 
else
    get_disable
fi

# Fix limit of fan speed in 90%
if [ "$FAN_SPEED" -gt "90" ];
then
    nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=90"
fi

# Limit of temperature and fix fan
if [ "$GPU_TEMP" -gt "85" ];
then
    nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=90"
fi
