# OutConsolePicture
Powershell cmdlet for rendering image files to console

# How to install?
The module is published to the Powershell Gallery, so get it from there with `Install-Module -Name OutConsolePicture`

# Result
![Dandelion](https://i.imgur.com/80gucpA.png)

# Documentation

Straight from the module help:

```
NAME
    Out-ConsolePicture

SYNOPSIS
    Renders an image to the console


SYNTAX
    Out-ConsolePicture [-Path] <String[]> [-Width <Int32>] [-TransparencyColor <Color>] [-HorizontalPosition <String>] [-DoNotResize] [<CommonParameters>]

    Out-ConsolePicture -Url <Uri[]> [-Width <Int32>] [-TransparencyColor <Color>] [-HorizontalPosition <String>] [-DoNotResize] [<CommonParameters>]

    Out-ConsolePicture -InputObject <Bitmap[]> [-Width <Int32>] [-TransparencyColor <Color>] [-HorizontalPosition <String>] [-DoNotResize] [<CommonParameters>]


DESCRIPTION
    Out-ConsolePicture will take an image file and convert it to a text string. Colors will be "encoded" using ANSI escape strings. The final result will be output in the shell. By
    default images will be reformatted to the size of the current shell, though this behaviour can be suppressed with the -DoNotResize switch. ISE users, take note: ISE does not report
    a window width, and scaling fails as a result. I don't think there is anything I can do about that, so either use the -DoNotResize switch, or don't use ISE.


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

    -Width <Int32>
        Renders the image at this specific width. Use of the width parameter overrides DoNotResize.

        Required?                    false
        Position?                    named
        Default value                0
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -TransparencyColor <Color>
        If the image is transparent this is the color that will be used for transparency. The parameter needs a color object. Check examples for how to set it. This should be the same
        color as your console background usually.

        Required?                    false
        Position?                    named
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -HorizontalPosition <String>
        Takes the values "Left", "Center", or "Right" and renders the image in that position.

        Required?                    false
        Position?                    named
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -DoNotResize [<SwitchParameter>]
        By default, images will be resized to have their width match the current console width. Setting this switch disables that behaviour.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).

INPUTS
    One or more System.Drawing.Bitmap objects


OUTPUTS
    Gloriously coloured console output


    -------------------------- EXAMPLE 1 --------------------------

    PS > Out-ConsolePicture ".\someimage.jpg"
    Renders the image to console






    -------------------------- EXAMPLE 2 --------------------------

    PS > Out-ConsolePicture -Url "http://somewhere.com/image.jpg"
    Renders the image to console






    -------------------------- EXAMPLE 3 --------------------------

    PS > $image = New-Object System.Drawing.Bitmap -ArgumentList "C:\myimages\image.png"
    $image | Out-ConsolePicture
    Creates a new Bitmap object from a file on disk renders it to the console






    -------------------------- EXAMPLE 4 --------------------------

    PS > Out-ConsolePicture ".\someimage.jpg" -TransparencyColor ([System.Drawing.Color]::FromArgb(40, 44, 52))
    Renders a transparent image using the specified color for transparency.







RELATED LINKS
```

# License
You can copy it, change it, or stick it in your hat;
But never charge a penny for it - simple as that!