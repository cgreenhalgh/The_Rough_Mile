# merge conposition files...
if process.argv.length<3
  console.log 'Usage: node merge <xlsx-file> [ <participant> ... ]'
  process.exit -1

xlsx = require 'xlsx'
fs = require 'fs'
mustache = require 'mustache'

infile = process.argv[2];
console.log 'read spreadsheet '+infile
workbook = xlsx.readFile infile
sheet = workbook.Sheets[workbook.SheetNames[0]]
cellid = (c,r) -> 
  p = String(r+1)
  rec = (c) ->
    p = (String.fromCharCode 'A'.charCodeAt(0)+(c % 26)) + p
    c = Math.floor c/26
    if c!=0
      rec c
  rec c
  p 
#console.log 'A1 = '+cellid(0,0)+' '+(JSON.stringify sheet[cellid(0,0)]) 
#columns = []

templates = fs.readdirSync 'templates'

readrow = (r) ->
  track = 'Track0'
  data = {}
  data.id = sheet[cellid(0,r)]?.v
  for c in [1..1000]
    head = sheet[cellid(c,0)]?.v
    if not head?
      break
    m = head.match /^((Answer|Track)[1-6])$/
    if m?
      track = m[1]

    if data[track]==undefined
      data[track] = {}
    data[track][head] = sheet[cellid(c,r)]?.v
  data
for r in [1..1000]
  cell = sheet[cellid(0,r)]
  if cell == undefined
    break
  id = cell.v
  if not id?
    continue
  if process.argv.length<4 || (process.argv.indexOf id)>=0
    data = readrow r
    console.log 'Read participant '+id+': '+(JSON.stringify data)
    outdir = 'output/'+id
    try
      fs.statSync outdir
    catch err
      console.log 'Create output directory '+outdir
      fs.mkdirSync outdir
    for template in templates
      infile = fs.readFileSync 'templates/'+template, {encoding:'utf8'}
      outfilename = outdir+'/'+(template.replace 'PARTICIPANT', id)
      console.log 'Generate '+outfilename
      outfile = mustache.render infile, data
      fs.writeFileSync outfilename, outfile, {encoding: 'utf8'}
