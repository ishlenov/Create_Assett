#В боевой ситуации скрипт отправляет информацию в HelpDesk. Ссылки тут битые
[string]$firstCreationUriPart = 'https://test.test.ru/rest/METHOD/objectBase$testObject/{"parentBO":"objectBase$"'

[string]$accessKey = '}?accessKey=accessKey'

# Сперва описаны методы, которые вытаскивают информацию

#Для нового ПК
Function Get-PCCurrentDate {

[string]$deprecationDate =',"deprecationDat":"' + ((Get-Date).AddYears(5)).ToString("yyyy.MM.dd") + '"'

[string]$startUpDate = ',"startUpDate":"' + (Get-Date).ToString("yyyy.MM.dd") + '"'

[string]$warrantyEnd = ',"warrantyEnd":"' + ((Get-Date).AddYears(1)).ToString("yyyy.MM.dd") + '"'

[string]$PCCurrentDate = $startUpDate + $deprecationDate + $warrantyEnd

return $PCCurrentDate
}

#Для старого ПК
Function Get-OldPCDate {

[DateTime]$ReadDate = (Read-Host "Дата ввода в эксплуатацию, формат:dd.mm.yyyy") -as[datetime]

[string]$startUpDate = ',"startUpDate":"' + $ReadDate.ToString("yyyy.MM.dd") + '"'

[string]$deprecationDate =',"deprecationDat":"' + ($ReadDate.AddYears(5)).ToString("yyyy.MM.dd") + '"'

[string]$warrantyEnd = ',"warrantyEnd":"' + ($ReadDate.AddYears(1)).ToString("yyyy.MM.dd") + '"'

[string]$OldPCDate = $startUpDate + $deprecationDate + $warrantyEnd

return $OldPCDate
}

#Оперативка - универсально
Function Get-RAM {
[Array]$AllRam =(gwmi win32_physicalmemory | ForEach-Object {($_.Manufacturer + " " +  $_.configuredclockspeed + " МГц " + $_.capacity/1gb + " ГБ")})

[int16]$a = 0

[string]$ramSlotCount = ',"ramSlotCount":"' + [int16](wmic memphysical get MemoryDevices)[2] + '"'

[string]$RAM = $null

while ($a -lt $AllRam.Length) {

[string]$AddRAM = ',"RAM' + (++$a) + '":"' + $AllRam[$a-1] + '"'

$RAM += $AddRAM 
}

$RAM += $ramSlotCount

return $RAM

}

#Жесткие диски - универсально
Function Get-HardDisk {
    [Array]$AllDisks = (Get-PhysicalDisk | ForEach-Object {$_.MediaType + " " + [int16]($_.Size/1gb) + " ГБ"})

    [string]$HardDisk = $null

    [int16]$a = 0

    while ($a -lt $AllDisks.Length) {
        
        [string]$AddDisk = ',"hdd' + (++$a) + '":"' + $AllDisks[$a-1] + '"'

        $HardDisk += $AddDisk
    }

    [int16]$DiskCount = $null

    if ([int16]$AllDisks.Length -le 4){
        $DiskCount = 4;
    }
    elseif ([int16]$AllDisks.Length -le 6){
        $DiskCount = 6
    }
    elseif ([int16]$AllDisks.Length -le 8){
        $DiskCount = 8
    }
    elseif ([int16]$AllDisks.Length -le 10){
        $DiskCount = 10
    }
    elseif ([int16]$AllDisks.Length -le 12){
        $DiskCount = 12
    }

    [string]$HDDSlotCount = ',"HDDSlotCount":"' + $DiskCount + '"'

    $HardDisk += $HDDSlotCount

    return $HardDisk

}

#ПК - модель серийник производитель процессор
Function Get-PCmodel {

[string]$cpu = ',"cpu":"' + (gwmi win32_Processor).name + '"'

[string]$model = ',"model":"' + (gwmi win32_baseboard).product +'"'

[string]$producer = ',"producer":"' + (gwmi win32_baseboard).manufacturer + '"'

[string]$title = ',"title":"' + ((gwmi win32_baseboard).manufacturer) + " " + ((gwmi win32_baseboard).model) + '"'

[string]$SerialNumber = ',"serialNumber":"' + (gwmi win32_baseboard).serialnumber + '"'

[string]$PCmodel = $cpu + $model + $producer + $title + $SerialNumber

return $PCmodel

}

#Получение информации о пользователе, авторе, департаменте
Function Get-UserInfo {

    <# Нужно добавить возможность привязать к департаменту но пользователем назначить заносящего #>

    [string]$AuthorLogin = Read-Host "Your Login"

    [string]$AuthorLoginUri = 'https://test.test.ru/rest/METHOD/employee$employee/{login:"' + $AuthorLogin + '"}?accessKey=accessKey'

    [object]$AuthorLoginInfo = Invoke-RestMethod -Uri $AuthorLoginUri -Method Get

    [string]$Author = ',"author":"' + $AuthorLoginInfo.UUID + '"'

    [string]$UserLogin = Read-Host "User Login"

    [string]$UserInfoUri = 'https://test.test.ru/rest/METHOD/employee$employee/{login:"' + $UserLogin + '"}?accessKey=accessKey'

    [object]$UserInfoObject = Invoke-RestMethod -Uri $UserInfoUri -Method Get

    [string]$Owner = ',"owner":"' + $UserInfoObject.parent.UUID + '"'

    [string]$Users = ',"users":"' + $UserInfoObject.UUID + '"'

    [string]$UserInfo = $Author + $Owner + $Users

    return $UserInfo
}


[string]$IsThatANewPC = Read-Host 'Новый ПК ? Да/Нет'

[string]$Date

if ($IsThatANewPC -eq 'ДА' -or $IsThatANewPC -eq 'Да' -or $IsThatANewPC -eq 'да' -or $IsThatANewPC -eq 'yes'){
    $Date = Get-PCCurrentDate   
}
else {
    $Date = Get-OldPCDate
}

[string]$RAM = Get-RAM

[string]$HardDisk = Get-HardDisk

[string]$PCmodel = Get-PCmodel

[string]$OsVersion = ',"OsVersion":"' +(Get-WmiObject -class Win32_OperatingSystem).Caption + '"'

[string]$UserInfo = Get-UserInfo

[string]$CreatePCUri = $firstCreationUriPart + $RAM + $HardDisk + $PCmodel  + $OsVersion + $UserInfo + $Date

$CreatePCUri += $accessKey

Invoke-RestMethod -Uri $CreatePCUri -Method POST