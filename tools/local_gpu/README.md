# Lokala animationer på din egen dator (ROG Ally X)

**Kort:** Det här gör samma animationsklipp som Hugging Face, fast på din
egen dator, utan kvot. Det går långsamt på Ally X:ens inbyggda grafik
(räkna med 10–40 minuter per klipp), men det gör inget: låt den stå över natten.

## Engångsinstallation
1. Installera **Python 3.11** från python.org (kryssa i *Add Python to PATH*).
2. **Ally X:** öppna Armoury Crate → *Performance* → sätt *GPU Memory* (UMA) till
   **12 GB eller mer** och kör i *Turbo* med laddaren i.
3. Dubbelklicka `setup_windows.bat`. Den laddar ner PyTorch (för AMD) och
   resten. Första gången tar det en stund.

## Köra
- Dubbelklicka `run_queue.bat`. Den skriver först vilka klipp som saknas och
  börjar sen göra dem ett i taget. Modellen (Wan 2.2 TI2V 5B, ca 10 GB) laddas
  ner första gången.
- Klara klipp hamnar i `tools/local_gpu/clips/`.
- Du kan stänga fönstret när som helst: nästa gång fortsätter den där den var.

## Lämna över klippen
Lägg in mappen `clips/` i git och pusha (eller skicka klippen), så skär
Claude dem till sprites med `tools/video2sprite.py` och lägger in dem i spelet.

## Vad som står i kön
`queue.json`: vem, vilka rörelser och en beskrivning. Startbilderna (en
grönskärmsbild per figur) ligger i `starts/<vem>.png`. Ny figur = lägg in en
startbild och en rad i `queue.json`.

## Om det strular
- *"No GPU found"*: ROCm/DirectML installerades inte. Kör setup igen, eller
  installera AMD:s senaste Adrenalin-drivrutin först.
- *Slut på minne*: höj GPU Memory i Armoury Crate, eller kör
  `python local_wan.py --size 576x448 --frames 33`.
- Det är beta-stöd för AMD på Windows; ett NVIDIA-kort funkar direkt.
