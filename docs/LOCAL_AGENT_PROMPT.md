# Prompt for a local agent on the ROG Ally X (animation clips)

**Svenska:** Klistra in texten nedan (från "You are working on") till en
agent som kör lokalt på Ally X:en (t.ex. Claude Code i Claude-appen på
datorn). Den gör animationsklippen på datorns grafikkort och pushar dem,
sen gör Claude sprites av dem och lägger in dem i spelet.

---

You are working on the Windows game project "Father & Son" (Godot 4.7.2) on a
ROG Ally X (AMD Radeon 890M iGPU, 14 GB VRAM set in Armoury Crate, plug the
charger in and use Turbo mode). Your job: generate animation video clips
locally with Wan 2.2 TI2V-5B and push them to GitHub. Do not change any game
code.

0. Keep the machine awake for the whole job (it stopped overnight last
   time). In an admin PowerShell:
   `powercfg /change standby-timeout-ac 0`
   `powercfg /change hibernate-timeout-ac 0`
   `powercfg /change monitor-timeout-ac 0`
   Keep the charger in. If the model download (~30 GB) stopped half way,
   just run the same command again: Hugging Face downloads resume from where
   they stopped (the cache is in `%USERPROFILE%\.cache\huggingface`). If it
   keeps failing, run `set HF_HUB_ENABLE_HF_TRANSFER=1` after
   `pip install hf_transfer` in the venv, then retry.
1. Get the code (skip if it is already on disk):
   `git clone https://github.com/Rebelyouthz/HnT.git` then
   `git checkout claude/gallant-galileo-5ctrmf` (pull if it already exists).
   Read `tools/local_gpu/README.md` first.
2. Make sure Python 3.11 (64-bit, on PATH) and git are installed. Then run
   `tools/local_gpu/setup_windows.bat` once (creates `tools/local_gpu/venv`,
   installs PyTorch for the AMD GPU: ROCm nightlies for gfx1150, else
   torch-directml, plus diffusers etc.). Verify the GPU is used:
   `venv\Scripts\python -c "import torch;print(torch.cuda.is_available())"`
   (ROCm) or `import torch_directml` works (DirectML). If neither works, fix
   the install (latest AMD Adrenalin driver, try the other backend) before
   generating; CPU would take days.
3. Generate, in this order (from `tools/local_gpu`, venv active):
   **The machine froze last time at 100 % memory.** First `git pull` (the
   script is now gentle: max 11 GB on the GPU, the text model is thrown out
   of memory after the prompts are read, half the CPU cores, low priority,
   30 s rest between clips). If it still struggles, close everything else and
   use `python local_wan.py --vram 10 --rest 60 --frames 41`.
   `python local_wan.py --list` to see what is missing, then
   `python local_wan.py --only son`
   `python local_wan.py --only punk`
   `python local_wan.py --only cop`
   `python local_wan.py --only bag_snatch`
   `python local_wan.py --only mohawk`
   `python local_wan.py --only shift_lead`
   `python local_wan.py --only roof_runner`
   Then the rest: `python local_wan.py`.
   Clips land in `tools/local_gpu/clips/<who>_<move>.mp4`; a finished clip is
   skipped on the next run, so it is safe to stop and restart.
   If it runs out of memory: `--size 576x448 --frames 33`. If one clip takes
   more than ~60 minutes, try `--steps 20`.
4. After every few clips (and at the end), commit and push ONLY the clips:
   `git add tools/local_gpu/clips/*.mp4`
   `git commit -m "Local Wan clips: <list>"`
   `git push origin claude/gallant-galileo-5ctrmf`
   (pull --rebase first if the push is rejected). Never commit tokens, keys,
   the venv folder or the model cache.
5. Report which clips were made, the time per clip, and any errors.
6. If the run stops (crash, sleep, reboot): open the folder again, activate
   the venv (`tools\local_gpu\venv\Scripts\activate`) and run
   `python local_wan.py` again. Finished clips are skipped; it carries on.

Quality check before pushing: open a couple of clips. The character should
stay in a strict side view facing right on a flat green background, full
body in frame, and do the move named in the file. Delete and regenerate a
clip (change nothing else; the seed differs per run) if the body melts,
leaves the frame or the camera moves.
