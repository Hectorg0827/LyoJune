# On-Device AI: Gemma Model Conversion Guide

## 1. Overview

This document provides the necessary steps to download, convert, and integrate a Google Gemma language model for on-device inference in the LyoAppNewUI iOS application. The app's architecture is designed to use a small, local LLM for low-latency tasks like voice command intent recognition.

The recommended model is **Gemma 2B**, a powerful yet efficient model suitable for mobile devices. The target format is **Core ML (`.mlpackage`)**, which allows the model to be executed efficiently by Apple's hardware, including the Neural Engine.

## 2. Prerequisites

Before you begin, you will need:
- A [Hugging Face](https://huggingface.co/) account.
- Python 3.9+ installed on your machine.
- `pip` (the Python package installer).

## 3. Step-by-Step Conversion Process

### Step 1: Get Access to Gemma & Hugging Face Token

1.  Navigate to the [Gemma model page on Hugging Face](https://huggingface.co/google/gemma-2b).
2.  Read and accept the license terms to gain access to the model weights.
3.  Go to your Hugging Face account settings: `Settings` -> `Access Tokens`.
4.  Generate a new token with "Read" permissions. **Copy this token immediately** as you will need it in the script.

### Step 2: Set Up Python Environment

Open your terminal and install the required libraries. It is highly recommended to install `coremltools` directly from the `main` branch to get the latest updates for Gemma support.

```bash
pip install --upgrade "coremltools==9.0b1" transformers torch accelerate sentencepiece
```
*(Note: A specific beta version of coremltools is specified for stability, but you can also use `git+https://github.com/apple/coremltools.git` for the absolute latest version if needed.)*

### Step 3: Run the Conversion Script

1.  Create a new Python file named `convert_gemma.py`.
2.  Copy and paste the entire script below into that file.
3.  Replace `"YOUR_HUGGING_FACE_TOKEN"` with the access token you copied in Step 1.
4.  Run the script from your terminal: `python convert_gemma.py`

This script will download the Gemma 2B model, convert it to Core ML, and save it as `gemma_2b.mlpackage` in the same directory.

**`convert_gemma.py`:**
```python
import torch
import coremltools as ct
from transformers import AutoModelForCausalLM, AutoTokenizer
import os

# --- Configuration ---
HF_MODEL_NAME = "google/gemma-2b"
HF_TOKEN = "YOUR_HUGGING_FACE_TOKEN" # <--- PASTE YOUR HUGGING FACE TOKEN HERE
MODEL_OUTPUT_DIR = "./"
MODEL_FILENAME = "gemma_2b.mlpackage"

# --- Main Conversion Logic ---
def main():
    print(f"Loading Hugging Face model '{HF_MODEL_NAME}' into memory...")

    # Load the model and tokenizer from Hugging Face
    model = AutoModelForCausalLM.from_pretrained(HF_MODEL_NAME, token=HF_TOKEN)
    tokenizer = AutoTokenizer.from_pretrained(HF_MODEL_NAME, token=HF_TOKEN)

    print("Model loaded and configured.")

    # Create a wrapper for tracing, as Core ML needs a concrete example of inputs
    class GemmaWrapper(torch.nn.Module):
        def __init__(self, model):
            super().__init__()
            self.model = model

        def forward(self, input_ids):
            # The model returns a tuple, we only need the logits for Core ML
            return self.model(input_ids=input_ids).logits

    wrapper_model = GemmaWrapper(model)
    wrapper_model.eval()

    # Trace the model with a sample input
    # This creates a static graph that Core ML can convert.
    print("Tracing wrapper model to TorchScript...")
    example_input = torch.randint(0, model.config.vocab_size, (1, 10)) # Batch size 1, sequence length 10
    traced_model = torch.jit.trace(wrapper_model, example_input)
    print("TorchScript tracing complete.")

    # Convert the TorchScript model to Core ML
    print("Converting TorchScript model to Core ML...")
    ml_program = ct.convert(
        traced_model,
        convert_to="mlprogram",
        inputs=[ct.TensorType(name="input_ids", shape=(1, ct.RangeDim(1, 2048)), dtype=torch.int32)],
        compute_units=ct.ComputeUnit.ALL,
        minimum_deployment_target=ct.target.iOS17
    )

    print("Core ML conversion complete.")

    # Save the converted model
    output_path = os.path.join(MODEL_OUTPUT_DIR, MODEL_FILENAME)
    ml_program.save(output_path)

    print(f"Successfully converted and saved model to: {output_path}")


if __name__ == "__main__":
    main()
```

### Step 4: Add the Model to Xcode

1.  After the script finishes, you will have a `gemma_2b.mlpackage` file.
2.  Open the `LyoAppNewUI` project in Xcode.
3.  Drag the `gemma_2b.mlpackage` file directly into the Xcode project navigator.
4.  A dialog will appear. Make sure "Copy items if needed" is checked and that your app's main target (`LyoApp`) is selected.
5.  Click "Finish".

The model is now part of your app bundle and can be loaded by the on-device inference service you will build next.
```
