version 1.0

import "tasks/star.wdl" as star_task
import "tasks/samtools.wdl" as samtools
import "tasks/common.wdl" as common

workflow AlignStar {
    input {
        Array[File]+ inputR1
        Array[File]? inputR2
        String outputDir = "."
        String sample
        String library
        Array[String] readgroups
        String? platform = "illumina"
        Array[File]+ indexFiles

        Map[String, String] dockerImages = {
            "star": "quay.io/biocontainers/star:2.6.0c--0",
            "samtools": "quay.io/biocontainers/samtools:1.8--h46bd0b3_5"
        }
    }

    scatter (rg in readgroups) {
        String rgLine =
            '"ID:${rg}" "LB:${library}" "PL:${platform}" "SM:${sample}"'
    }

    call star_task.Star as star {
        input:
            inputR1 = inputR1,
            inputR2 = inputR2,
            outFileNamePrefix = outputDir + "/" + sample + "-" + library + ".",
            outSAMattrRGline = rgLine,
            indexFiles = indexFiles,
            dockerImage = dockerImages["star"]
    }

    call samtools.Index as samtoolsIndex {
        input:
            bamFile = star.bamFile,
            # This will only work if star.outSAMtype == "BAM SortedByCoordinate"
            outputBamPath = outputDir + "/" + sample + "-" + library +
                ".Aligned.sortedByCoord.out.bam",
            dockerImage = dockerImages["samtools"]
    }

    output {
        IndexedBamFile bamFile = {
            "file": samtoolsIndex.indexedBam,
            "index": samtoolsIndex.index
        }
    }
}
