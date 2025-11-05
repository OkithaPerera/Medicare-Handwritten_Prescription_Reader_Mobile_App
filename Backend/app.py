# take image from the frontend -- Done
# send to the text detection model to detect texts -- Done
# crop and save the detections after renaming -- Done
# send the crop images directory to hcr model one by one --Done
# make validations to the detection using an llm -- Done
# ask what is this medcine and what is for
# ask what are the side effects of this medicine
# ask what is the dosage of this medicine
# ask how to take this medicine
# keep an array of recognitions and response the data

import os
from typing import List
import cv2
import uuid
import shutil
from PIL import Image
from io import BytesIO
from pydantic import BaseModel
from fastapi import FastAPI, HTTPException, status, File,UploadFile
from fastapi.responses import JSONResponse
from ultralytics import YOLO
from openai import OpenAI
from dotenv import load_dotenv
import os
import traceback
from predict import recognize_text_from_image
from fastapi.middleware.cors import CORSMiddleware



import base64
from fastapi.responses import JSONResponse
from PIL import Image

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],  
    allow_headers=["*"],  
)

SAVE_DIRECTORY = "./text_dir"

load_dotenv()
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
client = OpenAI(api_key=OPENAI_API_KEY)

os.makedirs(SAVE_DIRECTORY, exist_ok=True)

model = YOLO('./Model/best.pt')

def process_and_save_detected_text(image: Image.Image) -> list:
    """
    Detect text regions using YOLO, crop them, save to disk, and return saved file paths.

    :param image: Input PIL image
    :return: List of file paths of saved cropped images
    """
    result = model(image, conf=0.6)
    boxes = result[0].boxes 


    if len(boxes) == 0:
        raise ValueError("No text detected in the image.")

    box_data = boxes.xyxy.cpu().numpy()  
    confidences = boxes.conf.cpu().numpy() 

    sorted_boxes = sorted(box_data, key=lambda box: (box[1], box[0]))
    
    saved_files = []
    for idx, box in enumerate(sorted_boxes):
        x_min, y_min, x_max, y_max = map(int, box[:4]) 

        cropped_image = image.crop((x_min, y_min, x_max, y_max))

        file_name = f"text_{idx+1}_{uuid.uuid4().hex[:8]}.jpg"
        file_path = os.path.join(SAVE_DIRECTORY, file_name)

        cropped_image.save(file_path)
        saved_files.append(file_path)

    return saved_files


def run_prediction_on_cropped_images():
    recognized_texts = []  
    validated_texts = []   

    if os.path.exists(SAVE_DIRECTORY) and os.path.isdir(SAVE_DIRECTORY):
        for filename in os.listdir(SAVE_DIRECTORY):
            image_path = os.path.join(SAVE_DIRECTORY, filename)

            if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.tiff', '.bmp', '.gif')):
                image = cv2.imread(image_path)
                if image is None:
                    print(f"Failed to load the image: {filename}")
                    continue 
                
                predicted_text = recognize_text_from_image(image)
                validated_text = llm_validation(predicted_text)
                recognized_texts.append(predicted_text)
                validated_texts.append(validated_text)
                print(f"Recognized text from {filename}: {predicted_text}")
        
        return recognized_texts, validated_texts 

    else:
        print("No directory found")
        return [], []  
    
def clear_save_directory(directory: str) -> None:
    if os.path.exists(directory):
        for file in os.listdir(directory):
            file_path = os.path.join(directory, file)
            try:
                if os.path.isfile(file_path) or os.path.islink(file_path):
                    os.unlink(file_path) 
                elif os.path.isdir(file_path):
                    shutil.rmtree(file_path)  
            except Exception as e:
                print(f"Failed to delete {file_path}. Reason: {e}")

def llm_validation(detected_text):
    # detected_text ="Sabursele Cong"
    prompt = f"""I have extracted the following text from a handwritten medical prescription:
            Detected text: {detected_text}
            As a medical expert, analyze the text and determine the most likely correct medicine 
            name based on known drug names, spellings, and context. If the text does not clearly 
            correspond to a valid medicine, return only "INVALID" to indicate rejection.

        Provide only the corrected medicine name or "INVALID", with no additional text or explanation.
    """
    try:
        completion = client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "user", "content": prompt}], # type: ignore
            max_tokens=50,  
            temperature=0.2,  
        )
        res = completion.choices[0].message.content
        print(f"Response: {res}")
        return res
    except Exception as e:
        error = f"OpenAI API error: {str(e)}"
        return error

def get_medcine_summary(medicine_name):
    prompt= f"""I need a medical summary for the following medicine:
        Medicine Name: {medicine_name}

        Provide a short and clear response, including:

        Class: (e.g., antibiotic, painkiller, anticoagulant)
        Uses: (main medical conditions it treats)
        Common Dosage: (typical prescribed dose)
    Keep the response concise and medically accurate.
    """
    try:
        completion = client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "user", "content": prompt}], # type: ignore
            max_tokens=250,  
            temperature=0.3,  
        )
        res = completion.choices[0].message.content
        print(f"Response: {res}")
        return res
    except Exception as e:
        error = f"OpenAI API error: {str(e)}"
        return error
    
