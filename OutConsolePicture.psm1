Add-Type -Assembly 'System.Drawing'

function GetPixelText ($color_fg, $color_bg) {
    "`e[38;2;{0};{1};{2}m`e[48;2;{3};{4};{5}m" -f $color_fg.r, $color_fg.g, $color_fg.b, $color_bg.r, $color_bg.g, $color_bg.b + [char]9600 + "`e[0m"
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
        [System.Drawing.Color]$TransparencyColor,

        [Parameter()]
        [ValidateSet("Left", "Center", "Right")]
        [string]$HorizontalPosition,

        [Parameter()]
        [switch]$DoNotResize
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
    }
    
    process {
        $InputObject | ForEach-Object {
            if ($_ -is [System.Drawing.Bitmap]) {
                
                # Do alpha blending if the image supports it
                if ([System.Drawing.Image]::IsAlphaPixelFormat($_.pixelformat)) {
                    # Respect the transparency color if manually set
                    if ($TransparencyColor) {
                        $transparency_color = $TransparencyColor
                    } else {
                        # Default to using "One Half Dark" background
                        $transparency_color = [System.Drawing.Color]::FromArgb(40, 44, 52)
                    }
                    # Create a balnk bitmap, same size as our image. Colour it with the desired alpha colour
                    # and then draw our image on top of it. Pass along the modified image.
                    $base = New-Object System.Drawing.Bitmap -ArgumentList $_.Width, $_.Height
                    $gfx_object = [System.Drawing.Graphics]::FromImage($base)
                    $gfx_object.Clear($transparency_color)
                    $gfx_object.DrawImage($_, 0, 0)
                    $_ = $base
                }

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

                # Extracting for performance purposes, so we don't have to access properties in a heavy loop later
                $img_width = $_.Width
                $img_height = $_.Height

                # Figure out where to place the image if positioning was specified
                switch ($HorizontalPosition) {
                    "Left" { $pos_x = 0 }
                    "Center" { $pos_x = [Math]::Floor(($host.UI.RawUI.WindowSize.Width - $img_width) / 2) }
                    "Right" { $pos_x = $host.UI.RawUI.WindowSize.Width - $img_width }
                    Default { $pos_x = 0 }
                }       

                $color_string = New-Object System.Text.StringBuilder

                for ($y = 0; $y -lt $img_height; $y++) {
                    if ($y % 2) {
                        continue
                    }
                    else {
                        [void]$color_string.append("`n`e[$($pos_x)G")
                    }
                    # If https://github.com/PowerShell/PowerShell/issues/8482 ever gets fixed, the below should return
                    # to calling the GetPixelText function, like God intended.
                    for ($x = 0; $x -lt $img_width; $x++) {
                        if (($y + 2) -gt $img_height) {
                            # We are now on the last row. The bottom half of it in images with uneven pixel height
                            # should just be coloured like the background of the console.
                            $color_fg = $_.GetPixel($x, $y)
                            $color_bg = [System.Drawing.Color]::FromName($Host.UI.RawUI.BackgroundColor)
                            $pixel = "`e[38;2;{0};{1};{2}m`e[48;2;{3};{4};{5}m" -f $color_fg.r, $color_fg.g, $color_fg.b, $color_bg.r, $color_bg.g, $color_bg.b + [char]9600 + "`e[0m"
                            [void]$color_string.Append($pixel)
                        }
                        else {
                            #$pixel = GetPixelText $_.GetPixel($x, $y) $_.GetPixel($x, $y + 1)
                            $color_fg = $_.GetPixel($x, $y)
                            $color_bg = $_.GetPixel($x, $y + 1)
                            $pixel = "`e[38;2;{0};{1};{2}m`e[48;2;{3};{4};{5}m" -f $color_fg.r, $color_fg.g, $color_fg.b, $color_bg.r, $color_bg.g, $color_bg.b + [char]9600 + "`e[0m"
                            [void]$color_string.Append($pixel)
                        }
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
.PARAMETER Width
Renders the image at this specific width. Use of the width parameter overrides DoNotResize.
.PARAMETER HorizontalPosition
Takes the values "Left", "Center", or "Right" and renders the image in that position.
.PARAMETER TransparencyColor
If the image is transparent this is the color that will be used for transparency. The parameter needs a color object. Check examples for how to set it. This should be the same color as your console background usually.

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

.EXAMPLE
    Out-ConsolePicture ".\someimage.jpg" -TransparencyColor ([System.Drawing.Color]::FromArgb(40, 44, 52))
    Renders a transparent image using the specified color for transparency.

.INPUTS
    One or more System.Drawing.Bitmap objects
.OUTPUTS
    Gloriously coloured console output
#>
}

