#!/bin/bash


DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=0
WIDTH=0
CWD=`pwd`

#select device
TAPE_DEVICE=`dialog --radiolist "Select device ..." 0 0 2 \
  /dev/nst0 "HP C7438A (DAT72)" on \
  /dev/nst1 "CERTANCE ULTRIUM 2 (LTO-2)" off \
  /dev/nst2 "Tandberg SLR75 (SLR)" off 3>&1 1>&2 2>&3`

display_result() {
  dialog --title "$1: $TAPE_DEVICE" \
    --no-collapse \
    --msgbox "$result" 0 0
}



# Main
while true; do
  exec 3>&1
  CURRENT_POSITION=`mt -f $TAPE_DEVICE tell`
  selection=$(dialog \
    --backtitle "Tape Drive Control: $TAPE_DEVICE" \
    --title "Tape $CURRENT_POSITION" \
    --clear \
    --cancel-label "Exit" \
    --menu "Select:" $HEIGHT $WIDTH 9 \
    "1" "Controller" \
    "2" "Device" \
    "3" "List" \
    "4" "Rewind" \
    "5" "Backup" \
    "6" "Restore" \
    "7" "Eject" \
    "8" "About" \
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
      result=$(dmesg | grep scsi; echo; lsscsi | grep tape )
      display_result "SCSI Controller"
      ;;
    2 )
      result=$(dmesg | grep $TAPE_DEVICE; mt -f $TAPE_DEVICE status )
      display_result "Tape Device"
      ;;
    3 )
	dialog --title "Contents of $TAPE_DEVICE $CURRENT_POSITION" \
	--prgbox "tar tzf $TAPE_DEVICE ; mt -f $TAPE_DEVICE tell" 30 98
      ;;
    4 )
       mt -f $TAPE_DEVICE rewind | dialog --title "Rewinding ..." --progressbox 0 0
      ;;
    5 )
      BACKUP_PATH=`dialog --dselect $CWD 5 5   3>&1 1>&2 2>&3`
        dialog --title "Backup $BACKUP_PATH to $TAPE_DEVICE" \
        --prgbox "tar czvf $TAPE_DEVICE $BACKUP_PATH ; mt -f $TAPE_DEVICE tell" 30 90
      ;;
    6 )
      RESTORE_PATH=`dialog --dselect / 5 5   3>&1 1>&2 2>&3`
        dialog --title "Restore from $TAPE_DEVICE to $RESTORE_PATH" \
        --prgbox "tar xzf $TAPE_DEVICE $BACKUP_PATH ; mt -f $TAPE_DEVICE tell" 30 90
      ;;
    7 )
       mt -f $TAPE_DEVICE eject | dialog --title "Ejecting ..." --progressbox 0 0
      ;;
    8 )
      result=$(echo; echo "This system has the following versions:"; echo; mt --version | head -n 1; tar --version | head -n 1; echo -n "dialog "; dialog --version ; bash --version | head -n 1 )
      display_result "About"
      ;;
  esac
done
