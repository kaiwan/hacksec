TENMB=$((1024*1024*10))
len=${TENMB}
i=1
while [ true ]
do
 echo "$i: len = ${len}"
 ./userspc_mmap /dev/mmap_baddrv ${len} || break
 let i=i+1
 len=$((len+(10*${TENMB})))
done
