#!/usr/bin/env python3
###############################################################################
# Copyright 2016 Aurora Solutions
#
#    http://www.aurorasolutions.io
#
# Aurora Solutions is an innovative services and product company at
# the forefront of the software industry, with processes and practices
# involving Domain Driven Design(DDD), Agile methodologies to build
# scalable, secure, reliable and high performance products.
#
# Stakater is an Infrastructure-as-a-Code DevOps solution to automate the
# creation of web infrastructure stack on Amazon. Stakater is a collection
# of Blueprints; where each blueprint is an opinionated, reusable, tested,
# supported, documented, configurable, best-practices definition of a piece
# of infrastructure. Stakater is based on Docker, CoreOS, Terraform, Packer,
# Docker Compose, GoCD, Fleet, ETCD, and much more.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

###############################################################################
# Merge extra cloud-config units
# This script merges extra cloud config units into the cloud-config template
# and creates a cloud-config.yaml file
# Authors: Hazim
###############################################################################
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
