<#
.SYNOPSIS
.DESCRIPTION
.PARAMETER
.EXAMPLE
	C:\PS> Get-Process | Sort-Object -Property WS | Select-Object Name,WS -Last 5  | out-chart -xField 'name' -yField 'WS'
	
	Description 
    ----------- 
	Create a bar chart (which is the default option) from the first file 5 entries of Get-Process with the Name as the X filed  and the Working set as the Y field
.EXAMPLE
	C:\PS> Get-Process | Sort-Object -Property WS | Select-Object Name,WS -Last 5 | out-chart -xField 'name' -yField 'WS' -filename 'c:\users\u00\documents\process.png'

	Description 
    ----------- 
	Create a bar chart (which is the default option) from the first file 5 entries of Get-Process with the Name as the X filed and the Working set as the Y field and then save the file to the directory 'c:\users\u00\documents\process.png'

.EXAMPLE
	C:\PS> Get-Process | Sort-Object -Property WS | Select-Object Name,WS -Last 5  | out-chart -xField 'name' -yField 'WS' -chartType 'Pie'
	
	Description 
    ----------- 
	Create a Pie from the first file 5 entries of Get-Process with the Name as the X filed  and the Working set as the Y field
.EXAMPLE
	C:\PS> out-chart -xField 'name' -yField 'WS' -scriptBlock {Get-Process | Sort-Object -Property WS | Select-Object Name,WS -Last 1} -chartType 'line'
	
	Description 
    ----------- 
	NEEDS TESTING
.NOTES  
	Adapteded from Chad Miller at Poshcode.org
.LINK


#Requires -Version 2.0 
#>


