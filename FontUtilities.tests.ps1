BeforeAll { 
    Import-Module .\FontUtilities.psm1
}

Describe "Install font file" {
    BeforeAll {
        $NonFontFileName = 'foo.txt'
        $FontFileName = 'font.ttf'
        $FontFilePath = "TestDrive:\$FontFileName"
        $FontRegistryEntry = 'font (TrueType)'
        $FontsDestinationDirectory = 'TestDrive:\fonts'
        $FontsDestinationRegistry = 'TestRegistry:\fonts'
    }
    Context "Font is installed" {
        BeforeAll {
            New-Item -Path $FontFilePath -ItemType File

            Install-FontFile -Path $FontFilePath `
                             -Destination $FontsDestinationDirectory `
                             -Registry $FontsDestinationRegistry
        }
        It "<FontFileName> is copied to the <FontsDestinationDirectory>" {
            Test-Path "$FontsDestinationDirectory\$FontFileName" | 
                should -BeTrue -because "$FontFileName should be copied"
        }
        It "<FontFileName> is added to the <FontsDestinationRegistry>" {
            Get-ItemProperty -path $FontsDestinationRegistry |
                Select-object -ExpandProperty $FontRegistryEntry |
                should -be $FontFileName -because 'Registry entry should be created'
        }
        AfterAll {
            Remove-Item -Path $FontsDestinationRegistry, 
                              $FontsDestinationDirectory, 
                              $FontFilePath -Recurse -Force -ErrorAction Ignore
        }
    }

    Context "Throw if font file does not exist" {
        BeforeAll {
            Install-FontFile -Path $FontFilePath `
                             -Destination $FontsDestinationDirectory `
                             -Registry $FontsDestinationRegistry `
                             -ErrorVariable err
        }
        It "There are errors" {
            $err.Count | should -BeGreaterThan 0
        }
        AfterAll {
            Remove-Item -Path $FontsDestinationDirectory,
                              $FontsDestinationRegistry -Recurse -Force -ErrorAction Ignore
        }
    }
    
    Context "Throws if file is not a font file" -Foreach @(
        @{File="TestDrive:\file.json"}
        @{File="TestDrive:\file.txt"}
        @{File="TestDrive:\file.xml"}
    ) {
        BeforeAll{
            New-Item -Path $FontsDestinationDirectory -ItemType Directory
            New-Item -Path $FontsDestinationRegistry, $File -ItemType File
            Install-FontFile -Path $File `
                             -Destination $FontsDestinationDirectory `
                             -Registry $FontsDestinationRegistry `
                             -ErrorVariable err
        }
        It "There should be errors" {
            $err.Count | should -BeGreaterThan 0
        }
        It "'<file>' was not copied to <FontsDestinationDirectory>" {
            Get-ChildItem -Path $FontsDestinationDirectory | should -HaveCount 0
        }
        It "'<file>' was not added to the <FontsDestinationRegistry>" {
            Get-Item -path $FontsDestinationRegistry |
                Select-Object -ExpandProperty Property |
                should -HaveCount 0
        }
        AfterAll {
            Remove-Item -Path $File,
                              $FontsDestinationDirectory, 
                              $FontsDestinationRegistry  -Recurse -Force -ErrorAction Ignore
        }
    }

    Context "Creates location if it doesn't exist" {
        BeforeAll {
            New-Item -Path $FontFilePath -ItemType File

            Install-FontFile -Path $FontFilePath `
                             -Destination $FontsDestinationDirectory `
                             -Registry $FontsDestinationRegistry
        }
        It "<FontsDestinationDirectory> is created automatically" {
            Test-Path -Path $FontsDestinationDirectory | should -beTrue
        }
        It "<FontsDestinationDirectory>\<FontFileName> exists" {
            Test-Path -Path $FontsDestinationDirectory\$FontFileName | should -beTrue
        }
        AfterAll {
            Remove-Item -Path $FontFilePath, 
                              $FontsDestinationRegistry, 
                              $FontsDestinationDirectory -Recurse -Force -ErrorAction Ignore
        }
    }

    Context "Creates Registry key if it doesn't exist" {
        BeforeAll {
            New-Item -Path $FontFilePath -ItemType File
            
            Install-FontFile -Path $FontFilePath `
                             -Destination $FontsDestinationDirectory `
                             -Registry $FontsDestinationRegistry
        }
        It "<FontsDestinationRegistry> is created automatically" {
            Test-Path $FontsDestinationRegistry | should -beTrue -because 'Install-FontFamily should create non existing register key'
        }
        It "<FontRegistryEntry> should be created" {
            Get-ItemProperty -path $FontsDestinationRegistry |
                Select-object -ExpandProperty $FontRegistryEntry |
                should -be $FontFileName -because 'Registry entry should be created if missing'
        }
        AfterAll {
            Remove-Item -Path $FontFilePath, $FontsDestinationRegistry, $FontsDestinationDirectory -Recurse -Force -ErrorAction Ignore        }
    }

    Context "Installs several fonts at once" {
        BeforeAll {
            #region Garbage
            $FontNames = 'font1', 'font2'
            $FontFileNames = foreach ($font in $FontNames) { "$font.ttf" }
            $FontPaths = foreach ($fontFileName in $FontFileNames) { "TestDrive:\$fontFileName" }
            $FontRegistryProperties = foreach ($fontName in $FontNames) { "$fontName (TrueType)" }
            foreach ($fontPath in $FontPaths) { New-Item -Path $fontPath -ItemType File }
            New-Item -Path $FontsDestinationRegistry,
                           $FontsDestinationDirectory -ItemType Directory
            
            #endregion Garbage

            Install-FontFile -Path $FontPaths `
                             -Destination $FontsDestinationDirectory `
                             -Registry $FontsDestinationRegistry
        }

        It "'<FontPaths>' were installed" {
            foreach ($font in $fonts) {
                Test-Path -Path $Location\$font | should -beTrue -because "$font should be installed in the $location"
            }
        }

        It "'<FontPaths> were added to registry" {
            $RegistryItem = Get-ItemProperty $FontsDestinationRegistry
            foreach ($counter in 0..($FontRegistryProperties.Length - 1)) { 
                $RegistryItem |
                    Select-Object -ExpandProperty $FontRegistryProperties[$counter] |
                    should -be $FontFileNames[$counter] -because 'Registry entry should be created'
            }
        }

        AfterAll {
            Remove-Item -Path ($FontPaths +
                               $FontsDestinationRegistry + 
                               $FontsDestinationDirectory) -Recurse -Force -ErrorAction Ignore
        }
    }

    Context "Install several fonts at once. One file is a txt file" {
        BeforeAll {
            #region Garbage
            $nonFileName = 'bar.txt'
            $nonFilePath = "TestDrive:\$nonFileName"

            New-Item -Path $fontFilePath,
                           $nonFilePath -ItemType File
            #endregion Garbage

            Install-FontFile -Path $fontFilePath, $nonFilePath `
                             -Destination $FontsDestinationDirectory `
                             -Registry $FontsDestinationRegistry
        }
        It "<fontName> was installed" {
            Test-Path $FontsDestinationDirectory\$fontFileName | should -beTrue
        }
        It "<FontRegistryEntry> was added to registry" {
            Get-ItemProperty $FontsDestinationRegistry |
                Select-Object -ExpandProperty $FontRegistryEntry |
                should -be $fontFileName -because 'Registry entry should be created'
        }
        It "<registry> does not contain any other stuff" {
            Get-ItemProperty $FontsDestinationRegistry | should -HaveCount 1
        }
        It "<nonFileName> was not installed" {
            Test-Path $FontsDestinationDirectory\$nonFileName |
                should -beFalse -because "Application doesn't install non font files"
        }
        AfterAll {
            Remove-Item -Path $FontsDestinationDirectory, 
                              $FontsDestinationRegistry, 
                              $fontFilePath, 
                              $nonFilePath -Recurse -Force -ErrorAction Ignore
        }
    }

    Context "Install fonts from directory" {
        BeforeAll {
            $FontsSourceDirectory = "TestDrive:\source-directory"
        }

        Context "Folder with a single file" {
            BeforeAll {
                New-Item -Path $FontsSourceDirectory\$fontFileName -Force -ItemType File
    
                Install-FontFile -Path $FontsSourceDirectory `
                                 -Destination $FontsDestinationDirectory `
                                 -Registry $FontsDestinationRegistry `
                                 -ErrorVariable err
            }

            It "No errors" {
                $err.Count | Should -be 0
            }
            
            It "<FontFileName> is installed in the <FontsDestinationDirectory>" {
                Test-Path -Path $FontsDestinationDirectory\$FontFileName | should -beTrue
            }
            
            It "<FontRegistryEntry> is added to <FontsDestinationRegistry>" {
                Get-ItemProperty -path $FontsDestinationRegistry |
                    Select-object -ExpandProperty $FontRegistryEntry |
                    should -be $FontFileName -because 'Registry entry should be created if missing'
            }
            
            AfterAll {
                Remove-Item -Path $FontsDestinationRegistry, 
                                  $FontsSourceDirectory -Recurse -Force -ErrorAction Ignore
            }
        }

        Context "Folder with two font files" {
            BeforeAll {
                $font2Name = 'font2'
                $font2FileName = "$font2Name.ttf"
                $font2RegistryEntry = "$font2Name (TrueType)"

                New-Item -Path $FontsSourceDirectory\$fontFileName,
                               $FontsSourceDirectory\$font2FileName -Force -ItemType File
    
                Install-FontFile -Path $FontsSourceDirectory `
                                 -Destination $FontsDestinationDirectory `
                                 -Registry $FontsDestinationRegistry `
                                 -ErrorVariable err
            }
            It "No errors" {
                $err.Count | Should -be 0
            }
            
            It "<FontFileName> is installed in the <FontsDestinationDirectory>" {
                Test-Path -Path $FontsDestinationDirectory\$FontFileName | should -beTrue
            }
            
            It "<FontRegistryEntry> is added to <FontsDestinationRegistry>" {
                Get-ItemProperty -path $FontsDestinationRegistry |
                    Select-object -ExpandProperty $FontRegistryEntry |
                    should -be $FontFileName -because 'Registry entry should be created if missing'
            }
            It "<Font2FileName> is installed in the <FontsDestinationDirectory>" {
                Test-Path -Path $FontsDestinationDirectory\$Font2FileName | should -beTrue
            }
            
            It "<Font2RegistryEntry> is added to <FontsDestinationRegistry>" {
                Get-ItemProperty -path $FontsDestinationRegistry |
                    Select-object -ExpandProperty $Font2RegistryEntry |
                    should -be $Font2FileName -because 'Registry entry should be created if missing'
            }

            AfterAll {
                Remove-Item -Path $FontsDestinationRegistry, 
                                  $FontsSourceDirectory,
                                  $FontsDestinationDirectory -Recurse -Force -ErrorAction Ignore
            }
        }

        Context "Folder with a font file and a garbage file " {
            BeforeAll {
                $nonFontFile = 'font2.txt'
                New-Item -Path $FontsSourceDirectory\$fontFileName,
                               $FontsSourceDirectory\$nonFontFile -Force -ItemType File
    
                Install-FontFile -Path $FontsSourceDirectory `
                                 -Destination $FontsDestinationDirectory `
                                 -Registry $FontsDestinationRegistry `
                                 -ErrorVariable err
            }
            It "No errors" {
                $err.Count | Should -be 0
            }
            
            It "<FontFileName> is installed in the <FontsDestinationDirectory>" {
                Test-Path -Path $FontsDestinationDirectory\$FontFileName | 
                    should -beTrue -Because "$FontFileName was copied to the $FontsDestinationDirectory"
            }
            
            It "<FontRegistryEntry> is added to <FontsDestinationRegistry>" {
                Get-ItemProperty -path $FontsDestinationRegistry |
                    Select-object -ExpandProperty $FontRegistryEntry |
                    should -be $FontFileName -because 'Registry entry should be created if missing'
            }
            It "<nonFontFile> is not installed in the <FontsDestinationDirectory>" {
                Test-Path -Path $FontsDestinationDirectory\$nonFontFile | 
                    should -BeFalse -Because "$nonFontFile was not copied to the $FontsDestinationDirectory"
            }
            
            It "<FontsDestinationRegistry> contains no garbage" {
                Get-Item -path $FontsDestinationRegistry |
                    Select-Object -ExpandProperty Property |
                    should -HaveCount 1
            }

            AfterAll {
                Remove-Item -Path $FontsDestinationRegistry,
                                  $FontsDestinationDirectory,
                                  $FontsSourceDirectory -Recurse -Force -ErrorAction Ignore
            }
        }
    }

    Context "Download fonts" {
        BeforeAll {
            $job = Start-Job -Verbose -ScriptBlock { 
                param($path)
                python -m http.server 8000 -d $path 
            } -ArgumentList $TestDrive
            $server = "http://localhost:8000"
        }
        Context "A valid link" {
            BeforeAll {
                $NonFontFileName = 'test.txt'
                $NonFontFilePath = "$TestDrive\$NonFontFileName"
                $FontZipName = 'TestFont.zip'
                $FontZipPath = "$TestDrive\$FontZipName"
                $url = "$server/$FontZipName"
                
                New-Item -Path $FontFilePath, 
                               $NonFontFilePath -ItemType File
                Compress-Archive -Path $FontFilePath, $NonFontFilePath -DestinationPath $FontZipPath
                Install-FontFile -Registry $FontsDestinationRegistry `
                                 -Destination $FontsDestinationDirectory `
                                 -Url $url `
                                 -ErrorVariable err
            }
            It "No errors should happen" {
                $err | Should -HaveCount 0 
            }
            It "<FontFileName> is installed to <FontsDestinationDirectory>" {
                Test-Path "$FontsDestinationDirectory\$FontFileName" | should -beTrue
            }
            It "<FontRegistryEntry> is added to <FontsDestinationRegistry>" {
                Get-ItemProperty -path $FontsDestinationRegistry |
                Select-object -ExpandProperty $FontRegistryEntry |
                should -be $FontFileName -because 'Registry entry should be created if missing'
            }
            AfterAll {
                Remove-Item -Path $FontFilePath,
                                  $NonFontFilePath, 
                                  $FontFilePath, 
                                  $FontsDestinationDirectory, 
                                  $FontsDestinationRegistry -Recurse -Force -ErrorAction Ignore
            }
        }   
        Context "An invalid link" {
            BeforeAll {
                $NonExistingFile = "NonExistingFont_$([guid]::NewGuid()).ttf"
                $url = "$Server/$NonExistingFile"
                
                Install-FontFile -Registry $FontsDestinationRegistry `
                                 -Destination $FontsDestinationDirectory `
                                 -Url $url `
                                 -ErrorVariable err
            }
            It "A error should occur" {
                $err.Count | should -BeGreaterThan 0
            }
            AfterAll {
                Remove-Item -Path $FontsDestinationDirectory,
                                  $FontsDestinationRegistry -Recurse -Force -ErrorAction Ignore
            }
        }
        Context "A non zip file" {
            BeforeAll {
                $url = "$Server/$NonFontFileName"
                New-Item -Path $TestDrive\$NonFontFileName -ItemType File -Force
                Install-FontFile -Registry $FontsDestinationRegistry `
                                 -Destination $FontsDestinationDirectory `
                                 -Url $url `
                                 -ErrorVariable err `
                                 -ErrorAction Ignore
            }
            It "A error should occur" {
                $err.Count | should -BeGreaterThan 0
            }
            It "<FontsDestinationDirectory> should not exists"{
                Test-Path $FontsDestinationDirectory | Should -BeFalse
            }
            It "<FontsDestinationRegistry> should not exist" {
                Test-Path $FontsDestinationRegistry | should -BeFalse
            }
            AfterAll {
                Remove-Item -Path $FontsDestinationDirectory,
                                  $TestDrive\$NonFontFileName,
                                  $FontsDestinationRegistry -Recurse -Force -ErrorAction Ignore
            }
        }
        AfterAll {
            Remove-Job -Id $job.Id -Force
        }
    }

    Context "Add font family" {
        It "Add-FontFamily" {
            $FontFamily = 'Roboto'
            $url = 'https://google.com'
            
            Add-FontFamily -Family $FontFamily -Url = $url
            Get-FontFamily -Family $FontFamily | should -be $url
            
            Remove-FontFamily -Family $FontFamily
            Get-FontFamily -Family $FontFamily | should -BeNullOrEmpty
        }
        It "Get-AllFonts" {
            Add-FontFamily -Family 'Roboto1' -Url = 'https://google1.com'
            Add-FontFamily -Family 'Cambera1' -Url = 'https://google2.com'
            Get-FontFamily -All | should -BeLike @{
                'Roboto1' = 'https://google1.com';
                'Cambera1' = 'https://google2.com'
            }
            
            Remove-FontFamily -All
            Get-FontFamily -All | should -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module FontUtilities -ErrorAction Ignore
}
