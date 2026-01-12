from fastapi import FastAPI
from pydantic import BaseModel
from supertonic import TTS
from fastapi.staticfiles import StaticFiles
from dotenv import load_dotenv
import uuid
import os


app = FastAPI()
app.mount("/audio", StaticFiles(directory="."), name="audio")

class TTSRequest(BaseModel):
    text: str

@app.post("/tts")
def tts(req: TTSRequest):
    tts = TTS(auto_download=True)

    # Get a voice style
    style = tts.get_voice_style(voice_name="F5")

    # Generate speech
    text = req.text
    wav, duration = tts.synthesize(text, voice_style=style)
    # wav: np.ndarray, shape = (1, num_samples)
    # duration: np.ndarray, shape = (1,)

    # Save to file
    filename = f"audio_{uuid.uuid4().hex}.wav"
    tts.save_audio(wav, filename)

    return {"audio_file": filename}
