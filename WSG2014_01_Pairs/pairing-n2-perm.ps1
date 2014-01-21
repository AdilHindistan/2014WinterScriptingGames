$file = $(get-date -f 'MMddyyyy')+'.txt'
$alpha = "a","b","c"
$num = 1,2,3
$alpha|%{
    $__=$_;
    $alpha|%{echo $__$_} | Out-File -Encoding ascii $file
    }
