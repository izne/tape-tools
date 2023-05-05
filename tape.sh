#!/bin/bash

DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=0
WIDTH=0
CWD=`pwd`

#select device
TAPE_DEVICE=`dialog --radiolist "Select device ..." 0 0 3 \
  /dev/nst0 "HP DAT72" off\
  /dev/nst1 "LTO-2" off\
  /dev/nst2 "Tandberg SLR75" off 3>&1 1>&2 2>&3`


display_result() {
  dialog --title "$1: $TAPE_DEVICE" \
    --no-collapse \
    --msgbox "$result" 0 0
}

program_result(){
  dialog --title "$1: $TAPE_DEVICE" \
    --no-collapse \
    --programbox "$result" 0 0

}

# Main

while true; do
  exec 3>&1
  selection=$(dialog \
    --backtitle "Tape Drive Control: $TAPE_DEVICE" \
    --title "Tape Menu" \
    --clear \
    --cancel-label "Exit" \
    --menu "Select:" $HEIGHT $WIDTH 6 \
    "1" "Drive Info" \
    "2" "Head position" \
    "3" "List contents" \
    "4" "Backup" \
    "5" "Restore" \
    "6" "Rewind" \
    "7" "Eject" \
    2>&1 1>&3)
  exit_status=$?
  exec 3>&-
  case $exit_status in
    $DIALOG_CANCEL)
      clear
      echo "Program terminated."
      exit
      ;;
    $DIALOG_ESC)
      clear
      echo "Program aborted." >&2
      exit 1
      ;;
  esac
  case $selection in
    1 )
      result=$(dmesg | grep $TAPE_DEVICE; mt -f $TAPE_DEVICE status )
      display_result "Tape Information"
      ;;
    2 )
      result=$(mt -f $TAPE_DEVICE tell )
      display_result "Head position"
      ;;
    3 )
        dialog --title "Listing contents of $TAPE_DEVICE" \
        --prgbox "tar tzf $TAPE_DEVICE ; mt -f $TAPE_DEVICE tell" 30 90
      ;;
    4 )
      BACKUP_PATH=`dialog --dselect $CWD 5 5   3>&1 1>&2 2>&3`
        dialog --title "Backup $BACKUP_PATH to $TAPE_DEVICE" \
        --prgbox "tar czvf $TAPE_DEVICE $BACKUP_PATH ; mt -f $TAPE_DEVICE tell" 30 90
      ;;
    5 )
      result=$(tar xzvf $TAPE_DEVICE )
      display_result "Restore from tape"
      RESTORE_PATH=`dialog --dselect / 5 5   3>&1 1>&2 2>&3`
        dialog --title "Restore from $TAPE_DEVICE to $RESTORE_PATH" \
        --prgbox "tar xzf $TAPE_DEVICE $BACKUP_PATH ; mt -f $TAPE_DEVICE tell" 30 90
      ;;
    6 )
      result=$(mt -f $TAPE_DEVICE rewind; echo "Rewind completed!" )
      display_result "Rewind"
      ;;
    7 )
      result=$(mt -f $TAPE_DEVICE eject; echo "The tape has been ejected!" )
      display_result "Eject"
      ;;
  esac
done
