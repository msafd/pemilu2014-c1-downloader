#/bin/bash
start() {
  pausetime="5"
  dataKecamatan="data/$1/data_kecamatan.txt"
  dataKelurahan="data/$1/data_kelurahan.txt"
  dataTPS="data/$1/data_tps.txt"
  if [[ -z "$1" ]]; then
    echo "parameter \$1 mana?"
    exit 1
  fi
  if [[ ! -d "data/$1" ]]; then
    echo "folder data $1 tidak ditemukan!"
    exit 1
  else
    if [[ ! -f "$dataKecamatan" ]]; then
      echo "data kecamatan tidak ditemukan!"
      exit 1
    else
      kabupaten=$(sed -n 1p "$dataKecamatan")
      mkdir -p "scan/$kabupaten"
      mkdir -p "temp/$kabupaten/tps" "temp/$kabupaten/list" "temp/$kabupaten/url"
      if [[ ! -f "$dataKelurahan" ]]; then
        echo "data kelurahan tidak ditemukan!"
        exit 1
      else
        if [[ ! -f "$dataTPS" ]]; then
          echo "data tps tidak ditemukan!"
          exit 1
        else
          # semua ok
          getfile "$1"
        fi
      fi
    fi
  fi
}
getfile() {
  num=13
  jumtps=$(cat "data/$1/data_tps.txt" | wc -l)
  max=$(( $jumtps + 1 ))
  # max=20
  while [[ $num -lt $max ]]; do
    line=$(sed -n "$num"p "$dataTPS")
    # echo -e "$num\t$line"
    cekonline
    curl -s "http://tps.kpu.go.id/api.php?cmd=search&tps_id=$line" > "temp/$kabupaten/tps/$line"
    cat "temp/$kabupaten/tps/$line" | python -mjson.tool > "temp/$kabupaten/tps/$line.json"
    idKec=$(cat "temp/$kabupaten/tps/$line.json" | grep "kec_id" | sed 's/[^0-9]*//g')
    kecamatan=$(cat "$dataKecamatan" | grep "$idKec" | cut -d "#" -f2)
    idKel=$(cat "temp/$kabupaten/tps/$line.json" | grep "kel_id" | sed 's/[^0-9]*//g')
    kelurahan=$(cat "$dataKelurahan" | grep "$idKel" | cut -d "#" -f2)
    nomortps=$(cat "temp/$kabupaten/tps/$line.json" | grep "num_tps" | sed 's/[^0-9]*//g')
    curl -s "http://pemilu2014.kpu.go.id/api.php?cmd=view&tps_id=$line" > "temp/$kabupaten/list/$line"
    cat "temp/$kabupaten/list/$line" | python -mjson.tool > "temp/$kabupaten/list/$line.json"
    cat "temp/$kabupaten/list/$line.json" | grep file | cut -d '"' -f4 > "temp/$kabupaten/url/$line"
    linkFile="temp/$kabupaten/url/$line"
    nomor=1
    jumfile=$(cat "$linkFile" | wc -l)
    maxfile=$(( $jumfile + 1 ))
    echo ""
    echo "Mendownload Scan > KEC. $kecamatan > $kelurahan > TPS $nomortps ($jumfile file)"
    echo "--------------------------------------------------"
    downloadDir="scan/$kabupaten/KEC. $kecamatan/$kelurahan/TPS $nomortps $line"
    mkdir -p "$downloadDir"
    while [[ $nomor -lt $maxfile ]]; do
      link=$(sed -n "$nomor"p "$linkFile")
      filename=$(echo "$link" | cut -d '=' -f2)
      cekonline
      wget -nv "$link" -O "$downloadDir/$filename"
      let nomor++;
    done
    let num++;
  done
}
cekonline() {
  if eval "ping -c 1 8.8.4.4 -w 2 > /dev/null 2>&1"; then
    isonline="1"
  else
    isonline="0"
  fi
  if [[ $isonline -gt 0 ]]; then
    if [[ $paused -gt 0 ]]; then
      echo -e "\e[1;92m# OK Connected! \e[96m(Resuming scan..)\e[0;39m"
      paused="0"
    fi
  else
    if [[ $paused -gt 0 ]]; then
      sleep $pausetime
      cekonline
    else
      echo -e "\e[1;93m# WARNING: \e[93mCan't connect to internet! \e[96m(pausing untill connected..)\e[0;39m"
      paused="1"
      cekonline
    fi
  fi
}
start "$@"
