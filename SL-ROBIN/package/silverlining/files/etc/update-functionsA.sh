#!/bin/sh

ME=update
updt_host=$(uci get general.services.updt_srv)
checker=$(uci get general.services.checker)
node_role=$(uci get node.general.role)	# 1=gateway 0=client
KERNEL=$(uci get node.general.kernel)
BOARD=$(uci get node.general.board)
cp_HANDLER=$(uci get cp_switch.main.which_handler)
ra_HANDLER=$(uci get ra_switch.main.which_handler)

WDIR=/etc/update
DASHBOARD="${updt_host}/${checker}"
DASHBOARD_REPLY=$WDIR/received
OLD_REPLY=$WDIR/received.old

lastCheckin=$WDIR/last_checkin
LOG=/tmp/update.log ; echo -n > $LOG	
key_config="#@#config"

wget_opt="-t 3 -T 60 --no-cache -o ${LOG}"
wget_opt_ssl="${wget_opt} --no-check-certificate"

REASON=91	

force_openDNS() {
	cat $LOG |grep -q "unable to resolve" && {
		# don't touch alternate nameserver settings, only force to use openDNS
		# at least until next reboot or a related change in dashboard reply 

		RESOLV_CONF="/etc/resolv.conf"
		cat /etc/resolv.conf.openDNS > /tmp/resolv.conf
		cp -f /tmp/resolv.conf $RESOLV_CONF
	}
}

blank_flags () {
	for FLAG in cps node system ; do
		uci set flags.restart.${FLAG}="0"
	done
	uci commit flags
}

heartbeat () {
	run_heartbeat=$(uci get cp_switch."handler_${cp_HANDLER}".need_heart )
		
	if [ "$run_heartbeat" -eq 1 ] ; then
		echo "sending heartbeat..."
		HEARTBEAT_SCRIPT=$(uci get cp_switch."handler_${cp_HANDLER}".heartbeat) 
		/sbin/${HEARTBEAT_SCRIPT}
	fi
}

checkin_dashboard () {
	echo "check dashboard..."
	echo $data > $WDIR/update.arg


    echo "check SL dashboard..."
    DASHBOARD_SL="https://app.silverliningnetworks.com/sl/checkin"
	NODOGS=$(pgrep nodogsplash | wc -l)
	TCPCONNS=$(cat /proc/net/nf_conntrack | wc -l)
	SL_URL="${DASHBOARD_SL}?${data}&nodogs=${NODOGS}&tcpconns=${TCPCONNS}"
    $(wget $wget_opt_ssl "${SL_URL}")
	if [ "$?" -ne 0 ] ; then
		logger -st ${0##*/} "failed checking Silver Lining dashboard, exit."
	fi	

	if [ 1 -eq "$(uci get management.enable.https)" ]; then
		case $(uci get management.enable.method_POST) in
			0) wget $wget_opt_ssl "https://${DASHBOARD}?${data}" -O $DASHBOARD_REPLY ;;
			1) wget $wget_opt_ssl --post-file $WDIR/update.arg "https://${DASHBOARD}" -O $DASHBOARD_REPLY ;;
		esac
		wget_result=$?

		else

		case $(uci get management.enable.method_POST) in
			0) wget $wget_opt "http://${DASHBOARD}?${data}" -O $DASHBOARD_REPLY ;;
			1) wget $wget_opt --post-file $WDIR/update.arg "http://${DASHBOARD}" -O $DASHBOARD_REPLY ;;
		esac
		wget_result=$?
	fi
	
	[ "$wget_result" -ne 0 ] && {
			force_openDNS
			logger -st ${0##*/} "failed checking the dashboard, exit."
			exit
	}		

	chck_cnt=$(cat $lastCheckin |awk '{print $1}')
	let chck_cnt=chck_cnt+1 
	echo "$chck_cnt on $(date)" |sed s/GMT//g > $lastCheckin
	logger -st ${0##*/} "dashboard updated successfully: checkin #${chck_cnt}"
}

custom_update () {
     [ "$(uci get management.enable.custom_update)" -eq 1 ] || return	
	custom_host=$(uci get general.services.cstm_srv)
	WDIR=/etc/update
	CUSTOM_MD5=$WDIR/custom.md5
	[ -e $CUSTOM_MD5 ] || echo "$(md5sum /etc/robin_version | head -c 32)" > $CUSTOM_MD5	
	
	$(wget "http://${custom_host}custom.sh" -O /tmp/custom.sh)
	if [ "$?" -ne 0 ] ; then
		logger -s -t  "$ME" "custom download failed!"
		return 
	fi
	
	PREV_CUSTOM_MD5=$(cat $CUSTOM_MD5)
	CURR_CUSTOM_MD5="$(md5sum /tmp/custom.sh | head -c 32)"
	
	if [ "$CURR_CUSTOM_MD5" = "$PREV_CUSTOM_MD5" ] ; then
		logger -s -t  "$ME" "nothing customized for this node"
		
		else # apply custom update
		echo $CURR_CUSTOM_MD5 > $CUSTOM_MD5
		chmod 755 /tmp/custom.sh
		$(sh /tmp/custom.sh)
		if [ "$?" -ne 0 ] ; then
			$(rm $CUSTOM_MD5)
		fi
		wait
		rm -f /tmp/custom.sh
	fi
	return 
}

pre_process_reply () {
	#called at very first checkin -OR- if the received reply differs from the previous one
	echo "pre-process reply..."
	for settings in mesh wireless general acl iprules maclist1 madwifi management node nodes \
		secondary radio cp_switch chilli nodog splash-HTML ra_switch batman olsr ; do
		rm -f $WDIR/${settings}
	done
	
	while read record ; do
		[ -n "$record" ] && {
			field_1=$(echo $record |awk '{print $1}')
			[ -n "$field_1" ] || continue
			case $field_1 in
				$key_config) field_2=$(echo $record |awk '{print $2}') ;;
				$bogus) ;; 
				*) file_out="${WDIR}/${field_2}"; echo $record >> $file_out ;;
			esac
		}
	done < $DASHBOARD_REPLY
	[ -e $WDIR/ath_hal ] && mv $WDIR/ath_hal $WDIR/madwifi 

	#alternate update server
	k_sec=$(cat $DASHBOARD_REPLY | awk '$1=="backend.update" {print $2}') 
	k_sec=${k_sec:-0}
	if [ "$k_sec" -eq 1 ] ; then
		SECONDARY_srv=$(cat $DASHBOARD_REPLY | awk '$1=="backend.server" {print $2}')	
		if [ -n $SECONDARY_srv ] ; then
			SECONDARY_srv=$(echo $SECONDARY_srv |tr -d '\r')					
			uci set general.services.updt_srv=$SECONDARY_srv
			uci commit general															
		fi							
	fi
}

