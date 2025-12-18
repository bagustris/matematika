#!/bin/bash

# Script to convert Beamer LaTeX files to HTML using Pandoc
# Pattern: bab?_*.tex (e.g., bab1_intro.tex, bab2_algebra.tex)

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

MODE="tex" # tex (pandoc->revealjs) | pdf (render PDF pages to images) | pdf-embed (embed PDF pages)
TEX_STYLE="default" # default | beamerish

usage() {
    cat <<EOF
Usage: $0 [--tex|--tex-beamerish|--pdf|--pdf-embed]

    --tex            Convert .tex -> Reveal.js HTML using Pandoc (default)
    --tex-beamerish  Like --tex, but injects Beamer-inspired CSS to better match the PDF theme
  --pdf   Preserve Beamer/PDF look by converting bab?_*.pdf pages to images
    --pdf-embed Preserve Beamer/PDF look by embedding the PDF directly (vector) in an iframe

Notes:
    - --pdf produces slides as images (layout preserved, text not selectable).
    - --pdf-embed preserves vector quality and may keep text selectable depending on the browser PDF viewer.
    - Many browsers ignore #page=N for embedded PDFs; this mode embeds the PDF once (one slide).
  - You can override the Reveal.js base URL via env var REVEALJS_URL.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --tex)
            MODE="tex"
            TEX_STYLE="default"
            shift
            ;;
        --tex-beamerish|--hybrid)
            MODE="tex"
            TEX_STYLE="beamerish"
            shift
            ;;
        --pdf)
            MODE="pdf"
            shift
            ;;
        --pdf-embed|--embed-pdf)
            MODE="pdf-embed"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown argument: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Check required tools
if [ "$MODE" = "tex" ]; then
    if ! command -v pandoc &> /dev/null; then
        echo -e "${RED}Error: pandoc is not installed.${NC}"
        echo "Please install pandoc first:"
        echo "  Ubuntu/Debian: sudo apt-get install pandoc"
        echo "  macOS: brew install pandoc"
        echo "  Other: https://pandoc.org/installing.html"
        exit 1
    fi
else
    if ! command -v pdflatex &> /dev/null; then
        echo -e "${RED}Error: pdflatex is not installed.${NC}"
        echo "Please install TeX Live (pdflatex) first."
        exit 1
    fi
    if [ "$MODE" = "pdf" ]; then
        if ! command -v pdftoppm &> /dev/null; then
            echo -e "${RED}Error: pdftoppm is not installed.${NC}"
            echo "Please install poppler utils first:"
            echo "  Ubuntu/Debian: sudo apt-get install poppler-utils"
            exit 1
        fi
    fi
    if [ "$MODE" = "pdf-embed" ]; then
        if ! command -v pdfinfo &> /dev/null; then
            echo -e "${RED}Error: pdfinfo is not installed.${NC}"
            echo "Please install poppler utils first:"
            echo "  Ubuntu/Debian: sudo apt-get install poppler-utils"
            exit 1
        fi
    fi
fi

# Create docs directory if it doesn't exist
mkdir -p docs

# Avoid stale PNG assets when not using image mode
if [ "$MODE" = "pdf-embed" ]; then
    rm -rf docs/assets
fi

# Optional Beamer-ish CSS for tex mode
PANDOC_CSS_ARGS=()
if [ "$MODE" = "tex" ] && [ "$TEX_STYLE" = "beamerish" ]; then
    if [ -f "reveal-beamerish.css" ]; then
        cp -f "reveal-beamerish.css" "docs/reveal-beamerish.css"
        PANDOC_CSS_ARGS=(--css "reveal-beamerish.css")
    else
        echo -e "${YELLOW}Warning: reveal-beamerish.css not found; continuing without extra CSS.${NC}"
    fi
fi

# Reveal.js asset location
# - If you want offline viewing (no CDN), place reveal.js under: docs/revealjs/
#   (so docs/revealjs/dist/reveal.js exists). The generated HTML will then use
#   relative paths like revealjs/dist/reveal.css.
# - Otherwise we default to a pinned CDN build.
if [ -f "docs/revealjs/dist/reveal.js" ]; then
    REVEALJS_URL="revealjs"
else
    REVEALJS_URL="${REVEALJS_URL:-https://cdn.jsdelivr.net/npm/reveal.js@4.6.1}"
fi

# Counter for processed files
count=0
success=0
failed=0

# Find and convert all matching files
echo -e "${YELLOW}Starting conversion of bab?_*.tex files...${NC}"
echo "----------------------------------------"

