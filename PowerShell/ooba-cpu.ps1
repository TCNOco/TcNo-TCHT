

iex (irm install-git.tb.ag)

# CD into text-generation-webui if not already
mkdir -p repositories
Set-Location repositories
git clone https://github.com/qwopqwop200/GPTQ-for-LLaMa


git clone https://github.com/oobabooga/GPTQ-for-LLaMa.git -b cuda
cd GPTQ-for-LLaMa
python setup_cuda.py install