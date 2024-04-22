#!/usr/bin/python3

from torch.utils.data import DataLoader
from data_handler.NixSAMData import SAMDataset
from transformers import SamModel, SamProcessor
import torch.nn.functional as F

from torch.optim import Adam
import monai
from tqdm import tqdm
from statistics import mean
import torch
from torch.nn.functional import threshold, normalize

import numpy as np
import os
import sys
image_dataset_path= os.environ.get('DATASET')
ground_truth_path= os.environ.get('GROUNDTRUTH')
ground_truth_type = os.environ.get('GT_TYPE')

processor = SamProcessor.from_pretrained("facebook/sam-vit-base")
train_dataset = SAMDataset(ground_truth_type=ground_truth_type, ground_truth_path=ground_truth_path, image_dataset_path=image_dataset_path, processor=processor)
train_dataloader = DataLoader(train_dataset, batch_size=2, shuffle=True)

model = SamModel.from_pretrained("facebook/sam-vit-base")

# # make sure we only compute gradients for mask decoder
for name, param in model.named_parameters():
  if name.startswith("vision_encoder") or name.startswith("prompt_encoder"):
    param.requires_grad_(False)

optimizer = Adam(model.mask_decoder.parameters(), lr=1e-5, weight_decay=0)
seg_loss = monai.losses.DiceCELoss(sigmoid=True, squared_pred=True, reduction='mean')

num_epochs = 100

device = "cuda"
print(torch.cuda.is_available())
model.to(device)

model.train()
for epoch in range(num_epochs):
    epoch_losses = []
    for batch in tqdm(train_dataloader):
      # forward pass
      outputs = model(pixel_values=batch["pixel_values"].to(device),
                      input_boxes=batch["input_boxes"].to(device),
                      multimask_output=False)

      # compute loss
      predicted_masks = outputs.pred_masks.squeeze(1)  # Squeeze if there's an unnecessary extra dimension
      ground_truth_masks = batch["ground_truth_mask"].float().to(device).squeeze(1)  # Make sure this matches expected dimensions
      ground_truth_masks = F.interpolate(ground_truth_masks.unsqueeze(1), size=(256, 256), mode='bilinear', align_corners=False)  # Resize if needed
      loss = seg_loss(predicted_masks, ground_truth_masks)

      # backward pass (compute gradients of parameters w.r.t. loss)
      optimizer.zero_grad()
      loss.backward()

      # optimize
      optimizer.step()
      epoch_losses.append(loss.item())

    print(f'EPOCH: {epoch}')
    print(f'Mean loss: {mean(epoch_losses)}')
     
