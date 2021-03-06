#!/system/bin/sh
# Advanced Charging Controller Power Supply Logger
# Copyright (c) 2019-2020, VR25 (xda-developers)
# License: GPLv3+


gather_ps_data() {
  local target="" target2=""
  for target in $(ls -1 $1 | grep -Ev '^[0-9]|^block$|^dev$|^fs$|^ram$'); do
    if [ -f $1/$target ]; then
      echo $1/$target | grep -Ev 'logg|(/|_|-)log|at_pmrst' | grep -Eq 'batt|charg|power_supply' && {
        echo $1/$target
        grep -q $1/$target $logsDir/psl-blacklist.txt 2>/dev/null && echo "  BLACKLISTED" || {
          echo $1/$target >> $logsDir/psl-blacklist.txt
          cat -v $1/$target 2>/dev/null | sed 's#^#  #'
          sed -i "\|$1/$target|d" $logsDir/psl-blacklist.txt
        }
        echo
      }
    elif [ -d $1/$target ]; then
      for target2 in $(find $1/$target \( \( -type f -o -type d \) \
        -a \( -ipath '*batt*' -o -ipath '*charg*' -o -ipath '*power_supply*' \) \) \
        -print 2>/dev/null | grep -Ev 'logg|(/|_|-)log|at_pmrst')
      do
        [ -f $target2 ] && {
          echo $target2
          grep -q $target2 $logsDir/psl-blacklist.txt 2>/dev/null && echo "  BLACKLISTED" || {
            echo $target2 >> $logsDir/psl-blacklist.txt
            cat -v $target2 2>/dev/null | sed 's#^#  #'
            sed -i "\|$target2|d" $logsDir/psl-blacklist.txt
          }
          echo
        }
      done
    fi
  done
}


export TMPDIR=/dev/.acc
execDir=/data/adb/acc
logsDir=/data/adb/acc-data/logs

print_wait 2>/dev/null || echo "(i) Alright, this may take a minute or so..."


# log
umask 0077
exec 2> $logsDir/power-supply-logger.sh.log
set -x


. $execDir/setup-busybox.sh

{
  date
  echo accVerCode=$(sed -n s/versionCode=//p $execDir/module.prop)
  echo
  echo
  cat /proc/version 2>/dev/null || uname -a
  echo
  echo
  getprop | grep product
  echo
  getprop | grep version
  echo
  echo
  gather_ps_data /sys
  echo
  gather_ps_data /proc
} > $logsDir/power_supply-$(getprop ro.product.device | grep .. || getprop ro.build.product).log

exit 0
