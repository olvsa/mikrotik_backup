# 20230315 sable
# proto: `ssh -i _id_rsa -o "StrictHostKeyChecking=no" backup@10.10.1.1 "export" >10.10.1.1.txt`

$base = "C:\srv"
$ssh_u = "backup"
$ssh_i = "$base\backups\_id_rsa"

Start-Process -FilePath "takeown" -ArgumentList "/f `"$ssh_i`""
Start-Process -FilePath "icacls" -ArgumentList "`"$ssh_i`" /reset"
Start-Process -FilePath "icacls" -ArgumentList "`"$ssh_i`" /inheritance:r"
Start-Process -FilePath "icacls" -ArgumentList "`"$ssh_i`" /grant:r `"$env:UserDomain`\$env:UserName`":`"(R)`""

$stamp = (Get-Date).ToString("yyyyMMdd")

foreach ( $obj in `
 "10.10.0.1", "10.10.1.1", "10.10.2.1", "10.10.3.1", "10.10.3.129", "10.10.4.1", "10.10.4.129", "10.10.12.1"
 ) {
 $dir_obj = "$base\backups\$obj"

 New-Item -Path "$dir_obj" -ItemType directory -Force -ErrorAction SilentlyContinue
 if ( Test-Path "$dir_obj" -PathType Container ) {
  $t1 = New-TemporaryFile
  $args = "-C -i `"$ssh_i`" -o `"StrictHostKeyChecking=no`" -o `"PasswordAuthentication=no`" $ssh_u@$obj `"export`""
  Start-Process -FilePath "ssh.exe" -ArgumentList "$args" -Wait `
   -RedirectStandardOutput "$t1" -RedirectStandardError "$dir_obj\$stamp.log"

  if ( (Get-Item "$t1").Length -gt 4096 ) {
   Move-Item -Path "$t1" -Destination "$dir_obj\$stamp.txt" -Force
  } else {
   Remove-Item -Path $t1 -Force -ErrorAction SilentlyContinue
  }
  if ( (Get-Item "$dir_obj\$stamp.log").Length -eq 0 ) {
   Remove-Item -Path "$dir_obj\$stamp.log" -Force -ErrorAction SilentlyContinue
  }

  Get-ChildItem -Path "$dir_obj" -Filter "*.log" | sort -Descending | select -Skip 17 | Remove-Item -Force
  Get-ChildItem -Path "$dir_obj" -Filter "*.txt" | sort -Descending | select -Skip 17 | Remove-Item -Force
 }
}
