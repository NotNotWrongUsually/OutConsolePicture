Add-Type -Assembly 'System.Drawing'

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
        [int]$AlphaThreshold = 255,

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
    }
    
    process {
		# Character used to cause a line break
        $line_break_char = "`n"
		
		# For each image
        $InputObject | ForEach-Object {
			
			# If it's a recognized bitmap
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
				
				# For each row of pixels in image
                for ($y = 0; $y -lt $_.Height; $y++) {
                    if ($y % 2) {
						# Skip over even rows because we process them in pairs of odds only
                        continue
                    }
                    else {
						if($y -gt 0) {
							# Add linebreaks after every row, if we're not on the first row
							[void]$color_string.append($line_break_char)
						}
                    }
					
					# For each pixel (and its corresponding pixel below)
                    for ($x = 0; $x -lt $_.Width; $x++) {
						
						# Reset variables
						$fg_transparent, $bg_transparent = $false, $false
						$color_bg, $color_fg = $null, $null
						$pixel = ""
						
						# Determine foreground color and transparency state
						$color_fg = $_.GetPixel($x, $y)
						if($color_fg.A -lt $AlphaThreshold){
							$fg_transparent = $true
						}
						
						# Check if there's even a pixel below to work with
                        if (($y + 2) -gt $_.Height) {
							# We are on the last row. There's not.
                            # There is no pixel below, and so treat the background as transparent
							$bg_transparent = $true
						}
						else{
							# There is a pixel below
							# Determine background color and transparency state
							$color_bg = $_.GetPixel($x, $y + 1)
							if($color_bg.A -lt $AlphaThreshold){
								$bg_transparent = $true
                            }
						}
						
						# If both top/bottom pixels are transparent, just use an empty space as a fully "transparent" pixel pair
						if($fg_transparent -and $bg_transparent){
							$pixel = " "
						}
						# Otherwse determine which to render and which not to render
						else{
							# The two types of characters to use
							$top_half_char = [char]9600	# In which the foreground is on top
							$bottom_half_char = [char]9604 # In which the foreground is on the bottom
							
							# Use the top character as the foreground by default
							$character_to_use = $top_half_char
							
							# If our top character is transparent but bottom isnt, we can't render the foreground as transparent and also have a background.
							if($fg_transparent -and -not $bg_transparent){
								# We need to flip the logic, so
								
								# So use the bottom-half char to render instead
								$character_to_use = $bottom_half_char
								
								# Invert the colors
								$color_fg = $color_bg
								
								# Invert the known transparent states
								$fg_transparent = $false
								$bg_transparent = $true
							}
							
							# If the fg (top pixel) is not transparent, give it a character with color
							if(-not $fg_transparent){
								# Draw a foreground
								$pixel += "$([char]27)[38;2;{0};{1};{2}m" -f $color_fg.r, $color_fg.g, $color_fg.b
							}
							# If the bg (bottom pixel) is not transparent, give it a character with color
							if(-not $bg_transparent){
								# Draw a background
								$pixel += "$([char]27)[48;2;{0};{1};{2}m" -f $color_bg.r, $color_bg.g, $color_bg.b
							}
							
							# Add the actual character to render
							$pixel += $character_to_use
							
							# Reset the style to prepare for the next pixel
							$pixel += "$([char]27)[0m"
						}                            

						# Add the pixel-pair to the string builder
                        [void]$color_string.Append($pixel)
                    }
                }

                # Write the colors to the console based on alignment
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
Default 255; Pixels with an alpha (opacity) value less than this are rendered as fully transparent. Fully opaque = 255. Lowering the value will require a pixel to be more transparent to vanish, and will therefor include more pixels.
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
