import os
os.environ["CUDA_VISIBLE_DEVICES"] = ""  # disable GPU
os.environ["FORCE_CPU"] = "1"     
import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image

# Device configuration

device = torch.device("cpu")


# Load model only once
model = models.resnet50(weights=None)
num_features = model.fc.in_features
model.fc = nn.Linear(num_features, 2)
model.load_state_dict(torch.load("fmd_resnet50.pth", map_location=device))
model.to(device)
model.eval()

# Class names
classes = ["FMD_Infected", "Healthy"]

# Transform (same as training)
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406],
                         [0.229, 0.224, 0.225])
])

def predict_from_image_file(file_stream):
    """
    Predicts Foot and Mouth Disease (FMD) infection from an image file stream.

    Args:
        file_stream: file-like object (e.g., from Flask's request.files["file"].stream)
    
    Returns:
        dict: {
            "prediction": <class_name>,
            "confidence": <float>,
            "probabilities": { "FMD_Infected": <float>, "Healthy": <float> }
        }
    """
    img = Image.open(file_stream).convert("RGB")
    img_tensor = transform(img).unsqueeze(0).to(device)

    with torch.no_grad():
        outputs = model(img_tensor)
        probs = torch.softmax(outputs, dim=1)[0]
        conf, pred = torch.max(probs, 0)

    result = {
        "prediction": classes[pred.item()],
        "confidence": round(float(conf.item()) * 100, 2),
        "probabilities": {
            classes[0]: round(float(probs[0]) * 100, 2),
            classes[1]: round(float(probs[1]) * 100, 2)
        }
    }
    return result
