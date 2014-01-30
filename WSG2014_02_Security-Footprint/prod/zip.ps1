function ZipFiles( $zipfilename, $sourcedir )
{
   [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
   $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
   [System.IO.Compression.ZipFile]::CreateFromDirectory($sourcedir,
        $zipfilename, $compressionLevel, $false)
}