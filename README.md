(For us) Optional README that can be developed later in case we want to save details for project. Ideally we'd have Shivant largely write it as it relates a lot to overarching goals and purpose of the project but I (Ian) will start by just outlining the general structure and then  we can add more documentation later.

What to include:

Project Title

Project Description
  - Describe what the code does in relation to research
  - Why we used given technologies
  - Challenges we have to help any future development
  - Table of contents (If project gets large - I don't expect it will be needed)
  - How to install and run
  - How to use the code
  - Credits for team members
  - License if you want to be fancy

HOW TO RUN

The Linkdin amazon data set is too large to store on the repository, /cleaning has scripts to shorten the dataset, but make sure you aren't tracking the large one on git, even though it should be locally stored in /Data.

In order to run the project's scripts, you need to reproduce the virtual environment on your local machine. Create a virtual environment, activate it, and then install the requirements to the virtual environment. (Will not be on your global machine) Should look like:

```
~ % python3 -m venv DIR/env
~ % source DIR/env/bin/activate
(env) ~ % pip install -r DIR/BrookingsChicago/requirements.txt
```

Work should be done in the virtual environment. To go back to base status run the command:

```
(env) ~ % deactivate
```


cleaning:
  - amz.py: First argument is state one wants to parse to.
  - listJobs.py: First argument is file to parse. Lists the job mapped roles set by Brookings to command line.
