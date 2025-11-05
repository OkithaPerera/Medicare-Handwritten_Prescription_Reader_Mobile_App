import cv2
import numpy as np
from tkinter import Tk
from tkinter.filedialog import askopenfilename
from mltu.inferenceModel import OnnxInferenceModel
from mltu.utils.text_utils import ctc_decoder
from mltu.transformers import ImageResizer
from mltu.configs import BaseModelConfigs



class ImageToWordModel(OnnxInferenceModel):
    def __init__(self, char_list, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.char_list = char_list

    def predict_text(self, image: np.ndarray):
        """
        Predict text from an image.
        :param image: Input image as a NumPy array.
        :return: Recognized text.
        """
        image = ImageResizer.resize_maintaining_aspect_ratio(image, *self.input_shape[:2][::-1])
        image_pred = np.expand_dims(image, axis=0).astype(np.float32)
        preds = self.model.run(None, {self.input_name: image_pred})[0]
        text = ctc_decoder(preds, self.char_list)[0]
        return text

# Load model once and reuse
configs = BaseModelConfigs.load("Models/04_sentence_recognition/202301131202/configs.yaml")
model = ImageToWordModel(model_path=configs.model_path, char_list=configs.vocab)

def recognize_text_from_image(image: np.ndarray):
    """
    Recognize text from a given image.
    :param image: Image in NumPy array format.
    :return: Recognized text.
    """
    if image is None:
        raise ValueError("Error: Provided image is None.")
    return model.predict_text(image)
