#!/bin/bash

#train_cmd="utils/run.pl"
#decode_cmd="utils/run.pl"

threshold=1
nnet_dir=xvector_nnet_1a
name=test

. ./cmd.sh
. ./path.sh

# Feature extraction
echo "############ make_mfcc"
for x in test ; do 
 steps/make_mfcc.sh --nj 1 --write-utt2num-frames true data/$x exp/make_mfcc/$x mfcc || exit 1
 utils/fix_data_dir.sh data/$x || exit 1
done

echo "############ prepare_feats"
local/nnet3/xvector/prepare_feats.sh --nj 1 data/$name data/${name}_cmn exp/${name}_cmn || exit 1

cp data/$name/segments data/${name}_cmn/ || exit 1
utils/fix_data_dir.sh data/${name}_cmn || exit 1

echo "############ extract_xvectors"
diarization/nnet3/xvector/extract_xvectors.sh --nj 1 --window 1.5 --period 0.75 --apply-cmn false --min-segment 0.5 $nnet_dir data/${name}_cmn $nnet_dir/xvectors_${name} || exit 1

echo "############ score_plda"
diarization/nnet3/xvector/score_plda.sh --target-energy 0.9 --nj 1 $nnet_dir/xvectors_$name $nnet_dir/xvectors_$name $nnet_dir/xvectors_$name/plda_scores || exit 1

#diarization/nnet3/xvector/score_plda.sh --target-energy 0.9 --nj 1 xvector_nnet_1a/xvectors_test xvector_nnet_1a/xvectors_test xvector_nnet_1a/xvectors_test/plda_scores

echo "############ cluster"
#diarization/cluster.sh  --nj 1 --reco2num-spk data/$name/reco2num_spk $nnet_dir/xvectors_$name/plda_scores $nnet_dir/xvectors_$name/plda_scores_num_speakers || exit 1

# using threshold
diarization/cluster.sh --nj 1 --threshold $threshold $nnet_dir/xvectors_$name/plda_scores $nnet_dir/xvectors_$name/plda_scores_threshold_${threshold}
