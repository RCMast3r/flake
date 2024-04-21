# based on https://github.com/NielsRogge/Transformers-Tutorials/tree/master
import numpy as np
from torch.utils.data import Dataset
from PIL import Image
import os
# TODO add in the loading from an environment variable
class SAMDataset(Dataset):

    def __init__(self, ground_truth_type, ground_truth_path, image_dataset_path, processor):

        self.image_data = np.load(os.path.join(image_dataset_path, "samples.npy"), allow_pickle=True)
        
        prompt_res_path = os.path.join(ground_truth_path, "Prompting_results", ground_truth_type, "st1")
        max_dict = self.find_max_second_number(prompt_res_path)

        self.ground_truths = self.load_images_from_folder(prompt_res_path, max_dict)

        self.processor = processor

    # for handling the masks
    def find_max_second_number(self, folder_path):
        max_dict = {}
        for filename in os.listdir(folder_path):
            if filename.endswith("_mask.png"):  # Check if it's a relevant image
                parts = filename.split('_')
                if len(parts) == 3:  # Confirm filename format is as expected
                    index = int(parts[0])
                    second_number = int(parts[1])
                    if index in max_dict:
                        if second_number > max_dict[index]:
                            max_dict[index] = second_number
                    else:
                        max_dict[index] = second_number
        return max_dict

    def load_images_from_folder(self, folder_path, max_dict):
        images = []
        for filename in os.listdir(folder_path):
            if filename.endswith("_mask.png"):
                parts = filename.split('_')
                index = int(parts[0])
                second_number = int(parts[1])
                if second_number == max_dict.get(index, -1):  # Load only if it matches the max second number
                    img_path = os.path.join(folder_path, filename)
                    try:
                        with Image.open(img_path) as img:
                            images.append(np.array(img))
                    except IOError:
                        print(f"Error opening image {filename}")
        return images
        
    def get_bounding_box(ground_truth_map):
        # get bounding box from mask
        y_indices, x_indices = np.where(ground_truth_map > 0)
        x_min, x_max = np.min(x_indices), np.max(x_indices)
        y_min, y_max = np.min(y_indices), np.max(y_indices)
        # add perturbation to bounding box coordinates
        H, W = ground_truth_map.shape
        x_min = max(0, x_min - np.random.randint(0, 20))
        x_max = min(W, x_max + np.random.randint(0, 20))
        y_min = max(0, y_min - np.random.randint(0, 20))
        y_max = min(H, y_max + np.random.randint(0, 20))
        bbox = [x_min, y_min, x_max, y_max]

        return bbox

    def __len__(self):
        return len(self.image_data)

    def __getitem__(self, idx):
        
        
        image = self.image_data[idx]
        
        ground_truth_mask = self.ground_truths[idx]

        # get bounding box prompt
        prompt = self.get_bounding_box(ground_truth_mask)

        # prepare image and prompt for the model
        inputs = self.processor(image, input_boxes=[[prompt]], return_tensors="pt")

        # remove batch dimension which the processor adds by default
        inputs = {k: v.squeeze(0) for k, v in inputs.items()}

        # add ground truth segmentation
        inputs["ground_truth_mask"] = ground_truth_mask

        return inputs
