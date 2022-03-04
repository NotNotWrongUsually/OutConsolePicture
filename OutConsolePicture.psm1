Add-Type -Assembly 'System.Drawing'

function GetPixelText ($color_fg, $color_bg) {
    "$([char]27)[38;2;{0};{1};{2}m$([char]27)[48;2;{3};{4};{5}m" -f $color_fg.r, $color_fg.g, $color_fg.b, $color_bg.r, $color_bg.g, $color_bg.b + [char]9600 + "$([char]27)[0m"
}

function Out-ConsolePicture {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "FromPath", Position = 0)]
        [ValidateNotNullOrEmpty()][string[]]
        $Path,
        
        [Parameter(Mandatory = $true, ParameterSetName = "FromWeb")]
        [System.Uri[]]$Url,
        
        [Parameter(Mandatory = $true, ParameterSetName = "FromPipeline", ValueFromPipeline = $true)]
        [System.Drawing.Bitmap[]]$InputObject,
        
        [Parameter()]        
        [int]$Width,

        [Parameter()]
        [switch]$DoNotResize,

        [Parameter()]
        [int]$AlphaThreshold = 0,

        [Parameter()]
        [ValidateSet("Left","Center","Right")]
        [string]$Align = "Left"
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
                try {
                    $data = (Invoke-WebRequest $uri).RawContentStream    
                }
                catch [Microsoft.PowerShell.Commands.HttpResponseException] {
                    if ($_.Exception.Response.statuscode.value__ -eq 302) {
                        $actual_location = $_.Exception.Response.Headers.Location.AbsoluteUri
                        $data = (Invoke-WebRequest $actual_location).RawContentStream    
                    }
                    else {
                        throw $_
                    }                 
                }
                
                try {
                    $image = New-Object System.Drawing.Bitmap -ArgumentList $data
                    $InputObject += $image
                }
                catch {
                    Write-Error "An error occurred while loading image. Supported formats are BMP, GIF, EXIF, JPG, PNG and TIFF."
                }
            }
        }

        if ($Host.Name -eq "Windows PowerShell ISE Host") {
            # ISE neither supports ANSI, nor reports back a width for resizing.
            Write-Warning "ISE does not support ANSI colors. No images for you. Sorry! :("
            Break
        }

        $AlphaLevelConsideredTransparent = $AlphaThreshold
    }
    
    process {
        $line_break_char = "`n"
        $InputObject | ForEach-Object {
            if ($_ -is [System.Drawing.Bitmap]) {
                # Resize image to console width or width parameter
                if ($width -or (($_.Width -gt $host.UI.RawUI.WindowSize.Width) -and -not $DoNotResize)) {
                    if ($width) {
                        $new_width = $width
                    }
                    else {
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
                        continue
                    }
                    else {
                        [void]$color_string.append($line_break_char)
                    }
                    # If https://github.com/PowerShell/PowerShell/issues/8482 ever gets fixed, the below should return
                    # to calling the GetPixelText function, like God intended.
                    for ($x = 0; $x -lt $_.Width; $x++) {
                        if (($y + 2) -gt $_.Height) {
                            # We are now on the last row. The bottom half of it in images with uneven pixel height
                            $pixel = " "
                        }
                        else {
                            #$pixel = GetPixelText $_.GetPixel($x, $y) $_.GetPixel($x, $y + 1)
                            $color_fg = $_.GetPixel($x, $y)
                            if($color_fg.A -lt $AlphaLevelConsideredTransparent){
                                $pixel = " "
                            }
                            else{
                                $color_bg = $_.GetPixel($x, $y + 1)
                                $pixel = "$([char]27)[38;2;{0};{1};{2}m$([char]27)[48;2;{3};{4};{5}m" -f $color_fg.r, $color_fg.g, $color_fg.b, $color_bg.r, $color_bg.g, $color_bg.b + [char]9600 + "$([char]27)[0m"
                            }
                        }

                        [void]$color_string.Append($pixel)
                    }
                }

                # Write the colors to the console

                switch ($Align) {
                    "Left" {
                        # Left is the default
                        $color_string.ToString()
                    }
                    "Right" {
                        # Add spaces each line to push to right of buffer
                        $screen_width = $Host.UI.RawUI.BufferSize.Width;
                        $image_width = $new_width;
                        $padding = $screen_width - $image_width;
                        $color_string.ToString().Split($line_break_char) | % {
                            Write-Host (" "*$padding + $_)
                        }
                    }
                    "Center" {
                        # Add spaces each line to push to center of buffer
                        $screen_width = $Host.UI.RawUI.BufferSize.Width / 2;
                        $image_width = $new_width / 2;
                        $padding = $screen_width - $image_width + 1;
                        $color_string.ToString().Split($line_break_char) | % {
                            Write-Host (" "*$padding + $_)
                        }
                    }
                }

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
.PARAMETER Width
Renders the image at this specific width. Use of the width parameter overrides DoNotResize.
.PARAMETER AlphaThreshold
Default 0; Pixels with an alpha value less than this are rendered as fully transparent. Fully opaque = 255. Start raising above 0 to turn more pixels fully transparent.
.PARAMETER Align
Default 'Left'; Align image to the Left, Right, or Center of the terminal.

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

