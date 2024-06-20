#!/bin/bash
export ACCELERATE_CONFIG_FILE="accelerate_inference_config.yaml"

jutil env activate -p hai_baylora

USER="onal1"
CODE_PATH="/p/project/hai_baylora/"${USER}"/SWAG-LoRA"
OUT_PATH="/p/project/hai_baylora/"${USER}"/SWAG-LoRA/outputs"
DATA_PATH="/p/scratch/hai_baylora/data_${USER}"
MODELS_PATH="/p/scratch/hai_baylora/models2"

### Job specs ### ------------------------------------------
TIME="02:00:00"
PARTITION="develbooster"
RUN_ID=2 # 0, 1, 2, .... for repeat exps
 
model="llama_7b_hf"

task="arc-c"
subtask=""
bsz=16

ood_task="mmlu"
ood_subtask="anatomy"
ood_bsz=16
only_ood=True

SWAG_SAMPLE_SCALE=1.0
NUM_SAMPLES=15

JOB_NAME="evalmultiswag_${task}${subtask}-${ood_task}${ood_subtask}-scale_${SWAG_SAMPLE_SCALE}_${RUN_ID}"

paths=(
    "results/arc-c/meta-llama/Llama-2-7b-hf/swag/trainswag_arc-c_LR3e-4_BSZ8_DIV2_4/20240329-020415"
    "results/arc-c/meta-llama/Llama-2-7b-hf/swag/trainswag_arc-c_LR3e-4_BSZ8_DIV2_1/20240329-013413"
    "results/arc-c/meta-llama/Llama-2-7b-hf/swag/trainswag_arc-c_LR3e-4_BSZ8_DIV2_2/20240329-014408"
    "results/arc-c/meta-llama/Llama-2-7b-hf/swag/trainswag_arc-c_LR3e-4_BSZ8_DIV2_3/20240329-014541"
    "results/arc-c/meta-llama/Llama-2-7b-hf/swag/trainswag_arc-c_LR3e-4_BSZ8_DIV2_4/20240329-020415"
)

#================================================================

# Check if the directory exists
if [ ! -d "$OUT_PATH" ]; then
    # Directory does not exist, so create it
    mkdir -p "$OUT_PATH"
    echo "Directory created: $OUT_PATH"
else
    echo "Directory already exists: $OUT_PATH"
fi

# Convert array to a string that represents a list in Python
paths_string="[\"${paths[0]}\""
for i in "${paths[@]:1}"; do
    paths_string+=", \"$i\""
done
paths_string+="]"

#================================================================

for method in "_"; do
for task_name in $task; do
    sleep 0.1
    job_file="$OUT_PATH/$JOB_NAME.cmd"
echo "#!/bin/bash
#SBATCH --account=hai_baylora
#SBATCH --nodes=1
# ------------------------
#SBATCH --ntasks-per-node=4
# ------------------------
#SBATCH -J $JOB_NAME
#SBATCH --output=$OUT_PATH/$JOB_NAME.out
#SBATCH --error=$OUT_PATH/$JOB_NAME.err
#SBATCH --partition=$PARTITION
#SBATCH --time=$TIME
#SBATCH --gres=gpu:4
source ~/.bash_profile
module load git
# conda activate mvTCR
source sc_venv_template/activate.sh
accelerate launch $CODE_PATH/multisampling_evaluation.py model=$model experiment.task=$task_name experiment.batch_size=$bsz experiment.ood_task=$ood_task experiment.ood_subtask=$ood_subtask experiment.ood_batch_size=$ood_bsz \
evaluation.eval_method=swag evaluation.num_samples=$NUM_SAMPLES evaluation.only_ood=$only_ood evaluation.swag_sample_scale=$SWAG_SAMPLE_SCALE experiment.data_path=$DATA_PATH experiment.model_path=${MODELS_PATH} evaluation.seed=$RUN_ID +paths='$paths_string'
" > ${job_file}
        sbatch $job_file
done
done
