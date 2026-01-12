from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from supertonic import TTS
import uuid
from dotenv import load_dotenv

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
