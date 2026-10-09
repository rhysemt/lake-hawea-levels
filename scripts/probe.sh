#!/usr/bin/env bash
# One-off: fetch EMI Hawea inflow and storage series for validation.
set -u
mkdir -p probe && cd probe
E=https://www.emi.ea.govt.nz/Environment/Datasets/HydrologicalModellingDataset
curl -sSL -m 120 -o emi_inflow.csv "$E/2_Flows_20241231/SI_HWE_Natural_LakeHawea_Inflow_9170(1).csv"
curl -sSL -m 120 -o emi_storage.csv "$E/3_StorageAndSpill_20241231/3_1_Storage/SI_HWE_Storage_LakeHawea.csv"
curl -sSL -m 120 -o emi_flow_index.csv "$E/2_Flows_20241231/FileIndex_Flows.csv"
wc -c *.csv > log.txt
