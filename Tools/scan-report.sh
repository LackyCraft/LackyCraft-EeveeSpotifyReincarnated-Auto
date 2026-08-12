#!/usr/bin/env bash
# Scan file(s) with ClamAV (always, local, no account needed) and VirusTotal
# (only if VT_API_KEY env var is set - skipped with a note otherwise).
# Writes a Markdown report and exits 2 if anything critical was found so the
# caller can surface a warning without treating it as a hard build failure.
#
# Usage: scan-report.sh <label> <report.md> <file...>

LABEL="$1"; shift
REPORT="$1"; shift

CRITICAL=0
: > "$REPORT"
echo "## Antivirus report: $LABEL" >> "$REPORT"
echo >> "$REPORT"

for f in "$@"; do
  [ -f "$f" ] || continue
  name=$(basename "$f")

  # --- ClamAV ---
  echo "### ClamAV — $name" >> "$REPORT"
  if command -v clamscan >/dev/null 2>&1; then
    out=$(clamscan --no-summary "$f" 2>&1)
    rc=$?
    echo '```' >> "$REPORT"
    echo "$out" >> "$REPORT"
    echo '```' >> "$REPORT"
    if [ "$rc" -eq 1 ]; then
      CRITICAL=1
      echo "::error::ClamAV flagged $name ($LABEL) as infected"
    elif [ "$rc" -gt 1 ]; then
      echo "_ClamAV scan error (exit $rc) - treat as inconclusive, see output above._" >> "$REPORT"
    fi
  else
    echo "_ClamAV not available, skipped._" >> "$REPORT"
  fi
  echo >> "$REPORT"

  # --- VirusTotal ---
  echo "### VirusTotal — $name" >> "$REPORT"
  if [ -n "${VT_API_KEY:-}" ]; then
    size=$(stat -f%z "$f")
    if [ "$size" -gt 33554432 ]; then
      upload_url=$(curl -s -H "x-apikey: $VT_API_KEY" "https://www.virustotal.com/api/v3/files/upload_url" | jq -r '.data // empty')
    else
      upload_url="https://www.virustotal.com/api/v3/files"
    fi

    if [ -z "$upload_url" ]; then
      echo "_Could not get a VirusTotal upload URL for a file this size._" >> "$REPORT"
    else
      resp=$(curl -s -H "x-apikey: $VT_API_KEY" -X POST "$upload_url" -F "file=@${f}")
      analysis_id=$(echo "$resp" | jq -r '.data.id // empty')

      if [ -z "$analysis_id" ]; then
        echo "_Upload to VirusTotal failed: $(echo "$resp" | jq -c '.error // .' 2>/dev/null || echo "$resp")_" >> "$REPORT"
      else
        status=""
        analysis="{}"
        for _ in $(seq 1 20); do
          sleep 20
          analysis=$(curl -s -H "x-apikey: $VT_API_KEY" "https://www.virustotal.com/api/v3/analyses/$analysis_id")
          status=$(echo "$analysis" | jq -r '.data.attributes.status // empty')
          [ "$status" = "completed" ] && break
        done

        if [ "$status" != "completed" ]; then
          echo "_Scan did not finish in time (last status: ${status:-unknown}). Check manually: https://www.virustotal.com/gui/file-analysis/$analysis_id_" >> "$REPORT"
        else
          malicious=$(echo "$analysis" | jq -r '.data.attributes.stats.malicious // 0')
          suspicious=$(echo "$analysis" | jq -r '.data.attributes.stats.suspicious // 0')
          echo "Malicious: $malicious, Suspicious: $suspicious" >> "$REPORT"
          if [ "$malicious" != "0" ] || [ "$suspicious" != "0" ]; then
            echo >> "$REPORT"
            echo "Flagged by:" >> "$REPORT"
            echo "$analysis" | jq -r '.data.attributes.results | to_entries[] | select(.value.category=="malicious" or .value.category=="suspicious") | "- \(.key): \(.value.result)"' >> "$REPORT"
          fi
          if [ "$malicious" != "0" ]; then
            CRITICAL=1
            echo "::error::VirusTotal flagged $name ($LABEL) as malicious by $malicious engine(s)"
          fi
        fi
      fi
    fi
  else
    echo "_VirusTotal skipped: VT_API_KEY secret not configured._" >> "$REPORT"
  fi
  echo >> "$REPORT"
done

[ "$CRITICAL" = "1" ] && exit 2
exit 0
