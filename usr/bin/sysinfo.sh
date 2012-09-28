#!/bin/bash 

space="............................"
function ceil() {
	ceiling_result=$((($1+$2-1)/$2))
}
function format() {
	
	width=78
	column_seperator="   "

    headers_len=${#headers[@]}

    min_length=$width
    for (( i = 0; i < $headers_len; i++ )) do
     	header_len=${#headers[$i]}

    	if [ $header_len -lt $min_length ]; then
			min_length=${header_len}
		fi
	done

	ceil $width $((min_length + 3))
	columns=$ceiling_result


	while true; do
		ceil $headers_len $columns
		headers_per_column=$ceiling_result
		header_lengths=( )
		total_length=0
		for (( column = 0; column < $columns; column++ )) 
		do
			widest_len=0
			for (( row = 0; row < $headers_per_column ; row++ )) do
				header_index=$(($column * $headers_per_column + $row))

				if [ $header_index -lt $headers_len ]; then
					header=${headers[$header_index]}
					header_len=${#header}

					if [ $widest_len -lt $header_len ]; then
						widest_len=$header_len
					fi
	
				fi
			done

			if [ $column -gt 0 ]; then
				total_length=$(($total_length+3))
			fi
								
			total_length=$(($total_length + $widest_len))
			header_lengths=("${header_lengths[@]}" "$widest_len")

		done

		if [ $columns -eq 1 -o $total_length -lt $width ]; then
			break
		fi

		columns=$(($columns - 1))
	done

	for (( row = 0; row < $headers_per_column ; row++ )) do
		line=""
		for (( c = 0; c < $columns; c++ )) do
			header_index=$(($c * 3 + $row))

			if [ $header_index -lt $headers_len ]; then
				header=${headers[$header_index]}
				widest_len=${header_lengths[$c]}
				if [ $column -gt 0 ]; then
					line="$line$column_seperator"
				fi
				line="$line$header"
				x=$((($c+1) * $headers_per_column + $row))

				if [ $headers_len -gt $x ]; then
					
					y=$(($widest_len - ${#header}))
					for ((i=0; i < $y; i++ )) do
						line="$line "
					done
				fi
			fi
		done
		lines=("${lines[@]}" "$line")
	done

	printf "%s \n" "${lines[@]}"
}

function format_mb() {
    if [ $1 -ge 1048576 ]; then
    	tb=`echo $1/1048576 | bc -l`
        mb=$(printf "%.2fTB" $tb)
    elif [ $1 -ge 1024 ]; then
    	gb=`echo $1/1024 | bc -l`
        mb=$(printf "%.2fGB" $gb)
    else
        mb=$(printf "%.2fMB" $1)
    fi
}
### Load
load=$(uptime | cut -d: -f5 | cut -d,  -f1)
headers=("${headers[@]}" "System load:$load")


### PHYSICAL DRIVE USAGE ###
used=$(df -m / | tail -1 | awk '{ print $3 }')
total=$(df -m / | tail -1 | awk '{ print $2 }')
percent=`echo $used*100/$total | bc -l`
format_mb $total
usage=$(printf "%0.1f%% of %s" $percent $mb )
headers=("${headers[@]}" "Disk Usage: $usage") 

### IP INTERFACE INFORMATION ###
list=$(ifconfig | grep "eth" | awk '{print $1}')
for item in $list; do
address=$(ifconfig $item | grep "inet addr" | awk '{print $2}' | cut -d ":" -f2)
headers=("${headers[@]}" "IP Address for $item: $address")
done


### SYSTEM INFORMATION ###

num_processes=$(ps aux | wc -l)
headers=("${headers[@]}" "Total Processes: $num_processes")
num_zombies=$(ps aux | awk '{ print $8 " " $2 }' | grep -w Z |wc -l)
if [ $num_zombies -eq 0 ]; then
	notes=("${notes[@]}" "There is 1 zombie process.")
else
	notes=("${notes[@]}" "There are $num_zombies zombie processes.")
fi

phymem=$(free -m | grep "Mem:" | awk '{printf "%d%%\n", $3*100/$2}')
swapmem=$(free -m | grep "Swap:" | awk '{printf "%d%%\n", $3*100/$2}')
headers=("${headers[@]}" "Memory usage: $phymem")
headers=("${headers[@]}" "Swap usage: $swapmem")


### USER LOGIN INFORMATION ###
logins=$(who | wc -l)
headers=("${headers[@]}" "Users logged in: $logins")


format

