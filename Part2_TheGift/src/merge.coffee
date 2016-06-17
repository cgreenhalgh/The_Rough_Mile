# merge conposition files...
if process.argv.length<3
  console.log 'Usage: node merge <xlsx-file> [ <participant> ... ]'
  process.exit -1

xlsx = require 'xlsx'
fs = require 'fs'
mustache = require 'mustache'

console.log 'read defaults.json'
defaults = JSON.parse fs.readFileSync 'defaults.json',{encoding:'utf8'}

infile = process.argv[2];
console.log 'read spreadsheet '+infile
workbook = xlsx.readFile infile
sheet = workbook.Sheets[workbook.SheetNames[0]]
cellid = (c,r) -> 
  p = String(r+1)
  rec = (c) ->
    p = (String.fromCharCode 'A'.charCodeAt(0)+(c % 26)) + p
    c = Math.floor (c/26)
    if c!=0
      rec c-1
  rec c
  p 
console.log 'AA1 = '+cellid(26,0)+' '+(JSON.stringify sheet[cellid(26,0)]) 
#columns = []

templates = fs.readdirSync 'templates'

readrow = (r) ->
  track = 'Track0'
  data = {}
  data.id = sheet[cellid(0,r)]?.v
  for c in [1..1000]
    head = sheet[cellid(c,0)]?.v?.toLowerCase()
    if not head?
      break
    m = head.match /^((answer|track)[1-6])$/
    if m?
      track = m[1]
    if data[track]==undefined
      data[track] = {}
      for k,v of defaults[m[2]]
        data[track][k] = v
      #console.log 'add defaults for '+m[2]+': '+(JSON.stringify data[track])
    
    val = sheet[cellid(c,r)]?.v
    if val?
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
      if outfilename.indexOf '.json' >= 0
        JSON.parse outfile