for texfile in bab?_*.tex; do
    # Check if any files match (handles case where no files match)
    if [ !  -f "$texfile" ]; then
        echo -e "${RED}No files matching pattern 'bab?_*.tex' found.${NC}"
        exit 1
    fi
    
    # Get filename without extension
    basename=$(basename "$texfile" .tex)
    
    # Output HTML file path
    htmlfile="docs/${basename}.html"
    
    if [ "$MODE" = "tex" ]; then
        echo -e "Converting (Pandoc): ${YELLOW}$texfile${NC} → ${GREEN}$htmlfile${NC}"

        # Convert using pandoc
        if pandoc "$texfile" \
            -t revealjs \
            -s \
            -o "$htmlfile" \
            -V revealjs-url="$REVEALJS_URL" \
            "${PANDOC_CSS_ARGS[@]}" \
            --mathjax \
            --slide-level=2 \
            -V theme=serif \
            -V slideNumber=true \
            -V transition=slide \
            -V navigationMode=linear \
            --toc \
            --toc-depth=1 \
            --metadata title="$basename" \
            2>/dev/null; then

            echo -e "${GREEN}✓ Successfully converted: $texfile${NC}"
            ((success++))
        else
            echo -e "${RED}✗ Failed to convert: $texfile${NC}"
            ((failed++))
        fi
    else
        pdffile="docs/${basename}.pdf"

        # Build/update PDF if needed
        if [ ! -f "$pdffile" ] || [ "$texfile" -nt "$pdffile" ]; then
            echo -e "Building PDF: ${YELLOW}$texfile${NC} → ${GREEN}$pdffile${NC}"
            if ! pdflatex -interaction=nonstopmode -halt-on-error -output-directory=docs "$texfile" >/dev/null 2>&1; then
                echo -e "${RED}✗ Failed to build PDF: $texfile${NC}"
                ((failed++))
                ((count++))
                echo "----------------------------------------"
                continue
            fi
            # Beamer often needs a second pass for TOC/refs
            pdflatex -interaction=nonstopmode -halt-on-error -output-directory=docs "$texfile" >/dev/null 2>&1 || true

            # Keep docs/ tidy
            rm -f "docs/${basename}.aux" "docs/${basename}.log" "docs/${basename}.nav" "docs/${basename}.out" "docs/${basename}.snm" "docs/${basename}.toc" "docs/${basename}.vrb" >/dev/null 2>&1 || true
        fi

        if [ ! -f "$pdffile" ]; then
            echo -e "${RED}✗ Missing PDF: $pdffile${NC}"
            ((failed++))
            ((count++))
            echo "----------------------------------------"
            continue
        fi

        if [ "$MODE" = "pdf" ]; then
            outdir="docs/assets/${basename}"
            mkdir -p "$outdir"
            rm -f "$outdir"/slide-*.png

            echo -e "Converting (PDF→PNG): ${YELLOW}$pdffile${NC} → ${GREEN}$htmlfile${NC}"
            if ! pdftoppm -png -r 150 "$pdffile" "$outdir/slide" >/dev/null 2>&1; then
                echo -e "${RED}✗ Failed to convert PDF pages: $pdffile${NC}"
                ((failed++))
                ((count++))
                echo "----------------------------------------"
                continue
            fi

            # Generate Reveal.js HTML that shows each page as an image slide
            {
                echo "<!DOCTYPE html>"
                echo "<html>"
                echo "<head>"
                echo "  <meta charset=\"utf-8\">"
                echo "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
                echo "  <title>${basename}</title>"
                echo "  <link rel=\"stylesheet\" href=\"${REVEALJS_URL}/dist/reset.css\">"
                echo "  <link rel=\"stylesheet\" href=\"${REVEALJS_URL}/dist/reveal.css\">"
                echo "  <link rel=\"stylesheet\" href=\"${REVEALJS_URL}/dist/theme/serif.css\" id=\"theme\">"
                echo "  <style>"
                echo "    .reveal section img { max-width: 100%; max-height: 85vh; width: auto; height: auto; }"
                echo "  </style>"
                echo "</head>"
                echo "<body>"
                echo "  <div class=\"reveal\">"
                echo "    <div class=\"slides\">"
            } > "$htmlfile"

            # Natural sort so slide-10 comes after slide-9
            while IFS= read -r img; do
                img_rel="${img#docs/}"
                echo "      <section><img src=\"${img_rel}\" alt=\"${basename}\"></section>" >> "$htmlfile"
            done < <(ls -1v "$outdir"/slide-*.png 2>/dev/null)

            {
                echo "    </div>"
                echo "  </div>"
                echo "  <script src=\"${REVEALJS_URL}/dist/reveal.js\"></script>"
                echo "  <script>"
                echo "    Reveal.initialize({"
                echo "      hash: true,"
                echo "      controls: true,"
                echo "      progress: true,"
                echo "      slideNumber: true,"
                echo "      transition: 'slide'"
                echo "    });"
                echo "  </script>"
                echo "</body>"
                echo "</html>"
            } >> "$htmlfile"

            echo -e "${GREEN}✓ Successfully converted (PDF mode): $texfile${NC}"
            ((success++))
        else
            # pdf-embed: embed the generated PDF directly (already in docs/)
            docspdf="$pdffile"

            pages=$(pdfinfo "$docspdf" 2>/dev/null | awk '/^Pages:/ {print $2}')
            if [ -z "$pages" ]; then
                echo -e "${RED}✗ Could not determine page count for: $docspdf${NC}"
                ((failed++))
                ((count++))
                echo "----------------------------------------"
                continue
            fi

            echo -e "Embedding (PDF): ${YELLOW}$docspdf${NC} → ${GREEN}$htmlfile${NC} (${pages} pages)"

            {
                echo "<!DOCTYPE html>"
                echo "<html>"
                echo "<head>"
                echo "  <meta charset=\"utf-8\">"
                echo "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
                echo "  <title>${basename}</title>"
                echo "  <link rel=\"stylesheet\" href=\"${REVEALJS_URL}/dist/reset.css\">"
                echo "  <link rel=\"stylesheet\" href=\"${REVEALJS_URL}/dist/reveal.css\">"
                echo "  <link rel=\"stylesheet\" href=\"${REVEALJS_URL}/dist/theme/serif.css\" id=\"theme\">"
                echo "  <style>"
                echo "    html, body { height: 100%; }"
                echo "    .reveal section { padding: 0 !important; }"
                echo "    .reveal .pdf-frame { width: 100vw; height: 100vh; border: 0; }"
                echo "  </style>"
                echo "</head>"
                echo "<body>"
                echo "  <div class=\"reveal\">"
                echo "    <div class=\"slides\">"
            } > "$htmlfile"

            # Single slide: embed PDF viewer once.
            # Use standard PDF Open Parameters for better cross-browser support.
            # view=FitV fits the page to the viewport height in many built-in viewers.
            echo "      <section><iframe class=\"pdf-frame\" src=\"${basename}.pdf#page=1&view=FitV\"></iframe></section>" >> "$htmlfile"

            {
                echo "    </div>"
                echo "  </div>"
                echo "  <script src=\"${REVEALJS_URL}/dist/reveal.js\"></script>"
                echo "  <script>"
                echo "    Reveal.initialize({"
                echo "      hash: true,"
                echo "      controls: true,"
                echo "      progress: true,"
                echo "      slideNumber: true,"
                echo "      disableLayout: true,"
                echo "      transition: 'slide'"
                echo "    });"
                echo "  </script>"
                echo "</body>"
                echo "</html>"
            } >> "$htmlfile"

            echo -e "${GREEN}✓ Successfully converted (PDF-embed mode): $texfile${NC}"
            ((success++))
        fi
    fi
    
    ((count++))
    echo "----------------------------------------"
