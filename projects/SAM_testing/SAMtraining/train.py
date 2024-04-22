#!/usr/bin/python3

import torch
from torch.utils.data import random_split, DataLoader
from data_handler.NixSAMData import SAMDataset
from transformers import SamModel, SamProcessor
import torch.nn.functional as F
from torch.optim import Adam
import monai
from tqdm import tqdm
from statistics import mean
import os

torch.manual_seed(21231)

image_dataset_path = os.environ.get('DATASET')
ground_truth_path = os.environ.get('GROUNDTRUTH')
ground_truth_type = os.environ.get('GT_TYPE')

processor = SamProcessor.from_pretrained("facebook/sam-vit-base", cache_dir=".")
dataset = SAMDataset(ground_truth_type=ground_truth_type, ground_truth_path=ground_truth_path, image_dataset_path=image_dataset_path, processor=processor)

# Split dataset into train and validation
train_size = int(0.8 * len(dataset))
val_size = len(dataset) - train_size
train_dataset, val_dataset = random_split(dataset, [train_size, val_size])

train_dataloader = DataLoader(train_dataset, batch_size=2, shuffle=True)
val_dataloader = DataLoader(val_dataset, batch_size=2, shuffle=False)

model = SamModel.from_pretrained("facebook/sam-vit-base")

# Make sure we only compute gradients for mask decoder
for name, param in model.named_parameters():
    if name.startswith("vision_encoder") or name.startswith("prompt_encoder"):
        param.requires_grad_(False)

optimizer = Adam(model.mask_decoder.parameters(), lr=1e-5, weight_decay=0)
seg_loss = monai.losses.DiceCELoss(sigmoid=True, squared_pred=True, reduction='mean')

num_epochs = 5
device = "cuda" if torch.cuda.is_available() else "cpu"
model.to(device)

# Initialize best loss value for model saving condition
best_loss = float('inf')
model.train()

for epoch in range(num_epochs):
    model.train()
    epoch_losses = []
    for batch in tqdm(train_dataloader):
        outputs = model(pixel_values=batch["pixel_values"].to(device),
                        input_boxes=batch["input_boxes"].to(device),
                        multimask_output=False)
        predicted_masks = outputs.pred_masks.squeeze(1)
        ground_truth_masks = batch["ground_truth_mask"].float().to(device).squeeze(1)
        ground_truth_masks = F.interpolate(ground_truth_masks.unsqueeze(1), size=(256, 256), mode='bilinear', align_corners=False)
        loss = seg_loss(predicted_masks, ground_truth_masks)
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        epoch_losses.append(loss.item())

    # Validation phase
    model.eval()
    val_losses = []
    with torch.no_grad():
        for val_batch in val_dataloader:
            outputs = model(pixel_values=val_batch["pixel_values"].to(device),
                            input_boxes=val_batch["input_boxes"].to(device),
                            multimask_output=False)
            predicted_masks = outputs.pred_masks.squeeze(1)
            ground_truth_masks = val_batch["ground_truth_mask"].float().to(device).squeeze(1)
            ground_truth_masks = F.interpolate(ground_truth_masks.unsqueeze(1), size=(256, 256), mode='bilinear', align_corners=False)
            val_loss = seg_loss(predicted_masks, ground_truth_masks)
            val_losses.append(val_loss.item())

    avg_train_loss = mean(epoch_losses)
    avg_val_loss = mean(val_losses)
    print(f'EPOCH: {epoch}, Train Loss: {avg_train_loss}, Validation Loss: {avg_val_loss}')

    if avg_val_loss < best_loss:
        best_loss = avg_val_loss
        torch.save(model.state_dict(), 'best_model_weights.pth')
        print(f"Saved best model weights with Validation Loss: {best_loss}")