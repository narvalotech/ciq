#!/bin/bash
#
# Copy the output of vscode agent into a new "session-x.md" file.
# (right-click, copy-all)
#
# Run this script in this dir. Check in the prompts.

# Define the output file
OUTPUT_FILE="all_prompts.md"

# Clear or create the output file
echo "# Extracted Agent Prompts" > "$OUTPUT_FILE"
echo "Generated on: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Loop through all matching session files
for file in session-*.md; do
    [ -e "$file" ] || continue
    
    echo "Processing $file..."
    
    # Extract prompts: text between "User:" and "GitHub Copilot:"
    # Uses awk to collect multi-line blocks as complete prompts
    awk '
    /^User:/ {
        in_prompt = 1
        # Remove "User:" or "User: " prefix from first line
        sub(/^User:[[:space:]]*/, "")
        prompt = $0
        next
    }
    /^GitHub Copilot:/ {
        if (in_prompt && prompt != "") {
            print "### PROMPT\n" prompt "\n"
        }
        in_prompt = 0
        prompt = ""
        next
    }
    in_prompt {
        prompt = prompt "\n" $0
    }
    ' "$file" >> "$OUTPUT_FILE"
done

echo "Done! All prompts saved to $OUTPUT_FILE"
