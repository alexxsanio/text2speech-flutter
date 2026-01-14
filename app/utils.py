from PIL import Image

def img_central_crop(filename):
    img = Image.open(filename)
    w, h = img.size

    size = min(w, h)

    left = int((w - size) * 3.2 / 4)
    top = (h - size) // 2
    right = left + size
    bottom = top + size

    img.crop((left, top, right, bottom))
    return img