done

# Create index.html with links to all presentations
echo -e "${YELLOW}Creating index page...${NC}"

cat > docs/index.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Matematika - Presentations</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        h1 {
            color: #333;
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 10px;
        }
        .presentation-list {
            background:  white;
            padding: 20px;
            border-radius:  8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .presentation-item {
            margin: 15px 0;
            padding: 15px;
            border-left: 4px solid #4CAF50;
            background-color: #fafafa;
            transition: background-color 0.3s;
        }
        .presentation-item:hover {
            background-color: #e8f5e9;
        }
        a {
            text-decoration: none;
            color: #2196F3;
            font-size: 18px;
            font-weight: 500;
        }
        a:hover {
            color: #0d47a1;
            text-decoration: underline;
        }
        .footer {
            margin-top: 40px;
            text-align: center;
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <h1>📊 Matematika - Presentations</h1>
    <div class="presentation-list">
        <p>Select a presentation to view:</p>
EOF

# Add links for each converted file
for htmlfile in docs/bab*.html; do
    if [ -f "$htmlfile" ]; then
        filename=$(basename "$htmlfile")
        displayname=$(basename "$htmlfile" .html | sed 's/_/ - /g' | sed 's/bab/Bab /g')
        echo "        <div class='presentation-item'>" >> docs/index.html
        echo "            <a href='$filename'>$displayname</a>" >> docs/index.html
        echo "        </div>" >> docs/index.html
    fi
done

cat >> docs/index.html << 'EOF'
    </div>
    <div class="footer">
        <p>Generated with Pandoc + Reveal.js</p>
        <p>Hosted on GitHub Pages</p>
    </div>
</body>
</html>
EOF

echo -e "${GREEN}✓ Index page created:  docs/index.html${NC}"
echo "========================================"
echo -e "${GREEN}Conversion Summary:${NC}"
echo -e "Total files processed: $count"
echo -e "${GREEN}Successful:  $success${NC}"
if [ $failed -gt 0 ]; then
    echo -e "${RED}Failed: $failed${NC}"
fi
echo "================= DONE ================="
