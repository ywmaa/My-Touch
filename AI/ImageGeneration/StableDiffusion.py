from InvokeAI.ldm.generate import Generate

# Create an object with default values
gr = Generate(weights = "weights/model.ckpt",
              config  = 'InvokeAI/configs/stable-diffusion/v1-inference.yaml')

# do the slow model initialization
#gr.load_model()

# Do the fast inference & image generation. Any options passed here
# override the default values assigned during class initialization
# Will call load_model() if the model was not previously loaded and so
# may be slow at first.
# The method returns a list of images. Each row of the list is a sub-list of [filename,seed]
results = gr.prompt2png(prompt     = "an astronaut riding a horse",
                         outdir     = "./outputs",
                         iterations = 1)

for row in results:
    print(f'filename={row[0]}')
    print(f'seed    ={row[1]}')


"""
The full list of arguments to Generate() are:
gr = Generate(
          weights     = path to model weights ('models/ldm/stable-diffusion-v1/model.ckpt')
          config     = path to model configuraiton ('configs/stable-diffusion/v1-inference.yaml')
          iterations  = <integer>     // how many times to run the sampling (1)
          steps       = <integer>     // 50
          seed        = <integer>     // current system time
          sampler_name= ['ddim', 'k_dpm_2_a', 'k_dpm_2', 'k_euler_a', 'k_euler', 'k_heun', 'k_lms', 'plms']  // k_lms
          grid        = <boolean>     // false
          width       = <integer>     // image width, multiple of 64 (512)
          height      = <integer>     // image height, multiple of 64 (512)
          cfg_scale   = <float>       // condition-free guidance scale (7.5)
          )

"""

"""
ldm.generate.prompt2image() is the common entry point for txt2img() and img2img()
It takes the following arguments:
    prompt                          // prompt string (no default)
    iterations                      // iterations (1); image count=iterations
    steps                           // refinement steps per iteration
    seed                            // seed for random number generator
    width                           // width of image, in multiples of 64 (512)
    height                          // height of image, in multiples of 64 (512)
    cfg_scale                       // how strongly the prompt influences the image (7.5) (must be >1)
    seamless                        // whether the generated image should tile
    init_img                        // path to an initial image
    strength                        // strength for noising/unnoising init_img. 0.0 preserves image exactly, 1.0 replaces it completely
    gfpgan_strength                 // strength for GFPGAN. 0.0 preserves image exactly, 1.0 replaces it completely
    ddim_eta                        // image randomness (eta=0.0 means the same seed always produces the same image)
    step_callback                   // a function or method that will be called each step
    image_callback                  // a function or method that will be called each time an image is generated
    with_variations                 // a weighted list [(seed_1, weight_1), (seed_2, weight_2), ...] of variations which should be applied before doing any generation
    variation_amount                // optional 0-1 value to slerp from -S noise to random noise (allows variations on an image)

To use the step callback, define a function that receives two arguments:
- Image GPU data
- The step number

To use the image callback, define a function of method that receives two arguments, an Image object
and the seed. You can then do whatever you like with the image, including converting it to
different formats and manipulating it. For example:

    def process_image(image,seed):
        image.save(f{'images/seed.png'})

The callback used by the prompt2png() can be found in ldm/dream_util.py. It contains code
to create the requested output directory, select a unique informative name for each image, and
write the prompt into the PNG metadata.
"""