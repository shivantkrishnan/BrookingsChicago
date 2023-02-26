(For us) Optional README that can be developed later in case we want to save details for project. Ideally we'd have Shivant largely write it as it relates a lot to overarching goals and purpose of the project but I (Ian) will start by just outlining the general structure and then  we can add more documentation later.

What to include:

Project Title

Project Description:
  - Describe what the code does in relation to research
  - Why we used given technologies
  - Challenges we have to help any future development
  - Table of contents (If project gets large - I don't expect it will be needed)
  - How to install and run
  - How to use the code
  - Credits for team members
  - License if you want to be fancy

HOW TO RUN

Data set is too large to store on repo, install on local and then store in /Data directory for script to work.

In order to run the project's scripts, you need to reproduce the virtual environment on your local machine. Create a virtual environment, activate it, and then install the requirements to the virtual environment. (Will not be on your global machine) Should look like:


~ % python3 -m venv DIRECTORY/env

~ % source DIRECTORY/env/bin/activate

(env) ~ % pip install -r DIRECTORY/BrookingsChicago/requirements.txt


Work should be done in the virtual environment. To go back to base status run the command:


(env) ~ % deactivate

