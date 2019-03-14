Add-Type -Assembly 'System.Drawing'

function GetPixelText ($color) {
    "$([char]27)[48;2;{0};{1};{2}m" -f $color.r, $color.g, $color.b + " " + "$([char]27)[0m"
}

function Out-ConsolePicture {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "FromPath", Position = 0)]
        [Parameter(Mandatory = $true, ParameterSetName = "FromPathNoResize")]
        [ValidateNotNullOrEmpty()][string[]]
        $Path,
        
        [Parameter(Mandatory = $true, ParameterSetName = "FromWeb")]
        [Parameter(Mandatory = $true, ParameterSetName = "FromWebNoResize")]
        [System.Uri[]]$Url,
        
        [Parameter(Mandatory = $true, ParameterSetName = "FromPipeline", ValueFromPipeline = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = "FromPipelineNoResize")]
        [System.Drawing.Bitmap[]]$InputObject,
        
        
        [Parameter(ParameterSetName = "FromPath")]
        [Parameter(ParameterSetName = "FromWeb")]
        [Parameter(ParameterSetName = "FromPipeline")]
        [ValidateNotNullOrEmpty()]
        [int]$Width,

        [Parameter(Mandatory = $true, ParameterSetName = "FromPathNoResize")]
        [Parameter(Mandatory = $true, ParameterSetName = "FromWebNoResize")]
        [Parameter(Mandatory = $true, ParameterSetName = "FromPipelineNoResize")]
        [switch]$DoNotResize,
        
        [Parameter()]
        [switch]$NoAspectCorrection
    )
    
    begin {
        if ($PSCmdlet.ParameterSetName -eq "FromPath") {
            foreach ($file in $Path) {
                try {
                    $image = New-Object System.Drawing.Bitmap -ArgumentList "$(Resolve-Path $file)"
                    $InputObject += $image
                }
                catch {
                    Write-Error "An error occurred while loading image. Supported formats are BMP, GIF, EXIF, JPG, PNG and TIFF."
                }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq "FromWeb") {
            foreach ($uri in $Url) {
                $data = (Invoke-WebRequest $uri).RawContentStream
                $image = New-Object System.Drawing.Bitmap -ArgumentList $data
                $InputObject += $image
            }
        }

        if ($Host.Name -eq "Windows PowerShell ISE Host") {
            # ISE neither supports ANSI, nor reports back a width for resizing.
            Write-Warning "ISE does not support ANSI colors. No images for you. Sorry! :("
            Break
        }
    }
    
    process {
        $InputObject | ForEach-Object {
            if ($_ -is [System.Drawing.Bitmap]) {
                # Resize image to console width if needed
                
                if ($width -or ($_.Width -gt $host.UI.RawUI.WindowSize.Width) -and -not $DoNotResize) {
                    if ($width) {
                        $new_width = $width
                    } else {
                        $new_width = $host.UI.RawUI.WindowSize.Width
                    }
                    $new_height = $_.Height / ($_.Width / $new_width)
                    $resized_image = New-Object System.Drawing.Bitmap -ArgumentList $_, $new_width, $new_height
                    $_.Dispose()
                    $_ = $resized_image
                }
                $color_string = New-Object System.Text.StringBuilder
                for ($y = 0; $y -lt $_.Height; $y++) {
                    if ($y % 2) {
                        if (-not $NoAspectCorrection) {
                            continue
                        }
                    }
                    else {
                        [void]$color_string.append("`n")
                    }
                    for ($x = 0; $x -lt $_.Width; $x++) {
                        $pixel = GetPixelText $_.GetPixel($x, $y)
                        [void]$color_string.Append($pixel)
                    }
                }
                $color_string.ToString()
                $_.Dispose()
            }
        }
    }
    
    end {
    }
    <#
.SYNOPSIS
    Renders an image to the console
.DESCRIPTION
    Out-ConsolePicture will take an image file and convert it to a text string. Colors will be "encoded" using ANSI escape strings. The final result will be output in the shell. By default images will be reformatted to the size of the current shell, though this behaviour can be suppressed with the -DoNotResize switch. ISE users, take note: ISE does not report a window width, and scaling fails as a result. I don't think there is anything I can do about that, so either use the -DoNotResize switch, or don't use ISE.
.PARAMETER Path
One or more paths to the image(s) to be rendered to the console.
.PARAMETER Url
One or more Urls for the image(s) to be rendered to the console.
.PARAMETER InputObject
A Bitmap object that will be rendered to the console.
.PARAMETER DoNotResize
By default, images will be resized to have their width match the current console width. Setting this switch disables that behaviour.
.PARAMETER NoAspectCorrection
By default only every other line in the image will be rendered, due to most console fonts using an spect ratio of 1:2. Setting this switch causes the entire image to be rendered. Unless a font with an aspect ratio close to 1:1 is used this will look stretched.

.EXAMPLE
    Out-ConsolePicture ".\someimage.jpg"
    Renders the image to console

.EXAMPLE
    Out-ConsolePicture -Url "http://somewhere.com/image.jpg"
    Renders the image to console

.EXAMPLE
    $image = New-Object System.Drawing.Bitmap -ArgumentList "C:\myimages\image.png"
    $image | Out-ConsolePicture
    Creates a new Bitmap object from a file on disk renders it to the console

.INPUTS
    One or more System.Drawing.Bitmap objects
.OUTPUTS
    Gloriously coloured console output
#>
}

