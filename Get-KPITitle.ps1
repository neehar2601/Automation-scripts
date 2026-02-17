param(
    [string]$JsonFile,
    [string]$KPIId,
    [string]$ETLFileName = ""
)

<#
.SYNOPSIS
    Gets a normalized folder name for ETL processing based on KPI ID

.DESCRIPTION
    This script generates a normalized folder name for organizing ETL files.
    It supports two modes:
    1. JSON Mode (Current): Always uses KPI-Details.json to look up the title
    2. Filename Mode (Future): Uses ETL filename if it contains description, otherwise falls back to JSON

.PARAMETER JsonFile
    Path to the KPI-Details.json file

.PARAMETER KPIId
    The KPI ID to look up (e.g., GLD1008)

.PARAMETER ETLFileName
    The ETL filename without path or extension (e.g., GLD1008_busy_idle_Tracelog)

.EXAMPLE
    Get-KPITitle.ps1 -JsonFile "KPI-Details.json" -KPIId "GLD1008"
    Returns: gld1008_cinebench_r24_mt

.EXAMPLE
    Get-KPITitle.ps1 -JsonFile "KPI-Details.json" -KPIId "GLD1008" -ETLFileName "GLD1008_busy_idle_Tracelog"
    Returns: gld1008_cinebench_r24_mt (JSON mode - ignores filename)
#>

function Normalize-FolderName {
    param([string]$name)
    
    # Replace invalid filename characters with underscore (including brackets)
    $name = $name -replace '[\\/:*?"<>|\[\]]', '_'
    
    # Convert to lowercase and replace spaces with underscores
    $name = $name.ToLower() -replace '\s+', '_'
    
    # Replace hyphens surrounded by underscores with just underscore
    $name = $name -replace '_-_', '_'
    
    # Remove multiple consecutive underscores
    $name = $name -replace '_+', '_'
    
    # Remove leading/trailing underscores
    $name = $name.Trim('_')
    
    return $name
}

try {
    # Convert KPI ID to lowercase
    $kpiIdLower = $KPIId.ToLower()
    
    # ====================================================================================
    # FUTURE ENHANCEMENT: Use ETL filename if it contains description
    # ====================================================================================
    # Uncomment the following section to enable filename-based naming:
    <#
    if ($ETLFileName -ne "") {
        # Remove _Tracelog suffix if present
        $cleanName = $ETLFileName -replace '_Tracelog$', ''
        
        # Check if filename has description after KPI ID (e.g., GLD1008_busy_idle)
        if ($cleanName -match '^GLD\d+_.+') {
            # Has description, use the filename
            $folderName = Normalize-FolderName -name $cleanName
            Write-Output $folderName
            return
        }
    }
    #>
    # ====================================================================================
    
    # CURRENT: Always use JSON file for folder naming
    $json = Get-Content $JsonFile | ConvertFrom-Json
    $kpi = $json | Where-Object { $_.KPIId -eq $KPIId }
    
    if ($kpi) {
        $title = Normalize-FolderName -name $kpi.Title
        $folderName = "${kpiIdLower}_${title}"
        Write-Output $folderName
    } else {
        # KPI not found in JSON, just return lowercase KPI ID
        Write-Output $kpiIdLower
    }
    
} catch {
    # On error, return lowercase KPI ID
    Write-Output $KPIId.ToLower()
}
