from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from supertonic import TTS
from pdf2image import convert_from_path
import pytesseract
import uuid
from dotenv import load_dotenv
from utils import img_central_crop

load_dotenv()

app = FastAPI()
app.mount("/audio", StaticFiles(directory="./audios/"), name="audio")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten later
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class TTSRequest(BaseModel):
    text: str

class IMGRequest(BaseModel):
    filename: str

@app.post("/tts")  # <--- must be POST
def tts(req: TTSRequest):
    tts = TTS(auto_download=True)

    # Get a voice style
    style = tts.get_voice_style(voice_name="F5")

    # Generate speech
    text = req.text
    wav, duration = tts.synthesize(text, voice_style=style)

    # Save to file
    filename = f"audio_{uuid.uuid4().hex}.wav"
    tts.save_audio(wav, f"audios/{filename}")

    return {"audio_file": filename}

@app.post("/img2text")  # <--- must be POST
def img2text(req: IMGRequest):
    filename = req.filename
    if filename.endswith(".pdf"):
        images = convert_from_path(filename)
    else: 
        img = img_central_crop(filename)
        text = pytesseract.image_to_string(img)

    text = ""
    for img in images:
        text_img = pytesseract.image_to_string(img)
        text += f"{text_img}\n"
    
    return {"text": text}
