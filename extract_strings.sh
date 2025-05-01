#!/bin/bash

# Create l10n directory if it doesn't exist
mkdir -p lib/l10n

# Initialize ARB file with locale
echo '{
  "@@locale": "en",' > lib/l10n/app_en.arb

# Find all Dart files and extract strings, cleaning up the Text() and title: prefixes
STRINGS=$(find lib -name "*.dart" -type f -exec grep -ho "Text(\([\"'][^\"']*[\"']\)" {} \; | sed "s/Text(\([\"']\)\(.*\)\1)/\2/" | sort -u)
TITLES=$(find lib -name "*.dart" -type f -exec grep -ho "title:\s*[\"'][^\"']*[\"']" {} \; | sed "s/title:\s*[\"']\(.*\)[\"']/\1/" | sort -u)

# Combine all strings
ALL_STRINGS=$(echo -e "$STRINGS\n$TITLES" | sort -u)

# Convert strings to ARB format
while IFS= read -r line; do
    if [ ! -z "$line" ]; then
        # Convert "Welcome to App" to "welcomeToApp"
        key=$(echo "$line" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-zA-Z0-9 ]//g' | awk '{for(i=1;i<=NF;i++)if(i==1)printf "%s", $i; else printf "%s", toupper(substr($i,1,1)) substr($i,2)}')

        # Clean up the string and add the key-value pair to ARB file
        cleaned_string=$(echo "$line" | sed 's/^Text(//' | sed 's/^title: //' | sed 's/)$//' | sed "s/^['\"]//; s/['\"]$//")
        echo "  \"$key\": \"$cleaned_string\"," >> lib/l10n/app_en.arb
    fi
done <<< "$ALL_STRINGS"

# Close the JSON object
sed -i '' -e '$ s/,$//' lib/l10n/app_en.arb
echo "}" >> lib/l10n/app_en.arb

# Count entries
COUNT=$(grep -c ":" lib/l10n/app_en.arb)
echo "Generated app_en.arb with $((COUNT - 1)) strings"