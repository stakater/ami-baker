#!/usr/bin/env python3
import argparse

argParse = argparse.ArgumentParser()
argParse.add_argument('-t', '--cloud-config-tmpl', dest='t')
argParse.add_argument('-c', '--cloud-config-file', dest='c')
argParse.add_argument('-e', '--extra-cloud-config-units', dest='e')
argParse.add_argument('-p', '--placeholder', dest='p')

opts = argParse.parse_args()


if not any([opts.e]):
    argParse.print_usage()
    print('Argument `-e` or `--extra-cloud-config-units` must be specified')
    quit()

cloudConfigTmpl = "../cloud-config/cloud-config.tmpl.yaml" if not opts.t else opts.t
cloudConfigFile = '../cloud-config/cloud-config.yaml' if not opts.c else opts.c
placeholder = "<#EXTRA_CLOUDCONFIG_UNITS#>" if not opts.p else opts.p
extraCloudConfigUnits = opts.e

cloudConfigFileStart = ''
cloudConfigFileEnd = ''
foundPlaceholder = False
with open(cloudConfigTmpl) as input_data:
    # Read until placeholder
    for line in input_data:
        if line.strip() == placeholder:
            foundPlaceholder = True
            break
        cloudConfigFileStart += line
    # Read after placeholder
    for line in input_data:
        cloudConfigFileEnd += line

target = open(cloudConfigFile, 'w')
mergedCloudConfig = ''
if foundPlaceholder:
    mergedCloudConfig = cloudConfigFileStart + extraCloudConfigUnits + '\n\n' + cloudConfigFileEnd
else:
    mergedCloudConfig = cloudConfigFileStart

target.write(mergedCloudConfig)
