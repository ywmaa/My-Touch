from InvokeAI.ldm.generate import Generate

# Create an object with default values
gr = Generate()

# do the slow model initialization
gr.load_model()

# Do the fast inference & image generation. Any options passed here
# override the default values assigned during class initialization
# Will call load_model() if the model was not previously loaded and so
# may be slow at first.
# The method returns a list of images. Each row of the list is a sub-list of [filename,seed]
results = gr.prompt2png(prompt     = "an astronaut riding a horse",
                         outdir     = "./outputs/samples",
                         iterations = 3)

for row in results:
    print(f'filename={row[0]}')
    print(f'seed    ={row[1]}')