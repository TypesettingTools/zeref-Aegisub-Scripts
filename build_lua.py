#!/usr/bin/env python3

import argparse, os, subprocess, re

parser = argparse.ArgumentParser()
parser.add_argument('input_file')
parser.add_argument('output_file')
parser.add_argument('--moonc', default='moonc')
args = parser.parse_args()

moon_input = args.input_file
source_dir, moon_input_base = os.path.split(moon_input)
module_name = os.path.splitext(moon_input_base)[0]

moonc = args.moonc
header_input = os.path.join(source_dir, module_name + 'C.h')
lua_output = args.output_file
moon_output = os.path.join(os.path.dirname(lua_output), module_name + '.processed.moon')

re_preproc = re.compile('(\#|extern|\}).*\n')
re_export = re.compile('EXPORT ')
re_include = re.compile('___INCLUDE___')

if (os.path.isfile(header_input)):
    # "Preprocess" headers
    with open(header_input) as f:
        header = f.read()

    header = re.sub(re_preproc, '', header)
    header = re.sub(re_export, '', header)
    header = '\n'.join([line.rstrip() for line in header.splitlines() if line.strip()])

    # Drop the header into the Moonscript file
    with open(moon_input) as f:
        moon = f.read()

    moon = re.sub(re_include, header, moon)

    with open(moon_output, 'w') as f:
        f.write(moon)

    # Compile the Moonscript file
    subprocess.run([moonc, '-o', lua_output, moon_output])

    os.remove(moon_output)
else:
    subprocess.run([moonc, '-o', lua_output, moon_input])
