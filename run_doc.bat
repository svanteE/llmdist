@echo off
cd /d "c:\Users\svante\OneDrive - Aalborg Universitet\geodesic\llmdist"
R --vanilla --quiet --slave < temp_doc.R > temp_doc_output.txt 2>&1
pause
