from torch.utils.data import DataLoader
from NixSAMData import SAMDataset


train_dataset = SAMDataset(dataset=dataset, processor=processor)
train_dataloader = DataLoader(train_dataset, batch_size=2, shuffle=True)
