#!/bin/bash 
#SBATCH --job-name=preprocessing
#SBATCH --array=1-1
#SBATCH --partition=short-serial
#SBATCH -o ./logs_pp/%A_%a.out 
#SBATCH -e ./logs_pp/%A_%a.err 
#SBATCH --time=1:00:00
#SBATCH --mem=64000
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --mail-user=ricorne@noc.ac.uk

# 1 - 840
source ./setenv0.sh
if [ -f preprocess_${SLURM_ARRAY_TASK_ID}.success ]
then
    echo ""
    echo "Job previously successful, job not rerun. Remove file 'preprocess_${SLURM_ARRAY_TASK_ID}.success' to force rerun."
    echo ""
else
    python3 ${scripts_directory}/preprocess_rc.py -jobs ${jobs_directory} -job_index ${SLURM_ARRAY_TASK_ID} \
        -schema ${code_directory}/config/schemas/imma/imma.json -code_tables ${code_directory}/config/schemas/imma/code_tables/ \
        -source $data_directory -corrections ${corrections_directory} \
        -destination ${working_directory}/corrected_data/
    if [ $? -eq 0 ] 
    then
	    touch preprocess_${SLURM_ARRAY_TASK_ID}.success
        if [ -f preprocess_${SLURM_ARRAY_TASK_ID}.failed ]
        then
            rm preprocess_${SLURM_ARRAY_TASK_ID}.failed
        fi
        echo "submitting clean up job: mv ./logs_pp/${SLURM_JOBID}_${SLURM_ARRAY_TASK_ID}.* ./logs_pp/successful/"
        bsub -w "done(${SLURM_JOBID})" mv ./logs_pp/${SLURM_JOBID}_${SLURM_ARRAY_TASK_ID}.* ./logs_pp/successful/
    else
	    touch preprocess_${SLURM_ARRAY_TASK_ID}.failed
        echo "submitting clean up job: mv ./logs_pp/${SLURM_JOBID}_${SLURM_ARRAY_TASK_ID}.* ./logs_pp/failed/"
        bsub -w "done(${SLURM_JOBID})" mv ./logs_pp/${SLURM_JOBID}_${SLURM_ARRAY_TASK_ID}.* ./logs_pp/failed/                
	fi
fi
