#!/bin/bash
#SBATCH --cpus-per-task=5
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=8
#SBATCH --gres=gpu:8
#SBATCH --time=8:00:00
#SBATCH --job-name=contriever
#SBATCH --output=
#SBATCH --partition=
#SBATCH --mem=450GB
#SBATCH --signal=USR1@140
#SBATCH --open-mode=append


port=$(shuf -i 15000-16000 -n 1)
TDIR="/workspace/contriever/encoded-data"
TRAINDATASETS="${TDIR}/pl_contriever_data/"

rmin=0.05
rmax=0.5
T=0.05
QSIZE=131072
MOM=0.9995
POOL=average
AUG=delete
PAUG=0.1
LC=0.
mo=allegro/herbert-base-cased
mp=none

name=$SLURM_JOB_ID-$POOL-rmin$rmin-rmax$rmax-T$T-$QSIZE-$MOM-$mo-$AUG-$PAUG

srun docker run --gpus all -it --ipc=host --network=host -v ${DATADIR}:${TDIR} -v ${CHECKPOINT_DIR}:/workspace/checkpoint/ ${DOCKER_IMAGE} python train.py \
        --model_path $mp \
        --sampling_coefficient $LC \
        --retriever_model_id $mo --pooling $POOL \
        --augmentation $AUG --prob_augmentation $PAUG \
        --train_data $TRAINDATASETS --loading_mode split \
        --ratio_min $rmin --ratio_max $rmax --chunk_length 256 \
        --momentum $MOM --queue_size $QSIZE --temperature $T \
        --warmup_steps 20000 --total_steps 500000 --lr 0.00005 \
        --name $name \
        --scheduler linear \
        --optim adamw \
        --per_gpu_batch_size 64 \
        --output_dir /workspace/checkpoint/$name \
        --main_port $port \