def get_instructions_to_use(medcine_name):
    prompt = f"""I need usage instructions for the following medicine:

        Medicine Name: {medcine_name}

        Provide a structured response including:

        How to Take It: (e.g., with food, water, time of day)
        Dosage by Age Group:
        Adults (18+ years): (recommended dosage & frequency)
        Adolescents (12–17 years): (if applicable)
        Children (6–11 years): (if applicable)
        Infants & Toddlers (0–5 years): (if applicable)
        Special Instructions: (e.g., avoid alcohol, dose adjustments for kidney/liver disease)
        Keep the response clear, structured, and medically accurate.
    """
    try:
        completion = client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "user", "content": prompt}], # type: ignore
            max_tokens=150,  
            temperature=0.2,  
        )
        res = completion.choices[0].message.content
        print(f"Response: {res}")
        return res
    except Exception as e:
        error = f"OpenAI API error: {str(e)}"
        return error
    
def get_side_effects(medcine_name):
    prompt = f"""I need a list of side effects for the following medicine:

        Medicine Name: {medcine_name}

        Provide a structured response, categorizing the side effects into:

        Common Side Effects (≥1% occurrence): (e.g., nausea, headache)
        Less Common Side Effects (0.1% – 1% occurrence): (e.g., dizziness, rash)
        Rare but Serious Side Effects (<0.1% occurrence): (e.g., severe allergic reactions, liver toxicity)
        When to Seek Medical Help: (signs of severe reactions that require urgent care)
        Keep the response clear, structured, and medically accurate
    """
    try:
        completion = client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "user", "content": prompt}], # type: ignore
            max_tokens=150,  
            temperature=0.4  
        )
        res = completion.choices[0].message.content
        print(f"Response: {res}")
        return res
    except Exception as e:
        error = f"OpenAI API error: {str(e)}"
        return error
    

    
@app.post("/get_prescription", status_code=200)
async def get_image(file: bytes = File(...)):
    try:
        clear_save_directory(SAVE_DIRECTORY)
        input_image = Image.open(BytesIO(file)).convert("RGB")
        saved_files = process_and_save_detected_text(input_image)
        # text, medicine = run_prediction_on_cropped_images()
        
        # Convert saved images to Base64
        encoded_images = []
        for file_path in saved_files:
            with open(file_path, "rb") as image_file:
                encoded_string = base64.b64encode(image_file.read()).decode("utf-8")
                encoded_images.append(encoded_string)

        return JSONResponse(
            status_code=200,
            content={
                "message": "Text regions detected and saved.",
                # "recognized_text": text,
                # "suggested_medicine": medicine,
                "images": encoded_images  # Base64 encoded images
            },
        )
    except Exception as e:
        error_message = traceback.format_exc()
        print("Error occurred:", error_message)
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")

@app.post('/run_prediction', status_code=200)
async def predict_text(files: List[UploadFile] = File(...)):
    try:
        print('hery')
        clear_save_directory(SAVE_DIRECTORY)
        print('here')
        saved_paths = []
        
        for file in files:
            # image = Image.open(BytesIO(await file.read())).convert("RGB")
            file_content = await file.read()
            image = Image.open(BytesIO(file_content)).convert("RGB")
            filename = f"{uuid.uuid4().hex}.jpg"  
            file_path = os.path.join(SAVE_DIRECTORY, filename)
            image.save(file_path)
            saved_paths.append(file_path)

        text, medicine = run_prediction_on_cropped_images()
        return JSONResponse(
            status_code=200,
            content={
                "message": "Prescriptions detected and validated.",
                "recognized_text": text,
                "suggested_medicine": medicine,
            },
        )
    except Exception as e:
        error_message = traceback.format_exc()
        print("Error occurred:", error_message)
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")

@app.post("/get_medicine_summuary", status_code=200)
async def get_medicine_summuary(medicine_name:str):
    try:
        medicine_summary = get_medcine_summary(medicine_name)
        return JSONResponse(
            status_code=200,
            content={"message": "Medicine summary.", "medicine_summary": medicine_summary},
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")
    
@app.post("/get_usage_instructions", status_code=200)
async def get_usage_instructions(medicine_name:str):
    try:
        medicine_summary = get_instructions_to_use(medicine_name)
        return JSONResponse(
            status_code=200,
            content={"message": "Instructions to Use.", "medicine_summary": medicine_summary},
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")
    

@app.post("/get_side_effects", status_code=200)
async def get_side_medicine_effects(medicine_name:str):
    try:
        medicine_summary = get_side_effects(medicine_name)
        return JSONResponse(
            status_code=200,
            content={"message": "Medicine Side effects.", "medicine_summary": medicine_summary},
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")