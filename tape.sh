#!/bin/bash
# 2023 Dimitar Angelov <funkamateur@gmail.com>
# github.com/izne 
# 
# This one requires:
# bash, dialog, tar, mt, lsscsi, dmesg, sudo


DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=0
WIDTH=0
CWD=`pwd`

# hardcode your devices, todo: make dynamic
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
    --backtitle "Tape Tools: $TAPE_DEVICE" \
    --title "Tape $CURRENT_POSITION" \
    --clear \
    --cancel-label "Exit" \
    --menu "Select:" $HEIGHT $WIDTH 7 \
    "1" "Device Info" \
    "2" "List" \
    "3" "Rewind" \
    "4" "Backup" \
    "5" "Restore" \
    "6" "Eject" \
    "7" "About" \
    2>&1 1>&3)
  exit_status=$?
  exec 3>&-
  case $exit_status in
    $DIALOG_CANCEL)
	dialog --yesno "Confirm: Exit Tape Tools?" 0 0
	antwort=$?
	dialog --clear
	if [ $antwort = 0 ]
	then
		clear
		echo "Program terminated."
		exit
	fi
      ;;
    $DIALOG_ESC)
	dialog --yesno "Confirm: Exit Tape Tools?" 0 0
	antwort=$?
	dialog --clear
	if [ $antwort = 0 ]
	then
      clear
      echo "Program aborted." >&2
      exit 1
	fi
      ;;
  esac
  case $selection in
    1 )
      result=$(lsscsi | grep tape; echo; mt -f $TAPE_DEVICE status  )
      display_result "SCSI Information"
      ;;
    2 )
		dialog --title "Contents of $TAPE_DEVICE $CURRENT_POSITION" \
		--prgbox "tar tzf $TAPE_DEVICE ; mt -f $TAPE_DEVICE tell" 30 98
      ;;
    3 )
		dialog --infobox "Rewinding tape..." 5 30
		mt -f $TAPE_DEVICE rewind
		dialog --clear
      ;;
    4 )
      BACKUP_PATH=`dialog --dselect $CWD 5 5   3>&1 1>&2 2>&3`
	   NUM_FILES=`find $BACKUP_PATH -type f | wc -l`
        dialog --title "Backup $BACKUP_PATH to $TAPE_DEVICE" \
        --prgbox "echo 'Files to archive: ' $NUM_FILES; tar czvf $TAPE_DEVICE $BACKUP_PATH ; mt -f $TAPE_DEVICE tell" 30 90
      ;;
    5 )
      RESTORE_PATH=`dialog --dselect / 5 5   3>&1 1>&2 2>&3`
        dialog --title "Restore from $TAPE_DEVICE to $RESTORE_PATH" \
        --prgbox "tar xzf $TAPE_DEVICE $BACKUP_PATH ; mt -f $TAPE_DEVICE tell" 30 90
      ;;
    6 )
		dialog --infobox "Ejecting cassette..." 5 30
		mt -f $TAPE_DEVICE eject
		dialog --clear
		exit
      ;;
    7 )
      result=$(echo; echo "This system has:"; echo; mt --version | head -n 1; tar --version | head -n 1; echo -n "dialog "; dialog --version ; bash --version | head -n 1 )
      display_result "About"
      ;;
  esac
done
