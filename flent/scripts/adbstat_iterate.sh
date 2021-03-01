#!/bin/bash

count=20
interval=0.5
interface=wlan0

while getopts "c:I:i:" opt; do
    case $opt in
        c) count=$OPTARG ;;
        I) interval=$OPTARG ;;
        i) interface=$OPTARG ;;
    esac
done

# adb is slow as hell so we need to subtract script evaluation time
# It is not recommended to use interval values less than 0.5 so let it be the default value
interval=$(echo $interval | awk '{printf "%.2f", $1 - 0.262}')

command_string=$(cat <<EOF
ap_mac=\$(iw dev $interface link | awk 'NR==1 {print \$3}');
echo "interface is $interface";
echo "ap_mac is $ap_mac";
for i in \$(seq $count); do
    date '+Time: %s.%N';
    iw dev  $interface station get \$ap_mac | awk '/tx bitrate/ {printf "tx_bitrate: %.2f \n",\$3} /rx bitrate/ { printf "rx_bitrate: %.2f \n",\$3} /signal:/ {  printf "rssi: %.2f \n",\$2}';
    cat /proc/net/wireless | awk '/$interface/ { printf "noise: %.2f \n",\$5}';
    awk '{ printf "thermal_zone0_temp: %.2f \n",\$1 / 1000}' /sys/class/thermal/thermal_zone0/temp;
    awk '{ printf "thermal_zone1_temp: %.2f \n",\$1 / 1000}' /sys/class/thermal/thermal_zone1/temp;
    awk '{ printf "cpu0_freq: %.2f \n",\$1}' /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq;
    awk '{ printf "cpu1_freq: %.2f \n",\$1}' /sys/devices/system/cpu/cpu1/cpufreq/cpuinfo_cur_freq;
    awk '{ printf "cpu2_freq: %.2f \n",\$1}' /sys/devices/system/cpu/cpu2/cpufreq/cpuinfo_cur_freq;
    awk '{ printf "cpu3_freq: %.2f \n",\$1}' /sys/devices/system/cpu/cpu3/cpufreq/cpuinfo_cur_freq;
    printf "---\n";
    sleep $interval || exit 1;
done
EOF
)

echo "$command_string" | adb shell
