#!/bin/bash

# Create fonts directory if it doesn't exist
mkdir -p assets/fonts

# Download Inter font files
curl -L "https://github.com/rsms/inter/raw/master/docs/font-files/Inter-Regular.woff2" -o assets/fonts/Inter-Regular.ttf
curl -L "https://github.com/rsms/inter/raw/master/docs/font-files/Inter-Medium.woff2" -o assets/fonts/Inter-Medium.ttf
curl -L "https://github.com/rsms/inter/raw/master/docs/font-files/Inter-SemiBold.woff2" -o assets/fonts/Inter-SemiBold.ttf
curl -L "https://github.com/rsms/inter/raw/master/docs/font-files/Inter-Bold.woff2" -o assets/fonts/Inter-Bold.ttf

echo "Font files downloaded successfully!" 