[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")


function New-Chart
{
    param (
		[int]$width,
		[int]$height,
		[int]$left,
		[int]$top,
		[int]$chartTitle,
		[Switch]$Transparent
	)
    #create chart object 
    $global:Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart 
    $global:Chart.Width = $width 
    $global:Chart.Height = $height 
    $global:Chart.Left = $left 
    $global:Chart.Top = $top
	
   	#create a chartarea to draw on and add to chart 
    $chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea 
    $global:chart.ChartAreas.Add($chartArea)

    If ($chartTitle) {
		[void]$global:Chart.Titles.Add($chartTitle)
	}

    #change chart area colour
	#This messes with the save option since it clears out any text outside of the Chart
	# 
	if ($Transparent) {
    	$global:Chart.BackColor = [System.Drawing.Color]::Transparent
	}

} 

#######################
function New-BarColumnChart
{
    param ([hashtable]$ht, $chartType='Column', $chartTitle,$xTitle,$yTitle, [int]$width,[int]$height,[int]$left,[int]$top,[bool]$asc)

    New-Chart -width $width -height $height -left $left -top $top -chartTile $chartTitle

    $chart.ChartAreas[0].AxisX.Title = $xTitle
    $chart.ChartAreas[0].AxisY.Title = $yTitle

    [void]$global:Chart.Series.Add("Data")
    $global:Chart.Series["Data"].Points.DataBindXY($ht.Keys, $ht.Values)

    $global:Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::$chartType

    if ($asc)
    { $global:Chart.Series["Data"].Sort([System.Windows.Forms.DataVisualization.Charting.PointSortOrder]::Ascending, "Y") }
    else
    { $global:Chart.Series["Data"].Sort([System.Windows.Forms.DataVisualization.Charting.PointSortOrder]::Descending, "Y") }
    
    $global:Chart.Series["Data"]["DrawingStyle"] = "Cylinder"
    $global:chart.Series["Data"].IsValueShownAsLabel = $true
    $global:chart.Series["Data"]["LabelStyle"] = "Top"


} #New-BarColumnChart

#######################
function New-LineChart
{

    param ([hashtable]$ht,$chartTitle, [int]$width,[int]$height,[int]$left,[int]$top)

    New-Chart -width $width -height $height -left $left -top $top -chartTile $chartTitle

    [void]$global:Chart.Series.Add("Data")
    $global:Chart.Series["Data"].Points.DataBindY($ht.Values)

    $global:Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
    $global:chart.Series["Data"].IsValueShownAsLabel = $false

} #New-LineChart

#######################
function New-PieChart
{

    param ([hashtable]$ht,$chartTitle, [int]$width,[int]$height,[int]$left,[int]$top)

    New-Chart -width $width -height $height -left $left -top $top -chartTile $chartTitle

    [void]$global:Chart.Series.Add("Data")
    $global:Chart.Series["Data"].Points.DataBindXY($ht.Keys, $ht.Values)

    $global:Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie

    $global:Chart.Series["Data"]["PieLabelStyle"] = "Outside" 
    $global:Chart.Series["Data"]["PieLineColor"] = "Black" 
	$global:Chart.Series["Data"]["PieDrawingStyle"] = "Concave" 
    $global:chart.Series["Data"].IsValueShownAsLabel = $true
    $global:chart.series["Data"].Label =  "#PERCENT{P1}"
    $legend = New-object System.Windows.Forms.DataVisualization.Charting.Legend
    $global:Chart.Legends.Add($legend)
    $Legend.Name = "Default"

} #New-PieChart  

#######################
function Remove-Points
{
    param($name='Data',[int]$maxPoints=200)
    
    while ( $global:chart.Series["$name"].Points.Count > $maxPoints )
    { $global:chart.Series["$name"].Points.RemoveAT(0) }

} #Add-Series

#######################
function Out-Form
{
    param($interval,$scriptBlock,$xField,$yField)

    # display the chart on a form 
    $global:Chart.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right -bor 
                    [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left 
    $Form = New-Object Windows.Forms.Form 
    $Form.Text = 'PowerCharts'
    $Form.Width = 600
    $Form.Height = 600 
    $Form.controls.add($global:Chart)
    if ($scriptBlock -is [ScriptBlock])
    { 
        if (!($xField -or $yField))
        { throw 'xField and yField required with scriptBlock parameter.' }
        $timer = New-Object System.Windows.Forms.Timer 
        $timer.Interval = $interval
        $timer.add_Tick({
 
        $ht = &$scriptBlock | ConvertTo-HashTable $xField $yField
        if ($global:Chart.Series["Data"].ChartTypeName -eq 'Line')
        {
            Remove-Points
            #$ht | foreach { $global:Chart.Series["Data"].Points.AddXY($($_.Keys), $($_.Values)) }               
            $ht | foreach { $global:Chart.Series["Data"].Points.AddY($ht[$xField]) }               
        }
        else
        { $global:Chart.Series["Data"].Points.DataBindXY($ht.Keys, $ht.Values) }
        $global:chart.ResetAutoValues()
        $global:chart.Invalidate()
 
        })
        $timer.Enabled = $true
        $timer.Start()
        
    }
    $Form.Add_Shown({$Form.Activate()}) 
    $Form.ShowDialog()

} #Out-Form

#######################
function Out-ImageFile
{
    param($fileName,$fileformat)

    $global:Chart.SaveImage($fileName,$fileformat)
}
#######################
### ConvertTo-Hashtable function based on code by Jeffery Snover
### http://blogs.msdn.com/powershell/archive/2008/11/23/poshboard-and-convertto-hashtable.aspx 
#######################
function ConvertTo-Hashtable
{ 
    param([string]$key, $value) 

    Begin 
    { 
        $hash = @{} 
    } 
    Process 
    { 
        $thisKey = $_.$Key
        $hash.$thisKey = $_.$Value 
    } 
    End 
    { 
        Write-Output $hash 
    }

} #ConvertTo-Hashtable

#######################
function Out-Chart
{
    param(  $xField=$(throw 'Out-Chart:xField is required'),
            $yField=$(throw 'Out-Chart:yField is required'), 
            $chartType='Column',$chartTitle,
            [int]$width=500,
            [int]$height=400,
            [int]$left=40,
            [int]$top=30,
            $filename,
            $fileformat='png',
            [int]$interval=1000,
            $scriptBlock,
            [switch]$asc
        )

    Begin
    {
        $ht = @{}
    }
    Process
    {
       if ($_)
       {
        $thisKey = $_.$xField
        $ht.$thisKey = $_.$yField 
       }
    }
    End
    {
        if ($scriptBlock)
        { $ht = &$scriptBlock | ConvertTo-HashTable $xField $yField }
        switch ($chartType)
        {
            'Bar' {New-BarColumnChart -ht $ht -chartType $chartType -chartTitle $chartTitle -width $width -height $height -left $left -top $top -asc $($asc.IsPresent)}
            'Column' {New-BarColumnChart -ht $ht -chartType $chartType -chartTitle $chartTitle -width $width -height $height -left $left -top $top -asc $($asc.IsPresent)}
            'Pie' {New-PieChart -chartType -ht $ht  -chartTitle $chartTitle -width $width -height $height -left $left -top $top }
            'Line' {New-LineChart -chartType -ht $ht -chartTitle $chartTitle -width $width -height $height -left $left -top $top }

        }

        if ($filename)
        { Out-ImageFile $filename $fileformat }
        elseif ($scriptBlock )
        { Out-Form $interval $scriptBlock $xField $yField }
        else
        { Out-Form }
    }

} #Out-Chart