ismac() {
  ERROR=0
  oldIFS=$IFS
  IFS=:
  set -f
  set -- $1
  if [ $# -eq 6 ]; then
    for seg; do
      case $seg in
        “”|*[!0-9a-fA-F]*)
          ERROR=1
          break
          ;; # Segment empty or non-hexadecimal
        ??)
          ;; # Segment with 2 caracters are ok
        *)
          ERROR=1
          break
          ;;
      esac
    done
  else
    ERROR=2 ## Not 6 segments
  fi
  IFS=$oldIFS
  set +f

  return $ERROR
}

update_UCI () {
	MODE="1"
	SETTINGS=

	#synlinks (only once)
	[ -h /usr/sbin/update-wireless.sh ] || ln -sf /usr/sbin/update-wifi.sh /usr/sbin/update-wireless.sh 
	[ -h /usr/sbin/update-nodogsplash.sh ] || ln -sf /usr/sbin/update-nodog.sh /usr/sbin/update-nodogsplash.sh 
	[ -h $WDIR/nodogsplash ] || ln -sf $WDIR/nodog $WDIR/nodogsplash

	if [ -s "$OLD_REPLY" ]; then 
		uci show -q >/tmp/uci.db

		[ -e $WDIR/cp_switch ] && {
			reply_cp_HANDLER=$(cat $WDIR/cp_switch |awk '{print $2}')
			[ "$cp_HANDLER" -eq "$reply_cp_HANDLER" ] || SETTINGS="${SETTINGS} cp_switch"
		}

		[ -e $WDIR/ra_switch ] && {
			reply_ra_HANDLER=$(cat $WDIR/ra_switch |awk '{print $2}')
			[ "$ra_HANDLER" -eq "$reply_ra_HANDLER" ] || SETTINGS="${SETTINGS} ra_switch"
		}

		diff $DASHBOARD_REPLY $OLD_REPLY \
			|grep '+' |awk '{print $1}'|grep -v "++\|@\|_handler" |sed s/+// > /tmp/dum
		diff $OLD_REPLY $DASHBOARD_REPLY \
			|grep '+' |awk '{print $1}'|grep -v "++\|@\|_handler" |sed s/+// >> /tmp/dum
		sort -u /tmp/dum > /tmp/mud

		[ -s /tmp/mud ] && { 
			while read record ; do 
				[ -n "$record" ] && {
					if [ "$record" == "R" -o "$record" == "G" ]; then
						f=nodes
						elif ismac $record ; then
						f=acl
						elif echo $record |grep -q 'bogus' ; then
						f=nodogsplash
					else
						f=$(grep $record /tmp/uci.db |awk -F. '{print $1}')
					fi
					[ -n "$f" -a "$f" != "$sf" ] && { SETTINGS="${SETTINGS} $f"; sf=$f; }
				}
			done < /tmp/mud
		}

	else 
		# ...splitted in two lines for a better reading)
		SETTINGS="cp_switch ra_switch mesh wireless general acl iprules madwifi"
		SETTINGS="${SETTINGS} management node nodes radio batman olsr nodog chilli"
	fi

	[ -n "$SETTINGS" ] && {
		for uci in $SETTINGS ; do
			[ -e $WDIR/$uci ] && /usr/sbin/update-${uci}.sh $MODE
		done
	}

	sync
}

check_node_drift () {
	local nodeDrift=0
	
	DASHBOARD_SETTING=$(cat /tmp/reply/ra_switch | awk '$1=="main.which_handler" {print $2}') 
	LOCAL_SETTING=$(uci get ra_switch.main.preset)
	[ "$LOCAL_SETTING" -eq "$DASHBOARD_SETTING" ] || nodeDrift=1
	
	DASHBOARD_SETTING=$(cat /tmp/reply/radio  | awk '$1=="channel.alternate" {print $2}') 
	LOCAL_SETTING=$(uci get radio.channel.alternate)
	[ "$LOCAL_SETTING" -eq "$DASHBOARD_SETTING" ] || nodeDrift=1
	
	if [ 1 -eq "$nodeDrift" ] ; then # force next update to process the reply
		echo "$(md5sum /etc/robin_version | head -c 32)" > $MD5
	else
		logger -s -t  "$ME" "dashboard and node settings are in sync"		
	fi
}
#
