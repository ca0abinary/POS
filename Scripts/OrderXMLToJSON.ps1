Param(
  [string]$sourceOrderXmlFilePath,
  [string]$destinationPath,
  [string]$logFile,
  [bool]$outputToConsole,
  [bool]$createUniqueOrderID
)


$fileFound = Test-Path  $sourceOrderXmlFilePath
if(-not $fileFound){
    Add-Content $logFile "Source XML File Not Found : " $sourceOrderXmlFilePath
    exit;
}

Try{

    $orderXml = [XML](Get-Content -Path $sourceOrderXmlFilePath)

    $orderHeader = $orderXml.Envelope.Body.ProcessOrder.sOrderXmlDoc.OrderHeader;

    if ($createUniqueOrderID){
        $uniqueOrderID = [guid]::NewGuid().guid
    }
    else{
        $uniqueOrderID  =  $orderHeader.UniqueOrderID
    }

    $headerHash = @{
        StoreID = $orderHeader.StoreID;
        StoreName = $orderHeader.StoreName;
        UniqueOrderID = $uniqueOrderID;
        DateCreated = $orderHeader.DateCreated;
        SupplierID = $orderHeader.SupplierID;
        SupplierName = $orderHeader.SupplierName;
        OrderTotal = $orderHeader.OrderTotal;
        StorePONumber = $orderHeader.StorePONumber;
        AccountNumber = $orderHeader.AccountNumber;
        OrderSource = $orderHeader.OrderSource;
        OrderStatus = $orderHeader.OrderStatus;
        ValidateItemData = $orderHeader.ValidateItemData;
    }

    $orderDetail = $orderXml.Envelope.Body.ProcessOrder.sOrderXmlDoc.OrderHeader.OrderDetail;


    $detailsHash = New-Object System.Collections.Generic.List[System.Object];

    foreach($detail in $orderDetail){
        $orderDetailItem = @{
            GTIN = $detail.GTIN;
            SupplierSKU = $detail.SupplierSKU;
            Quantity = $detail.Quantity;
            Cost = $detail.Cost;
            Front = $detail.Front;
            Back = $detail.Back;
            ItemDescription = $detail.ItemDescription;
            PagePartition = $detail.PagePartition;
        }
        $detailsHash.Add($orderDetailItem);
    }

    $orderHash = @{
        Header = $headerHash;
        Details = $detailsHash;
    }

    $outFileName = $orderHeader.UniqueOrderID;
    $outFileName = $outFileName.replace("{","");
    $outFileName = $outFileName.replace("}","");
    $outFileName = $outFileName + ".json";

    $jsonOutFilePath = $destinationPath + $outFileName
    $message = "Output file: $jsonOutFilePath"
    Add-Content $logFile $message
    if($outputToConsole) {
        Write-Host $message
    }

    ConvertTo-Json -InputObject $orderHash | Out-File -Encoding ASCII $jsonOutFilePath  -ErrorAction Stop
    return $jsonOutFilePath

}
catch{
    Add-Content $logFile "OrderXMLtoJSON Error Message: $_.Exception.Message"
    $message = "Error occurred in line " +  $_.InvocationInfo.ScriptLineNumber
    Add-Content $logFile $message
    Throw  $_.Exception
}
