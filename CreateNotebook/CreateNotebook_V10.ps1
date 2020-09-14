#В боевой ситуации скрипт отправляет информацию в HelpDesk. Ссылки тут битые

#Проверка нужна т.к. система предусматривает только 2 жестких диска у ноутбука, флешку система читаем как еще один жесткий диск
Write-Host "Если в ноутбук вставлена флешка - вытащи ее"

Read-Host "Готово ? Да\Нет"

[string]$firstCreationUriPart = 'https://test.test.ru/rest/METHOD/objectBase$Notebook/{"parentBO":"objectBase$"'

[string]$accessKey = '}?accessKey=accessKey'

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

    [int16]$DiskCount = 2

    [string]$HDDSlotCount = ',"HDDSlotCount":"' + $DiskCount + '"'

    $HardDisk += $HDDSlotCount

    return $HardDisk

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

#Для нового Ноутбука
Function Get-NotebookCurrentDate {

[string]$deprecationDate =',"deprecationDat":"' + ((Get-Date).AddYears(3)).ToString("yyyy.MM.dd") + '"'

[string]$startUpDate = ',"startUpDate":"' + (Get-Date).ToString("yyyy.MM.dd") + '"'

[string]$warrantyEnd = ',"warrantyEnd":"' + ((Get-Date).AddYears(1)).ToString("yyyy.MM.dd") + '"'

[string]$NotebookCurrentDate = $startUpDate + $deprecationDate + $warrantyEnd

return $NotebookCurrentDate
}

#Для старого Ноутбука
Function Get-OldNotebookDate {

[DateTime]$ReadDate = (Read-Host "Дата ввода в эксплуатацию, формат:dd.mm.yyyy") -as[datetime]

[string]$startUpDate = ',"startUpDate":"' + $ReadDate.ToString("yyyy.MM.dd") + '"'

[string]$deprecationDate =',"deprecationDat":"' + ($ReadDate.AddYears(3)).ToString("yyyy.MM.dd") + '"'

[string]$warrantyEnd = ',"warrantyEnd":"' + ($ReadDate.AddYears(1)).ToString("yyyy.MM.dd") + '"'

[string]$OldNotebookDate = $startUpDate + $deprecationDate + $warrantyEnd

return $OldNotebookDate
}

#Ноутбук - Модель серийник производитель процессор
Function Get-NotebookModel {
[string]$cpu = ',"cpu":"' + (gwmi win32_Processor).name + '"'

[string]$model = ',"model":"' + (gwmi win32_computersystem).model +'"'

[string]$producer = ',"producer":"' + (gwmi win32_computersystem).manufacturer + '"'

[string]$title = ',"title":"' + (gwmi win32_computersystem).manufacturer + " " + (gwmi win32_computersystem).model + '"'

[string]$SerialNumber = ',"serialNumber":"' + (gwmi win32_bios).serialnumber + '"'

[string]$NotebookModel = $cpu + $model + $producer + $title + $SerialNumber

return $NotebookModel
}

[string]$IsThatANewPC = Read-Host 'Новый Ноутбук ? Да/Нет'

[string]$Date

if ($IsThatANewPC -eq 'ДА' -or $IsThatANewPC -eq 'Да' -or $IsThatANewPC -eq 'да' -or $IsThatANewPC -eq 'yes'){
    $Date = Get-NotebookCurrentDate   
}
else {
    $Date = Get-OldNotebookDate
}

[string]$RAM = Get-RAM

[string]$HardDisk = Get-HardDisk

[string]$NoteBookModel = Get-NotebookModel

[string]$UserInfo = Get-UserInfo

[string]$OsVersion = ',"OsVersion":"' +(Get-WmiObject -class Win32_OperatingSystem).Caption + '"'

[string]$key = (wmic path softwarelicensingservice get OA3xOriginalProductKey)[2]

[string]$windowsKey = ',"windowsKey":"' + ([string](wmic path softwarelicensingservice get OA3xOriginalProductKey)[2]).Trim() + '"'

[string]$diagonal = Read-Host "Диагональ экрана ?"

$diagonal = ',"diagonal":"' + $diagonal + '"'

[string]$CreateNotebookUri = $firstCreationUriPart + $RAM + $HardDisk + $NoteBookModel + $UserInfo + $OsVersion + $diagonal + $windowsKey +$Date

$CreateNotebookUri += $accessKey

Invoke-RestMethod -Uri $CreateNotebookUri -Method POST