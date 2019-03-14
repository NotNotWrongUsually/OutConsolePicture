# OutConsolePicture
Powershell cmdlet for rendering image files to console

# How to install?
The module is published to the Powershell Gallery, so get it from there with `Install-Module -Name OutConsolePicture`

# Documentation

Straight from the module help:

```
NAME
    Out-ConsolePicture

SYNOPSIS
    Renders an image to the console


SYNTAX
    Out-ConsolePicture [-Path] <String[]> [-DoNotResize] [-NoAspectCorrection] [<CommonParameters>]

    Out-ConsolePicture -Url <Uri[]> [-DoNotResize] [-NoAspectCorrection] [<CommonParameters>]

    Out-ConsolePicture -InputObject <Bitmap[]> [-DoNotResize] [-NoAspectCorrection] [<CommonParameters>]


DESCRIPTION
    Out-ConsolePicture will take an image file and convert it to a text string. Colors will be "encoded" using ANSI esc
    ape strings. The final result will be output in the shell. By default images will be reformatted to the size of the
     current shell, though this behaviour can be suppressed with the -DoNotResize switch.


PARAMETERS
    -Path <String[]>
        One or more paths to the image(s) to be rendered to the console.

        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Url <Uri[]>
        One or more Urls for the image(s) to be rendered to the console.

        Required?                    true
        Position?                    named
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -InputObject <Bitmap[]>
        A Bitmap object that will be rendered to the console.

        Required?                    true
        Position?                    named
        Default value
        Accept pipeline input?       true (ByValue)
        Accept wildcard characters?  false

    -DoNotResize [<SwitchParameter>]
        By default, images will be resized to have their width match the current console width. Setting this switch dis
        ables that behaviour.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -NoAspectCorrection [<SwitchParameter>]
        By default only every other line in the image will be rendered, due to most console fonts using an spect ratio
        of 1:2. Setting this switch causes the entire image to be rendered. Unless a font with an aspect ratio close to
         1:1 is used this will look stretched.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216).

INPUTS
    One or more System.Drawing.Bitmap objects


OUTPUTS
    Gloriously coloured console output


    -------------------------- EXAMPLE 1 --------------------------

    PS C:\>Out-ConsolePicture ".\someimage.jpg"

    Renders the image to console




    -------------------------- EXAMPLE 2 --------------------------

    PS C:\>Out-ConsolePicture -Url "http://somewhere.com/image.jpg"

    Renders the image to console




    -------------------------- EXAMPLE 3 --------------------------

    PS C:\>$image = New-Object System.Drawing.Bitmap -ArgumentList "C:\myimages\image.png"

    $image | Out-ConsolePicture
    Creates a new Bitmap object from a file on disk renders it to the console





RELATED LINKS
```

# License
You can copy it, change it, or stick it in your hat;
But never charge a penny for it - simple as that!