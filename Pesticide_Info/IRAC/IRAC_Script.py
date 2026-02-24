## INSTALLATION:
# sudo apt install ghostscript python3-tk
#
# best set up a special environment with pyenv or conda
# pip install "camelot-py[base]"
#
# need to downgrade PYPDF2 due to compatibility issues
# pip install 'PyPDF2<3.0'
#
## USER MANUAL:
# https://camelot-py.readthedocs.io/en/master/
#

#1. import necessary library
import camelot

#2. import file to read
fname = "PATH to the pdf ../IRAC/MoA-Classification_v11.1_30Jan24.pdf"

#3. define pages with tables
tablepages='35-42'

#4. output filename stub
oname = "PATH to output ../IRAC/Insecticide_Table/IRAC"


#5. import the PDF (uses option 'lattice', i.e. the vertical and horizontal lines. SO only works if those are present.)
tables = camelot.read_pdf(fname, pages=tablepages)

#6. print report on quality of table import
for i in tables:
   print(i.parsing_report)

#7. export tables as csv
tables.export(f"{oname}.csv", f='csv') # json, excel, html, markdown, sqlite

#8. look at tables as pandas DataFrame
tables[0].df # get a pandas DataFrame!



