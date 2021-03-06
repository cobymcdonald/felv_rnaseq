### Approach 1: use Python to mess with file names to make them easier for wildcards:
# import glob, sys #following Eric A--omg PYTHON exciting!!!
#
# fullnames= glob.glob('/data/*.fastq.gz')
#
# # get sample name without .fastq.gz
# sample= []
# for name in fullnames:
#     base= name.split('.')[0]
#     sample.append(base)
#
# # get base name without R1 or R2
# basename= []
# for read in sample:
#     noR= read.split('_')[0] + '_' + read.split('_')[1]
#     basename.append(noR)


### Approach 2: import metadata as pandas df, create wildcards object for input function
import pandas as pd
#
met_long = pd.read_table("data/metadata/felv_metadata_long.txt").set_index("sample_id", drop=False)
# fastq_list = met_long['fastq'].tolist() #stores column as list of attributes
# Integrating pandas df with snakemake supposedly:
# input:
    # lambda wildcards, output: met_long.fastq[wildcards.sample_id]

# class Foo(object):
#     pass
#
# wildcards= Foo()

# wildcards.sample_id= met_long['sample_id'].tolist()
# wildcards.sample_id= met_long.loc["4438_R1", "sample_id"]

### Approach 3: just list all the samples in a config file
# configfile: "config/config.yaml"

##########

# define an input function

# using config file:
# def get_input_fastqs(wildcards):
#     return config["samples"][wildcards.sample_id]

# using pandas:
def get_input_fastqs(wildcards):
    return "data/samples/" + met_long.loc[wildcards.sample_id, "fastq"]

# don't totally understand this rule yet...cannot have wildcards within target rule
rule all:
    input:
        #the last output
        # directory("results/multiqc/raw/multiqc_data")
        "results/multiqc/raw/multiqc_data"

rule fastqc_raw:
    input:
        get_input_fastqs #works with both definitions!!!
        # lambda wildcards: config["samples"][wildcards.sample_id] #works
        # "data/samples/" + metadata.loc[wildcards.sample_id, "fastq"] #this works when I define a specific sample id as the attribute as in wildcards.sample_id= metadata.loc["4438_R1", "sample_id"], but not with a list of all sample_ids.
    output:
        "results/fastqc/raw/{sample_id}_fastqc.html",
        "results/fastqc/raw/{sample_id}_fastqc.zip"
    conda:
        "envs/fastqc.yaml" #note: don't list workflow parent dir as snakemake recognizes it automatically
    log:
        "logs/fastqc/raw/{sample_id}.log"
    threads: 19
    shell:
        "echo (fastqc -t {threads} {input}) 2> {log}"

rule multiqc_raw:
    input:
        "results/fastqc/raw"
    output:
        "results/multiqc/raw/multiqc_report.html",
        direct=directory("results/multiqc/raw")
    conda:
        "envs/multiqc.yaml"
    shell:
        "echo multiqc {input} -o {output.direct}"

rule trimgalore:
    input:
        get_input_fastqs
    output:

    shell:
        "echo trim_galore --paired --retain_unpaired --phred33 --length 36 -q 5 --stringency 1 -e 0.1 -o ./trim_galore_pe_out/ {input.f1} {input.f2}"
#
# rule fastqc_trim:
#     input:
#         "/results/trimming/{basename}_val_1.fastq.gz",
#         "/results/trimming/{basename}_val_2.fastq.gz"
#     output:
#         "/results/fastqc/trimmed/{sample}.trimmed_fastqc.zip",
#         "/results/fastqc/trimmed/{sample}.trimmed_fastqc.html"
#     shell:
#         "fastqc {input}"
#
# rule multiqc_trim:
#     input:
#         "/results/fastqc/trimmed/"
#     output:
#         "/results/multiqc/trimmed/multiqc_report.html",
#         #directory("/results/multiqc/trimmed/multiqc_data")
#     shell:
#         "multiqc {input}"
