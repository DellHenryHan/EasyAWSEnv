Function Make-CfFile {
	[CmdletBinding()]  
    Param( 
        [Parameter(Mandatory=$True)]  
        [string]$iniFile,
        [Hashtable]$extraParam=@{},
        [string]$outFile="$env:temp\temp.json",
        [string]$templatePath=$PSScriptRoot+"\templates",
		[string]$description="Template composed by easyawsenv"
    )
    $Sections=Get-InstanceSections $iniFile $extraParam
    $jsonContent=@()
    $jsonContent+='{'
    $jsonContent+='    "AWSTemplateFormatVersion": "2010-09-09",'
    $jsonContent+='    "Description": "'+$description+'",'
    $jsonContent+='    "Resources": {'
    foreach($k in $Sections.Keys){
        try{
            $jsonContent+=(Collect-InstanceInfo -Key $k -Section $Sections[$k] -templatePath $templatePath)
        }
        catch [Exception]{
            $_.Exception.message
            return
        }
    }
    $jsonContent[$jsonContent.Count-1]=$jsonContent[$jsonContent.Count-1].TrimEnd(",")
    $jsonContent+="    }"
    $jsonContent+="}"
    $jsonContent|Out-File $outFile -Encoding ascii
}

Function Get-InstanceSections{
	Param( 
        [Parameter(Mandatory=$True)]  
        [string]$iniFile,
        [Hashtable]$extraParam
    )
	$iniContent=Get-IniContent $iniFile
	if(-not $iniContent["GLOBAL"]){
        $iniContent["GLOBAL"]=@{}
    }
	if($extraParam.Count -gt 0){
		$extraParam.Keys|%{$iniContent[$_]=$extraParam[$_]}
	}
	$globalContent=$iniContent["GLOBAL"]
    $iniContent.Remove("GLOBAL")
	foreach($k in $globalContent.keys){
        $iniContent.Keys|%{if(-not $iniContent[$_].ContainsKey($k)){$iniContent[$_][$k]=$globalContent[$k]}}
    }
	foreach($Section in $iniContent.keys){
		$iniContent[$Section]["ResourceName"]=$Section.replace("._","")
        $EnvVariables=@()
		$iniContent[$Section].Keys|%{$replaced=$iniContent[$Section][$_].replace('\','\\').replace('"','\"').replace("'","''");$EnvVariables+="""[Environment]::SetEnvironmentVariable('$_','$replaced','Machine')"",`n"}
		if($iniContent[$Section]["DC"]){
			$iniContent[$Section]["FetchDcIp"]='{ "Fn::Join": ["", ["[Environment]::SetEnvironmentVariable(''DcIp'',''",{"Fn::GetAtt": ["'+$iniContent[$Section]["DC"]+'", "PrivateIp"]},"'',''Machine'')"]]},'
		}
		else{
			$iniContent[$Section]["FetchDcIp"]=""
		}
		if(-not $iniContent[$Section]["InstanceName"]){
			$iniContent[$Section]["InstanceName"]=""
		}
		if(-not $iniContent[$Section]["InstanceRoleProfile"]){
			$iniContent[$Section]n["InstanceRoleProfile"]='""'
		}
		$iniContent[$Section]["EnvVariables"]=$EnvVariables
    }
	return $iniContent
}

Function Collect-InstanceInfo{
    Param(
        [Parameter(Mandatory=$True)]
        [string]$key,
        [HashTable]$Section, 
        [string]$templatePath
    )
    $templateContent=Get-Content "$templatePath\$($Section['Role'])"
    $Section.Keys|%{$key=$_;$templateContent=($templateContent|%{$_.replace("#{$key}",$Section[$key])})}
    $matchItems=$templateContent -join "`n"| select-string -Pattern "#\{(.*)\}" -AllMatches | % { $_.Matches } |%{$_.Groups[1].value}
    if($matchItems){
        throw "The following items need to be replaced in templates for $($Section["ComputerName"]) :$matchItems"
    }
    return $templateContent
}

Function Get-IniContent {     
    [CmdletBinding()]  
    Param(  
        [ValidateNotNullOrEmpty()]  
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]  
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]  
        [string]$FilePath  
    )  
      
    Begin  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}  
          
    Process  
    {  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"  
              
        $ini = @{}  
        switch -regex -file $FilePath  
        {  
            "^\[(.+)\]$" # Section  
            {  
                $section = $matches[1]  
                $ini[$section] = @{}  
                $CommentCount = 0  
            }  
            "^(;.*)$" # Comment  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $value = $matches[1]  
                $CommentCount = $CommentCount + 1  
                $name = "Comment" + $CommentCount  
                $ini[$section][$name] = $value  
            }   
            "(.+?)\s*=\s*(.*)" # Key  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $name,$value = $matches[1..2]  
                $ini[$section][$name] = $value  
            }  
        }  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"  
        Return $ini  
    }  
          
    End  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}  
}